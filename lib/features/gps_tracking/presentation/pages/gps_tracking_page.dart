// 🎯 GPS TRACKING PAGE - GOOGLE MAPS WITH LIVE CAT SIMULATION
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:ui' as ui;

class GpsTrackingPage extends StatefulWidget {
  const GpsTrackingPage({super.key});

  @override
  State<GpsTrackingPage> createState() => _GpsTrackingPageState();
}

class _GpsTrackingPageState extends State<GpsTrackingPage> with SingleTickerProviderStateMixin {
  LatLng? _currentPosition;
  GoogleMapController? _mapController;
  String? _selectedCat;
  bool _isLoading = true;
  bool _isSheetExpanded = true;
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
    },
    {
      'name': 'Oyen',
      'distance': '210m away',
      'battery': 42,
      'color': Colors.orange,
      'image': 'assets/images/Oyen.png',
      'offset': const LatLng(-0.0012, -0.0008),
      'isLost': true,
    },
    {
      'name': 'Bella',
      'distance': '150m away',
      'battery': 90,
      'color': Colors.pink,
      'image': 'assets/images/Bella.png',
      'offset': const LatLng(0.0008, -0.0018),
    },
  ];

  Timer? _simulationTimer;

  @override
  void initState() {
    super.initState();
    _initTracking();
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
    super.dispose();
  }

  // 🎯 LOAD CUSTOM ASSET ICONS FOR GOOGLE MAPS
  Future<void> _loadMarkerIcons() async {
    for (var cat in _cats) {
      final String assetPath = cat['image'];
      final icon = await _getAssetIcon(assetPath, 120); // Resize for map marker
      if (mounted) {
        setState(() {
          _markerIcons[cat['name']] = icon;
        });
      }
    }
  }

  // Helper to resize and convert asset to BitmapDescriptor
  Future<BitmapDescriptor> _getAssetIcon(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    final byteData = await fi.image.toByteData(format: ui.ImageByteFormat.png);
    final uint8List = byteData!.buffer.asUint8List();
    return BitmapDescriptor.fromBytes(uint8List);
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

    return GoogleMap(
      initialCameraPosition: CameraPosition(target: center, zoom: 16),
      onMapCreated: (controller) => _mapController = controller,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapType: MapType.normal,
      markers: _cats.map((cat) {
        final catLoc = LatLng(center.latitude + cat['offset'].latitude, center.longitude + cat['offset'].longitude);
        return Marker(
          markerId: MarkerId(cat['name']),
          position: catLoc,
          // ✅ USE THE CAT IMAGE AS MARKER ICON
          icon: _markerIcons[cat['name']] ?? BitmapDescriptor.defaultMarker,
          onTap: () => setState(() => _selectedCat = cat['name']),
        );
      }).toSet(),
      polylines: polylines,
      circles: {
        Circle(
          circleId: const CircleId('safe_zone'),
          center: center,
          radius: 180,
          fillColor: Colors.green.withValues(alpha: 0.15),
          strokeColor: Colors.green.withValues(alpha: 0.4),
          strokeWidth: 2,
        ),
      },
    );
  }

  Widget _buildBackButton() {
    return Positioned(
      top: 50, left: 20,
      child: GestureDetector(
        onTap: () => _selectedCat != null ? setState(() => _selectedCat = null) : Navigator.pop(context),
        child: SvgPicture.asset('assets/icons/Back.svg', colorFilter: const ColorFilter.mode(Color(0xFF985BEF), BlendMode.srcIn), width: 35),
      ),
    );
  }

  Widget _buildTopOverlays() {
    return Positioned(
      top: 100, left: 0, right: 0,
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
    return Positioned(
      left: 20, top: 410,
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
    return Align(
      alignment: Alignment.bottomCenter,
      child: _selectedCat == null ? _buildCatProfileSheet() : _buildCatDetailView(_selectedCat!),
    );
  }

  Widget _buildCatProfileSheet() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _isSheetExpanded ? 400 : 100,
      width: double.infinity, padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(40)), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 15, offset: Offset(0, -5))]),
      child: Column(
        children: [
          GestureDetector(onTap: () => setState(() => _isSheetExpanded = !_isSheetExpanded), child: Container(height: 6, width: 60, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(3)))),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('GPS Tracking', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
              IconButton(icon: Icon(_isSheetExpanded ? Icons.expand_more : Icons.expand_less, size: 35), onPressed: () => setState(() => _isSheetExpanded = !_isSheetExpanded)),
            ],
          ),
          if (_isSheetExpanded) Expanded(child: ListView.builder(itemCount: _cats.length, itemBuilder: (context, i) => _catTile(_cats[i]))),
        ],
      ),
    );
  }

  Widget _catTile(Map<String, dynamic> cat) {
    return GestureDetector(
      onTap: () => setState(() => _selectedCat = cat['name']),
      child: Container(
        margin: const EdgeInsets.only(bottom: 18), padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(25), border: Border.all(color: cat['color'].withValues(alpha: 0.4), width: 2)),
        child: Row(
          children: [
            ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.asset(cat['image'], width: 70, height: 70, fit: BoxFit.cover)),
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
    return Container(
      height: 500, width: double.infinity, padding: const EdgeInsets.all(30),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(45)), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5))]),
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
          ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: Colors.red, minimumSize: const Size(double.infinity, 65), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), child: const Text('Lost cat?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22))),
          const SizedBox(height: 30),
          const Align(alignment: Alignment.centerLeft, child: Text('Location History Timeline', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22))),
          const SizedBox(height: 20),
          _historyTile(cat),
        ],
      ),
    );
  }

  Widget _historyTile(Map<String, dynamic> cat) {
    return GestureDetector(
      onTap: () => Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(builder: (context) => LocationHistoryScreen(initialLocation: _currentPosition!))),
      child: Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(color: const Color(0xFFF5F5F7), borderRadius: BorderRadius.circular(25)), child: Row(children: [const CircleAvatar(backgroundColor: Color(0xFF00D100), radius: 12), const SizedBox(width: 18), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Distance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), Text(cat['distance'], style: const TextStyle(color: Colors.grey, fontSize: 14))]), const Spacer(), const Icon(Icons.arrow_forward_ios, size: 20, color: Colors.grey)])),
    );
  }
}

// ─────────────────────────────────────────────
// Location History Screen (unchanged)
// ─────────────────────────────────────────────
class LocationHistoryScreen extends StatefulWidget {
  final LatLng initialLocation;
  const LocationHistoryScreen({super.key, required this.initialLocation});

  @override
  State<LocationHistoryScreen> createState() => _LocationHistoryScreenState();
}

class _LocationHistoryScreenState extends State<LocationHistoryScreen> {
  bool _isMapView = false;
  final List<Map<String, String>> _historyData = [
    {'loc': 'No. 12, Jalan Hang Tuah', 'time': 'Current Location - At Home', 'type': 'current'},
    {'loc': 'Simpang Jalan Hang Jebat', 'time': '10 mins ago - 50m away', 'type': 'past'},
    {'loc': 'Taman Permainan Hang Li Po', 'time': '25 mins ago - 120m away', 'type': 'past'},
    {'loc': 'Jalan Tun Perak (Outside Safe Zone)', 'time': '45 mins ago - 300m away', 'type': 'warning'},
    {'loc': 'Klinik Veterinar Melaka', 'time': '1 hour ago - 450m away', 'type': 'past'},
    {'loc': 'Lorong Tun Tan Cheng Lock', 'time': '2 hours ago - 200m away', 'type': 'past'},
    {'loc': 'Jalan Hang Tuah (Safe Zone)', 'time': 'Starting Point - 8:30 AM', 'type': 'past'},
  ];

  @override
  Widget build(BuildContext context) {
    final double tp = MediaQuery.of(context).padding.top + 16;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          _isMapView ? _buildMapView() : _buildListView(),
          Positioned(top: tp, left: 20, child: GestureDetector(onTap: () => Navigator.pop(context), child: SvgPicture.asset('assets/icons/Back.svg', colorFilter: const ColorFilter.mode(Color(0xFF985BEF), BlendMode.srcIn), width: 35))),
          Positioned(top: tp + 40, left: 0, right: 0, child: Center(child: GestureDetector(onTap: () => setState(() => _isMapView = !_isMapView), child: Container(padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 8), decoration: BoxDecoration(color: const Color(0xFF985BEF), borderRadius: BorderRadius.circular(10)), child: Text(_isMapView ? 'List view' : 'Map view', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)))))),
        ],
      ),
    );
  }

  Widget _buildListView() {
    return SafeArea(child: Column(children: [const SizedBox(height: 140), const Text('Location History Timeline', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black)), const SizedBox(height: 30), Expanded(child: ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 40), itemCount: _historyData.length, itemBuilder: (context, index) => _historyNode(index)))]));
  }

  Widget _historyNode(int index) {
    final item = _historyData[index];
    final bool isWarning = item['type'] == 'warning';
    return IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Column(children: [Container(width: 24, height: 24, decoration: BoxDecoration(shape: BoxShape.circle, color: item['type'] == 'current' ? const Color(0xFF00D100) : (isWarning ? Colors.red : const Color(0xFFD9D9D9)))), if (index != _historyData.length - 1) Expanded(child: Container(width: 2.5, color: const Color(0xFFD9D9D9)))]), const SizedBox(width: 25), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item['loc']!, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isWarning ? Colors.red : Colors.black)), Text(item['time']!, style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 13, fontWeight: FontWeight.w500)), const SizedBox(height: 45)]))]));
  }

  Widget _buildMapView() {
    return GoogleMap(
      initialCameraPosition: CameraPosition(target: widget.initialLocation, zoom: 15),
      myLocationEnabled: true,
      circles: {
        Circle(circleId: const CircleId('safe_zone'), center: widget.initialLocation, radius: 150, fillColor: Colors.green.withValues(alpha: 0.2), strokeColor: Colors.green.withValues(alpha: 0.5), strokeWidth: 2),
      },
    );
  }
}
