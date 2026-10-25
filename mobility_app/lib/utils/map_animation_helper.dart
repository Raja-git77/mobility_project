import 'package:flutter/animation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

extension MapControllerAnimatedCameraExtension on MapController {
  void animateCamera(
    LatLng destLocation, {
    double? destZoom,
    TickerProvider? vsync,
    Duration duration = const Duration(milliseconds: 750),
    Curve curve = Curves.easeInOutCubic,
  }) {
    final startCenter = camera.center;
    final startZoom = camera.zoom;
    final targetZoom = destZoom ?? startZoom;

    if (vsync != null) {
      final latTween = Tween<double>(begin: startCenter.latitude, end: destLocation.latitude);
      final lngTween = Tween<double>(begin: startCenter.longitude, end: destLocation.longitude);
      final zoomTween = Tween<double>(begin: startZoom, end: targetZoom);

      final controller = AnimationController(duration: duration, vsync: vsync);
      final curvedAnimation = CurvedAnimation(parent: controller, curve: curve);

      curvedAnimation.addListener(() {
        move(
          LatLng(latTween.evaluate(curvedAnimation), lngTween.evaluate(curvedAnimation)),
          zoomTween.evaluate(curvedAnimation),
        );
      });
      curvedAnimation.addStatusListener((status) {
        if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
          controller.dispose();
        }
      });
      controller.forward();
    } else {
      move(destLocation, targetZoom);
    }
  }
}
