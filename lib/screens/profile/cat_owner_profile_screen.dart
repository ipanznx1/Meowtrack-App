import 'package:flutter/material.dart';

class CatOwnerProfileScreen extends StatefulWidget {
  const CatOwnerProfileScreen({super.key});

  @override
  State<CatOwnerProfileScreen> createState() => _CatOwnerProfileScreenState();
}

class _CatOwnerProfileScreenState extends State<CatOwnerProfileScreen> {
  // 1. LOCAL STATE: Checklist tasks
  final List<Map<String, dynamic>> _tasks = [
    {
      "title": "Pergi ke Veterinar (Physical Vet Visit)",
      "completed": false,
    },
    {
      "title": "Suntikan Vaksin Pertama (First Vaccination Complete)",
      "completed": false,
    },
    {
      "title": "Beli Makanan/Kibbles Berkualiti (Purchase Cat Food)",
      "completed": false,
    },
    {
      "title": "Pasang Kolar GPS Tracker (Setup GPS Collar)",
      "completed": false,
    },
    {
      "title": "Kemas Kini Berat Kucing (Update Cat Weight Info)",
      "completed": false,
    },
  ];

  // Helper to count completed tasks
  int get _totalTasksCompleted => _tasks.where((task) => task["completed"]).length;

  // 2. ASSET RANK LOGIC
  Map<String, String> _getRankInfo() {
    int completed = _totalTasksCompleted;
    if (completed <= 1) {
      return {
        "name": "Newbie Pawrent",
        "image": "assets/rank/Newbie Pawrent.png",
      };
    } else if (completed == 2) {
      return {
        "name": "Guardian Angel",
        "image": "assets/rank/Guardian Angel.png",
      };
    } else if (completed == 3) {
      return {
        "name": "Cat Whisperer",
        "image": "assets/rank/Cat Whisperer.png",
      };
    } else if (completed == 4) {
      return {
        "name": "Professor Meow",
        "image": "assets/rank/Professor Meow.png",
      };
    } else {
      return {
        "name": "Cat Royalty",
        "image": "assets/rank/Cat Royalty.png",
      };
    }
  }

  void _onTaskToggled(int index, bool? value) {
    setState(() {
      _tasks[index]["completed"] = value ?? false;
      
      // Trigger Alert if reaching max rank
      if (_totalTasksCompleted == 5) {
        _showRoyaltyAlert();
      }
    });
  }

  void _showRoyaltyAlert() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Text("TAHNIAH! 👑", style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF985BEF))),
        content: const Text(
          "Anda telah mencapai pangkat Cat Royalty! 🎉🐾\nKucing anda pasti bangga mempunyai tuan seperti anda.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Teruskan!", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rankInfo = _getRankInfo();
    final double progress = _totalTasksCompleted / _tasks.length;

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Cat Owner Profile", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            
            // 3. HEADER SECTION: Profile Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(35),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF985BEF).withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Rank Avatar Image
                    Container(
                      height: 120,
                      width: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2EEFF),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF985BEF), width: 4),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          rankInfo["image"]!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, _, __) => const Icon(Icons.person, size: 60, color: Color(0xFF985BEF)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    
                    // Owner Name
                    const Text(
                      "Ahmad",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.black87),
                    ),
                    const SizedBox(height: 10),
                    
                    // Rank Name Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF985BEF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        rankInfo["name"]!,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 35),
            
            // 4. PROGRESS SECTION
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Pencapaian Penjagaan", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      Text("${(_totalTasksCompleted / _tasks.length * 100).toInt()}%", 
                        style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF985BEF))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 12,
                      backgroundColor: const Color(0xFFE8E8FF),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF985BEF)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text("$_totalTasksCompleted daripada ${_tasks.length} tugasan selesai", 
                    style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            
            const SizedBox(height: 35),
            
            // 5. SELF-CARE TASK CHECKLIST SECTION
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 25),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text("Tugasan Penjagaan", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              ),
            ),
            const SizedBox(height: 10),
            
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _tasks.length,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemBuilder: (context, index) {
                final task = _tasks[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: CheckboxListTile(
                    value: task["completed"],
                    onChanged: (val) => _onTaskToggled(index, val),
                    activeColor: const Color(0xFF985BEF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    title: Text(
                      task["title"],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: task["completed"] ? Colors.grey : Colors.black87,
                        decoration: task["completed"] ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                );
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
