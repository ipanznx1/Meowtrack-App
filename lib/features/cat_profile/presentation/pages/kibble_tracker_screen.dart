import 'dart:io';
import 'package:flutter/material.dart';
import 'package:meow_track/core/app_state.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart' as gemini;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class KibbleTrackerScreen extends StatefulWidget {
  const KibbleTrackerScreen({super.key});

  @override
  State<KibbleTrackerScreen> createState() => _KibbleTrackerScreenState();
}

class _KibbleTrackerScreenState extends State<KibbleTrackerScreen> {
  Cat? _selectedCat;
  final _gramsController = TextEditingController();
  bool _isScanning = false;
  final ImagePicker _picker = ImagePicker();
  double _kcalPer100g = 350.0; // Default: 3.5 kcal/g

  // Ambil nilai dari .env atau Remote Config secara selamat
  String get _geminiApiKey {
    try {
      final envKey = dotenv.env['GEMINI_API_KEY'];
      if (envKey != null && envKey.isNotEmpty) return envKey;
      return appState.geminiApiKey;
    } catch (_) {
      return appState.geminiApiKey;
    }
  }

  @override
  void initState() {
    super.initState();
    if (appState.cats.isNotEmpty) {
      _selectedCat = appState.cats.first;
      appState.loadFoodLogs(_selectedCat!.id);
    }
  }

  void _onCatSelected(Cat cat) {
    setState(() => _selectedCat = cat);
    appState.loadFoodLogs(cat.id);
  }

  Future<void> _scanNutritionalLabel() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo == null) return;

    setState(() => _isScanning = true);

    try {
      final model = gemini.GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _geminiApiKey,
      );

      final content = [
        gemini.Content.multi([
          gemini.TextPart("Identify the calorie content (kcal/100g or kcal/kg) from this cat food label. Just return the number per 100g. If it says 3500 kcal/kg, return 350. Just the number."),
          gemini.DataPart('image/jpeg', await File(photo.path).readAsBytes()),
        ])
      ];

      final response = await model.generateContent(content);
      final String? result = response.text;

      if (result != null && mounted) {
        // Cuba dapatkan nombor sahaja daripada hasil AI
        final double? caloriesPer100g = double.tryParse(RegExp(r'\d+').stringMatch(result) ?? '');
        
        if (caloriesPer100g != null) {
          _showAiResultDialog(caloriesPer100g);
        } else {
          throw Exception("AI tidak dapat mengesan maklumat kalori yang jelas.");
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Ralat Scan: ${e.toString()}")));
      }
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  void _showAiResultDialog(double kcalPer100g) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hasil Imbasan AI"),
        content: Text("AI mengesan kandungan kalori: $kcalPer100g kcal / 100g.\n\nSila masukkan berat hidangan untuk pengiraan."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () {
              setState(() => _kcalPer100g = kcalPer100g);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("AI Nilai Disimpan: $kcalPer100g kcal/100g.")));
            },
            child: const Text("Gunakan"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("MeowKibble Tracker", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Cat Selector
            const Text("Pilih Kucing", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 12),
            ListenableBuilder(
              listenable: appState,
              builder: (context, _) {
                if (appState.cats.isEmpty) {
                  return const Text("Sila daftar kucing anda terlebih dahulu di Dashboard.", style: TextStyle(color: Colors.grey));
                }
                
                // Auto-select cat if none selected
                if (_selectedCat == null && appState.cats.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _onCatSelected(appState.cats.first);
                  });
                }

                return SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: appState.cats.length,
                    itemBuilder: (context, index) {
                      final cat = appState.cats[index];
                      final isSelected = _selectedCat?.id == cat.id;
                      return GestureDetector(
                        onTap: () => _onCatSelected(cat),
                        child: Container(
                          width: 80,
                          margin: const EdgeInsets.only(right: 15),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF985BEF) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF985BEF).withOpacity(0.2)),
                            boxShadow: isSelected ? [BoxShadow(color: const Color(0xFF985BEF).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))] : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 20, 
                                backgroundImage: cat.image.startsWith('http') 
                                  ? NetworkImage(cat.image) 
                                  : (cat.image.startsWith('/') || cat.image.startsWith('content') || cat.image.contains('cat_cutout')
                                      ? FileImage(File(cat.image))
                                      : AssetImage(cat.image) as ImageProvider),
                              ),
                              const SizedBox(height: 8),
                              Text(cat.name, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 10)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),

            const SizedBox(height: 35),

            // 2. Daily Calorie Progress
            ListenableBuilder(
              listenable: appState,
              builder: (context, _) {
                final logs = _selectedCat != null ? (appState.catFoodLogs[_selectedCat!.id] ?? []) : [];
                final today = DateTime.now();
                final todayLogs = logs.where((l) => l.timestamp.day == today.day && l.timestamp.month == today.month && l.timestamp.year == today.year).toList();
                
                double totalCaloriesToday = 0;
                for (var l in todayLogs) {
                  totalCaloriesToday += l.calories;
                }

                int targetCalories = 1000; // Mock target
                double progress = totalCaloriesToday / targetCalories;
                if (progress > 1.0) progress = 1.0;

                return Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)],
                  ),
                  child: Column(
                    children: [
                      const Text("Ambilan Kalori Hari Ini", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 25),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            height: 150,
                            width: 150,
                            child: CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 15,
                              backgroundColor: const Color(0xFFF0F0F5),
                              color: const Color(0xFF985BEF),
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                          Column(
                            children: [
                              Text("$totalCaloriesToday", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF985BEF))),
                              Text("daripada $targetCalories kcal", style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (todayLogs.isNotEmpty)
                        Column(
                          children: todayLogs.take(3).map((l) => Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("${l.grams}g", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                Text("${l.calories} kcal", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          )).toList(),
                        ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 35),

            // 3. Add Food Form
            const Text("Tambah Rekod Makanan", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _gramsController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: "Berat Makanan (gram)",
                      prefixIcon: const Icon(Icons.scale, color: Color(0xFF985BEF)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: const Color(0xFFFBFBFF),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      if (_selectedCat != null && _gramsController.text.isNotEmpty) {
                        double grams = double.parse(_gramsController.text);
                        // Guna nilai dari AI scan (kcal per 100g)
                        int cals = (grams * (_kcalPer100g / 100)).toInt(); 
                        appState.addFoodLog(_selectedCat!.id, grams, cals);
                        _gramsController.clear();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Rekod ditambah! ($cals kcal dikira dari $_kcalPer100g kcal/100g)")));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF985BEF),
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: const Text("Simpan & Kira Kalori", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // 4. AI Scanner Banner (Functional)
            GestureDetector(
              onTap: _isScanning ? null : _scanNutritionalLabel,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF985BEF), Color(0xFFC084FC)]),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  children: [
                    _isScanning 
                      ? const SizedBox(width: 40, height: 40, child: CircularProgressIndicator(color: Colors.white))
                      : const Icon(Icons.auto_awesome, color: Colors.white, size: 40),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text("AI Kibble Scanner", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          Text("Imbas label nutrisi pada pek makanan untuk kiraan automatik.", style: TextStyle(color: Colors.white70, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
