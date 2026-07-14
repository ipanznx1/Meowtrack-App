import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:meow_track/core/app_state.dart';
import 'package:meow_track/router/app_router.dart';
import 'package:url_launcher/url_launcher.dart';

class VetDirectoryPage extends StatefulWidget {
  const VetDirectoryPage({super.key});

  @override
  State<VetDirectoryPage> createState() => _VetDirectoryPageState();
}

class _VetDirectoryPageState extends State<VetDirectoryPage> {
  static const String _googlePlacesApiKey = 'AIzaSyAGz4NvKPo3GGXd9pe9CYGOTRf64FNt8Bo';
  static const double initialRadius = 5000; // 5km
  static const double maxRadius = 25000; // 25km

  bool _isMapView = true;
  bool _onlyOpenNow = false;
  bool _only24h = false;
  bool _catFriendly = false;
  GoogleMapController? _mapController;
  Position? _currentPosition;
  bool _mapReady = false;
  bool _permissionDenied = false;
  bool _placesLoading = false;
  String? _placesError;
  bool _hasFetchedPlaces = false;
  bool _isMoreLoading = false;
  String? _nextPageToken;
  bool _hasMoreVets = false;

  List<Map<String, dynamic>> _clinics = [];
  List<Map<String, dynamic>> _filteredClinics = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController = null;
    super.dispose();
  }

  void _onSearchChanged() {
    _applyFilters();
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredClinics = _clinics.where((clinic) {
        final name = (clinic['name'] ?? '').toString().toLowerCase();
        final vicinity = (clinic['vicinity'] ?? '').toString().toLowerCase();
        
        final matchesSearch = name.contains(query);
        final isOpen = clinic['isOpen'] == true;
        
        // Mock identification for demo/keyword based
        final is24h = name.contains('24') || name.contains('emergency') || vicinity.contains('24');
        final isCatFriendly = name.contains('cat') || name.contains('feline') || clinic['isCatFriendly'] == true;

        bool matches = matchesSearch;
        if (_onlyOpenNow && !isOpen) matches = false;
        if (_only24h && !is24h) matches = false;
        if (_catFriendly && !isCatFriendly) matches = false;
        
        return matches;
      }).toList();

      if (_only24h) {
        // Sort by distance if SOS mode
        _filteredClinics.sort((a, b) {
          double distA = double.tryParse(a['distance'].split(' ').first) ?? 999;
          double distB = double.tryParse(b['distance'].split(' ').first) ?? 999;
          return distA.compareTo(distB);
        });
      }
    });
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _permissionDenied = true);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _permissionDenied = true);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => _permissionDenied = true);
      return;
    }

    try {
      _currentPosition = await Geolocator.getCurrentPosition();
      if (_currentPosition != null) {
        await _startSmartSearch();
      }
      if (_mapController != null && _currentPosition != null) {
        _moveCameraToCurrentLocation();
      }
    } catch (_) {
      setState(() => _permissionDenied = true);
    }
    if (mounted) setState(() {});
  }

  Future<void> _startSmartSearch() async {
    bool found = await _fetchNearbyVets(radius: initialRadius);
    if (!found && mounted) {
      await _fetchNearbyVets(radius: maxRadius);
    }
  }

  Future<bool> _fetchNearbyVets({String? pageToken, double? radius, int retryCount = 0}) async {
    if (_currentPosition == null) return false;
    if (pageToken == null && _hasFetchedPlaces && radius == null) return false;
    if (pageToken != null && (_placesLoading || _isMoreLoading)) return false;

    setState(() {
      if (pageToken == null) {
        _placesLoading = true;
        _placesError = null;
      } else {
        _isMoreLoading = true;
      }
    });

    final params = {
      'location': '${_currentPosition!.latitude},${_currentPosition!.longitude}',
      'radius': (radius ?? initialRadius).toStringAsFixed(0),
      'type': 'veterinary_care',
      'keyword': 'veterinary clinic',
      'key': _googlePlacesApiKey,
    };
    if (pageToken != null) params['pagetoken'] = pageToken;

    final url = Uri.https('maps.googleapis.com', '/maps/api/place/nearbysearch/json', params);

    try {
      final response = await http.get(url);
      if (response.statusCode != 200) {
        setState(() {
          _placesError = 'Request failed';
          _placesLoading = false;
          _isMoreLoading = false;
        });
        return false;
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final status = body['status'] as String? ?? 'UNKNOWN';
      final nextPageToken = body['next_page_token'] as String?;
      final results = (body['results'] as List<dynamic>?) ?? <dynamic>[];

      if (pageToken != null && status == 'INVALID_REQUEST' && retryCount < 3) {
        await Future.delayed(const Duration(seconds: 2));
        return _fetchNearbyVets(pageToken: pageToken, radius: radius, retryCount: retryCount + 1);
      }

      if (status != 'OK') {
        setState(() {
          if (status == 'ZERO_RESULTS') {
            _placesError = (radius == maxRadius) ? 'Tiada klinik berdekatan' : null;
          } else {
            _placesError = 'API Error: $status';
          }
          _placesLoading = false;
          _isMoreLoading = false;
          _hasMoreVets = false;
          if (pageToken == null) _hasFetchedPlaces = true;
        });
        return false;
      }

      final places = results.map<Map<String, dynamic>>((place) {
        final location = (place['geometry']['location'] as Map<String, dynamic>?) ?? {};
        final photoRefs = (place['photos'] as List<dynamic>?)?.map((i) => i['photo_reference'] as String?).whereType<String>().toList() ?? [];
        final image = photoRefs.isNotEmpty ? _getPlacePhotoUrl(photoRefs.first) : '';
        final gallery = photoRefs.skip(1).take(3).map(_getPlacePhotoUrl).toList();
        final name = place['name'] as String? ?? 'Vet Clinic';

        return {
          'name': name,
          'rating': (place['rating'] is num) ? (place['rating'] as num).toDouble() : 4.5,
          'isOpen': (place['opening_hours']?['open_now'] as bool?) ?? false,
          'location': LatLng((location['lat'] as num?)?.toDouble() ?? 0.0, (location['lng'] as num?)?.toDouble() ?? 0.0),
          'image': image,
          'gallery': gallery,
          'placeId': place['place_id'] as String? ?? '',
          'vicinity': place['vicinity'] as String? ?? 'No address provided',
          // Mock data for cat-friendly based on name or random for demo
          'isCatFriendly': name.toLowerCase().contains('cat') || name.toLowerCase().contains('feline') || (name.hashCode % 5 == 0),
        };
      }).toList();

      setState(() {
        final processed = places.map((p) {
          final loc = p['location'] as LatLng;
          final dist = Geolocator.distanceBetween(_currentPosition!.latitude, _currentPosition!.longitude, loc.latitude, loc.longitude);
          p['distance'] = '${(dist / 1000).toStringAsFixed(1)} km away';
          return p;
        }).toList();

        _clinics = pageToken == null ? processed : [..._clinics, ...processed];
        _filteredClinics = _clinics;
        _nextPageToken = nextPageToken;
        _hasMoreVets = nextPageToken != null && nextPageToken.isNotEmpty;
        _placesLoading = false;
        _isMoreLoading = false;
        if (pageToken == null) _hasFetchedPlaces = true;
      });
      return true;
    } catch (e) {
      setState(() {
        _placesError = e.toString();
        _placesLoading = false;
        _isMoreLoading = false;
      });
      return false;
    }
  }

  void _loadMoreVets() {
    if (_nextPageToken != null) _fetchNearbyVets(pageToken: _nextPageToken);
  }

  Future<void> _moveCameraToCurrentLocation() async {
    if (_mapController == null || _currentPosition == null) return;
    await _mapController!.animateCamera(CameraUpdate.newLatLngZoom(LatLng(_currentPosition!.latitude, _currentPosition!.longitude), 14));
  }

  String _getPlacePhotoUrl(String photoReference) {
    return Uri.https('maps.googleapis.com', '/maps/api/place/photo', {'maxwidth': '400', 'photoreference': photoReference, 'key': _googlePlacesApiKey}).toString();
  }

  Future<void> _launchMapDirections(double lat, double lng) async {
    final url = Uri.parse("https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving");
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  Future<Map<String, dynamic>> _fetchClinicExtraDetails(String placeId) async {
    if (placeId.isEmpty) return {'phone': '', 'reviews': [], 'hours': 'Not available'};
    final url = Uri.https('maps.googleapis.com', '/maps/api/place/details/json', {
      'place_id': placeId, 
      'fields': 'reviews,formatted_phone_number,international_phone_number,opening_hours', 
      'key': _googlePlacesApiKey
    });

    try {
      final response = await http.get(url);
      if (response.statusCode != 200) return {'phone': '', 'reviews': [], 'hours': 'Not available'};
      final body = jsonDecode(response.body);
      final result = body['result'] as Map<String, dynamic>?;
      
      final phone = result?['international_phone_number'] ?? result?['formatted_phone_number'] ?? '';
      final reviews = (result?['reviews'] as List<dynamic>?) ?? [];
      
      // Get current day's opening hours
      String todayHours = 'Closed today';
      final openingHours = result?['opening_hours'] as Map<String, dynamic>?;
      if (openingHours != null) {
        final weekdayText = openingHours['weekday_text'] as List<dynamic>?;
        if (weekdayText != null && weekdayText.isNotEmpty) {
          // Find today's text (Google usually returns Monday-Sunday)
          final now = DateTime.now();
          // Adjust for Google index (Monday is 0 in weekdayText, but in DateTime 1 is Monday)
          int googleIdx = now.weekday - 1; 
          if (googleIdx >= 0 && googleIdx < weekdayText.length) {
            todayHours = weekdayText[googleIdx].toString().split(': ').last;
          }
        } else if (openingHours['open_now'] != null) {
          todayHours = (openingHours['open_now'] as bool) ? "Open Now" : "Closed Now";
        }
      }

      return {
        'phone': phone,
        'hours': todayHours,
        'reviews': reviews.map<Map<String, dynamic>>((r) => {
          'name': r['author_name'] ?? 'Anon', 
          'rating': r['rating'] ?? 0, 
          'comment': r['text'] ?? '', 
          'time': r['relative_time_description'] ?? ''
        }).toList()
      };
    } catch (_) {
      return {'phone': '', 'reviews': [], 'hours': 'Not available'};
    }
  }

  void _showClinicDetails(Map<String, dynamic> clinicMap) async {
    // Tunjukkan loading overlay
    final loadingOverlay = OverlayEntry(
      builder: (context) => Container(
        color: Colors.black.withOpacity(0.3),
        child: const Center(child: CircularProgressIndicator(color: Color(0xFF985BEF))),
      ),
    );
    Overlay.of(context).insert(loadingOverlay);

    try {
      // PENTING: Gunakan 'placeId' (bukan place_id)
      final String pid = clinicMap['placeId'] ?? clinicMap['place_id'] ?? '';
      final extra = await _fetchClinicExtraDetails(pid);
      
      loadingOverlay.remove();
      if (!mounted) return;

      final clinic = VetClinic(
        name: clinicMap['name']?.toString() ?? 'Vet Clinic',
        rating: (clinicMap['rating'] ?? 4.5).toString(),
        distance: clinicMap['distance']?.toString() ?? 'Nearby',
        hours: extra['hours'] ?? '10:00 AM - 10:00 PM',
        phone: extra['phone'] ?? '',
        whatsapp: extra['phone'] ?? '',
        headerImage: clinicMap['image']?.toString() ?? '',
        gallery: clinicMap['gallery'] != null ? List<String>.from(clinicMap['gallery']) : [],
        description: clinicMap['vicinity']?.toString() ?? 'Professional veterinary services.',
        lat: (clinicMap['location'] as LatLng).latitude,
        lng: (clinicMap['location'] as LatLng).longitude,
        reviews: extra['reviews'] ?? [],
      );

      context.push(AppRouter.vetClinicDetails, extra: clinic);
    } catch (e) {
      loadingOverlay.remove();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Unable to load clinic details.")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(),
          if (_placesLoading) const LinearProgressIndicator(minHeight: 3),
          if (_placesError != null) Container(width: double.infinity, color: Colors.red.shade50, padding: const EdgeInsets.all(10), child: Text(_placesError!, style: const TextStyle(color: Colors.red, fontSize: 12))),
          Expanded(child: _isMapView ? _buildMapView() : _buildListView()),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            onPressed: _triggerSOS,
            backgroundColor: _only24h ? Colors.black : Colors.red,
            icon: Icon(Icons.emergency, color: Colors.white),
            label: Text(_only24h ? 'Show All' : 'SOS 24H', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            onPressed: _moveCameraToCurrentLocation, 
            backgroundColor: const Color(0xFF985BEF), 
            child: const Icon(Icons.my_location, color: Colors.white)
          ),
        ],
      ),
    );
  }

  void _triggerSOS() async {
    setState(() {
      _only24h = !_only24h;
      if (_only24h) {
        _isMapView = false; // Switch to list view to see the nearest clearly
        _onlyOpenNow = true;
      }
    });
    
    _applyFilters();

    // If no 24h clinics found in current list, try fetching with keyword
    bool has24h = _filteredClinics.any((c) => c['name'].toLowerCase().contains('24') || c['name'].toLowerCase().contains('emergency'));
    
    if (_only24h && !has24h) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Searching for 24-hour emergency clinics...")));
      await _fetchNearbyVets(radius: maxRadius); // Try wider radius
      _applyFilters();
    }
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 18),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(color: const Color(0xFFF5F5F8), borderRadius: BorderRadius.circular(22)),
                  child: TextField(controller: _searchController, decoration: const InputDecoration(hintText: 'Search...', border: InputBorder.none, suffixIcon: Icon(Icons.search, color: Color(0xFF985BEF)))),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  setState(() => _onlyOpenNow = !_onlyOpenNow);
                  _applyFilters();
                },
                child: Container(
                  padding: const EdgeInsets.all(12), 
                  decoration: BoxDecoration(
                    color: _onlyOpenNow ? const Color(0xFF985BEF).withOpacity(0.1) : const Color(0xFFF5F5F8), 
                    borderRadius: BorderRadius.circular(18),
                    border: _onlyOpenNow ? Border.all(color: const Color(0xFF985BEF)) : null,
                  ), 
                  child: Icon(Icons.access_time_filled, color: _onlyOpenNow ? const Color(0xFF985BEF) : Colors.grey)
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => setState(() => _isMapView = !_isMapView),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF985BEF), 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), 
                  minimumSize: const Size(120, 48)
                ),
                child: Text(_isMapView ? 'List view' : 'Map view', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text("Cat-Friendly", style: TextStyle(fontSize: 12)),
                selected: _catFriendly,
                onSelected: (val) {
                  setState(() => _catFriendly = val);
                  _applyFilters();
                },
                selectedColor: const Color(0xFF985BEF).withOpacity(0.2),
                checkmarkColor: const Color(0xFF985BEF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              if (_onlyOpenNow || _only24h) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Color(0xFF985BEF)),
                  onPressed: () {
                    setState(() {
                      _onlyOpenNow = false;
                      _only24h = false;
                      _catFriendly = false;
                    });
                    _applyFilters();
                  },
                )
              ]
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredClinics.length + (_hasMoreVets ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _filteredClinics.length) return Center(child: TextButton(onPressed: _isMoreLoading ? null : _loadMoreVets, child: const Text('Load More')));
        final clinic = _filteredClinics[index];
        final is24h = (clinic['name'] ?? '').toString().contains('24') || (clinic['name'] ?? '').toString().toLowerCase().contains('emergency') || clinic['vicinity'].toString().contains('24');
        final isCatFriendly = clinic['isCatFriendly'] == true;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            onTap: () => _showClinicDetails(clinic),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: clinic['image'].isNotEmpty 
                ? Image.network(clinic['image'], width: 60, height: 60, fit: BoxFit.cover)
                : Container(width: 60, height: 60, color: Colors.grey[200], child: const Icon(Icons.local_hospital)),
            ),
            title: Row(
              children: [
                Expanded(child: Text(clinic['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                if (is24h) Container(margin: const EdgeInsets.only(left: 4), padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2), decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)), child: const Text('24H', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold))),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${clinic['rating']} ⭐ • ${clinic['distance']}'),
                if (isCatFriendly) 
                  Row(
                    children: [
                      const Icon(Icons.pets, size: 10, color: Color(0xFF985BEF)),
                      const SizedBox(width: 4),
                      const Text('Cat-Friendly', style: TextStyle(color: Color(0xFF985BEF), fontSize: 10, fontWeight: FontWeight.w600)),
                    ],
                  ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.directions, color: Color(0xFF985BEF)),
                  onPressed: () => _launchMapDirections(clinic['location'].latitude, clinic['location'].longitude),
                ),
                Icon(Icons.circle, color: clinic['isOpen'] ? Colors.green : Colors.red, size: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMapView() {
    return GoogleMap(
      initialCameraPosition: CameraPosition(target: _currentPosition != null ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude) : const LatLng(3.1319, 101.6840), zoom: 13),
      onMapCreated: (c) => _mapController = c,
      markers: _filteredClinics.map((c) => Marker(markerId: MarkerId(c['name']), position: c['location'], onTap: () => _showClinicDetails(c))).toSet(),
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
    );
  }
}
