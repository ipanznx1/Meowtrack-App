import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:meow_track/core/app_state.dart';
import 'package:meow_track/core/widgets/meow_animated_dialog.dart';

class EditCatScreen extends StatefulWidget {
  final Cat cat;
  const EditCatScreen({super.key, required this.cat});

  @override
  State<EditCatScreen> createState() => _EditCatScreenState();
}

class _EditCatScreenState extends State<EditCatScreen> {
  late TextEditingController _nameController;
  late String _selectedBreed;
  late String _selectedGender;
  late Color _selectedColor;

  final List<Color> _themeColors = [
    const Color(0xFFD0E0FF), // Light Blue
    const Color(0xFFE1BEE7), // Purple
    const Color(0xFFFFD1DC), // Pink
    const Color(0xFFFFCC80), // Orange
    const Color(0xFFD1FFD1), // Green
    const Color(0xFFFFF9C4), // Yellow
    const Color(0xFFB3E5FC), // Sky Blue
    const Color(0xFFFFCDD2), // Rose
  ];

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.cat.name);
    _selectedBreed = widget.cat.breed;
    _selectedGender = widget.cat.gender;
    _selectedColor = widget.cat.themeColor;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _updateCat() async {
    setState(() => _isSubmitting = true);
    try {
      await appState.updateCat(widget.cat.id, {
        'name': _nameController.text.trim(),
        'breed': _selectedBreed,
        'gender': _selectedGender,
        'themeColor': _selectedColor.value,
      });

      if (mounted) {
        MeowAnimatedDialog.show(
          context,
          animationPath: 'assets/animations/save_settings.json',
          title: "Berjaya!",
          description: "Profil ${widget.cat.name} telah dikemaskini.",
          themeColor: _selectedColor,
          onConfirm: () {
            context.pop(); // Close dialog
            context.pop(); // Return to profile
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAEAEA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Edit Profile', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
            const Text('Cat’s Name', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildTextField(_nameController, 'Name', 'assets/icons/Cat’s name.svg'),
            const SizedBox(height: 20),
            
            const Text('Breed', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildBreedDropdown(),
            const SizedBox(height: 20),

            const Text('Gender', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildGenderSelector(),
            const SizedBox(height: 25),

            const Text('Theme Color', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildColorSelector(),
            const SizedBox(height: 40),

            Center(
              child: _isSubmitting 
                ? const CircularProgressIndicator(color: Color(0xFF985BEF))
                : ElevatedButton(
                    onPressed: _updateCat,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF985BEF),
                      minimumSize: const Size(200, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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
            child: SvgPicture.asset(svgAsset, colorFilter: ColorFilter.mode(const Color(0xFF985BEF).withValues(alpha: 0.5), BlendMode.srcIn), width: 20, height: 20),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }

  Widget _buildBreedDropdown() {
    final List<String> breedOptions = ['British Shorthair', 'Persian', 'Domestic Long Hair', 'Domestic Shorthair'];
    if (!breedOptions.contains(_selectedBreed)) {
      breedOptions.add(_selectedBreed);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedBreed,
          isExpanded: true,
          items: breedOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) => setState(() => _selectedBreed = v!),
        ),
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Row(
      children: ['Female', 'Male'].map((gender) {
        final selected = gender == _selectedGender;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedGender = gender),
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF985BEF) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: selected ? Colors.transparent : Colors.grey.shade300),
              ),
              child: Center(
                child: Text(gender, style: TextStyle(color: selected ? Colors.white : Colors.black87, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildColorSelector() {
    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _themeColors.length,
        separatorBuilder: (context, index) => const SizedBox(width: 15),
        itemBuilder: (context, index) {
          final color = _themeColors[index];
          final isSelected = _selectedColor == color;
          return GestureDetector(
            onTap: () => setState(() => _selectedColor = color),
            child: Container(
              width: 50,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF985BEF) : Colors.white,
                  width: isSelected ? 3 : 2,
                ),
              ),
              child: isSelected ? const Icon(Icons.check, color: Color(0xFF985BEF), size: 24) : null,
            ),
          );
        },
      ),
    );
  }
}
