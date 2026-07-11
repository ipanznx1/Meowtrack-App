import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:meow_track/core/app_state.dart';

class MedicalHistoryPage extends StatelessWidget {
  final Cat cat;
  final String diagnosis;

  const MedicalHistoryPage({super.key, required this.cat, required this.diagnosis});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cat.themeColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset('assets/icons/Back.svg', width: 24, height: 24, colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            const Text('Medical History', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
            
            _buildLabel('Date'),
            _buildStaticBox('12 February 2026'),
            const SizedBox(height: 25),
            
            _buildLabel('Clinic'),
            _buildStaticBox('Klinik Vet Melaka (Dr. Amin)'),
            const SizedBox(height: 30),
            
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: Column(
                children: [
                  _infoLine('Clinical Diagnosis', diagnosis),
                  const Divider(height: 30),
                  _infoLine('Procedure Done', 'Open Reduction Internal Fixation (ORIF)'),
                  const Divider(height: 30),
                  _infoLine('Anesthesia Used', 'Isoflurane Gas'),
                ],
              ),
            ),
            const SizedBox(height: 30),
            
            _buildLabel('Medical attachments'),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: Wrap(
                spacing: 10,
                children: [
                  _buildFilePill(context, 'X-Ray_Pre_Op.dicom'),
                  _buildFilePill(context, 'Blood_Profile_Full.pdf'),
                ],
              ),
            ),
            const SizedBox(height: 30),
            
            _buildLabel('Current Medications Given'),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _medDetail('Tramadol 50mg (Painkiller)', '1/2 tablet (2x daily)'),
                  const SizedBox(height: 15),
                  _medDetail('Amoxicillin 125mg (Antibiotic)', '1.5ml (2x daily)'),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String l) => Align(alignment: Alignment.centerLeft, child: Padding(padding: const EdgeInsets.only(bottom: 10, left: 5), child: Text(l, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))));
  
  Widget _buildStaticBox(String t) => Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)), child: Text(t, style: const TextStyle(fontWeight: FontWeight.w500)));

  Widget _infoLine(String l, String v) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 2, child: Text(l, style: const TextStyle(color: Colors.grey, fontSize: 14))), Expanded(flex: 3, child: Text(v, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)))]);

  Widget _medDetail(String t, String d) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), Text(d, style: const TextStyle(color: Colors.grey, fontSize: 12))]);

  Widget _buildFilePill(BuildContext context, String fileName) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('[Placeholder] Fetching document file for ${cat.name}: $fileName')));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: Colors.purple.shade400, borderRadius: BorderRadius.circular(10)),
        child: Text(fileName, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
