import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart' as gemini;
import 'package:google_mlkit_subject_segmentation/google_mlkit_subject_segmentation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:meow_track/core/app_state.dart';
import 'package:meow_track/core/tutorial_controller.dart';
import 'package:meow_track/core/widgets/meow_animated_dialog.dart';
import 'package:provider/provider.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AddCatIdentityScreen extends StatefulWidget {
  const AddCatIdentityScreen({super.key});

  @override
  State<AddCatIdentityScreen> createState() => _AddCatIdentityScreenState();
}

class _AddCatIdentityScreenState extends State<AddCatIdentityScreen> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  String _selectedBreed = 'British Shorthair';
  String _selectedGender = 'Female';
  String _ageUnit = 'Years'; // 'Weeks', 'Months', 'Years'
  Color _selectedColor = const Color(0xFFD0E0FF);

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

  String? aiSuggestedBreed;
  String? aiExplanation;
  bool _isDetecting = false;
  bool _isProcessingImage = false;
  final ImagePicker _picker = ImagePicker();
  File? _processedImageFile;

  @override
  void initState() {
    super.initState();
    // 🎯 AUTO-START TUTORIAL (Fasa 2)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tutorial = Provider.of<TutorialController>(context, listen: false);
      if (!tutorial.isTutorialCompleted) {
        tutorial.startAddCatTutorial(context);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

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
            const Text('What is your cat’s name?', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 8),
            Showcase(
              key: Provider.of<TutorialController>(context, listen: false).catNameKey,
              description: "Masukkan nama manja si bulu anda di sini.",
              child: _buildTextField(_nameController, 'Cat’s name', 'assets/icons/Cat’s name.svg'),
            ),
            const SizedBox(height: 20),
            const Text('What is their breed?', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildBreedDropdown()),
                const SizedBox(width: 10),
                _buildScanButton(),
              ],
            ),
            if (aiSuggestedBreed != null) ...[
              const SizedBox(height: 15),
              _buildAiSuggestionCard(),
            ],
            const SizedBox(height: 20),
            const Text('Gender', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 8),
            _buildGenderSelector(),
            const SizedBox(height: 20),
            const Text('How old is your cat?', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildTextField(_ageController, 'Value', 'assets/icons/Current weight.svg'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _ageUnit,
                        isExpanded: true,
                        items: ['Weeks', 'Months', 'Years'].map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                        onChanged: (v) => setState(() => _ageUnit = v!),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),
            const Text('Choose Theme Color', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 12),
            SizedBox(
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
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(
                              color: const Color(0xFF985BEF).withValues(alpha: 0.3),
                              blurRadius: 8,
                              spreadRadius: 2,
                            )
                        ],
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Color(0xFF985BEF), size: 24)
                          : null,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 40),
            _buildUploadButton(),
            const SizedBox(height: 40),
            Center(
              child: Showcase(
                key: Provider.of<TutorialController>(context, listen: false).saveProfileKey,
                description: "Tekan 'Next' untuk melengkapkan profil kesihatan.",
                child: ElevatedButton(
                  onPressed: _canProceed ? _goNext : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _canProceed ? const Color(0xFF985BEF) : Colors.grey,
                    minimumSize: const Size(200, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text('Next', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _canProceed => _nameController.text.isNotEmpty && _ageController.text.isNotEmpty;

  void _goNext() {
    context.push('/add-cat-2', extra: {
      'name': _nameController.text.trim(),
      'breed': _selectedBreed,
      'gender': _selectedGender,
      'ageValue': _ageController.text.trim(),
      'ageUnit': _ageUnit,
      'themeColor': _selectedColor.value,
      'imagePath': _processedImageFile?.path,
    });
  }

  Future<void> detectBreed(File imageFile) async {
    setState(() {
      _isDetecting = true;
      aiSuggestedBreed = null;
      aiExplanation = null;
    });

    try {
      String activeApiKey = "";
      try {
        activeApiKey = dotenv.env['GEMINI_API_KEY'] ?? "";
      } catch (_) {}

      final model = gemini.GenerativeModel(
        model: 'gemini-1.5-flash-latest',
        apiKey: activeApiKey,
      );

      final content = [
        gemini.Content.multi([
          gemini.TextPart('Identify the breed of this cat. Output format: [BREED_NAME]\n[EXPLANATION]. Keep the explanation educational.'),
          gemini.DataPart('image/jpeg', await imageFile.readAsBytes()),
        ])
      ];

      final response = await model.generateContent(content);
      final text = response.text;

      if (text != null) {
        final parts = text.split('\n');
        final breed = parts[0].replaceAll('[', '').replaceAll(']', '').trim();
        final explanation = parts.length > 1 ? parts.skip(1).join('\n').trim() : "No explanation provided.";

        setState(() {
          aiSuggestedBreed = breed;
          aiExplanation = explanation;
        });
      }
    } catch (e) {
      debugPrint("Detect Breed Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("AI Detection failed. Please try again.")));
      }
    } finally {
      if (mounted) setState(() => _isDetecting = false);
    }
  }

  Widget _buildScanButton() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF985BEF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconButton(
        icon: _isDetecting 
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : const Icon(Icons.auto_awesome, color: Colors.white),
        onPressed: _isDetecting ? null : () async {
          final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
          if (photo != null) {
            await detectBreed(File(photo.path));
          }
        },
      ),
    );
  }

  Widget _buildAiSuggestionCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF985BEF), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Color(0xFF985BEF), size: 20),
              const SizedBox(width: 10),
              const Text('AI Suggestion', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF985BEF))),
            ],
          ),
          const SizedBox(height: 10),
          Text('Suggested: $aiSuggestedBreed', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          const SizedBox(height: 5),
          Text(aiExplanation ?? "", style: const TextStyle(fontSize: 12, color: Colors.black87)),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => setState(() { aiSuggestedBreed = null; aiExplanation = null; }),
                child: const Text('Dismiss', style: TextStyle(color: Colors.grey)),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _selectedBreed = aiSuggestedBreed!;
                    aiSuggestedBreed = null;
                    aiExplanation = null;
                  });
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF985BEF)),
                child: const Text('Apply', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, String svgAsset) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: TextField(
        controller: controller,
        onChanged: (_) => setState(() {}),
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
          items: breedOptions
              .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
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

  Widget _buildUploadButton() {
    return GestureDetector(
      onTap: _isProcessingImage ? null : _handleImageSelection,
      child: Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFF985BEF).withValues(alpha: 0.3)),
          image: _processedImageFile != null 
            ? DecorationImage(image: FileImage(_processedImageFile!), fit: BoxFit.contain)
            : null,
        ),
        child: Stack(
          children: [
            if (_processedImageFile == null)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset('assets/icons/Upload Profile Picture.svg', colorFilter: const ColorFilter.mode(Color(0xFF985BEF), BlendMode.srcIn), width: 32, height: 32),
                    const SizedBox(height: 10),
                    const Text('Upload & Remove Background', style: TextStyle(color: Color(0xFF985BEF), fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            if (_isProcessingImage)
              Container(
                decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(15)),
                child: const Center(child: CircularProgressIndicator(color: Colors.white)),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleImageSelection() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() => _isProcessingImage = true);

    try {
      final File processed = await _removeBackground(File(image.path));
      setState(() {
        _processedImageFile = processed;
      });
      await detectBreed(processed);
    } catch (e) {
      debugPrint("Error processing image: $e");
      if (mounted) {
        String errorMessage = "Failed to remove background.";
        if (e.toString().contains("optional module to be downloaded")) {
          errorMessage = "Sila tunggu sebentar. Modul AI sedang dimuat turun oleh sistem Google Play Services. Sila cuba lagi dalam 1-2 minit.";
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage), duration: const Duration(seconds: 5)));
      }
    } finally {
      if (mounted) setState(() => _isProcessingImage = false);
    }
  }

  Future<File> _removeBackground(File imageFile) async {
    final segmenter = SubjectSegmenter(options: SubjectSegmenterOptions(
      enableForegroundBitmap: true,
      enableForegroundConfidenceMask: true,
      enableMultipleSubjects: SubjectResultOptions(
        enableConfidenceMask: false,
        enableSubjectBitmap: false,
      ),
    ));

    final inputImage = InputImage.fromFile(imageFile);
    final result = await segmenter.processImage(inputImage);
    final Uint8List? foregroundBytes = result.foregroundBitmap;
    segmenter.close();

    if (foregroundBytes == null) throw Exception("Could not segment image");

    final directory = await getTemporaryDirectory();
    final String path = '${directory.path}/cat_cutout_${DateTime.now().millisecondsSinceEpoch}.png';
    final File file = File(path);
    await file.writeAsBytes(foregroundBytes);
    
    return file;
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
  DateTime? _selectedVaxDate;
  bool _isNeutered = true;
  bool _isVaxUpToDate = true;
  bool _hasNeverVaccinated = false;
  bool _isSubmitting = false;
  String _weightUnit = 'kg'; // 'kg', 'g'

  @override
  void initState() {
    super.initState();
    // Default unit based on age: if weeks or early months, suggest grams
    final ageUnit = widget.identityData['ageUnit'] as String;
    if (ageUnit == 'Weeks') {
      _weightUnit = 'g';
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _allergyController.dispose();
    super.dispose();
  }

  Future<void> _selectVaxDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF985BEF)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedVaxDate = picked);
    }
  }

  bool get _canSubmit {
    if (_weightController.text.isEmpty || _allergyController.text.isEmpty || _isSubmitting) return false;
    if (_isVaxUpToDate && _selectedVaxDate == null) return false;
    return true;
  }

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
            const Text('What is their current weight?', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildTextField(_weightController, 'Weight', 'assets/icons/Current weight.svg'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _weightUnit,
                        isExpanded: true,
                        items: ['kg', 'g'].map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                        onChanged: (v) => setState(() => _weightUnit = v!),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Is your cat neutered/spayed?', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 12),
            _buildChoiceRow('Neutered', selected: _isNeutered, onTap: () => setState(() => _isNeutered = true)),
            const SizedBox(height: 12),
            _buildChoiceRow('Spayed', selected: !_isNeutered, onTap: () => setState(() => _isNeutered = false)),
            const SizedBox(height: 20),
            const Text('Does your cat have any known allergies?', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 8),
            _buildTextField(_allergyController, 'Allergies', 'assets/icons/allergies_.svg'),
            const SizedBox(height: 20),
            const Text('Are their vaccinations up to date?', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 12),
            _buildChoiceRow('Yes', selected: _isVaxUpToDate, onTap: () => setState(() {
              _isVaxUpToDate = true;
              _hasNeverVaccinated = false;
            })),
            const SizedBox(height: 12),
            _buildChoiceRow('No', selected: !_isVaxUpToDate, onTap: () => setState(() => _isVaxUpToDate = false)),
            
            if (!_isVaxUpToDate) ...[
              const SizedBox(height: 15),
              Row(
                children: [
                  Checkbox(
                    value: _hasNeverVaccinated,
                    activeColor: const Color(0xFF985BEF),
                    onChanged: (val) => setState(() => _hasNeverVaccinated = val ?? false),
                  ),
                  const Expanded(
                    child: Text("Cat has never been vaccinated (e.g. newborn/rescue)", 
                      style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],

            if (_isVaxUpToDate) ...[
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => _selectVaxDate(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    children: [
                      Text(
                        _selectedVaxDate == null 
                          ? 'Select Last Vaccination Date' 
                          : '${_selectedVaxDate!.day}/${_selectedVaxDate!.month}/${_selectedVaxDate!.year}',
                        style: TextStyle(color: _selectedVaxDate == null ? Colors.grey : Colors.black87),
                      ),
                      const Spacer(),
                      SvgPicture.asset('assets/icons/Calendar.svg', width: 20, colorFilter: const ColorFilter.mode(Color(0xFF985BEF), BlendMode.srcIn)),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 40),
            Center(
              child: _isSubmitting 
                ? const CircularProgressIndicator(color: Color(0xFF985BEF))
                : ElevatedButton(
                    onPressed: _canSubmit ? _submitCat : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _canSubmit ? const Color(0xFF985BEF) : Colors.grey,
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

  Future<void> _submitCat() async {
    final user = FirebaseAuth.instance.currentUser;
    final String catId = DateTime.now().millisecondsSinceEpoch.toString();
    final String? localImagePath = widget.identityData['imagePath'];
    
    setState(() => _isSubmitting = true);

    try {
      final ageValue = widget.identityData['ageValue'] as String;
      final ageUnit = widget.identityData['ageUnit'] as String;
      
      final newCat = Cat(
        id: catId,
        name: widget.identityData['name'] as String,
        breed: widget.identityData['breed'] as String,
        gender: widget.identityData['gender'] as String,
        themeColor: Color(widget.identityData['themeColor'] as int? ?? 0xFFD0E0FF),
        image: 'assets/images/new_cat.png',
        ownerId: user?.uid ?? '',
        collaborators: [],
      );

      double weight = double.tryParse(_weightController.text) ?? 0.0;
      // If entered in grams, convert to kg for storage, but keep unit info for record
      if (_weightUnit == 'g') {
        // We'll store it as is for the registration, but the record will have the correct unit.
      }

      await appState.performFullCatRegistration(
        cat: newCat,
        initialWeight: weight,
        imageFile: localImagePath != null ? File(localImagePath) : null,
      );

      // 🎯 NEWBORN MILESTONES: Add special metadata to Firestore for kittens
      if (ageUnit == 'Weeks' || (ageUnit == 'Months' && int.parse(ageValue) < 4)) {
        await FirebaseFirestore.instance.collection('cats').doc(catId).update({
          'isKitten': true,
          'ageLabel': '$ageValue $ageUnit',
          'lastVaccinationDate': _hasNeverVaccinated ? null : _selectedVaxDate,
          'neverVaccinated': _hasNeverVaccinated,
          'birthDate': DateTime.now().subtract(Duration(
            days: ageUnit == 'Weeks' ? int.parse(ageValue) * 7 : (ageUnit == 'Months' ? int.parse(ageValue) * 30 : int.parse(ageValue) * 365)
          )),
        });
      } else {
        // Even for adult cats, store the vaccination info
        await FirebaseFirestore.instance.collection('cats').doc(catId).update({
          'lastVaccinationDate': _isVaxUpToDate ? _selectedVaxDate : null,
          'neverVaccinated': _hasNeverVaccinated,
        });
      }

      if (mounted) {
        MeowAnimatedDialog.show(
          context,
          animationPath: 'assets/animations/save_settings.json',
          title: "Pendaftaran Berjaya!",
          description: "Kucing baru anda telah didaftarkan ke dalam sistem.",
          themeColor: const Color(0xFF985BEF),
          onConfirm: () => context.go('/dashboard'),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildTextField(TextEditingController controller, String hint, String svgAsset) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: TextField(
        controller: controller,
        keyboardType: hint.contains('weight') ? TextInputType.number : TextInputType.text,
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

  Widget _buildChoiceRow(String label, {required bool selected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF985BEF) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? Colors.transparent : Colors.grey.shade300),
        ),
        child: Text(label, style: TextStyle(color: selected ? Colors.white : Colors.black87, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
