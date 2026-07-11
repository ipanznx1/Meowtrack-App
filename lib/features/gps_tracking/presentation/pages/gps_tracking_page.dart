// 🎯 GPS TRACKING PAGE - GOOGLE MAPS WITH LIVE CAT SIMULATION
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:meow_track/features/cat_profile/presentation/pages/report_lost_cat_screen.dart';
import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:meow_track/core/widgets/meow_animated_dialog.dart';

class GpsTrackingPage extends StatefulWidget {
  const GpsTrackingPage({super.key});

  @override
  State<GpsTrackingPage> createState() => _GpsTrackingPageState();
}


class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF985BEF).withValues(alpha: 0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final scanSize = size.width * 0.7;

    // Draw scanning square corners
    final rect = Rect.fromCenter(center: center, width: scanSize, height: scanSize);
    
    // Custom corners
    final double cornerSize = 40.0;
    
    // Top Left
    canvas.drawPath(
      Path()
        ..moveTo(rect.left, rect.top + cornerSize)
        ..lineTo(rect.left, rect.top)
        ..lineTo(rect.left + cornerSize, rect.top),
      paint..color = const Color(0xFF985BEF),
    );

    // Top Right
    canvas.drawPath(
      Path()
        ..moveTo(rect.right - cornerSize, rect.top)
        ..lineTo(rect.right, rect.top)
        ..lineTo(rect.right, rect.top + cornerSize),
      paint,
    );

    // Bottom Left
    canvas.drawPath(
      Path()
        ..moveTo(rect.left, rect.bottom - cornerSize)
        ..lineTo(rect.left, rect.bottom)
        ..lineTo(rect.left + cornerSize, rect.bottom),
      paint,
    );

    // Bottom Right
    canvas.drawPath(
      Path()
        ..moveTo(rect.right - cornerSize, rect.bottom)
        ..lineTo(rect.right, rect.bottom)
        ..lineTo(rect.right, rect.bottom - cornerSize),
      paint,
    );

    // Semi-transparent overlay outside the scan area
    final overlayPaint = Paint()..color = Colors.black.withValues(alpha: 0.5);
    
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, rect.top), overlayPaint);
    canvas.drawRect(Rect.fromLTWH(0, rect.bottom, size.width, size.height - rect.bottom), overlayPaint);
    canvas.drawRect(Rect.fromLTWH(0, rect.top, rect.left, scanSize), overlayPaint);
    canvas.drawRect(Rect.fromLTWH(rect.right, rect.top, size.width - rect.right, scanSize), overlayPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GpsTrackingPageState extends State<GpsTrackingPage> with TickerProviderStateMixin {
  LatLng? _currentPosition;
  GoogleMapController? _mapController;
  String? _selectedCat;
  bool _isLoading = true;
  bool _isSheetExpanded = false;
  StreamSubscription<Position>? _positionStreamSub;
  bool _followUser = true;

  // Live mode and path recording for simulation
  bool _isLiveMode = false;
  Map<String, List<LatLng>> _livePaths = {};

  // Map to store custom marker icons
  final Map<String, BitmapDescriptor> _markerIcons = {};

  final List<Map<String, dynamic>> _cats = [
    {
      'name': 'Luna',
      'distance': '180m away',
      'battery': 85,
      'color': Colors.blue,
      'image': 'assets/images/Luna.png',
      'offset': const LatLng(0.0015, 0.0012),
      'activeMinutes': 35,
      'targetMinutes': 120,
      'sleepHours': 9.5,
      'sleepQuality': 'Good',
      'heartRate': 128,
    },
    {
      'name': 'Oyen',
      'distance': '210m away',
      'battery': 42,
      'color': Colors.orange,
      'image': 'assets/images/Oyen.png',
      'offset': const LatLng(-0.0012, -0.0008),
      'isLost': true,
      'activeMinutes': 28,
      'targetMinutes': 120,
      'sleepHours': 8.2,
      'sleepQuality': 'Restless',
      'heartRate': 135,
    },
    {
      'name': 'Bella',
      'distance': '150m away',
      'battery': 90,
      'color': Colors.pink,
      'image': 'assets/images/Bella.png',
      'offset': const LatLng(0.0008, -0.0018),
      'activeMinutes': 42,
      'targetMinutes': 120,
      'sleepHours': 10.1,
      'sleepQuality': 'Excellent',
      'heartRate': 122,
    },
  ];

  Timer? _simulationTimer;
  late AnimationController _radarController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _initTracking();
    _radarController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);
    _pulseController.addListener(() => setState(() {}));
  }

  Future<void> _initTracking() async {
    await _loadMarkerIcons();
    await _determinePosition();
    _startMovementSimulation();
  }

  @override
  void dispose() {
    _positionStreamSub?.cancel();
    _simulationTimer?.cancel();
    _radarController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadMarkerIcons() async {
    for (var cat in _cats) {
      final String assetPath = cat['image'];
      final icon = await _getCatMarkerIcon(assetPath, cat['color'] as Color, 80); // Reduced from 100
      if (mounted) {
        setState(() {
          _markerIcons[cat['name']] = icon;
        });
      }
    }
  }

  // Helper to create a circular marker with the cat image centered inside.
  Future<BitmapDescriptor> _getCatMarkerIcon(String path, Color color, int iconSize) async {
    final ByteData data = await rootBundle.load(path);
    final ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: iconSize);
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    final ui.Image catImage = frameInfo.image;

    final int canvasSize = (iconSize * 1.6).toInt();
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder, Rect.fromLTWH(0, 0, canvasSize.toDouble(), canvasSize.toDouble()));
    final Offset center = Offset(canvasSize / 2, canvasSize / 2);
    final double outerRadius = canvasSize * 0.45;
    final double innerRadius = canvasSize * 0.34;

    final Paint fillPaint = Paint()..color = color.withValues(alpha: 0.18);
    final Paint strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = color.withValues(alpha: 0.85);

    canvas.drawCircle(center, outerRadius, fillPaint);
    canvas.drawCircle(center, outerRadius, strokePaint);

    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: innerRadius)));

    final double imageSize = innerRadius * 1.8;
    final Rect src = Rect.fromLTWH(0, 0, catImage.width.toDouble(), catImage.height.toDouble());
    final Rect dst = Rect.fromCenter(center: center, width: imageSize, height: imageSize);
    canvas.drawImageRect(catImage, src, dst, Paint());
    canvas.restore();

    final ui.Image combined = await recorder.endRecording().toImage(canvasSize, canvasSize);
    final ByteData? pngBytes = await combined.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(pngBytes!.buffer.asUint8List());
  }

  // 🎯 SIMULATE "LIVE" CAT MOVEMENT (Random Walking)
  void _startMovementSimulation() {
    _simulationTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) return;
      setState(() {
        final center = _currentPosition ?? const LatLng(3.1390, 101.6869);
        for (var cat in _cats) {
          final currentOffset = cat['offset'] as LatLng;

          // When live mode is active, make movement more aggressive and faster
          final double baseLatMove = (timer.tick % 4 == 0 ? 0.00008 : -0.00004);
          final double baseLngMove = (timer.tick % 3 == 0 ? 0.00006 : -0.00003);

          final double latMove = _isLiveMode ? baseLatMove * 4 : baseLatMove;
          final double lngMove = _isLiveMode ? baseLngMove * 4 : baseLngMove;

          final newOffset = LatLng(
            currentOffset.latitude + latMove,
            currentOffset.longitude + lngMove,
          );

          cat['offset'] = newOffset;

          // Compute absolute cat location (center + offset)
          final catName = cat['name'] as String;
          final LatLng catLoc = LatLng(center.latitude + newOffset.latitude, center.longitude + newOffset.longitude);

          // Record live path history
          final list = _livePaths.putIfAbsent(catName, () => <LatLng>[]);
          list.add(catLoc);
          // keep history bounded to avoid unbounded memory growth
          if (list.length > 500) list.removeAt(0);

          // Virtual fence: mark as lost if outside 180m safe radius
          final distanceMeters = Geolocator.distanceBetween(
            center.latitude,
            center.longitude,
            catLoc.latitude,
            catLoc.longitude,
          );
          cat['isLost'] = distanceMeters > 180;

          // 💗 Heart Rate Simulation
          if (_isLiveMode && _selectedCat == catName) {
            // Live mode: fast heartbeat (145-165 bpm) when cat is active
            cat['heartRate'] = 145 + Random().nextInt(21); // 145-165
          } else {
            // Normal mode: stable heartbeat (115-130 bpm)
            cat['heartRate'] = 115 + Random().nextInt(16); // 115-130
          }

          // 🏃 Active Minutes Simulation
          final currentActive = (cat['activeMinutes'] as int? ?? 0);
          final targetMinutes = (cat['targetMinutes'] as int? ?? 120);

          if (_isLiveMode && _selectedCat == catName) {
            // Live mode: increment by 1 every tick (capped at target)
            if (currentActive < targetMinutes) {
              cat['activeMinutes'] = currentActive + 1;
            }
          } else {
            // Normal mode: 20% chance to increment by 1 (casual movement)
            if (currentActive < targetMinutes && Random().nextDouble() < 0.2) {
              cat['activeMinutes'] = currentActive + 1;
            }
          }
        }
      });
    });
  }

  Future<void> _determinePosition() async {
    try {
      Position position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _isLoading = false;
        });
        _startPositionStream();
      }
    } catch (e) {
      // Fallback location if GPS fails
      setState(() {
        _currentPosition = const LatLng(3.1390, 101.6869); // Kuala Lumpur
        _isLoading = false;
      });
    }
  }

  void _startPositionStream() {
    _positionStreamSub = Geolocator.getPositionStream().listen((Position pos) {
      if (!mounted) return;
      final newLoc = LatLng(pos.latitude, pos.longitude);
      setState(() => _currentPosition = newLoc);
      if (_followUser) _mapController?.animateCamera(CameraUpdate.newLatLng(newLoc));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF985BEF)))
          : Stack(
              children: [
                _buildMapLayer(),
                _buildBackButton(),
                _buildTopOverlays(),
                _buildMapControls(),
                _buildBottomUI(),
              ],
            ),
    );
  }

  Widget _buildMapLayer() {
    final center = _currentPosition ?? const LatLng(3.1390, 101.6869);
    // Build polylines for the selected cat from recorded live paths
    final Set<Polyline> polylines = {};
    if (_selectedCat != null) {
      final path = _livePaths[_selectedCat];
      if (path != null && path.length > 1) {
        try {
          final cat = _cats.firstWhere((c) => c['name'] == _selectedCat);
          final Color catColor = (cat['color'] as Color?) ?? Colors.purple;
          polylines.add(Polyline(
            polylineId: PolylineId('path_$_selectedCat'),
            points: path,
            color: catColor,
            width: 4,
          ));
        } catch (_) {}
      }
    }

    // Build markers and circles, highlighting the selected cat with a circle
    final Set<Marker> markersSet = {};
    for (final cat in _cats) {
      final catLoc = LatLng(center.latitude + cat['offset'].latitude, center.longitude + cat['offset'].longitude);
      markersSet.add(Marker(
        markerId: MarkerId(cat['name']),
        position: catLoc,
        icon: _markerIcons[cat['name']] ?? BitmapDescriptor.defaultMarker,
        anchor: const Offset(0.5, 0.5),
        onTap: () => setState(() => _selectedCat = cat['name']),
      ));
    }

    final Set<Circle> circlesSet = {
      Circle(
        circleId: const CircleId('safe_zone'),
        center: center,
        radius: 180,
        fillColor: Colors.green.withValues(alpha: 0.15),
        strokeColor: Colors.green.withValues(alpha: 0.5),
        strokeWidth: 2,
      ),
    };

    if (_selectedCat != null) {
      try {
        final sel = _cats.firstWhere((c) => c['name'] == _selectedCat);
        final selLoc = LatLng(center.latitude + (sel['offset'] as LatLng).latitude, center.longitude + (sel['offset'] as LatLng).longitude);
        circlesSet.add(Circle(
          circleId: const CircleId('selected_cat'),
          center: selLoc,
          radius: 40,
          fillColor: (sel['color'] as Color).withValues(alpha: 0.18),
          strokeColor: (sel['color'] as Color).withValues(alpha: 0.6),
          strokeWidth: 2,
        ));
      } catch (_) {}
    }

    // Add pulsing indicator for each cat to make tracker locations more visible
    for (final cat in _cats) {
      try {
        final catLoc = LatLng(center.latitude + (cat['offset'] as LatLng).latitude, center.longitude + (cat['offset'] as LatLng).longitude);
        final base = 16.0; // meters
        final pulse = base + (_pulseController.value * 16.0); // 16-32 meters
        final opacity = 0.25 * (1.0 - _pulseController.value) + 0.1;
        final fillColor = (cat['color'] as Color).withValues(alpha: opacity);

        // Pulsing soft fill
        circlesSet.add(Circle(
          circleId: CircleId('pulse_${cat['name']}'),
          center: catLoc,
          radius: pulse,
          fillColor: fillColor,
          strokeColor: Colors.transparent,
          strokeWidth: 0,
        ));

        // Static circular outline around the cat marker
        circlesSet.add(Circle(
          circleId: CircleId('pulse_ring_${cat['name']}'),
          center: catLoc,
          radius: 22,
          fillColor: Colors.transparent,
          strokeColor: (cat['color'] as Color).withOpacity(0.75),
          strokeWidth: 3,
        ));
      } catch (_) {}
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(target: center, zoom: 16),
      onMapCreated: (controller) => _mapController = controller,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapType: MapType.normal,
      markers: markersSet,
      polylines: polylines,
      circles: circlesSet,
    );
  }

  Widget _buildBackButton() {
    final double top = MediaQuery.of(context).padding.top + 12;
    return Positioned(
      top: top, left: 20,
      child: GestureDetector(
        onTap: () => _selectedCat != null ? setState(() => _selectedCat = null) : Navigator.pop(context),
        child: SvgPicture.asset('assets/icons/Back.svg', colorFilter: const ColorFilter.mode(Color(0xFF985BEF), BlendMode.srcIn), width: 28),
      ),
    );
  }

  Widget _buildTopOverlays() {
    final double top = MediaQuery.of(context).padding.top + 72;
    return Positioned(
      top: top, left: 0, right: 0,
      child: Column(
        children: [
          if (_selectedCat != null) ...[
            () {
              final cat = _cats.firstWhere((c) => c['name'] == _selectedCat);
              if (cat['isLost'] == true) {
                return _statusChip('Emergency Alert', Colors.red, Colors.white, false);
              } else {
                return _statusChip('Meow is at Safe Zone', Colors.white, Colors.black, true);
              }
            }(),
          ] else ...[
            _statusChip('Meow is at Home', Colors.white, Colors.black, true),
            const SizedBox(height: 12),
            _statusChip('Emergency Alert', Colors.red, Colors.white, false),
          ],
        ],
      ),
    );
  }

  Widget _statusChip(String t, Color bg, Color c, bool b) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(15), border: b ? Border.all(color: Colors.black12) : null, boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)]),
      child: Text(t, style: TextStyle(color: c, fontWeight: FontWeight.w900, fontSize: 18)),
    );
  }

  Widget _buildMapControls() {
    final double top = MediaQuery.of(context).size.height * 0.22 + MediaQuery.of(context).padding.top;
    return Positioned(
      left: 20, top: top,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)]),
        child: Column(
          children: [
            IconButton(onPressed: () => _mapController?.animateCamera(CameraUpdate.zoomIn()), icon: const Icon(Icons.add_box_outlined, color: Color(0xFF985BEF), size: 30)),
            const SizedBox(height: 5),
            IconButton(onPressed: () => _mapController?.animateCamera(CameraUpdate.zoomOut()), icon: SvgPicture.asset('assets/icons/ZOOM OUT.svg', colorFilter: const ColorFilter.mode(Color(0xFF985BEF), BlendMode.srcIn), width: 30)),
            const SizedBox(height: 5),
            IconButton(onPressed: () => setState(() => _followUser = !_followUser), icon: SvgPicture.asset('assets/icons/COMPASS.svg', colorFilter: ColorFilter.mode(_followUser ? const Color(0xFF985BEF) : Colors.black, BlendMode.srcIn), width: 30)),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomUI() {
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    return Positioned(
      left: 0,
      right: 0,
      bottom: bottomInset,
      child: _selectedCat == null ? _buildCatProfileSheet() : _buildCatDetailView(_selectedCat!),
    );
  }

  Widget _buildCatProfileSheet() {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final rawMaxHeight = MediaQuery.of(context).size.height * 0.5;
    final height = _isSheetExpanded ? max(210.0, rawMaxHeight - bottomInset - 12) : 120.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: height,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(40)), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 15, offset: Offset(0, -5))]),
      child: SingleChildScrollView(
        physics: _isSheetExpanded ? const AlwaysScrollableScrollPhysics() : const NeverScrollableScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(onTap: () => setState(() => _isSheetExpanded = !_isSheetExpanded), child: Container(height: 6, width: 60, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(3)))),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('GPS Tracking', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Text('by', style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.bold)),
                          const SizedBox(width: 4),
                          SvgPicture.asset('assets/images/tractive.svg', height: 14),
                        ],
                      ),
                    ),
                  ],
                ),
                IconButton(icon: Icon(_isSheetExpanded ? Icons.expand_more : Icons.expand_less, size: 35), onPressed: () => setState(() => _isSheetExpanded = !_isSheetExpanded)),
              ],
            ),
            if (_isSheetExpanded) ...[const SizedBox(height: 12), SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () => _openScanner(), icon: const Icon(Icons.qr_code_scanner, size: 22), label: const Text('Scan QR for New Collar', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF985BEF), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)))), const SizedBox(height: 16)],
            if (_isSheetExpanded) ..._cats.map((c) => _catTile(c)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _catTile(Map<String, dynamic> cat) {
    return GestureDetector(
      onTap: () {
        setState(() => _selectedCat = cat['name']);
        
        // 🎯 Situasi #2: Alert jika kucing di luar zon
        if (cat['isLost'] == true) {
          MeowAnimatedDialog.show(
            context,
            animationPath: 'assets/animations/alert.json',
            title: "AMARAN: Luar Zon!",
            description: "${cat['name']} dikesan telah keluar dari kawasan Safe Zone!",
            themeColor: Colors.red,
            buttonText: "Pantau Sekarang",
          );
        }
        
        // 🎯 Situasi #6: Alert Bateri Lemah
        if (cat['battery'] < 45) {
          MeowAnimatedDialog.show(
            context,
            animationPath: 'assets/animations/The battery is running out of charge.json',
            title: "Bateri Lemah!",
            description: "Kolar ${cat['name']} perlu dicas segera (Baki: ${cat['battery']}%).",
            themeColor: Colors.orange,
            buttonText: "Faham",
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 18), padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(25), border: Border.all(color: cat['color'].withValues(alpha: 0.4), width: 2)),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.asset(cat['image'] as String, width: 70, height: 70, fit: BoxFit.cover),
            ),
            const SizedBox(width: 18),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(cat['name'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20)), Text(cat['distance'], style: const TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.bold))])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Row(children: [SvgPicture.asset('assets/icons/Collar Battery Status.svg', colorFilter: ColorFilter.mode(cat['color'], BlendMode.srcIn), width: 22), const SizedBox(width: 6), _batteryBar()]), const SizedBox(height: 5), Text('${cat['battery']}%', style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold))]),
          ],
        ),
      ),
    );
  }

  Widget _batteryBar() {
    return Container(height: 14, width: 65, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(7)), child: FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: 0.5, child: Container(decoration: BoxDecoration(color: Colors.yellow[700], borderRadius: BorderRadius.circular(7)))));
  }

  Widget _buildCatDetailView(String name) {
    final cat = _cats.firstWhere((c) => c['name'] == name);
    final maxHeight = MediaQuery.of(context).size.height * 0.78;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight - 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(30, 30, 30, 30),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(45)), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5))]),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Text(name, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
              const SizedBox(height: 25),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Battery', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)), const SizedBox(height: 8), Row(children: [_batteryBar(), const SizedBox(width: 10), const Icon(Icons.battery_alert, color: Colors.orange, size: 28)])]), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Distance', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)), const SizedBox(height: 8), Text(cat['distance'], style: const TextStyle(color: Colors.grey, fontSize: 20, fontWeight: FontWeight.bold))])]),
              const SizedBox(height: 35),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLiveMode = !_isLiveMode;
                    // reset live path for this cat when toggling
                    _livePaths[name] = [];
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isLiveMode ? const Color(0xFF985BEF) : Colors.grey,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: Text(
                  _isLiveMode ? 'LIVE MODE ACTIVE' : 'Enable Live Mode',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReportLostCatScreen())),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, minimumSize: const Size(double.infinity, 65), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                child: const Text('Lost cat?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22)),
              ),
              const SizedBox(height: 30),
              _buildWellnessDashboard(cat),
              const SizedBox(height: 30),
              const Align(alignment: Alignment.centerLeft, child: Text('Location History Timeline', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22))),
              const SizedBox(height: 20),
              _historyTile(cat),
            ],
          ),
        ),
      ),
    );
  }

  Widget _historyTile(Map<String, dynamic> cat) {
    return GestureDetector(
      onTap: () => Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(builder: (context) => LocationHistoryScreen(initialLocation: _currentPosition!, catName: cat['name'] as String))),
      child: Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(color: const Color(0xFFF5F5F7), borderRadius: BorderRadius.circular(25)), child: Row(children: [const CircleAvatar(backgroundColor: Color(0xFF00D100), radius: 12), const SizedBox(width: 18), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Distance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), Text(cat['distance'], style: const TextStyle(color: Colors.grey, fontSize: 14))]), const Spacer(), const Icon(Icons.arrow_forward_ios, size: 20, color: Colors.grey)])),
    );
  }

  Widget _buildWellnessDashboard(Map<String, dynamic> cat) {
    final activeMinutes = (cat['activeMinutes'] as int? ?? 0);
    final targetMinutes = (cat['targetMinutes'] as int? ?? 120);
    final sleepHours = (cat['sleepHours'] as double? ?? 0.0);
    final sleepQuality = (cat['sleepQuality'] as String? ?? 'Unknown');
    final heartRate = (cat['heartRate'] as int? ?? 0);
    final catColor = (cat['color'] as Color? ?? Colors.purple);

    final activityProgress = (activeMinutes / targetMinutes).clamp(0.0, 1.0);
    final isHeartRateElevated = heartRate > 135;

    return Column(
      children: [
        const Align(alignment: Alignment.centerLeft, child: Text('Wellness Dashboard', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22))),
        const SizedBox(height: 16),
        // First Row: Activity + Sleep
        Row(
          children: [
            // Activity Card
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFFF5F5F7), borderRadius: BorderRadius.circular(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.directions_run, color: catColor, size: 22),
                        const SizedBox(width: 6),
                        const Text('Activity', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text('$activeMinutes/$targetMinutes min', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black)),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: activityProgress,
                        minHeight: 5,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(catColor),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Sleep Quality Card
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFFF5F5F7), borderRadius: BorderRadius.circular(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.bedtime, color: catColor, size: 22),
                        const SizedBox(width: 6),
                        const Text('Sleep', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text('${sleepHours.toStringAsFixed(1)} hr', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black)),
                    const SizedBox(height: 4),
                    Text(sleepQuality, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 11, color: Colors.grey[600])),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Second Row: Heart Rate
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFFF5F5F7), borderRadius: BorderRadius.circular(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.favorite, color: isHeartRateElevated ? Colors.red : Colors.orange, size: 22),
                  const SizedBox(width: 6),
                  const Text('Heart Rate', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('$heartRate bpm', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black)),
                  Text(isHeartRateElevated ? 'Elevated' : 'Normal', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: isHeartRateElevated ? Colors.red : Colors.green)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _openScanner() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
          child: Stack(
            children: [
              MobileScanner(
                onDetect: (capture) {
                  final List<Barcode> barcodes = capture.barcodes;
                  if (barcodes.isNotEmpty) {
                    Navigator.pop(context); // Close scanner
                    _simulatePairing(barcodes.first.rawValue ?? "Unknown");
                  }
                },
              ),
              // Scanner Overlay (Radar Theme)
              CustomPaint(
                painter: _ScannerOverlayPainter(),
                child: Container(),
              ),
              Positioned(
                top: 20,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Scan Collar QR Code',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 20,
                right: 20,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _simulatePairing(String code) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            const CircularProgressIndicator(color: Color(0xFF985BEF)),
            const SizedBox(height: 20),
            Text('Processing Pairing...\nID: $code', textAlign: TextAlign.center),
          ],
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context); // Close processing dialog

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 10),
              Text('Success'),
            ],
          ),
          content: const Text('Device Paired Successfully!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _addNewCat();
              },
              child: const Text('Great!'),
            ),
          ],
        ),
      );
    });
  }

  void _addNewCat() async {
    final newCat = {
      'name': 'New Tracker',
      'distance': 'Connecting...',
      'battery': 100,
      'color': Colors.deepPurple,
      'image': 'assets/images/Luna.png', // Reusing an asset
      'offset': const LatLng(0.0005, -0.0005),
      'activeMinutes': 0,
      'targetMinutes': 120,
      'sleepHours': 0.0,
      'sleepQuality': 'Calm',
      'heartRate': 120,
    };

    // Prepare marker icon for the new cat
    final icon = await _getCatMarkerIcon(newCat['image'] as String, newCat['color'] as Color, 80);
    
    setState(() {
      _cats.add(newCat);
      _markerIcons[newCat['name'] as String] = icon;
      _selectedCat = newCat['name'] as String;
    });

    // Center map on new cat
    if (_currentPosition != null) {
      final newLoc = LatLng(
        _currentPosition!.latitude + (newCat['offset'] as LatLng).latitude,
        _currentPosition!.longitude + (newCat['offset'] as LatLng).longitude,
      );
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(newLoc, 17));
    }
  }

}

// ─────────────────────────────────────────────
// Location History Screen (unchanged)
// ─────────────────────────────────────────────
class LocationHistoryScreen extends StatefulWidget {
  final LatLng initialLocation;
  final String? catName; // Optional: track which cat's history
  const LocationHistoryScreen({super.key, required this.initialLocation, this.catName});

  @override
  State<LocationHistoryScreen> createState() => _LocationHistoryScreenState();
}

class _LocationHistoryScreenState extends State<LocationHistoryScreen> {
  bool _isMapView = false;
  late List<Map<String, dynamic>> _catHistories;

  final List<Map<String, dynamic>> _historyCats = [
    {
      'name': 'Luna',
      'markerHue': BitmapDescriptor.hueBlue,
      'color': Colors.blue,
      'locations': ['Home', 'Vet clinic', 'Park', 'Pet shop', 'Cafe'],
      'times': ['Now', '10 mins ago', '20 mins ago', '40 mins ago', '1 hour ago'],
      'distances': [0, 45, 110, 220, 320],
    },
    {
      'name': 'Bella',
      'markerHue': BitmapDescriptor.hueMagenta,
      'color': Colors.pink,
      'locations': ['Home', 'Garden', 'Pet store', 'Clinic', 'Riverwalk'],
      'times': ['Now', '8 mins ago', '18 mins ago', '35 mins ago', '55 mins ago'],
      'distances': [0, 55, 130, 195, 280],
    },
    {
      'name': 'Oyen',
      'markerHue': BitmapDescriptor.hueOrange,
      'color': Colors.orange,
      'locations': ['Home', 'Market', 'Park', 'Clinic', 'Friend house'],
      'times': ['Now', '7 mins ago', '16 mins ago', '33 mins ago', '50 mins ago'],
      'distances': [0, 60, 140, 260, 360],
    },
  ];

  @override
  void initState() {
    super.initState();
    _generateSimulatedHistory();
  }

  LatLng _destinationPoint(LatLng origin, double distanceMeters, double angleRadians) {
    final deltaDegrees = distanceMeters / 111000;
    return LatLng(
      origin.latitude + cos(angleRadians) * deltaDegrees,
      origin.longitude + sin(angleRadians) * deltaDegrees,
    );
  }

  void _generateSimulatedHistory() {
    final baseLocation = widget.initialLocation;
    final random = Random(42);

    _catHistories = _historyCats.map((catInfo) {
      final name = catInfo['name'] as String;
      final markerHue = catInfo['markerHue'] as double;
      final labelColor = catInfo['color'] as Color;
      final names = (catInfo['locations'] as List<String>);
      final times = (catInfo['times'] as List<String>);
      final distances = (catInfo['distances'] as List<int>);
      final startAngle = random.nextDouble() * 2 * pi;

      final history = <Map<String, dynamic>>[];
      for (int i = 0; i < names.length; i++) {
        final angle = startAngle + i * 0.9 + random.nextDouble() * 0.4;
        final distance = distances[i].toDouble();
        final variation = (random.nextDouble() - 0.5) * 20;
        final actualDistance = max(0.0, distance + variation).toDouble();
        final position = _destinationPoint(baseLocation, actualDistance, angle);
        final isWarning = actualDistance > 180;

        history.add({
          'cat': name,
          'catColor': labelColor,
          'markerHue': markerHue,
          'loc': names[i],
          'time': times[i],
          'type': i == 0 ? 'current' : (isWarning ? 'warning' : 'past'),
          'position': position,
          'distance': '${actualDistance.toStringAsFixed(0)}m away',
        });
      }

      return {
        'name': name,
        'markerHue': markerHue,
        'color': labelColor,
        'history': history,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final double tp = MediaQuery.of(context).padding.top + 16;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          _isMapView ? _buildMapView() : _buildListView(),
          Positioned(top: tp, left: 20, child: GestureDetector(onTap: () => Navigator.pop(context), child: SvgPicture.asset('assets/icons/Back.svg', colorFilter: const ColorFilter.mode(Color(0xFF985BEF), BlendMode.srcIn), width: 35))),
          Positioned(
            top: tp,
            right: 20,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _isMapView = !_isMapView),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: const Color(0xFF985BEF), borderRadius: BorderRadius.circular(12)),
                    child: Text(_isMapView ? 'List view' : 'Map view', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
                if (widget.catName != null) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => Navigator.of(context, rootNavigator: true).pushReplacement(MaterialPageRoute(builder: (_) => LocationHistoryScreen(initialLocation: widget.initialLocation))),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF985BEF)),
                      ),
                      child: const Text('All Cats', style: TextStyle(color: Color(0xFF985BEF), fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    final filteredHistories = widget.catName != null
        ? _catHistories.where((c) => c['name'] == widget.catName)
        : _catHistories;
    final allHistory = filteredHistories.expand((c) => c['history'] as List<Map<String, dynamic>>).toList();
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 140),
          Text(widget.catName != null ? '${widget.catName} History Timeline' : 'Location History Timeline', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Your Location: ${widget.initialLocation.latitude.toStringAsFixed(6)}, ${widget.initialLocation.longitude.toStringAsFixed(6)}',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: allHistory.length,
              itemBuilder: (context, index) => _historyNode(allHistory[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _historyNode(Map<String, dynamic> item) {
    final bool isWarning = item['type'] == 'warning';
    final String catName = item['cat'] as String;
    final Color catColor = item['catColor'] as Color;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: item['type'] == 'current' ? const Color(0xFF00D100) : (isWarning ? Colors.red : const Color(0xFFD9D9D9)),
                ),
              ),
              Expanded(child: Container(width: 2.5, color: const Color(0xFFD9D9D9))),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(color: catColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Text('$catName', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: catColor)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(item['loc'] as String, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isWarning ? Colors.red : Colors.black)),
                const SizedBox(height: 4),
                Text(item['time'] as String, style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(item['distance'] as String, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapView() {
    // If a specific cat is requested show only its history to reduce clutter
    final List<Map<String, dynamic>> catsToRender = widget.catName != null
        ? _catHistories.where((c) => c['name'] == widget.catName).toList()
        : _catHistories;

    final Set<Marker> markers = {};
    final Set<Polyline> polylines = {};

    LatLng initial = widget.initialLocation;

    for (final cat in catsToRender) {
      final catName = cat['name'] as String;
      final markerHue = cat['markerHue'] as double;
      final history = cat['history'] as List<Map<String, dynamic>>;
      final List<LatLng> pathPoints = history.map((item) => item['position'] as LatLng).toList();

      if (pathPoints.isEmpty) continue;

      // center map on selected cat latest point when focused
      if (widget.catName != null && catName == widget.catName) {
        initial = pathPoints.first;
      }

      markers.add(Marker(
        markerId: MarkerId(catName),
        position: pathPoints.first,
        infoWindow: InfoWindow(title: '$catName (latest)'),
        icon: BitmapDescriptor.defaultMarkerWithHue(markerHue),
      ));

      // only add detailed history markers when not focused on a single cat (or when explicitly requested)
      if (widget.catName == null) {
        markers.addAll(history.map((item) {
          final position = item['position'] as LatLng;
          final type = item['type'] as String;
          final isWarning = type == 'warning';
          final isCurrent = type == 'current';

          return Marker(
            markerId: MarkerId('${catName}_${item['loc']}'),
            position: position,
            infoWindow: InfoWindow(title: '${catName} - ${item['loc']}', snippet: item['time'] as String),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              isCurrent ? BitmapDescriptor.hueGreen : (isWarning ? BitmapDescriptor.hueRed : markerHue),
            ),
          );
        }));
      }

      if (pathPoints.length > 1) {
        polylines.add(Polyline(
          polylineId: PolylineId('path_$catName'),
          points: pathPoints,
          color: (cat['color'] as Color).withOpacity(0.6),
          width: 3,
          geodesic: true,
        ));
      }
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(target: initial, zoom: widget.catName != null ? 17 : 15),
      myLocationEnabled: true,
      markers: markers,
      polylines: polylines,
      circles: {
        Circle(
          circleId: const CircleId('safe_zone'),
          center: widget.initialLocation,
          radius: 150,
          fillColor: Colors.green.withValues(alpha: 0.2),
          strokeColor: Colors.green.withValues(alpha: 0.5),
          strokeWidth: 2,
        ),
      },
    );
  }
}

