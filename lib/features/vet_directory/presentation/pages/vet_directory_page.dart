import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:meow_track/core/app_state.dart';

class VetDirectoryPage extends StatefulWidget {
  const VetDirectoryPage({super.key});

  @override
  State<VetDirectoryPage> createState() => _VetDirectoryPageState();
}

class _VetDirectoryPageState extends State<VetDirectoryPage> {
  static const String _googlePlacesApiKey = 'AIzaSyAGz4NvKPo3GGXd9pe9CYGOTRf64FNt8Bo';
  bool _isMapView = true;
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

  // Clinic list populated from Google Places.
  List<Map<String, dynamic>> _clinics = [];

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _permissionDenied = true);
      return;
    }

    permission = await Geolocator.checkPermission();
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
        await _fetchNearbyVets();
      }
      if (_mapController != null && _currentPosition != null) {
        _moveCameraToCurrentLocation();
      }
    } catch (_) {
      setState(() => _permissionDenied = true);
      return;
    }

    if (mounted) setState(() {});
  }

  Future<void> _fetchNearbyVets([String? pageToken, int retryCount = 0]) async {
    if (_currentPosition == null) return;
    if (pageToken == null && _hasFetchedPlaces) return;
    if (pageToken != null && (_placesLoading || _isMoreLoading)) return;
    if (_googlePlacesApiKey.isEmpty || _googlePlacesApiKey == 'YOUR_GOOGLE_PLACES_API_KEY') {
      setState(() {
        _placesError = 'Google Places API key is missing in Dart code.';
      });
      return;
    }

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
      'radius': '5000',
      'type': 'veterinary_care',
      'key': _googlePlacesApiKey,
    };
    if (pageToken != null) {
      params['pagetoken'] = pageToken;
    }
    final url = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/nearbysearch/json',
      params,
    );

    try {
      final response = await http.get(url);
      if (response.statusCode != 200) {
        setState(() {
          _placesError = 'Places request failed: ${response.statusCode}';
          _placesLoading = false;
          _isMoreLoading = false;
          _hasFetchedPlaces = true;
        });
        return;
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final status = body['status'] as String? ?? 'UNKNOWN';
      final errorMessage = body['error_message'] as String?;
      final nextPageToken = body['next_page_token'] as String?;
      final results = (body['results'] as List<dynamic>?) ?? <dynamic>[];

      if (pageToken != null && status == 'INVALID_REQUEST' && retryCount < 3) {
        await Future.delayed(const Duration(seconds: 2));
        return _fetchNearbyVets(pageToken, retryCount + 1);
      }
      if (status != 'OK') {
        setState(() {
          if (status == 'ZERO_RESULTS') {
            _placesError = 'No nearby veterinary clinics found.';
          } else if (status == 'REQUEST_DENIED') {
            _placesError = 'Places request denied: check your API key restrictions (app/package restrictions are not allowed for HTTP REST calls).';
          } else {
            _placesError = 'Places API error: $status${errorMessage != null ? ' - $errorMessage' : ''}';
          }
          _placesLoading = false;
          _isMoreLoading = false;
          _hasMoreVets = false;
          _hasFetchedPlaces = true;
        });
        return;
      }

      if (results.isEmpty) {
        setState(() {
          _placesError = 'No nearby veterinary clinics found.';
          _placesLoading = false;
          _hasFetchedPlaces = true;
        });
        return;
      }

      final places = results.map<Map<String, dynamic>>((place) {
        final location = place['geometry']['location'] as Map<String, dynamic>;
        final name = place['name'] as String? ?? 'Vet Clinic';
        final rating = (place['rating'] is num) ? (place['rating'] as num).toDouble() : 4.5;
        final isOpen = place['opening_hours']?['open_now'] ?? false;
        final placeId = place['place_id'] as String? ?? '';
        final photoRefs = (place['photos'] as List<dynamic>?)
                ?.map((item) => (item as Map<String, dynamic>)['photo_reference'] as String?)
                .where((ref) => ref != null && ref.isNotEmpty)
                .cast<String>()
                .toList() ?? <String>[];

        final mainPhoto = photoRefs.isNotEmpty ? _getPlacePhotoUrl(photoRefs.first) : '';
        final galleryPhotos = photoRefs.length > 1
            ? photoRefs.skip(1).take(3).map(_getPlacePhotoUrl).toList()
            : <String>[];

        return {
          'name': name,
          'rating': rating,
          'distance': '',
          'isOpen': isOpen,
          'location': LatLng(location['lat'] as double, location['lng'] as double),
          'image': mainPhoto,
          'gallery': galleryPhotos,
          'phone': '',
          'placeId': placeId,
          'vicinity': place['vicinity'] as String? ?? '',
        };
      }).toList();

      setState(() {
        if (places.isNotEmpty) {
          final newPlaces = places.map((place) {
            final location = place['location'] as LatLng;
            final distanceMeters = Geolocator.distanceBetween(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
              location.latitude,
              location.longitude,
            );
            place['distance'] = '${(distanceMeters / 1000).toStringAsFixed(1)} km away';

            final gallery = (place['gallery'] as List<String>).toList();
            while (gallery.length < 3) {
              gallery.add(place['image'] as String? ?? '');
            }
            place['gallery'] = gallery.take(3).toList();

            return place;
          }).toList();
          _clinics = pageToken == null ? newPlaces : [..._clinics, ...newPlaces];
          _nextPageToken = nextPageToken;
          _hasMoreVets = nextPageToken != null && nextPageToken.isNotEmpty;
        }
        _placesLoading = false;
        _isMoreLoading = false;
        if (pageToken == null) _hasFetchedPlaces = true;
      });
    } catch (error) {
      setState(() {
        _placesError = error.toString();
        _placesLoading = false;
        _isMoreLoading = false;
        _hasFetchedPlaces = true;
      });
    }
  }

  void _loadMoreVets() {
    if (_nextPageToken == null || _nextPageToken!.isEmpty) return;
    _fetchNearbyVets(_nextPageToken);
  }

  Future<void> _moveCameraToCurrentLocation() async {
    if (_mapController == null || _currentPosition == null) return;
    await _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          zoom: 14,
        ),
      ),
    );
  }
  String _getPlacePhotoUrl(String photoReference) {
    return Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/photo',
      {
        'maxwidth': '400',
        'photoreference': photoReference,
        'key': _googlePlacesApiKey,
      },
    ).toString();
  }

  Future<List<Map<String, dynamic>>> _fetchPlaceReviews(String placeId) async {
    if (placeId.isEmpty) return [];

    final url = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/details/json',
      {
        'place_id': placeId,
        'fields': 'reviews',
        'key': _googlePlacesApiKey,
      },
    );

    try {
      final response = await http.get(url);
      if (response.statusCode != 200) return [];

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final result = body['result'] as Map<String, dynamic>?;
      final reviews = (result?['reviews'] as List<dynamic>?) ?? [];

      return reviews
          .map<Map<String, dynamic>>((review) => {
                'name': review['author_name'] ?? 'Anonymous',
                'rating': review['rating'] ?? 0,
                'comment': review['text'] ?? '',
                'time': review['relative_time_description'] ?? '',
              })
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header
          _buildHeader(),
          if (_placesLoading)
            const LinearProgressIndicator(minHeight: 3),
          if (_placesError != null)
            Container(
              width: double.infinity,
              color: Colors.red.shade50,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text(
                'Places API issue: $_placesError',
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ),
          
          // Map or List - fills remaining space
          Expanded(
            child: _isMapView ? _buildMapView() : _buildListView(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F8),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    children: const [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search...',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      Icon(Icons.search, color: Color(0xFF985BEF)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F8),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.tune, color: Color(0xFF985BEF)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Center(
            child: ElevatedButton(
              onPressed: () => setState(() => _isMapView = !_isMapView),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF985BEF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                elevation: 8,
                shadowColor: const Color(0xFF985BEF).withOpacity(0.35),
                minimumSize: const Size(160, 48),
              ),
              child: Text(
                _isMapView ? 'List view' : 'Map view',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    // Sort clinics by distance if we have current position
    List<Map<String, dynamic>> sortedClinics = _clinics;
    if (_currentPosition != null) {
      sortedClinics = List.from(_clinics)..sort((a, b) {
        double distA = Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          a['location'].latitude,
          a['location'].longitude,
        );
        double distB = Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          b['location'].latitude,
          b['location'].longitude,
        );
        return distA.compareTo(distB);
      });
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedClinics.length + (_hasMoreVets ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == sortedClinics.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: ElevatedButton(
                onPressed: _isMoreLoading ? null : _loadMoreVets,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF985BEF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
                ),
                child: _isMoreLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Next page', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          );
        }
        final clinic = sortedClinics[index];
        return GestureDetector(
          onTap: () => _showClinicDetails(clinic),
          child: Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Clinic name
                  Text(
                    clinic['name'],
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  
                  // Rating and distance in row
                  Row(
                    children: [
                      // Stars
                      Row(
                        children: List.generate(5, (i) => 
                          const Icon(Icons.star, color: Colors.amber, size: 14)
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${clinic['rating']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                      const Spacer(),
                      Text(clinic['distance'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Hours
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text('10:00 AM to 10:00 PM', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Action buttons
                  Row(
                    children: [
                      // Phone button
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(10),
                        child: const Icon(Icons.phone, color: Color(0xFF7C3AED), size: 18),
                      ),
                      const SizedBox(width: 12),
                      
                      // WhatsApp button
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(10),
                        child: const Icon(Icons.message, color: Color(0xFF7C3AED), size: 18),
                      ),
                      const Spacer(),
                      
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: clinic['isOpen'] ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          clinic['isOpen'] ? 'Open' : 'Closed',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: clinic['isOpen'] ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMapView() {
    // Build markers for clinics
    final markers = _clinics.map((clinic) {
      return Marker(
        markerId: MarkerId(clinic['name']),
        position: clinic['location'],
        infoWindow: InfoWindow(title: clinic['name'], snippet: clinic['distance']),
        onTap: () => _showClinicDetails(clinic),
      );
    }).toSet();

    // Build circles for each clinic (small highlight) and a radius around current location
    final circles = <Circle>{};
    for (final clinic in _clinics) {
      circles.add(Circle(
        circleId: CircleId(clinic['name']),
        center: clinic['location'],
        radius: 200, // 200 meters highlight around clinic
        fillColor: Colors.blue.withOpacity(0.12),
        strokeColor: Colors.blue.withOpacity(0.4),
        strokeWidth: 1,
      ));
    }

    if (_currentPosition != null) {
      circles.add(Circle(
        circleId: const CircleId('current_location'),
        center: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        radius: 50,
        fillColor: Colors.green.withOpacity(0.3),
        strokeColor: Colors.green.withOpacity(0.6),
        strokeWidth: 2,
      ));
    }

    if (_currentPosition != null) {
      final center = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
      circles.add(Circle(
        circleId: const CircleId('current_location_radius'),
        center: center,
        radius: 1000, // 1km radius showing available shops
        fillColor: Colors.green.withOpacity(0.06),
        strokeColor: Colors.green.withOpacity(0.35),
        strokeWidth: 1,
      ));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final initialPosition = _currentPosition != null
            ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
            : const LatLng(3.1319, 101.6840);

        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: Stack(
            children: [
              SizedBox.expand(
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(target: initialPosition, zoom: 13),
                  onMapCreated: (controller) {
                    _mapController = controller;
                    setState(() {
                      _mapReady = true;
                    });
                    if (_currentPosition != null) {
                      _moveCameraToCurrentLocation();
                    }
                  },
                  markers: markers,
                  circles: circles,
                  myLocationEnabled: true,
                  zoomControlsEnabled: true,
                  mapToolbarEnabled: true,
                  myLocationButtonEnabled: true,
                  compassEnabled: true,
                  mapType: MapType.normal,
                ),
              ),
              if (_permissionDenied)
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12)],
                    ),
                    child: const Text(
                      'Location permission denied. Showing nearby clinics by default.',
                      style: TextStyle(color: Colors.black87),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              if (_currentPosition == null)
                Positioned(
                  top: 80,
                  left: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.65),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Text('Detecting location...', style: TextStyle(color: Colors.white)),
                  ),
                ),
              Positioned(
                top: 20,
                right: 20,
                child: _MapStatusBanner(
                  message: _mapReady ? 'Map ready (${markers.length} markers)' : 'Loading map...'
                ),
              ),
              Positioned(
                bottom: 24,
                right: 20,
                child: FloatingActionButton(
                  onPressed: _moveCameraToCurrentLocation,
                  backgroundColor: const Color(0xFF985BEF),
                  child: const Icon(Icons.my_location),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showClinicDetails(Map<String, dynamic> clinic) async {
    // Fetch reviews from Google Places
    final reviews = await _fetchPlaceReviews(clinic['placeId'] as String? ?? '');
    clinic['reviews'] = reviews;

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.35),
      isDismissible: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        final topPadding = MediaQuery.of(context).padding.top;

        return DraggableScrollableSheet(
          initialChildSize: 0.78,
          minChildSize: 0.55,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return SafeArea(
              child: Container(
                margin: const EdgeInsets.only(top: 6),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: _buildClinicDetailsContent(clinic, topPadding, scrollController),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildClinicDetailsContent(Map<String, dynamic> clinic, double topPadding, ScrollController scrollController) {
    final gallery = (clinic['gallery'] as List<dynamic>?)?.cast<String>() ?? [];
    final String mainPhoto = (clinic['image'] as String?)?.isNotEmpty == true
        ? clinic['image'] as String
        : gallery.isNotEmpty
            ? gallery.first
            : '';

    final List<String> uniqueGallery = gallery
        .where((url) => url.isNotEmpty)
        .toSet()
        .toList();

    final List<String> display = uniqueGallery.take(3).toList();
    while (display.length < 3) {
      display.add('');
    }

    return Stack(
      children: [
        SingleChildScrollView(
          controller: scrollController,
          child: Column(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                child: mainPhoto.isNotEmpty
                    ? Image.network(
                        mainPhoto,
                        height: 250,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 250,
                          width: double.infinity,
                          color: Colors.grey[200],
                          child: const Icon(Icons.photo, color: Colors.grey, size: 60),
                        ),
                      )
                    : Container(
                        height: 250,
                        width: double.infinity,
                        color: Colors.grey[200],
                        child: const Icon(Icons.photo, color: Colors.grey, size: 60),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(25.0),
                child: Column(
                  children: [
                    Text(
                      clinic['name'],
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: 60,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _buildReviewsSection((clinic['reviews'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? []),
                    const SizedBox(height: 30),
                    const Text('Distance', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(clinic['distance'], style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 20),
                    const Text('Open hours', style: TextStyle(fontWeight: FontWeight.bold)),
                    const Text('10:00 AM to 10:00 PM', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildActionCircle(Icons.phone_outlined, () => launchUrl(Uri.parse('tel:${clinic['phone']}'))),
                        const SizedBox(width: 20),
                        _buildActionCircle(Icons.chat_bubble_outline, () => launchUrl(Uri.parse('https://wa.me/60123456789'))),
                      ],
                    ),
                    const SizedBox(height: 40),
                    const Text('Get Directions to Clinic', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildNavIcon('https://cdn-icons-png.flaticon.com/512/2991/2991148.png'),
                        const SizedBox(width: 30),
                        _buildNavIcon('https://cdn-icons-png.flaticon.com/512/5969/5969244.png'),
                      ],
                    ),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: topPadding + 10,
          left: 20,
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionDeniedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_off, size: 48, color: Color(0xFF985BEF)),
            const SizedBox(height: 18),
            const Text(
              'Location permission is required to show nearby vets.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Please enable location services and restart the app to view the map.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsSection(List<Map<String, dynamic>> reviews) {
    if (reviews.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text('No reviews yet', style: TextStyle(fontSize: 12, color: Colors.grey)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Reviews', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        ...reviews.take(3).map((review) => GestureDetector(
          onTap: () => _showFullReview(review),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              review['name'] as String,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                            Text(
                              review['time'] as String,
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: List.generate(5, (i) => Icon(
                          i < (review['rating'] as int) ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 14,
                        )),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    review['comment'] as String,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildGalleryItem(String url) {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: url.isNotEmpty
            ? Image.network(
                url,
                width: 90,
                height: 90,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.image, color: Colors.grey, size: 40),
                ),
              )
            : Container(
                color: Colors.grey[200],
                child: const Icon(Icons.image, color: Colors.grey, size: 40),
              ),
      ),
    );
  }

  void _showFullReview(Map<String, dynamic> review) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(review['name'] as String, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                              const SizedBox(height: 6),
                              Row(
                                children: List.generate(5, (i) => Icon(
                                  i < (review['rating'] as int) ? Icons.star : Icons.star_border,
                                  color: Colors.amber,
                                  size: 16,
                                )),
                              ),
                              const SizedBox(height: 8),
                              Text(review['time'] as String, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(review['comment'] as String, style: const TextStyle(fontSize: 14, color: Colors.black87)),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildActionCircle(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(15),
        ),
        child: Icon(icon, color: const Color(0xFF985BEF), size: 30),
      ),
    );
  }

  Widget _buildNavIcon(String url) {
    return Image.network(url, width: 50, height: 50);
  }
}

class _MapStatusBanner extends StatelessWidget {
  final String message;
  const _MapStatusBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
      ),
    );
  }
}
