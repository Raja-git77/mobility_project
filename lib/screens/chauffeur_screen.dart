import 'package:flutter/material.dart';
import 'vehicle_selection_page.dart';

class ChauffeurScreen extends StatefulWidget {
  const ChauffeurScreen({super.key});

  @override
  State<ChauffeurScreen> createState() => _ChauffeurScreenState();
}

class _ChauffeurScreenState extends State<ChauffeurScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _pickupCtrl = TextEditingController();
  final _dropoffCtrl = TextEditingController();
  String _selectedPackage = 'Local (8hrs / 80km)';
  String _selectedCarType = 'Sedan';

  static const _packages = [
    'Local (8hrs / 80km)',
    'Local (12hrs / 120km)',
    'Outstation One-Way',
    'Outstation Round-Trip',
    'Airport Transfer',
  ];

  static const _carTypes = ['Sedan', 'SUV', 'Luxury', 'Tempo Traveller'];

  static const Map<String, Map<String, double>> _fareTable = {
    'Local (8hrs / 80km)': {'Sedan': 1499, 'SUV': 1999, 'Luxury': 3499, 'Tempo Traveller': 2699},
    'Local (12hrs / 120km)': {'Sedan': 1999, 'SUV': 2699, 'Luxury': 4299, 'Tempo Traveller': 3299},
    'Outstation One-Way': {'Sedan': 2499, 'SUV': 3299, 'Luxury': 5999, 'Tempo Traveller': 4499},
    'Outstation Round-Trip': {'Sedan': 3999, 'SUV': 5499, 'Luxury': 8999, 'Tempo Traveller': 6999},
    'Airport Transfer': {'Sedan': 899, 'SUV': 1299, 'Luxury': 2499, 'Tempo Traveller': 1799},
  };

  double get _estimatedFare =>
      _fareTable[_selectedPackage]?[_selectedCarType] ?? 1499;
  double get _driverAllowance => _selectedPackage.contains('Outstation') ? 450 : 200;
  double get _totalFare => _estimatedFare + _driverAllowance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pickupCtrl.dispose();
    _dropoffCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rental Service', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white)),
            Text('Car + Professional Driver', style: TextStyle(fontSize: 10, color: Color(0xFFA1A1AA))),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF6366F1),
          labelColor: const Color(0xFF6366F1),
          unselectedLabelColor: const Color(0xFFA1A1AA),
          tabs: const [Tab(text: 'Book a Ride'), Tab(text: 'Packages')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildBookingTab(), _buildPackagesTab()],
      ),
    );
  }

  Widget _buildBookingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Trip Package'),
          const SizedBox(height: 10),
          _darkDropdown<String>(
            value: _selectedPackage,
            items: _packages,
            onChanged: (v) => setState(() => _selectedPackage = v!),
          ),
          const SizedBox(height: 16),
          _sectionLabel('Vehicle Type'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10, runSpacing: 10,
            children: _carTypes.map((t) => _chipSelect(t, _selectedCarType, () => setState(() => _selectedCarType = t))).toList(),
          ),
          const SizedBox(height: 16),
          _sectionLabel('Pickup Location'),
          const SizedBox(height: 8),
          _darkTextField(_pickupCtrl, 'Enter pickup address', Icons.trip_origin),
          const SizedBox(height: 12),
          _sectionLabel('Drop-off Location'),
          const SizedBox(height: 8),
          _darkTextField(_dropoffCtrl, 'Enter destination (optional)', Icons.location_on),
          const SizedBox(height: 20),
          // Fare Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0A0A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF1F1F22)),
            ),
            child: Column(
              children: [
                _fareRow('Base Fare', '₹${_estimatedFare.toStringAsFixed(0)}', color: Colors.white),
                const SizedBox(height: 8),
                _fareRow('Driver Allowance', '₹${_driverAllowance.toStringAsFixed(0)}', color: const Color(0xFFA1A1AA)),
                const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(color: Color(0xFF1F1F22))),
                _fareRow('Total Estimate', '₹${_totalFare.toStringAsFixed(0)}', color: const Color(0xFF6366F1), isBold: true),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => VehicleSelectionPage(
                    routeArgs: {
                      'pickupAddress': _pickupCtrl.text.isEmpty ? 'Your Location' : _pickupCtrl.text,
                      'dropoffAddress': _dropoffCtrl.text.isEmpty ? 'Destination' : _dropoffCtrl.text,
                      'distanceKm': 12.0,
                      'serviceType': 'rental_service',
                    },
                  ),
                ));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Book Rental Service', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackagesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: _packages.map((pkg) {
        final fares = _fareTable[pkg]!;
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF1F1F22)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(pkg, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.white)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12, runSpacing: 8,
                children: fares.entries.map((e) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(e.key, style: const TextStyle(fontSize: 11, color: Color(0xFFA1A1AA))),
                    Text('₹${e.value.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF6366F1))),
                  ],
                )).toList(),
              ),
              const SizedBox(height: 8),
              Text(
                pkg.contains('Outstation') ? '+ ₹450 driver allowance' : '+ ₹200 driver allowance',
                style: const TextStyle(fontSize: 11, color: Color(0xFFA1A1AA)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _fareRow(String label, String value, {Color color = Colors.white, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: const Color(0xFFA1A1AA), fontSize: 13, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }

  Widget _sectionLabel(String text) =>
      Text(text, style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5));

  Widget _darkTextField(TextEditingController ctrl, String hint, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1F1F22)),
      ),
      child: TextField(
        controller: ctrl,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF555558)),
          prefixIcon: Icon(icon, color: const Color(0xFFA1A1AA), size: 18),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
      ),
    );
  }

  Widget _darkDropdown<T>({required T value, required List<T> items, required ValueChanged<T?> onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1F1F22)),
      ),
      child: DropdownButton<T>(
        value: value,
        isExpanded: true,
        dropdownColor: const Color(0xFF0A0A0A),
        style: const TextStyle(color: Colors.white, fontSize: 14),
        underline: const SizedBox(),
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e.toString()))).toList(),
        onChanged: onChanged,
        icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFFA1A1AA)),
      ),
    );
  }

  Widget _chipSelect(String label, String selected, VoidCallback onTap) {
    final isSelected = label == selected;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF0A0A0A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF1F1F22)),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? Colors.white : const Color(0xFFA1A1AA), fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }
}
