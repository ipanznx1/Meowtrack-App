import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:meow_track/core/app_state.dart';

class AddAppointmentScreen extends StatefulWidget {
  const AddAppointmentScreen({super.key});

  @override
  State<AddAppointmentScreen> createState() => _AddAppointmentScreenState();
}

class _AddAppointmentScreenState extends State<AddAppointmentScreen> {
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  String? _selectedCatName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFE082), // Yellow background matching design
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset('assets/icons/Back.svg', color: Colors.black, width: 24, height: 24),
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
            Row(
              children: [
                _dateBox('12'), const SizedBox(width: 8),
                _dateBox('12'), const SizedBox(width: 8),
                _dateBox('2026', width: 100),
              ],
            ),
            
            const SizedBox(height: 25),
            const Text('Select Time', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Row(
              children: [
                _dateBox('10'), const SizedBox(width: 8),
                const Text(':', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                _dateBox('30'), const SizedBox(width: 8),
                _dateBox('AM'),
              ],
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
                Checkbox(value: true, onChanged: (v){}, activeColor: const Color(0xFF985BEF)),
                const Text('Notify me 1 day before'),
              ],
            ),
            
            const SizedBox(height: 40),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  if (_selectedCatName != null && _titleController.text.isNotEmpty) {
                    appState.addAppointment(Appointment(
                      catName: _selectedCatName!,
                      type: _titleController.text,
                      date: '12-12-2026',
                      time: '10:30 AM',
                      location: _locationController.text,
                      description: _notesController.text,
                    ));
                    context.pop();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF985BEF),
                  minimumSize: const Size(250, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('Add appoinment', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
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

  Widget _dateBox(String text, {double width = 50}) {
    return Container(
      width: width, height: 50,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Center(child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold))),
    );
  }
}
