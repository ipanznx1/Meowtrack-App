import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:meow_track/core/app_state.dart';

class AddCatIdentityScreen extends StatefulWidget {
  const AddCatIdentityScreen({super.key});

  @override
  State<AddCatIdentityScreen> createState() => _AddCatIdentityScreenState();
}

class _AddCatIdentityScreenState extends State<AddCatIdentityScreen> {
  final _nameController = TextEditingController();
  String _selectedBreed = 'British Shorthair';
  bool _isDateSelected = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAEAEA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset('assets/icons/Back.svg', width: 24, height: 24, colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn)),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: Text('Add cat', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold))),
            const SizedBox(height: 40),
            const Text('Identity', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            const Text('What is your cat\'s name?', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 8),
            _buildTextField(_nameController, 'Cat\'s name', 'assets/icons/Cat’s name.svg'),
            const SizedBox(height: 20),
            const Text('What is their breed?', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 8),
            _buildBreedDropdown(),
            const SizedBox(height: 20),
            const Text('How old is your cat?', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 15),
            _buildAgeSelection(),
            const SizedBox(height: 40),
            _buildUploadButton(),
            const SizedBox(height: 40),
            Center(
              child: ElevatedButton(
                onPressed: () => context.push('/add-cat-2', extra: {
                  'name': _nameController.text,
                  'breed': _selectedBreed,
                }),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF985BEF),
                  minimumSize: const Size(200, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('Next', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, String svgAsset) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
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

  Widget _buildBreedDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedBreed,
          isExpanded: true,
          items: ['British Shorthair', 'Persian', 'Domestic Long Hair', 'Domestic Shorthair']
              .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) => setState(() => _selectedBreed = v!),
        ),
      ),
    );
  }

  Widget _buildAgeSelection() {
    return Column(
      children: [
        Row(
          children: [
            Radio(value: true, groupValue: _isDateSelected, onChanged: (v) => setState(() => _isDateSelected = v!), activeColor: const Color(0xFF985BEF)),
            const Text('Date'),
            const SizedBox(width: 10),
            _dateBox('12'), const SizedBox(width: 5), _dateBox('12'), const SizedBox(width: 5), _dateBox('2026', width: 80),
          ],
        ),
        Row(
          children: [
            Radio(value: false, groupValue: _isDateSelected, onChanged: (v) => setState(() => _isDateSelected = v!), activeColor: const Color(0xFF985BEF)),
            const Text('Age'),
            const SizedBox(width: 10),
            _dateBox('12'),
          ],
        ),
      ],
    );
  }

  Widget _dateBox(String text, {double width = 45}) {
    return Container(
      width: width,
      height: 45,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: Center(child: Text(text)),
    );
  }

  Widget _buildUploadButton() {
    return Container(
      height: 60,
      width: double.infinity,
      decoration: BoxDecoration(color: const Color(0xFF985BEF).withValues(alpha: 0.7), borderRadius: BorderRadius.circular(15)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Upload Profile Picture', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(width: 10),
          SvgPicture.asset('assets/icons/Upload Profile Picture.svg', color: Colors.white, width: 24, height: 24),
        ],
      ),
    );
  }
}

class AddCatHealthScreen extends StatefulWidget {
  final Map<String, dynamic> identityData;
  const AddCatHealthScreen({super.key, required this.identityData});

  @override
  State<AddCatHealthScreen> createState() => _AddCatHealthScreenState();
}

class _AddCatHealthScreenState extends State<AddCatHealthScreen> {
  final _weightController = TextEditingController();
  final _allergyController = TextEditingController();
  bool _isNeutered = true;
  bool _isVaxUpToDate = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAEAEA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset('assets/icons/Back.svg', width: 24, height: 24, colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn)),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: Text('Add cat', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold))),
            const SizedBox(height: 40),
            const Text('Health', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            const Text('What is their current weight (kg)?', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 8),
            _buildTextField(_weightController, 'Current weight', 'assets/icons/Current weight.svg'),
            const SizedBox(height: 20),
            const Text('Is your cat neutered/spayed?', style: TextStyle(fontSize: 14)),
            Row(
              children: [
                Radio(value: true, groupValue: _isNeutered, onChanged: (v) => setState(() => _isNeutered = v!), activeColor: const Color(0xFF985BEF)),
                const Text('Neutered'),
                const SizedBox(width: 20),
                Radio(value: false, groupValue: _isNeutered, onChanged: (v) => setState(() => _isNeutered = v!), activeColor: const Color(0xFF985BEF)),
                const Text('Spayed'),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Does your cat have any known allergies?', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 8),
            _buildTextField(_allergyController, 'allergies?', 'assets/icons/allergies_.svg'),
            const SizedBox(height: 20),
            const Text('Are their vaccinations up to date?', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 10),
            Row(
              children: [
                Radio(value: true, groupValue: _isVaxUpToDate, onChanged: (v) => setState(() => _isVaxUpToDate = v!), activeColor: const Color(0xFF985BEF)),
                const Text('Yes'),
                const SizedBox(width: 10),
                _dateBox('12'), const SizedBox(width: 5), _dateBox('12'), const SizedBox(width: 5), _dateBox('2026', width: 80),
              ],
            ),
            Row(
              children: [
                Radio(value: false, groupValue: _isVaxUpToDate, onChanged: (v) => setState(() => _isVaxUpToDate = v!), activeColor: const Color(0xFF985BEF)),
                const Text('No'),
              ],
            ),
            const SizedBox(height: 40),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  final newCat = Cat(
                    name: widget.identityData['name'],
                    breed: widget.identityData['breed'],
                    gender: 'Male',
                    themeColor: Colors.purple.shade100,
                    image: 'assets/images/new_cat.png',
                  );
                  appState.addCat(newCat);
                  context.go('/dashboard');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF985BEF),
                  minimumSize: const Size(200, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('Add', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, String svgAsset) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
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

  Widget _dateBox(String text, {double width = 45}) {
    return Container(
      width: width, height: 45,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: Center(child: Text(text)),
    );
  }
}
