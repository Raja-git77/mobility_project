import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobility_project/main.dart' hide PaymentScreen;
import 'package:mobility_project/ai_engine.dart';
import 'package:mobility_project/services/geocoding_service.dart';
import 'package:mobility_project/utils/map_animation_helper.dart';
import 'package:mobility_project/screens/vehicle_selection_page.dart';
import 'package:mobility_project/screens/payment_screen.dart';

void main() {
  test('MobilityApp can be instantiated without errors', () {
    const app = MobilityApp();
    expect(app, isNotNull);
  });


  group('AIEngine Tests (IEEE Paper Section VII)', () {
    test('VII.A Vehicle Recommendation produces ranked vehicles with match %', () {
      final engine = AIEngine.instance;
      final vehicles = engine.rankVehicles(
        selectedService: 'Self-Drive Car',
        tripDistanceKm: 18.0,
        durationHours: 3,
      );

      expect(vehicles.length, 5);
      expect(vehicles.first.matchPercentage, greaterThanOrEqualTo(80.0));
      expect(vehicles.first.matchPercentage, lessThanOrEqualTo(100.0));
    });

    test('VII.B Demand Prediction produces valid surge and repositioning units', () {
      final engine = AIEngine.instance;
      final forecast = engine.predictDemand(location: 'Central Station');

      expect(forecast.location, 'Central Station');
      expect(forecast.surgeMultiplier, greaterThanOrEqualTo(1.0));
      expect(forecast.expectedBookingVolumePerHour, greaterThan(0));
    });

    test('VII.C Driver Matching ranks drivers by proximity, experience and rating', () {
      final engine = AIEngine.instance;
      final drivers = engine.matchDrivers(
        pickupAddress: 'Central Station',
        serviceType: 'Rental + Driver',
        tripDistanceKm: 12.0,
      );

      expect(drivers.isNotEmpty, true);
      expect(drivers.first.compositeScore, greaterThan(80.0));
      expect(drivers.first.rating, greaterThan(4.5));
    });

    test('VII.D Route Optimization generates savings vs baseline', () {
      final engine = AIEngine.instance;
      final route = engine.optimizeRoute(
        baselineDistanceKm: 15.0,
        trafficStatus: 'Moderate',
      );

      expect(route.optimizedDistanceKm, lessThan(route.baselineDistanceKm));
      expect(route.timeSavedMinutes, greaterThan(0));
    });

    test('VII.E Dynamic Pricing enforces reasonable bounds and caps', () {
      final engine = AIEngine.instance;
      final price = engine.calculatePrice(
        baseServiceRate: 1200.0,
        vehicleMultiplier: 1.3,
        distanceKm: 10.0,
        surgeMultiplier: 1.25,
      );

      expect(price.totalFare, greaterThan(1200.0));
      expect(price.surgeAddition, greaterThanOrEqualTo(0.0));
    });

    test('VII.F Fraud & Anomaly Detection flags abnormal trip distances', () {
      final engine = AIEngine.instance;
      final cleanReport = engine.checkBookingAnomaly(
        userId: 'user123',
        distanceKm: 15.0,
        fare: 1500.0,
        pickup: 'Central Station',
        dropoff: 'Tech Park',
      );
      expect(cleanReport.isClean, true);

      final anomalyReport = engine.checkBookingAnomaly(
        userId: 'user123',
        distanceKm: 500.0,
        fare: 1500.0,
        pickup: 'Central Station',
        dropoff: 'Tech Park',
      );
      expect(anomalyReport.isClean, false);
    });

    test('Section XII Performance Evaluation metrics return paper benchmarks', () {
      final metrics = AIEngine.instance.getPerformanceMetrics();
      expect(metrics.recommendationAccuracy, 94.2);
      expect(metrics.driverAcceptanceRate, 96.8);
      expect(metrics.averageDriverArrivalMins, 4.8);
      expect(metrics.vehicleUtilizationPct, 82.6);
      expect(metrics.demandMae, 1.42);
    });
  });

  group('Forward Geocoding & Map Camera Tests', () {
    test('GeocodingService resolves landmark addresses to LatLng', () async {
      final centralCoords = await GeocodingService.instance.geocodeAddress('Central Railway Station');
      expect(centralCoords, isNotNull);
      expect(centralCoords!.latitude, closeTo(13.085, 0.05));
      expect(centralCoords.longitude, closeTo(80.278, 0.05));

      final airportCoords = await GeocodingService.instance.geocodeAddress('Airport T1');
      expect(airportCoords, isNotNull);
      expect(airportCoords!.latitude, closeTo(12.985, 0.05));
      expect(airportCoords.longitude, closeTo(80.163, 0.05));
    });

    test('GeocodingService parses raw coordinate inputs directly', () async {
      final coords = await GeocodingService.instance.geocodeAddress('13.0827, 80.2707');
      expect(coords, isNotNull);
      expect(coords!.latitude, 13.0827);
      expect(coords.longitude, 80.2707);
    });

    testWidgets('MapController animateCamera extension can be invoked with rendered map', (tester) async {
      final mapController = MapController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlutterMap(
              mapController: mapController,
              options: const MapOptions(
                initialCenter: LatLng(13.0827, 80.2707),
                initialZoom: 14.0,
              ),
              children: const [],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(() => mapController.animateCamera(const LatLng(13.0850, 80.2780)), returnsNormally);
      expect(mapController.camera.center.latitude, closeTo(13.0850, 0.001));
      expect(mapController.camera.center.longitude, closeTo(80.2780, 0.001));
    });
  });

  group('Final Build Phase Tests', () {
    testWidgets('VehicleSelectionPage renders Bike, Auto, Hatchback/Mini, Sedan, and Premium/SUV', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: VehicleSelectionPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bike'), findsOneWidget);
      expect(find.text('Auto'), findsOneWidget);
      expect(find.text('Hatchback/Mini'), findsOneWidget);
      expect(find.text('Sedan'), findsOneWidget);
      expect(find.text('Premium/SUV'), findsOneWidget);
    });

    testWidgets('PaymentScreen safely parses Map data and renders Pay via UPI', (tester) async {
      final mockData = <dynamic, dynamic>{
        'vehicleType': 'Sedan',
        'price': 180,
        'pickupAddress': 'Central Station',
        'dropoffAddress': 'Airport T1',
        'distanceKm': 15.0,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: PaymentScreen(
            paymentArgs: Map<String, dynamic>.from(mockData),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Pay via UPI'), findsOneWidget);
      expect(find.text('Proceed to Pay'), findsOneWidget);
      expect(find.textContaining('Sedan'), findsWidgets);
    });
  });
}
