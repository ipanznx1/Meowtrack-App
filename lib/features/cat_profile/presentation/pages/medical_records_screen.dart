import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:meow_track/core/app_state.dart';
import 'package:meow_track/core/widgets/meow_animated_dialog.dart';

class MedicalRecord {
  final String id;
  final String date;
  final String clinic;
  final String diagnosis;
  final String procedure;
  final String anesthesia;
  final List<String> medications;
  final List<String> attachments;

  MedicalRecord({
    required this.id,
    required this.date,
    required this.clinic,
    required this.diagnosis,
    required this.procedure,
    required this.anesthesia,
    required this.medications,
    required this.attachments,
  });
}

class MedicalRecordsScreen extends StatefulWidget {
  final Cat cat;
  const MedicalRecordsScreen({super.key, required this.cat});

  @override
  State<MedicalRecordsScreen> createState() => _MedicalRecordsScreenState();
}

class _MedicalRecordsScreenState extends State<MedicalRecordsScreen> {
  late List<MedicalRecord> records;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  void _loadRecords() {
    // Check if the cat is MIKO (case insensitive) and owner is admin_ipang
    // We also check for 'miko' because ID might be different from name
    bool isTargetCat = (widget.cat.name.toUpperCase() == 'MIKO' || widget.cat.id.toLowerCase() == 'miko') &&
                       (appState.userName?.toLowerCase() == 'admin_ipang');

    if (isTargetCat) {
      records = [
        MedicalRecord(
          id: '1',
          date: '12 February 2026',
          clinic: 'Klinik Vet Melaka (Dr. Amin)',
          diagnosis: 'Right Femur Fracture',
          procedure: 'Open Reduction Internal Fixation (ORIF)',
          anesthesia: 'Isoflurane Gas',
          medications: ['Tramadol 50mg (1/2 tablet 2x daily)', 'Amoxicillin 125mg (1.5ml 2x daily)'],
          attachments: ['X-Ray_Pre_Op.dicom', 'Blood_Profile_Full.pdf'],
        ),
        MedicalRecord(
          id: '2',
          date: '15 January 2026',
          clinic: 'PetCare Veterinary Hospital',
          diagnosis: 'Routine Vaccination',
          procedure: 'FVRCP Booster',
          anesthesia: 'None',
          medications: [],
          attachments: ['Vaccination_Certificate.pdf'],
        ),
        MedicalRecord(
          id: '3',
          date: '20 December 2025',
          clinic: 'City Pet Clinic',
          diagnosis: 'Dental Cleaning',
          procedure: 'Ultrasonic Scaling & Polishing',
          anesthesia: 'Local + IV Sedation',
          medications: ['Amoxicillin 250mg (1 tablet daily for 5 days)'],
          attachments: ['Dental_Report.pdf'],
        ),
      ];
    } else {
      records = []; // No mock data for other cats/users
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F6FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset('assets/icons/Back.svg', colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn), width: 24, height: 24),
          onPressed: () => context.pop(),
        ),
        title: Text('${widget.cat.name}\'s Medical Records', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: false,
      ),
      body: records.isEmpty
          ? _buildEmptyState()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  ...records.map((record) => _buildMedicalRecordCard(record)).toList(),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => _showAddRecordDialog(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF985BEF),
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text('Add Medical Record', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.medical_services_outlined, size: 80, color: Colors.grey),
          const SizedBox(height: 20),
          const Text('No medical records yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 10),
          const Text('Keep track of your cat\'s medical history', style: TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () => _showAddRecordDialog(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF985BEF),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Add First Record', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalRecordCard(MedicalRecord record) {
    return GestureDetector(
      onTap: () => _showRecordDetails(record),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.diagnosis,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        record.clinic,
                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: const Text('Edit'),
                      onTap: () => _showEditRecordDialog(record),
                    ),
                    PopupMenuItem(
                      child: const Text('Delete', style: TextStyle(color: Colors.red)),
                      onTap: () => _showDeleteConfirmation(record),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(record.date, style: const TextStyle(fontSize: 13, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.medical_information, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    record.procedure,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (record.medications.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${record.medications.length} medication(s)',
                  style: const TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showRecordDetails(MedicalRecord record) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Medical Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => context.pop()),
                  ],
                ),
                const SizedBox(height: 20),
                _buildDetailRow('Date', record.date),
                const SizedBox(height: 15),
                _buildDetailRow('Clinic', record.clinic),
                const SizedBox(height: 15),
                _buildDetailRow('Diagnosis', record.diagnosis),
                const SizedBox(height: 15),
                _buildDetailRow('Procedure', record.procedure),
                const SizedBox(height: 15),
                _buildDetailRow('Anesthesia', record.anesthesia),
                if (record.medications.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Text('Medications', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ...record.medications.map((med) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, size: 18, color: Colors.green),
                        const SizedBox(width: 10),
                        Expanded(child: Text(med, style: const TextStyle(fontSize: 13, color: Colors.grey))),
                      ],
                    ),
                  )),
                ],
                if (record.attachments.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Text('Attachments', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    children: record.attachments.map((file) => Chip(
                      label: Text(file, style: const TextStyle(fontSize: 12)),
                      onDeleted: () {},
                    )).toList(),
                  ),
                ],
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black)),
      ],
    );
  }

  void _showAddRecordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Medical Record', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Medical record form would open here to add new visit details.'),
        actions: [
          TextButton(onPressed: () => context.pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF985BEF)),
            onPressed: () {
              Navigator.pop(context);
              MeowAnimatedDialog.show(
                context,
                animationPath: 'assets/animations/save_settings.json',
                title: "Rekod Ditambah",
                description: "Maklumat perubatan baru telah berjaya disimpan ke dalam profil.",
                themeColor: const Color(0xFF985BEF),
              );
            },
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditRecordDialog(MedicalRecord record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Medical Record', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Edit form would load with current record details.'),
        actions: [
          TextButton(onPressed: () => context.pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF985BEF)),
            onPressed: () {
              Navigator.pop(context);
              MeowAnimatedDialog.show(
                context,
                animationPath: 'assets/animations/save_settings.json',
                title: "Rekod Dikemaskini",
                description: "Perubahan pada rekod perubatan telah disimpan.",
                themeColor: const Color(0xFF985BEF),
              );
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(MedicalRecord record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Record?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => context.pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() => records.removeWhere((r) => r.id == record.id));
              context.pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Record deleted'), backgroundColor: Colors.red),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
