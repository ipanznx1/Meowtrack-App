import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:meow_track/core/app_state.dart';
import 'package:meow_track/core/widgets/meow_animated_dialog.dart';

class HealthOverviewPage extends StatefulWidget {
  final Cat? cat;
  const HealthOverviewPage({super.key, this.cat});

  @override
  State<HealthOverviewPage> createState() => _HealthOverviewPageState();
}

class _HealthOverviewPageState extends State<HealthOverviewPage> {
  @override
  void initState() {
    super.initState();
    if (widget.cat != null) {
      appState.loadWeightHistory(widget.cat!.id);
    }
  }

  void _showNewWeightDialog() {
    if (widget.cat == null) return;
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Add New Weight', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            hintText: 'Enter weight in KG (e.g. 4.5)',
            suffixText: 'KG',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final weight = double.tryParse(controller.text);
              if (weight != null) {
                appState.addWeightRecord(widget.cat!.id, weight);
                Navigator.pop(context);
                
                MeowAnimatedDialog.show(
                  context,
                  animationPath: 'assets/animations/Weight scale.json',
                  title: "Berat Dikemaskini",
                  description: "Rekod berat terbaru ${widget.cat!.name} telah berjaya disimpan.",
                  themeColor: Colors.green,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF985BEF)),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cat == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Health Overview')),
        body: const Center(child: Text('Cat data not found. Please try again.')),
      );
    }
    
    final Cat cat = widget.cat!;
    String status = "Healthy";
    if (cat.name == "Luna") {
      status = "Healthy";
    } else if (cat.name == "Oyen") {
      status = "Active";
    } else if (cat.name == "Tuteh") {
      status = "Recovering";
    }

    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final weightHistory = appState.catHealthRecords[cat.id] ?? [];
        final currentWeight = weightHistory.isNotEmpty ? (weightHistory.first['value'] as num).toDouble() : 0.0;

        return Scaffold(
          backgroundColor: cat.themeColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: SvgPicture.asset('assets/icons/Back.svg', colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn), width: 24, height: 24),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text('Health Overview', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderCard(cat, status),
                const SizedBox(height: 25),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Vitals', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    _buildMockBadge(),
                  ],
                ),
                const SizedBox(height: 15),
                _buildVitalsGrid(cat),
                const SizedBox(height: 25),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Activity & Sleep', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    _buildMockBadge(),
                  ],
                ),
                const SizedBox(height: 15),
                _buildActivityCard(cat),
                const SizedBox(height: 25),

                const Text('Weight Management', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 15),
                _buildWeightGraph(context, weightHistory, currentWeight),
                const SizedBox(height: 25),
                
                const Text('Weight History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 10),
                if (weightHistory.isEmpty)
                  const Text('No weight records yet.', style: TextStyle(color: Colors.grey, fontSize: 12))
                else
                  ...weightHistory.map((w) => _buildHistoryListItem(w['date'], (w['value'] as num).toDouble())).toList(),
                const SizedBox(height: 25),

                const Text('Vaccines', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 10),
                _buildUpcomingVaccine(),
                const SizedBox(height: 15),
                GestureDetector(
                  onTap: () => _showVaccineBottomSheet(context, cat, 'FVRCP', '21 January 2026', 'Completed'),
                  child: _buildVaccinationStatus(context, cat),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildMockBadge() {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Mock Data Information'),
            content: const Text('This data is currently simulated because a Meowtrack device is not yet connected to this cat. Once connected, you will see real-time vitals and activity.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
            ],
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.amber.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.amber.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline, size: 12, color: Colors.amber.shade800),
            const SizedBox(width: 4),
            Text(
              'MOCK DATA',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.amber.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalsGrid(Cat cat) {
    // Generate consistent mock data based on cat ID if real data is missing
    final mockHeartRate = cat.heartRate > 0 ? cat.heartRate : (120 + (cat.id.hashCode % 40));
    final mockBattery = cat.battery > 0 ? cat.battery : (75.0 + (cat.id.hashCode % 20));
    final mockDistance = cat.distance != 'Unknown' ? cat.distance : '${(150 + (cat.id.hashCode % 500))}m away';

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      childAspectRatio: 1.4,
      children: [
        _buildStatCard('Heart Rate', '$mockHeartRate bpm', Icons.favorite, Colors.red.shade300),
        _buildStatCard('Battery', '${mockBattery.toStringAsFixed(0)}%', Icons.battery_full, Colors.green.shade300),
        _buildStatCard('Distance', mockDistance, Icons.location_on, Colors.blue.shade300),
        _buildStatCard('Status', cat.isLost ? 'Lost' : 'Safe', Icons.security, Colors.purple.shade300),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: bgColor, size: 20),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black)),
        ],
      ),
    );
  }

  Widget _buildActivityCard(Cat cat) {
    // Generate consistent mock activity
    final mockActiveMinutes = cat.activeMinutes > 0 ? cat.activeMinutes : (30 + (cat.id.hashCode % 60));
    final mockTargetMinutes = cat.targetMinutes > 0 ? cat.targetMinutes : 120;
    final mockSleepQuality = cat.sleepQuality != 'Unknown' ? cat.sleepQuality : 'Good';
    
    final progress = mockActiveMinutes / mockTargetMinutes;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Daily Activity', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              Text('$mockActiveMinutes/$mockTargetMinutes min', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade400),
            ),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Sleep Quality', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              Text(mockSleepQuality, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(Cat cat, String status) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25)),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Container(
              width: 80, 
              height: 80, 
              color: Colors.grey[200], 
              child: _buildCatImage(cat.image),
            ),
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

  Widget _buildCatImage(String imagePath) {
    if (imagePath.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: imagePath,
        fit: BoxFit.cover,
        placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        errorWidget: (context, url, error) => const Icon(Icons.error, size: 30),
      );
    } else if (imagePath.startsWith('/') || imagePath.startsWith('C:') || imagePath.startsWith('E:') || imagePath.contains('cat_cutout') || imagePath.contains('cache')) {
      return Image.file(File(imagePath), fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const Icon(Icons.pets, size: 30, color: Colors.grey));
    }
    return Image.asset(imagePath, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const Icon(Icons.pets, size: 30, color: Colors.grey));
  }

  Widget _buildWeightGraph(BuildContext context, List<Map<String, dynamic>> history, double currentWeight) {
    final List<FlSpot> spots = [];
    if (history.isEmpty) {
      spots.add(const FlSpot(0, 0));
    } else {
      final limited = history.take(7).toList().reversed.toList();
      for (int i = 0; i < limited.length; i++) {
        spots.add(FlSpot(i.toDouble(), (limited[i]['value'] as num).toDouble()));
      }
    }

    return Container(
      height: 250,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25)),
      child: Column(
        children: [
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: true, drawVerticalLine: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(show: true, color: Colors.blue.withValues(alpha: 0.1)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Current Weight : $currentWeight KG', style: const TextStyle(fontWeight: FontWeight.bold)),
              ElevatedButton(
                onPressed: _showNewWeightDialog,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: const Text('New Weight', style: TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildHistoryListItem(String date, double weight) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(date, style: const TextStyle(fontWeight: FontWeight.bold)),
          Row(
            children: [
              Text('Weight : $weight KG', style: const TextStyle(color: Colors.grey)),
              const SizedBox(width: 5),
              const Icon(Icons.expand_more, color: Colors.purple, size: 18),
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

  Widget _buildVaccinationStatus(BuildContext context, Cat cat) {
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
          _buildQRPlaceholder(context, cat),
        ],
      ),
    );
  }

  Widget _buildQRPlaceholder(BuildContext context, Cat cat) {
    return GestureDetector(
      onTap: () => _showQRDialog(context, cat),
      child: Container(
        width: 80, height: 80,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey[300]!)),
        child: Center(
          child: QrImageView(
            data: 'Meowtrack-Vaccine-ID-${cat.name}-12345',
            version: QrVersions.auto,
            size: 60.0,
          ),
        ),
      ),
    );
  }

  void _showVaccineBottomSheet(BuildContext context, Cat cat, String name, String date, String status) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Vaccine Details', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 25),
            _detailRow('Vaccine Name', name),
            _detailRow('Date Administered', date),
            _detailRow('Status', status, color: Colors.green),
            const SizedBox(height: 20),
            const Center(
              child: Text(
                'This record is verified by Meowtrack Health System.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF985BEF),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text('Close', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color ?? Colors.black)),
        ],
      ),
    );
  }

  void _showQRDialog(BuildContext context, Cat cat) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QrImageView(
              data: 'Meowtrack-Vaccine-ID-${cat.name}-12345',
              version: QrVersions.auto,
              size: 200.0,
            ),
            const SizedBox(height: 20),
            const Text('Digital Vaccine Certificate', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
            Text('ID: MT-V-${cat.name.toUpperCase()}-001', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
