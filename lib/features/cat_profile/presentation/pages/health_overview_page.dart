import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:meow_track/core/app_state.dart';

class HealthOverviewPage extends StatelessWidget {
  final Cat cat;
  const HealthOverviewPage({super.key, required this.cat});

  @override
  Widget build(BuildContext context) {
    // Dynamic Status and Diagnosis based on Cat
    String status = "Healthy";
    String diagnosis = "Routine Checkup";
    if (cat.name == "Luna") {
      status = "Healthy";
      diagnosis = "Right Femur Fracture";
    } else if (cat.name == "Oyen") {
      status = "Active";
      diagnosis = "Flu Treatment";
    } else if (cat.name == "Tuteh") {
      status = "Recovering";
      diagnosis = "Sprained Paw";
    }

    return Scaffold(
      backgroundColor: cat.themeColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset('assets/icons/Back.svg', color: Colors.black, width: 24, height: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Health Overview', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 1. Header Card
            _buildHeaderCard(status),
            const SizedBox(height: 20),
            // 2. Breed & Gender
            Row(
              children: [
                Expanded(child: _buildInfoBox('Breed', cat.breed)),
                const SizedBox(width: 15),
                Expanded(child: _buildInfoBox('Gender', cat.gender)),
              ],
            ),
            const SizedBox(height: 25),
            const Text('Weight Management', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 15),
            // 3. Weight Graph
            _buildWeightGraph(),
            const SizedBox(height: 25),
            const Text('History List', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),
            _buildHistoryListItem(),
            const SizedBox(height: 25),
            const Text('Vaccines', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),
            _buildUpcomingVaccine(),
            const SizedBox(height: 15),
            _buildVaccinationStatus(context),
            const SizedBox(height: 25),
            const Text('Medical History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 15),
            _buildMedicalHistoryCard(context, diagnosis),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(String status) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25)),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Container(width: 80, height: 80, color: Colors.grey[200], child: const Icon(Icons.pets, size: 40, color: Colors.grey)),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(cat.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(10)),
                child: Text(status, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Text(value, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildWeightGraph() {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25)),
      child: Column(
        children: [
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      const FlSpot(0, 2.1),
                      const FlSpot(1, 2.4),
                      const FlSpot(2, 2.7),
                      const FlSpot(3, 2.9),
                      const FlSpot(4, 2.8),
                      const FlSpot(5, 3.1),
                      const FlSpot(6, 3.2),
                      const FlSpot(7, 3.3),
                    ],
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(show: true, color: Colors.blue.withOpacity(0.1)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Current Weight : 3.3 KG', style: TextStyle(fontWeight: FontWeight.bold)),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: const Text('New Weight', style: TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildHistoryListItem() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('24 January 2026', style: TextStyle(fontWeight: FontWeight.bold)),
          Row(
            children: const [
              Text('Weight : 3.3 KG', style: TextStyle(color: Colors.grey)),
              SizedBox(width: 5),
              Icon(Icons.expand_more, color: Colors.purple, size: 18),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingVaccine() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: const Center(child: Text('Upcoming Vaccines : 21 December 2026', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500))),
    );
  }

  Widget _buildVaccinationStatus(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Vaccination Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 10),
                const Text('Vaccines names : FVRCP', style: TextStyle(color: Colors.grey, fontSize: 12)),
                Row(children: const [Text('Status : ', style: TextStyle(color: Colors.grey, fontSize: 12)), Text('Completed', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold))]),
                const Text('Date : 21 January 2026', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          _buildQRPlaceholder(context),
        ],
      ),
    );
  }

  Widget _buildMedicalHistoryCard(BuildContext context, String diagnosis) {
    return GestureDetector(
      onTap: () => context.push('/medical-history', extra: {'cat': cat, 'diagnosis': diagnosis}),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  _medRow('assets/icons/Diagnosis.svg', 'Diagnosis :', diagnosis),
                  const SizedBox(height: 8),
                  _medRow('assets/icons/Treatment.svg', 'Treatment :', 'Tramadol 50mg...'),
                  const SizedBox(height: 8),
                  _medRow('assets/icons/Vet Clinic _.svg', 'Vet Clinic :', 'Klinik Vet Melaka'),
                ],
              ),
            ),
            _buildQRPlaceholder(context),
          ],
        ),
      ),
    );
  }

  Widget _medRow(String svgAsset, String label, String value) {
    return Row(
      children: [
        SvgPicture.asset(svgAsset, color: Colors.purple, width: 20, height: 20),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        const SizedBox(width: 5),
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11), overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  Widget _buildQRPlaceholder(BuildContext context) {
    return GestureDetector(
      onTap: () => _showQRDialog(context),
      child: Container(
        width: 80, height: 80,
        decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
        child: const Center(child: Text('QR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
      ),
    );
  }

  void _showQRDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.qr_code_2, size: 150, color: Colors.black87),
            SizedBox(height: 20),
            Text('Digital Vaccine Certificate Placeholder', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
