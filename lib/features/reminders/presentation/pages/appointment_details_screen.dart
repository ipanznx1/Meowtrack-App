import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:meow_track/core/app_state.dart';

// ✅ Tukar StatelessWidget -> StatefulWidget supaya boleh guna context dalam methods
class AppointmentDetailsScreen extends StatefulWidget {
  final Appointment appointment;

  const AppointmentDetailsScreen({super.key, required this.appointment});

  @override
  State<AppointmentDetailsScreen> createState() => _AppointmentDetailsScreenState();
}

class _AppointmentDetailsScreenState extends State<AppointmentDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFD54F),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 25.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // Header with Back Button
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => context.pop(),
                  child: SvgPicture.asset('assets/icons/Back.svg', width: 40, height: 40, colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn)),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                widget.appointment.type,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.black),
              ),
              const SizedBox(height: 15),
              // Upcoming Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Upcoming',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'Main Info',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black),
              ),
              const SizedBox(height: 15),
              // Main Info Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildInfoItem('Cat Name', widget.appointment.catName)),
                        Expanded(child: _buildInfoItem('Type', widget.appointment.type)),
                      ],
                    ),
                    const SizedBox(height: 30),
                    _buildInfoItem('When', '${widget.appointment.date} at ${widget.appointment.time}'),
                    const SizedBox(height: 30),
                    _buildInfoItem('Where', widget.appointment.location),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'Description',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black),
              ),
              const SizedBox(height: 15),
              // Description Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Text(
                  widget.appointment.description,
                  style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87),
                ),
              ),
              const SizedBox(height: 40),

              // ✅ RESCHEDULE BUTTON — buka date & time picker
              ElevatedButton(
                onPressed: () => _showRescheduleDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB0BEC5),
                  minimumSize: const Size(300, 60),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
                child: const Text(
                  'Reschedule Appointment',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(height: 20),

              // ✅ CANCEL BUTTON — buka confirmation dialog
              ElevatedButton(
                onPressed: () => _showCancelDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  minimumSize: const Size(300, 60),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
                child: const Text(
                  'Cancel Appointment',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'Get Directions to Clinic',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black),
              ),
              const SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildNavIcon('https://cdn-icons-png.flaticon.com/512/2991/2991148.png'),
                  const SizedBox(width: 40),
                  _buildNavIcon('https://cdn-icons-png.flaticon.com/512/5969/5969244.png'),
                ],
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ Reschedule dialog — user pilih tarikh & masa baru
  void _showRescheduleDialog(BuildContext context) async {
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();

    // Pick date dulu
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
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

    if (pickedDate == null) return; // user cancel
    selectedDate = pickedDate;

    if (!context.mounted) return;

    // Pick time lepas tu
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: selectedTime,
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

    if (pickedTime == null) return;
    selectedTime = pickedTime;

    if (!context.mounted) return;

    // Format tarikh & masa untuk display
    final String formattedDate =
        '${selectedDate.day} ${_monthName(selectedDate.month)} ${selectedDate.year}';
    final String formattedTime = selectedTime.format(context);

    // ✅ UPDATE GLOBAL STATE
    final updatedAppt = Appointment(
      catName: widget.appointment.catName,
      type: widget.appointment.type,
      date: formattedDate,
      time: formattedTime,
      location: widget.appointment.location,
      description: widget.appointment.description,
    );
    appState.updateAppointment(widget.appointment, updatedAppt);

    // Tunjuk snackbar confirm
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Appointment rescheduled to $formattedDate at $formattedTime ✅',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF985BEF),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
    context.pop(); // Go back after rescheduling
  }

  // ✅ Cancel dialog — tanya confirm dulu sebelum cancel
  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Cancel Appointment?',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: Text(
          'Are you sure you want to cancel the appointment for ${widget.appointment.catName}? This cannot be undone.',
          style: const TextStyle(color: Colors.black54, fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'No, Keep It',
              style: TextStyle(color: Color(0xFF985BEF), fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            onPressed: () {
              // ✅ REMOVE FROM GLOBAL STATE
              appState.removeAppointment(widget.appointment);

              Navigator.pop(ctx); // tutup dialog
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    'Appointment cancelled ❌',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  duration: const Duration(seconds: 2),
                ),
              );
              // Balik ke screen sebelum lepas cancel
              Future.delayed(const Duration(milliseconds: 500), () {
                if (context.mounted) context.pop();
              });
            },
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // Helper — tukar nombor bulan ke nama
  String _monthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildNavIcon(String url) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 5))
        ],
      ),
      child: Image.network(url, width: 60, height: 60),
    );
  }
}