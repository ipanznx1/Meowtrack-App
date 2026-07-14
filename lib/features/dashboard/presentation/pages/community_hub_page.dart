import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:meow_track/core/app_state.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class CommunityHubPage extends StatefulWidget {
  const CommunityHubPage({super.key});

  @override
  State<CommunityHubPage> createState() => _CommunityHubPageState();
}

class _CommunityHubPageState extends State<CommunityHubPage> {
  static const String _googlePlacesApiKey = 'AIzaSyAGz4NvKPo3GGXd9pe9CYGOTRf64FNt8Bo';
  static const double initialRadius = 5000; // 5km
  static const double maxRadius = 25000; // 25km

  final TextEditingController _searchController = TextEditingController();
  final List<String> _placeCategories = ['All', 'Pet-friendly cafe', 'Pet store', 'Veterinary clinic'];
  final List<String> _postCategories = ['All', 'Lost & found', 'Events', 'Adoption'];

  Position? _currentPosition;
  bool _permissionDenied = false;
  bool _isLoadingLocation = true;
  bool _placesLoading = false;
  bool _placesLoadingMore = false;
  bool _hasMoreResults = false;
  String? _placesError;
  String _selectedPlaceCategory = 'All';
  String _selectedPostCategory = 'All';
  String _searchQuery = '';
  String? _nextPageToken;
  List<Map<String, dynamic>> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  Future<void> _updatePostStatus(String postId) async {
    try {
      await FirebaseFirestore.instance.collection('community_posts').doc(postId).update({'status': 'Found'});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Status updated to Found!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating status: $e')));
      }
    }
  }

  void _showReportDialog(String postId) {
    final TextEditingController reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Report Post"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Why are you reporting this post?"),
            const SizedBox(height: 15),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                hintText: "Reason (e.g. Spam, Inappropriate content)",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) return;
              
              try {
                await appState.reportPost(postId, reason);
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Post reported successfully. Our team will review it.")),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Report", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _launchWhatsApp(String phone) async {
    final url = Uri.parse("https://wa.me/$phone");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not launch WhatsApp')));
      }
    }
  }

  void _sharePost(CommunityPost post) {
    final String text = '''
🐾 ${post.title} 🐾
Status: ${post.status.toUpperCase()}
Category: ${post.category}

${post.content}

📍 Lokasi: ${post.locationLabel}
👤 Oleh: ${post.author}

Muat turun Meowtrack untuk membantu kami!
''';
    Share.share(text, subject: post.title);
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _permissionDenied = true;
        _isLoadingLocation = false;
      });
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
      setState(() {
        _permissionDenied = true;
        _isLoadingLocation = false;
      });
      return;
    }

    try {
      _currentPosition = await Geolocator.getCurrentPosition();
    } catch (_) {
      setState(() {
        _permissionDenied = true;
      });
    }

    setState(() {
      _isLoadingLocation = false;
    });
    
    _startSmartPlacesSearch();
  }

  Future<void> _startSmartPlacesSearch({bool reset = true}) async {
    bool found = await _searchPlaces(reset: reset, radius: initialRadius);
    if (!found && mounted) {
      await _searchPlaces(reset: reset, radius: maxRadius);
    }
  }

  Future<bool> _searchPlaces({bool reset = true, double? radius}) async {
    if (_currentPosition == null) return false;

    if (_googlePlacesApiKey.isEmpty || _googlePlacesApiKey == 'YOUR_GOOGLE_PLACES_API_KEY') {
      setState(() => _placesError = 'Google Places API key is not configured.');
      return false;
    }

    if (reset) {
      _searchResults = [];
      _nextPageToken = null;
      _hasMoreResults = false;
    }

    setState(() {
      if (reset) {
        _placesLoading = true;
        _placesError = null;
      } else {
        _placesLoadingMore = true;
      }
    });

    final queryText = _searchQuery.trim().isEmpty
        ? _selectedPlaceCategory == 'All'
            ? 'pet-friendly places near me'
            : _selectedPlaceCategory
        : _searchQuery.trim();

    final params = {
      'query': queryText,
      'location': '${_currentPosition!.latitude},${_currentPosition!.longitude}',
      'radius': (radius ?? initialRadius).toStringAsFixed(0),
      'key': _googlePlacesApiKey,
    };
    if (_nextPageToken != null && _nextPageToken!.isNotEmpty) {
      params['pagetoken'] = _nextPageToken!;
    }

    final url = Uri.https('maps.googleapis.com', '/maps/api/place/textsearch/json', params);

    try {
      final response = await http.get(url);
      if (response.statusCode != 200) {
        setState(() {
          _placesLoading = false;
          _placesLoadingMore = false;
          _placesError = 'Search failed';
        });
        return false;
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final status = body['status'] as String? ?? 'UNKNOWN';
      final resultToken = body['next_page_token'] as String?;
      final results = (body['results'] as List<dynamic>?) ?? <dynamic>[];

      if (status != 'OK' && status != 'ZERO_RESULTS') {
        setState(() {
          _placesError = 'Places API error: $status';
          _placesLoading = false;
          _placesLoadingMore = false;
        });
        return false;
      }
      
      if (results.isEmpty) {
        setState(() {
          if (radius == maxRadius) _placesError = 'Tiada tempat berdekatan';
          _placesLoading = false;
          _placesLoadingMore = false;
        });
        return false;
      }

      final fetched = results.map<Map<String, dynamic>>((place) {
        final geometry = place['geometry'] as Map<String, dynamic>?;
        final location = (geometry?['location'] as Map<String, dynamic>?) ?? <String, dynamic>{};
        final lat = (location['lat'] as num?)?.toDouble() ?? 0.0;
        final lng = (location['lng'] as num?)?.toDouble() ?? 0.0;
        final distanceMeters = Geolocator.distanceBetween(_currentPosition!.latitude, _currentPosition!.longitude, lat, lng);
        final photoRefs = (place['photos'] as List<dynamic>?)?.map((item) => (item as Map<String, dynamic>)['photo_reference'] as String?).whereType<String>().toList() ?? <String>[];
        final photoUrl = photoRefs.isNotEmpty ? _photoUrl(photoRefs.first) : '';

        return {
          'name': place['name'] as String? ?? 'Pet Place',
          'address': place['formatted_address'] as String? ?? place['vicinity'] as String? ?? 'Unknown address',
          'rating': (place['rating'] is num) ? (place['rating'] as num).toDouble() : 0.0,
          'openNow': place['opening_hours']?['open_now'] as bool? ?? false,
          'distance': '${(distanceMeters / 1000).toStringAsFixed(1)} km',
          'photo': photoUrl,
          'location': LatLng(lat, lng),
          'placeId': place['place_id'] as String? ?? '',
        };
      }).toList();

      setState(() {
        _searchResults = reset ? fetched : [..._searchResults, ...fetched];
        _nextPageToken = resultToken;
        _hasMoreResults = resultToken != null && resultToken.isNotEmpty;
        _placesLoading = false;
        _placesLoadingMore = false;
      });
      return true;
    } catch (error) {
      setState(() {
        _placesError = 'Search failed';
        _placesLoading = false;
        _placesLoadingMore = false;
      });
      return false;
    }
  }

  String _photoUrl(String reference) {
    return 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=$reference&key=$_googlePlacesApiKey';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Hub'),
        backgroundColor: const Color(0xFF985BEF),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/create-post'),
        backgroundColor: const Color(0xFF985BEF),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isLoadingLocation) const LinearProgressIndicator(color: Color(0xFF985BEF)),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Find pet-friendly places, events, and community alerts near you.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 18),
                    _buildSearchBar(),
                    const SizedBox(height: 16),
                    _buildCategoryChips(),
                    const SizedBox(height: 18),
                    Text('Nearby Posts', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 12),
                    _buildPostCategoryChips(),
                  ],
                ),
              ),
              _buildNearbyPostsSection(),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const Text('Places matching your search', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              ),
              const SizedBox(height: 12),
              _buildPlacesSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(color: const Color(0xFFF2F2F7), borderRadius: BorderRadius.circular(20)),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              onSubmitted: (_) => _startSmartPlacesSearch(),
              decoration: const InputDecoration(
                hintText: 'Search pet stores, cafes, events...',
                hintStyle: TextStyle(color: Colors.grey),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: _startSmartPlacesSearch,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFF985BEF), borderRadius: BorderRadius.circular(18)),
            child: SvgPicture.asset('assets/icons/Search....svg', width: 20, colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChips() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _placeCategories.map((category) {
        final bool isSelected = _selectedPlaceCategory == category;
        return ChoiceChip(
          label: Text(category),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              setState(() {
                _selectedPlaceCategory = category;
                _searchQuery = '';
                _searchController.clear();
              });
              _startSmartPlacesSearch();
            }
          },
          selectedColor: const Color(0xFF985BEF),
          backgroundColor: const Color(0xFFF2F2F7),
          labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
        );
      }).toList(),
    );
  }

  Widget _buildPostCategoryChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: _postCategories.map((category) {
          final bool selected = _selectedPostCategory == category;
          return Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: ChoiceChip(
              label: Text(category),
              selected: selected,
              onSelected: (value) {
                if (value) setState(() => _selectedPostCategory = category);
              },
              selectedColor: const Color(0xFF985BEF),
              backgroundColor: const Color(0xFFF2F2F7),
              labelStyle: TextStyle(color: selected ? Colors.white : Colors.black87),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNearbyPostsSection() {
    if (_permissionDenied) return Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Text('Location required.', style: TextStyle(color: Colors.red[700])));
    if (_currentPosition == null) return const Center(child: CircularProgressIndicator());

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('community_posts').orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data?.docs ?? [];
        final List<CommunityPost> posts = docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return CommunityPost(
            id: doc.id,
            author: data['author'] ?? '',
            title: data['title'] ?? '',
            content: data['content'] ?? '',
            category: data['category'] ?? '',
            locationLabel: data['locationLabel'] ?? '',
            lat: (data['lat'] as num?)?.toDouble() ?? 0.0,
            lng: (data['lng'] as num?)?.toDouble() ?? 0.0,
            timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
            status: data['status'] ?? 'Lost',
            phone: data['phone'] ?? '',
            ownerId: data['ownerId'] ?? '',
            isVerified: data['isVerified'] ?? false,
            imageUrl: data['imageUrl'],
            reward: data['reward'],
          );
        }).where((post) {
          if (_selectedPostCategory != 'All' && post.category != _selectedPostCategory) return false;
          final dist = Geolocator.distanceBetween(_currentPosition!.latitude, _currentPosition!.longitude, post.lat, post.lng);
          return dist <= 10000;
        }).toList();

        if (posts.isEmpty) return const Padding(padding: EdgeInsets.all(20), child: Text('No nearby posts.'));

        return Column(children: posts.map((post) => _buildPostCard(post)).toList());
      },
    );
  }

  Widget _buildPostCard(CommunityPost post) {
    final bool isLostFound = post.category == 'Lost & found';
    final Color statusColor = post.status == 'Found' ? Colors.green : Colors.red;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final bool isOwner = post.ownerId == currentUserId;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post.imageUrl != null)
            GestureDetector(
              onTap: () => _showFullScreenImage(post.imageUrl!),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                child: Image.network(post.imageUrl!, height: 180, width: double.infinity, fit: BoxFit.cover),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: const Color(0xFFFFF2D9), borderRadius: BorderRadius.circular(16)), child: Text(post.category, style: const TextStyle(color: Color(0xFF985BEF), fontWeight: FontWeight.w900, fontSize: 12))),
                    const SizedBox(width: 8),
                    if (isLostFound) Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Text(post.status.toUpperCase(), style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10))),
                    if (post.isVerified) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.verified, color: Colors.blue, size: 18),
                    ],
                    const Spacer(),
                    Text('${post.timestamp.hour}:${post.timestamp.minute.toString().padLeft(2, '0')}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.share_outlined, size: 20, color: Colors.grey),
                      onPressed: () => _sharePost(post),
                    ),
                    IconButton(icon: const Icon(Icons.flag_outlined, size: 20, color: Colors.grey), onPressed: () => _showReportDialog(post.id)),
                  ],
                ),
                const SizedBox(height: 14),
                Text(post.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                if (post.reward != null && post.reward!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.green.shade200)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.payments_outlined, color: Colors.green, size: 16),
                        const SizedBox(width: 6),
                        Text('Ganjaran: RM${post.reward}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Text(post.content, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => _openMap(post.lat, post.lng),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Color(0xFF985BEF)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(post.locationLabel, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w600, decoration: TextDecoration.underline))),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text('By ${post.author}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                if (isLostFound) ...[
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(child: _postButton(Icons.phone, 'Hubungi', Colors.green, () => _launchWhatsApp(post.phone))),
                      const SizedBox(width: 8),
                      Expanded(child: _postButton(Icons.chat_bubble_outline, 'Chat', const Color(0xFF985BEF), () => context.push('/owner-chat', extra: post.author))),
                    ],
                  ),
                  if (isOwner && post.status == 'Lost') ...[
                    const SizedBox(height: 8),
                    SizedBox(width: double.infinity, child: _postButton(Icons.check_circle, 'I Found It!', Colors.orange, () => _updatePostStatus(post.id))),
                  ]
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _postButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: color),
      label: Text(label, style: TextStyle(fontSize: 12, color: color)),
      style: OutlinedButton.styleFrom(side: BorderSide(color: color), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
    );
  }

  void _showFullScreenImage(String url) {
    showDialog(context: context, builder: (_) => Dialog(backgroundColor: Colors.black, child: InteractiveViewer(child: Image.network(url))));
  }

  Future<void> _openMap(double lat, double lng) async {
    final url = Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lng");
    if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Widget _buildPlacesSection() {
    if (_placesError != null) return Center(child: Text(_placesError!));
    if (_placesLoading && _searchResults.isEmpty) return const Center(child: CircularProgressIndicator());
    return Column(children: _searchResults.map((item) => _buildPlaceCard(item)).toList());
  }

  Widget _buildPlaceCard(Map<String, dynamic> place) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)]),
      child: Column(
        children: [
          if (place['photo'].isNotEmpty) ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(25)), child: Image.network(place['photo'], height: 160, width: double.infinity, fit: BoxFit.cover)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(place['name'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(height: 8),
                Text(place['address'], style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('⭐ ${place['rating']}'),
                    const Spacer(),
                    Text(place['openNow'] ? 'Open' : 'Closed', style: TextStyle(color: place['openNow'] ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
