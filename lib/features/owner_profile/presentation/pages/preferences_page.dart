import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class PreferencesPage extends StatefulWidget {
  const PreferencesPage({super.key});

  @override
  State<PreferencesPage> createState() => _PreferencesPageState();
}

class _PreferencesPageState extends State<PreferencesPage> {
  // Unit State
  bool isKg = true;
  bool isMeters = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset('assets/icons/Back.svg', colorFilter: const ColorFilter.mode(Color(0xFF985BEF), BlendMode.srcIn), width: 30, height: 30),
          onPressed: () => context.pop(),
        ),
        title: const Text("Preferences", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Unit", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            // Unit Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25)),
              child: Column(
                children: [
                  _buildUnitRow("Weight Unit", 'assets/icons/Weight Unit.svg', "Kilograms (kg)", "Pounds (lbs)", isKg, (val) => setState(() => isKg = val)),
                  const SizedBox(height: 25),
                  _buildUnitRow("Distance Unit", 'assets/icons/Distance Unit.svg', "Meters / Kilometers", "Feet / Miles", isMeters, (val) => setState(() => isMeters = val)),
                ],
              ),
            ),
            const SizedBox(height: 30),

            const Text("System", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            // System Card
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25)),
              child: Column(
                children: [
                  _buildNavRow("Safe Zone Radius", 'assets/icons/Safe Zone Radius.svg', () => context.push('/preferences/safe-zone')),
                  const Divider(height: 1, indent: 60),
                  _buildNavRow("Tracking Frequency", 'assets/icons/Tracking Frequency.svg', () => context.push('/preferences/tracking-freq')),
                  const Divider(height: 1, indent: 60),
                  _buildNavRow("My privacy", 'assets/icons/My privacy.svg', () => context.push('/preferences/privacy')),
                ],
              ),
            ),
            const SizedBox(height: 30),

            const Text("Account", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () {},
              icon: SvgPicture.asset('assets/icons/Delete.svg', colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn), width: 20, height: 20),
              label: const Text("Delete Account", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnitRow(String label, String svgAsset, String option1, String label2, bool isFirstActive, Function(bool) onChanged) {
    return Column(
      children: [
        Row(
          children: [
            SvgPicture.asset(svgAsset, colorFilter: const ColorFilter.mode(Color(0xFF985BEF), BlendMode.srcIn), width: 24, height: 24),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _unitBtn(option1, isFirstActive, () => onChanged(true))),
            Expanded(child: _unitBtn(label2, !isFirstActive, () => onChanged(false))),
          ],
        ),
      ],
    );
  }

  Widget _unitBtn(String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF985BEF) : Colors.grey[300],
          borderRadius: label.contains("kg") || label.contains("Kilometers") 
              ? const BorderRadius.horizontal(left: Radius.circular(10)) 
              : const BorderRadius.horizontal(right: Radius.circular(10)),
        ),
        child: Center(
          child: Text(
            label, 
            style: TextStyle(color: isActive ? Colors.white : Colors.black54, fontSize: 11, fontWeight: FontWeight.bold)
          ),
        ),
      ),
    );
  }

  Widget _buildNavRow(String title, String svgAsset, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: SvgPicture.asset(svgAsset, colorFilter: const ColorFilter.mode(Color(0xFF985BEF), BlendMode.srcIn), width: 24, height: 24),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
    );
  }
}

// --------------------------------------------------------------------------
// SUB-SCREEN 1: SAFE ZONE RADIUS (Image 2)
// --------------------------------------------------------------------------
class SafeZoneRadiusPage extends StatefulWidget {
  const SafeZoneRadiusPage({super.key});

  @override
  State<SafeZoneRadiusPage> createState() => _SafeZoneRadiusPageState();
}

class _SafeZoneRadiusPageState extends State<SafeZoneRadiusPage> {
  double _radius = 350;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 20),
                child: IconButton(
                  icon: SvgPicture.asset('assets/icons/Back.svg', color: const Color(0xFF985BEF), width: 40, height: 40),
                  onPressed: () => context.pop(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text("Safe Zone Radius", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 80),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                children: [
                  const Text("0m", style: TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(
                    child: Slider(
                      value: _radius,
                      min: 0,
                      max: 500,
                      activeColor: const Color(0xFF985BEF),
                      inactiveColor: Colors.grey[300],
                      onChanged: (v) => setState(() => _radius = v),
                    ),
                  ),
                  const Text("500m", style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    color: Colors.white, 
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5)],
                  ),
                  child: Center(child: Text(_radius.toInt().toString(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                ),
                const SizedBox(width: 15),
                const Text("m", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// --------------------------------------------------------------------------
// SUB-SCREEN 2: TRACKING FREQUENCY (Image 3)
// --------------------------------------------------------------------------
class TrackingFrequencyPage extends StatefulWidget {
  const TrackingFrequencyPage({super.key});

  @override
  State<TrackingFrequencyPage> createState() => _TrackingFrequencyPageState();
}

class _TrackingFrequencyPageState extends State<TrackingFrequencyPage> {
  String _selectedFreq = "High Accuracy";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 20),
                child: IconButton(
                  icon: SvgPicture.asset('assets/icons/Back.svg', color: const Color(0xFF985BEF), width: 40, height: 40),
                  onPressed: () => context.pop(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text("Tracking Frequency", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 60),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: Column(
                children: [
                  _buildRadioCard("High Accuracy (Every 1 min)", "High Accuracy"),
                  _buildRadioCard("Balanced (5 mins)", "Balanced"),
                  _buildRadioCard("Power Saving (15 mins)", "Power Saving"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioCard(String label, String value) {
    bool isSelected = _selectedFreq == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedFreq = value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5)],
        ),
        child: Row(
          children: [
            Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle, 
                border: Border.all(color: Colors.grey.shade400, width: 1.5),
                color: isSelected ? const Color(0xFF985BEF) : Colors.white,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
          ],
        ),
      ),
    );
  }
}

// --------------------------------------------------------------------------
// SUB-SCREEN 3: MY PRIVACY (Image 1)
// --------------------------------------------------------------------------
class MyPrivacyPage extends StatefulWidget {
  const MyPrivacyPage({super.key});

  @override
  State<MyPrivacyPage> createState() => _MyPrivacyPageState();
}

class _MyPrivacyPageState extends State<MyPrivacyPage> {
  String _whoCanSee = "Public";
  bool _showBreed = true;
  bool _showPhotos = false;
  bool _showMed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: IconButton(
                    icon: SvgPicture.asset('assets/icons/Back.svg', colorFilter: const ColorFilter.mode(Color(0xFF985BEF), BlendMode.srcIn), width: 40, height: 40),
                    onPressed: () => context.pop(),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Center(child: Text("My privacy", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
              const SizedBox(height: 40),
              
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 30),
                child: Text("Who can see my cat profile ?", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Column(
                  children: [
                    _buildRadioCard("Public (Anyone with my Care Code)", "Public"),
                    _buildRadioCard("My Friends Only (Only approved friends)", "Friends"),
                    _buildRadioCard("Private (Only me and my Co-Owners)", "Private"),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 30),
                child: Text("Custom visibility", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Column(
                  children: [
                    _buildSwitchCard("Show My Cat's Breed", _showBreed, (v) => setState(() => _showBreed = v)),
                    _buildSwitchCard("Show My Cat's Photos", _showPhotos, (v) => setState(() => _showPhotos = v)),
                    _buildSwitchCard("Show Medical & Vaccine Status", _showMed, (v) => setState(() => _showMed = v)),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRadioCard(String label, String value) {
    bool isSelected = _whoCanSee == value;
    return GestureDetector(
      onTap: () => setState(() => _whoCanSee = value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5)],
        ),
        child: Row(
          children: [
            Container(
              width: 18, height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle, 
                border: Border.all(color: Colors.grey.shade400, width: 1.5),
                color: isSelected ? const Color(0xFF985BEF) : Colors.white,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchCard(String label, bool value, Function(bool) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          Switch(
            value: value, 
            onChanged: onChanged,
            activeThumbColor: Colors.black87,
            activeTrackColor: Colors.grey.shade300,
            inactiveThumbColor: Colors.grey.shade300,
            inactiveTrackColor: Colors.grey.shade100,
          ),
        ],
      ),
    );
  }
}
