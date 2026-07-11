import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:meow_track/core/app_state.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CatHealthPassportScreen extends StatelessWidget {
  final Cat cat;
  const CatHealthPassportScreen({super.key, required this.cat});

  @override
  Widget build(BuildContext context) {
    // Logik Mock: Hanya Admin yang bernama 'Ipang' sahaja boleh tambah rekod
    final bool isAdminIpang = appState.sessionRole == 'admin' && 
        (appState.userName?.toLowerCase().contains('ipang') ?? false);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text("Digital Health Passport", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildQRHeader(),
            const SizedBox(height: 20),
            _buildMedicalHistoryList(),
          ],
        ),
      ),
      floatingActionButton: isAdminIpang 
          ? FloatingActionButton.extended(
              onPressed: () => _showAddRecordDialog(context),
              backgroundColor: const Color(0xFF985BEF),
              icon: const Icon(Icons.add_moderator),
              label: const Text("Add Vet Record"),
            )
          : null,
    );
  }

  Widget _buildQRHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
      ),
      child: Column(
        children: [
          QrImageView(
            data: cat.id,
            version: QrVersions.auto,
            size: 200.0,
            eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.circle, color: Color(0xFF985BEF)),
            dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.circle, color: Colors.black),
          ),
          const SizedBox(height: 15),
          Text(cat.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text("Breed: ${cat.breed}", style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 10),
          const Text("Scan this QR at the clinic to access medical history", 
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Color(0xFF985BEF), fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildMedicalHistoryList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('cats')
          .doc(cat.id)
          .collection('medical_history')
          .orderBy('date', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final firestoreDocs = snapshot.data!.docs;
        List<Map<String, dynamic>> records = firestoreDocs.map((d) {
          final data = d.data() as Map<String, dynamic>;
          data['id'] = d.id;
          return data;
        }).toList();

        // TAMBAH DATA MOCK HANYA UNTUK MIKO @ admin_ipang
        bool isTarget = cat.name.toUpperCase() == 'MIKO' && 
                        (appState.userName?.toLowerCase() == 'admin_ipang');
        
        if (isTarget && records.isEmpty) {
          records.add({
            'date': Timestamp.fromDate(DateTime(2026, 2, 12)),
            'diagnosis': 'Right Femur Fracture (Mock)',
            'weight': 4.2,
            'notes': 'Kucing memerlukan pembedahan segera.',
            'clinicName': 'Klinik Vet Melaka (Mock)',
            'vetName': 'Dr. Amin',
            'isMock': true,
          });
        }

        if (records.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(40.0),
            child: Text("No medical records yet. Your vet will add records here.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: records.length,
          itemBuilder: (context, index) {
            final data = records[index];
            final date = (data['date'] as Timestamp).toDate();

            return GestureDetector(
              onTap: () => _showRecordDetails(context, data, date),
              child: Container(
                margin: const EdgeInsets.only(bottom: 15),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF985BEF).withValues(alpha: 0.1)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(DateFormat('dd MMM yyyy').format(date), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF985BEF))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                          child: Text("${data['weight']} kg", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue)),
                        )
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(data['diagnosis'] ?? 'General Checkup', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    Text(data['notes'] ?? '', style: const TextStyle(fontSize: 13, color: Colors.grey), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const Divider(height: 25),
                    Row(
                      children: [
                        const Icon(Icons.local_hospital, size: 14, color: Colors.grey),
                        const SizedBox(width: 5),
                        Text(data['clinicName'] ?? 'Unknown Clinic', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showRecordDetails(BuildContext context, Map<String, dynamic> data, DateTime date) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: const Color(0xFF985BEF).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(15)),
                          child: const Icon(Icons.local_hospital, color: Color(0xFF985BEF), size: 30),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(data['clinicName'] ?? 'Ipang Veterinary Clinic', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              Text(DateFormat('EEEE, dd MMMM yyyy').format(date), style: const TextStyle(color: Colors.grey, fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),
                    
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(15)),
                      child: Row(
                        children: [
                          const CircleAvatar(radius: 20, backgroundColor: Color(0xFF985BEF), child: Icon(Icons.person, color: Colors.white)),
                          const SizedBox(width: 15),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(data['vetName'] ?? 'Dr. Irfan Pang', style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text("License No: ${data['vetLicense'] ?? 'VE-12345-2024'}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    const Text("Vital Signs", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildVitalItem("Weight", "${data['weight']} kg", Icons.monitor_weight_outlined, Colors.blue),
                        _buildVitalItem("Temp", "${data['temp'] ?? '38.5'}°C", Icons.thermostat, Colors.orange),
                        _buildVitalItem("Heart Rate", "${data['heartRate'] ?? '120'} bpm", Icons.favorite_outline, Colors.red),
                      ],
                    ),
                    const SizedBox(height: 30),

                    const Text("Clinical Notes", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Text(
                        data['notes'] ?? 'Kucing aktif, selera makan baik, paru-paru jelas.',
                        style: const TextStyle(height: 1.5, fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.verified, color: Colors.green, size: 20),
                                SizedBox(width: 8),
                                Text("Verified by Vet", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text("Digital Signature Attached", style: TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalItem(String label, String value, IconData icon, Color color) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }

  void _showAddRecordDialog(BuildContext context) {
    final diagController = TextEditingController();
    final weightController = TextEditingController();
    final notesController = TextEditingController();
    final clinicController = TextEditingController(text: "Ipang Veterinary Clinic");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Text("New Medical Entry", style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInput(diagController, "Diagnosis / Reason", Icons.edit),
              _buildInput(weightController, "Weight (kg)", Icons.monitor_weight, isNumber: true),
              _buildInput(clinicController, "Clinic Name", Icons.location_on),
              _buildInput(notesController, "Clinical Notes", Icons.notes, maxLines: 3),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('cats')
                  .doc(cat.id)
                  .collection('medical_history')
                  .add({
                'date': FieldValue.serverTimestamp(),
                'diagnosis': diagController.text,
                'weight': double.tryParse(weightController.text) ?? 0.0,
                'notes': notesController.text,
                'clinicName': clinicController.text,
                'vetId': appState.userEmail,
                'vetName': appState.userName,
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF985BEF)),
            child: const Text("Save Record", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(TextEditingController controller, String label, IconData icon, {bool isNumber = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        ),
      ),
    );
  }
}
