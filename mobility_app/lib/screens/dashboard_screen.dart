import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/booking_provider.dart';
import '../models/booking_model.dart';
import 'route_planner_screen.dart';
import 'rental_service_screen.dart';
import 'acting_driver_screen.dart';
import 'partner_owner_screen.dart';
import 'profile_screen.dart';
import 'my_bookings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingProvider>().loadMyBookings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final booking = context.watch<BookingProvider>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x3310B981),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.directions_car_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mobility App',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    letterSpacing: -0.4,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Live Mobility Hub',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'My Bookings',
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.history_rounded,
                  color: Color(0xFF334155), size: 20),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyBookingsScreen()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              ),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                        ),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        (user?.name.isNotEmpty == true)
                            ? user!.name[0].toUpperCase()
                            : 'R',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.verified_rounded,
                        color: Color(0xFF10B981), size: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF10B981),
        backgroundColor: Colors.white,
        onRefresh: () => context.read<BookingProvider>().loadMyBookings(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── HERO GREETING BANNER ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello, ${user?.name.split(' ').first ?? 'Rajavel'} 👋',
                              style: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Smart Integrated Car, Driver & Partner Services',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.workspace_premium_rounded,
                                  color: Color(0xFFB45309), size: 15),
                              SizedBox(width: 4),
                              Text(
                                'GOLD MEMBER',
                                style: TextStyle(
                                  color: Color(0xFFB45309),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Quick stat chips row
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _statChip(Icons.stars_rounded, '4.9★ AI Road Match',
                            const Color(0xFF10B981)),
                        _statChip(Icons.bolt_rounded, 'Instant ETA 4 min',
                            const Color(0xFF2563EB)),
                        _statChip(Icons.security_rounded, '100% Verified Drivers',
                            const Color(0xFF7C3AED)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // ── 4 SERVICES HEADER ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'MOBILITY SERVICES',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '4 Active Modes',
                        style: TextStyle(
                          color: Color(0xFF065F46),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 6),

              // ── 4 DISTINCT SERVICES (Cards with custom badges, unique color accents) ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // Service 1: Self-Drive Car Rentals -> Emerald Green Accent (#10B981)
                    _ServiceCard(
                      serviceNumber: 'SERVICE 1',
                      title: 'Self-Drive Car Rentals',
                      badgeText: 'DRIVE YOURSELF',
                      badgeColor: const Color(0xFF10B981),
                      badgeBgColor: const Color(0xFFECFDF5),
                      primaryAccent: const Color(0xFF10B981),
                      secondaryAccent: const Color(0xFF059669),
                      icon: Icons.drive_eta_rounded,
                      extraIcon: Icons.vpn_key_rounded,
                      highlight:
                          'Hourly & Daily Self-Drive with Zero Deposit options. 10+ hatchbacks, sedans, SUVs with road routing.',
                      bulletPoints: const [
                        'Zero Security Deposit',
                        'Instant Doorstep Delivery',
                        'Unlimited KM Options'
                      ],
                      buttonText: 'Book Self-Drive Car',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RoutePlannerScreen(
                              serviceType: 'self_drive'),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Service 2: Rental Service (Renamed from Chauffeur Service) -> Royal Blue Accent (#2563EB)
                    _ServiceCard(
                      serviceNumber: 'SERVICE 2',
                      title: 'Rental Service',
                      badgeText: 'CAR + DRIVER',
                      badgeColor: const Color(0xFF2563EB),
                      badgeBgColor: const Color(0xFFEFF6FF),
                      primaryAccent: const Color(0xFF2563EB),
                      secondaryAccent: const Color(0xFF1D4ED8),
                      icon: Icons.airline_seat_recline_extra_rounded,
                      extraIcon: Icons.local_taxi_rounded,
                      highlight:
                          'Luxury local, airport & outstation trips with certified commercial driver. 10+ premium vehicles.',
                      bulletPoints: const [
                        'Local & Outstation Trips',
                        'Airport Pickup & Drop',
                        'Professional Driver Included'
                      ],
                      buttonText: 'Book Rental with Driver',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const RentalServiceScreen()),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Service 3: Acting Driver Services -> Amber/Gold Accent (#D97706)
                    _ServiceCard(
                      serviceNumber: 'SERVICE 3',
                      title: 'Acting Driver Services',
                      badgeText: 'HIRE A DRIVER',
                      badgeColor: const Color(0xFFD97706),
                      badgeBgColor: const Color(0xFFFFFBEB),
                      primaryAccent: const Color(0xFFD97706),
                      secondaryAccent: const Color(0xFFB45309),
                      icon: Icons.shield_rounded,
                      extraIcon: Icons.person_pin_circle_rounded,
                      highlight:
                          'Hire background-verified drivers for your own car. 5 mandatory proofs: License, Aadhaar, Police clearance.',
                      bulletPoints: const [
                        '5 Mandatory Proofs Verified',
                        'Hourly & Outstation Shifts',
                        'Manual & Automatic Experts'
                      ],
                      buttonText: 'Hire Acting Driver',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ActingDriverScreen()),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Service 4: Partner & Car Ownership Services -> Purple/Indigo Accent (#7C3AED)
                    _ServiceCard(
                      serviceNumber: 'SERVICE 4',
                      title: 'Partner & Car Ownership',
                      badgeText: 'ATTACH & EARN',
                      badgeColor: const Color(0xFF7C3AED),
                      badgeBgColor: const Color(0xFFF5F3FF),
                      primaryAccent: const Color(0xFF7C3AED),
                      secondaryAccent: const Color(0xFF6D28D9),
                      icon: Icons.handshake_rounded,
                      extraIcon: Icons.directions_car_filled_rounded,
                      highlight:
                          'Attach your vehicle or register as a certified driver. Upload 5 proofs, submit vehicle details & earn weekly.',
                      bulletPoints: const [
                        'Submit Vehicle & 5 Proofs First',
                        'Weekly Guaranteed Payouts',
                        '82% Revenue Share Fleet'
                      ],
                      buttonText: 'Register as Partner',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const PartnerOwnerScreen()),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── RECENT BOOKINGS HEADER ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'MY RECENT TRIPS',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const MyBookingsScreen()),
                      ),
                      child: const Text(
                        'View All',
                        style: TextStyle(
                          color: Color(0xFF10B981),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── RECENT BOOKINGS LIST ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: booking.isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(
                              color: Color(0xFF10B981)),
                        ),
                      )
                    : booking.myBookings.isEmpty
                        ? _emptyBookingsCard()
                        : Column(
                            children: booking.myBookings
                                .take(2)
                                .map((b) => _RecentBookingCard(booking: b))
                                .toList(),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyBookingsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Center(
        child: Text(
          'No trips yet. Choose a service above to book your first ride!',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// ── DISTINCT SERVICE CARD WITH ELEVATION ANIMATION ──
class _ServiceCard extends StatefulWidget {
  final String serviceNumber;
  final String title;
  final String badgeText;
  final Color badgeColor;
  final Color badgeBgColor;
  final Color primaryAccent;
  final Color secondaryAccent;
  final IconData icon;
  final IconData extraIcon;
  final String highlight;
  final List<String> bulletPoints;
  final String buttonText;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.serviceNumber,
    required this.title,
    required this.badgeText,
    required this.badgeColor,
    required this.badgeBgColor,
    required this.primaryAccent,
    required this.secondaryAccent,
    required this.icon,
    required this.extraIcon,
    required this.highlight,
    required this.bulletPoints,
    required this.buttonText,
    required this.onTap,
  });

  @override
  State<_ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<_ServiceCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()
          ..translate(0.0, _isHovered ? -3.0 : 0.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: _isHovered
                ? widget.primaryAccent
                : const Color(0xFFE2E8F0),
            width: _isHovered ? 1.8 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? widget.primaryAccent.withOpacity(0.12)
                  : const Color(0x080F172A),
              blurRadius: _isHovered ? 24 : 14,
              offset: Offset(0, _isHovered ? 8 : 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Custom Badge + Service Number
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: widget.badgeBgColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: widget.badgeColor.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(widget.extraIcon,
                                size: 13, color: widget.badgeColor),
                            const SizedBox(width: 5),
                            Text(
                              widget.badgeText,
                              style: TextStyle(
                                color: widget.badgeColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        widget.serviceNumber,
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Middle Row: Emblem Icon + Title
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              widget.primaryAccent,
                              widget.secondaryAccent,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: widget.primaryAccent.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(widget.icon,
                            color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              widget.highlight,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Highlights / feature chips row
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: widget.bulletPoints
                        .map(
                          (bp) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_rounded,
                                    size: 13, color: widget.primaryAccent),
                                const SizedBox(width: 5),
                                Text(
                                  bp,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF334155),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),

                  const SizedBox(height: 16),

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: widget.onTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.primaryAccent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.buttonText,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward_rounded, size: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── RECENT BOOKING CARD ──
class _RecentBookingCard extends StatelessWidget {
  final BookingModel booking;
  const _RecentBookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.directions_car_rounded,
                        color: Color(0xFF10B981), size: 16),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    booking.bookingRef,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: const Text(
                  'CONFIRMED ✅',
                  style: TextStyle(
                    color: Color(0xFF065F46),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.trip_origin_rounded,
                  color: Color(0xFF10B981), size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  booking.pickupAddress,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF334155)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.location_on_rounded,
                  color: Color(0xFFEF4444), size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  booking.dropoffAddress,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF334155)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Paid: ₹${booking.estimatedFare.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  color: Color(0xFF10B981),
                ),
              ),
              Text(
                '${booking.serviceType} • ${booking.distanceKm != null ? '${booking.distanceKm!.toStringAsFixed(1)} KM' : 'Direct'}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
