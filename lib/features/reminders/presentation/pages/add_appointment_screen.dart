import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:http/http.dart' as http;
import 'package:meow_track/core/app_state.dart';
import 'package:meow_track/core/widgets/meow_animated_dialog.dart';

class AddAppointmentScreen extends StatefulWidget {
  final Map<String, dynamic>? prefillData;
  const AddAppointmentScreen({super.key, this.prefillData});

  @override
  State<AddAppointmentScreen> createState() => _AddAppointmentScreenState();
}

class _AddAppointmentScreenState extends State<AddAppointmentScreen> {
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  final _reminderValueController = TextEditingController(text: "1");
  String _reminderUnit = 'Days';
  String? _selectedCatName;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 30);
  bool _notifyBefore = true;
  
  double? _selectedLat;
  double? _selectedLng;
  String? _selectedImageUrl;
  bool _isLocating = false;

  static const String _googleApiKey = 'AIzaSyAGz4NvKPo3GGXd9pe9CYGOTRf64FNt8Bo';

  @override
  void initState() {
    super.initState();
    if (widget.prefillData != null) {
      _titleController.text = widget.prefillData!['title'] ?? '';
      _locationController.text = widget.prefillData!['location'] ?? '';
      _selectedLat = widget.prefillData!['lat'];
      _selectedLng = widget.prefillData!['lng'];
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    _reminderValueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFE082),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset('assets/icons/Back.svg', colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn), width: 24, height: 24),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('What is the appointment for?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            _buildTextField(_titleController, 'Title appointment', 'assets/icons/Title appoinment.svg'),
            const SizedBox(height: 25),
            const Text('Which cat is this for?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            _buildCatDropdown(),
            const SizedBox(height: 25),
            const Text('Select Date', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDate,
              child: _buildDateTimeBox(_formattedDate),
            ),
            const SizedBox(height: 25),
            const Text('Select Time', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickTime,
              child: _buildDateTimeBox(_formattedTime),
            ),
            const SizedBox(height: 25),
            const Text('Location', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            _buildSmartLocationPicker(),
            const SizedBox(height: 10),
            _buildUseCurrentLocationButton(),
            const SizedBox(height: 25),
            const Text('Notes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            _buildTextField(_notesController, 'Notes', 'assets/icons/Notes.svg'),
            const SizedBox(height: 15),
            const Text('Reminder', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Row(
              children: [
                Checkbox(
                  value: _notifyBefore, 
                  onChanged: (value) => setState(() => _notifyBefore = value ?? true), 
                  activeColor: const Color(0xFF985BEF)
                ),
                const Text('Remind me'),
                const SizedBox(width: 10),
                if (_notifyBefore) ...[
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                      child: TextField(
                        controller: _reminderValueController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(border: InputBorder.none, hintText: '0'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _reminderUnit,
                        items: ['Hours', 'Days'].map((String value) {
                          return DropdownMenuItem<String>(value: value, child: Text(value));
                        }).toList(),
                        onChanged: (value) => setState(() => _reminderUnit = value!),
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Text('before'),
                ],
              ],
            ),
            const SizedBox(height: 40),
            Center(
              child: ElevatedButton(
                onPressed: _canSubmit ? _saveAppointment : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _canSubmit ? const Color(0xFF985BEF) : Colors.grey,
                  minimumSize: const Size(250, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('Add appointment', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _canSubmit =>
      _selectedCatName != null &&
      _titleController.text.isNotEmpty &&
      _locationController.text.isNotEmpty;

  String get _formattedDate {
    return '${_selectedDate.day.toString().padLeft(2, '0')}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.year}';
  }

  String get _formattedTime {
    final hour = _selectedTime.hourOfPeriod.toString().padLeft(2, '0');
    final minute = _selectedTime.minute.toString().padLeft(2, '0');
    final period = _selectedTime.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF985BEF),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF985BEF),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Widget _buildDateTimeBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildSmartLocationPicker() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: GooglePlaceAutoCompleteTextField(
        textEditingController: _locationController,
        googleAPIKey: _googleApiKey,
        inputDecoration: InputDecoration(
          hintText: 'Search location...',
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          suffixIcon: Padding(
            padding: const EdgeInsets.all(12.0),
            child: SvgPicture.asset('assets/icons/Location Appoinment.svg', colorFilter: const ColorFilter.mode(Color(0xFF985BEF), BlendMode.srcIn), width: 20, height: 20),
          ),
        ),
        debounceTime: 800,
        isLatLngRequired: true,
        getPlaceDetailWithLatLng: (Prediction prediction) async {
          if (prediction.placeId != null) {
            setState(() {
              _locationController.text = prediction.description ?? "";
              _selectedLat = double.tryParse(prediction.lat ?? "");
              _selectedLng = double.tryParse(prediction.lng ?? "");
            });
            await _fetchPlacePhoto(prediction.placeId!);
          }
        },
        itemClick: (Prediction prediction) {
          _locationController.text = prediction.description ?? "";
          _locationController.selection = TextSelection.fromPosition(TextPosition(offset: prediction.description?.length ?? 0));
        },
        // Location bias logic
        countries: ["my"], // Limit to Malaysia or remove if global
      ),
    );
  }

  Widget _buildUseCurrentLocationButton() {
    return InkWell(
      onTap: _getCurrentLocation,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _isLocating 
            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF985BEF)))
            : const Icon(Icons.my_location, size: 16, color: Color(0xFF985BEF)),
          const SizedBox(width: 8),
          Text(
            _isLocating ? 'Locating...' : 'Use Current Location',
            style: const TextStyle(color: Color(0xFF985BEF), fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      Position position = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
      setState(() {
        _selectedLat = position.latitude;
        _selectedLng = position.longitude;
      });

      // Reverse geocoding via Google Maps API
      final url = "https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$_googleApiKey";
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['results'].isNotEmpty) {
          setState(() {
            _locationController.text = data['results'][0]['formatted_address'];
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error getting location: $e")));
    } finally {
      setState(() => _isLocating = false);
    }
  }

  Future<void> _fetchPlacePhoto(String placeId) async {
    final detailsUrl = "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=photo&key=$_googleApiKey";
    try {
      final response = await http.get(Uri.parse(detailsUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final photos = data['result']?['photos'];
        if (photos != null && photos.isNotEmpty) {
          final photoRef = photos[0]['photo_reference'];
          setState(() {
            _selectedImageUrl = "https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photo_reference=$photoRef&key=$_googleApiKey";
          });
        }
      }
    } catch (e) {
      print("Error fetching photo: $e");
    }
  }

  void _saveAppointment() {
    final scheduledDate = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    // --- LOGIC TO CALCULATE NOTIFICATION DATE ---
    DateTime? notificationDate;
    if (_notifyBefore) {
      final int value = int.tryParse(_reminderValueController.text) ?? 0;
      final Duration offset = _reminderUnit == 'Days' 
          ? Duration(days: value) 
          : Duration(hours: value);
      notificationDate = scheduledDate.subtract(offset);
    }

    final appointment = Appointment(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      catName: _selectedCatName!,
      type: _titleController.text.trim(),
      scheduledAt: scheduledDate,
      location: _locationController.text.trim(),
      description: _notesController.text.trim(),
      notifyBefore: _notifyBefore,
      notificationDate: notificationDate, // Store the calculated date
      lat: _selectedLat,
      lng: _selectedLng,
      imageUrl: _selectedImageUrl,
    );

    appState.addAppointment(appointment);
    
    MeowAnimatedDialog.show(
      context,
      animationPath: 'assets/animations/reminder.json',
      title: "Peringatan Disimpan",
      description: "Kami akan hantar notifikasi supaya anda tidak lupa.",
      buttonText: "Faham!",
      themeColor: Colors.orange,
      onConfirm: () => context.pop(),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, String svgAsset) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          suffixIcon: Padding(
            padding: const EdgeInsets.all(12.0),
            child: SvgPicture.asset(svgAsset, color: const Color(0xFF985BEF).withValues(alpha: 0.5), width: 20, height: 20),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }

  Widget _buildCatDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCatName,
          hint: const Text('Dropdown menu'),
          isExpanded: true,
          items: appState.cats.map((cat) => DropdownMenuItem(value: cat.name, child: Text(cat.name))).toList(),
          onChanged: (v) => setState(() => _selectedCatName = v),
        ),
      ),
    );
  }

}
