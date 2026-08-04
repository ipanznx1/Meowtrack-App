import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:meow_track/core/app_state.dart';

class EditAppointmentScreen extends StatefulWidget {
  final Appointment appointment;

  const EditAppointmentScreen({super.key, required this.appointment});

  @override
  State<EditAppointmentScreen> createState() => _EditAppointmentScreenState();
}

class _EditAppointmentScreenState extends State<EditAppointmentScreen> {
  late TextEditingController _titleController;
  late TextEditingController _locationController;
  late TextEditingController _notesController;
  late String _selectedCatName;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late bool _notifyBefore;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.appointment.type);
    _locationController = TextEditingController(text: widget.appointment.location);
    _notesController = TextEditingController(text: widget.appointment.description);
    _selectedCatName = widget.appointment.catName;
    _selectedDate = widget.appointment.scheduledAt;
    _selectedTime = TimeOfDay.fromDateTime(widget.appointment.scheduledAt);
    _notifyBefore = widget.appointment.notifyBefore;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _notesController.dispose();
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
          icon: SvgPicture.asset('assets/icons/Back.svg', color: Colors.black, width: 24, height: 24),
          onPressed: () => context.pop(),
        ),
        title: const Text('Edit Reminder', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
        centerTitle: true,
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
            _buildTextField(_locationController, 'Location', 'assets/icons/Location Appoinment.svg'),
            const SizedBox(height: 25),
            const Text('Notes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            _buildTextField(_notesController, 'Notes', 'assets/icons/Notes.svg'),
            const SizedBox(height: 15),
            Row(
              children: [
                Checkbox(
                  value: _notifyBefore,
                  onChanged: (value) => setState(() => _notifyBefore = value ?? true),
                  activeColor: const Color(0xFF985BEF),
                ),
                const Text('Notify me 1 day before'),
              ],
            ),
            const SizedBox(height: 40),
            Center(
              child: ElevatedButton(
                onPressed: _canSubmit ? _saveChanges : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _canSubmit ? const Color(0xFF985BEF) : Colors.grey,
                  minimumSize: const Size(250, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: TextButton(
                onPressed: () => context.pop(),
                child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _canSubmit =>
      _selectedCatName.isNotEmpty &&
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

  void _saveChanges() {
    final scheduledDate = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final updatedAppointment = Appointment(
      id: widget.appointment.id,
      catName: _selectedCatName,
      type: _titleController.text.trim(),
      scheduledAt: scheduledDate,
      location: _locationController.text.trim(),
      description: _notesController.text.trim(),
      notifyBefore: _notifyBefore,
    );

    appState.updateAppointment(widget.appointment, updatedAppointment);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Appointment updated ✓', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFF985BEF),
        duration: Duration(seconds: 2),
      ),
    );
    context.pop();
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
          isExpanded: true,
          items: appState.cats.map((cat) => DropdownMenuItem(value: cat.name, child: Text(cat.name))).toList(),
          onChanged: (v) => setState(() => _selectedCatName = v!),
        ),
      ),
    );
  }
}
