import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:meow_track/core/app_state.dart';

class CatStatsScreen extends StatefulWidget {
  final Cat cat;
  const CatStatsScreen({super.key, required this.cat});

  @override
  State<CatStatsScreen> createState() => _CatStatsScreenState();
}

class _CatStatsScreenState extends State<CatStatsScreen> {
  @override
  Widget build(BuildContext context) {
    final cat = widget.cat;
    return Scaffold(
      backgroundColor: cat.themeColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset('assets/icons/Back.svg', colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn), width: 24, height: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('${cat.name}\'s Health Stats', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cat Info Header
            _buildCatInfoCard(cat),
            const SizedBox(height: 25),
            
            // Vitals Section
            const Text('Vitals', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black87)),
            const SizedBox(height: 15),
            _buildVitalsGrid(cat),
            const SizedBox(height: 25),
            
            // Activity Section
            const Text('Activity & Sleep', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black87)),
            const SizedBox(height: 15),
            _buildActivityCard(cat),
            const SizedBox(height: 25),
            
            // Sleep Quality Section
            const Text('Sleep Quality', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black87)),
            const SizedBox(height: 15),
            _buildSleepQualityCard(cat),
            const SizedBox(height: 25),
            
            // Weight History
            const Text('Weight Trend', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black87)),
            const SizedBox(height: 15),
            _buildWeightTrendCard(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildCatInfoCard(Cat cat) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 15)],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Container(
              width: 100,
              height: 100,
              color: Colors.grey[200],
              child: Image.asset(cat.image, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cat.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text(cat.breed, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: cat.themeColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(cat.gender, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalsGrid(Cat cat) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      children: [
        _buildStatCard('Heart Rate', '${cat.heartRate} bpm', Icons.favorite, Colors.red.shade300),
        _buildStatCard('Battery', '${cat.battery.toStringAsFixed(0)}%', Icons.battery_full, Colors.green.shade300),
        _buildStatCard('Distance', cat.distance, Icons.location_on, Colors.blue.shade300),
        _buildStatCard('Status', cat.isLost ? 'Lost' : 'Safe', Icons.security, Colors.purple.shade300),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: bgColor, size: 24),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
        ],
      ),
    );
  }

  Widget _buildActivityCard(Cat cat) {
    final progress = cat.activeMinutes / cat.targetMinutes;
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
              const Text('Daily Activity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text('${cat.activeMinutes}/${cat.targetMinutes} min', style: const TextStyle(fontSize: 14, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 12,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(progress > 1.0 ? Colors.green : Colors.blue.shade400),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            progress >= 1.0 ? '✓ Goal achieved!' : 'Keep playing! ${(cat.targetMinutes - cat.activeMinutes).toInt()} min to go',
            style: TextStyle(fontSize: 12, color: progress >= 1.0 ? Colors.green : Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildSleepQualityCard(Cat cat) {
    final sleepColor = cat.sleepQuality == 'Good' ? Colors.green : cat.sleepQuality == 'Fair' ? Colors.orange : Colors.red;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Sleep Hours', style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500)),
                  Text('${cat.sleepHours.toStringAsFixed(1)} hrs', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Quality', style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: sleepColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(cat.sleepQuality, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: sleepColor)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          const Text('Healthy cats sleep 12-18 hours per day', style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _buildWeightTrendCard() {
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
          const Text('Recent Weight Records', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildWeightRecord('Today', '4.2 kg', Colors.green),
          const SizedBox(height: 12),
          _buildWeightRecord('1 week ago', '4.1 kg', Colors.grey),
          const SizedBox(height: 12),
          _buildWeightRecord('1 month ago', '4.0 kg', Colors.grey),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: Colors.blue),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Weight is stable. Continue monitoring for any changes.',
                    style: TextStyle(fontSize: 12, color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightRecord(String date, String weight, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(date, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(weight, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        ),
      ],
    );
  }
}
