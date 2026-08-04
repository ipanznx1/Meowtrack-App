import 'package:flutter/material.dart';

enum UserRole { admin, vet }

class PatientMock {
  String name;
  String owner;
  String complaint;
  String status;
  String time;
  PatientMock({required this.name, required this.owner, required this.complaint, required this.status, required this.time});
}

class VetClinicMultiRoleDashboard extends StatefulWidget {
  const VetClinicMultiRoleDashboard({super.key});

  @override
  State<VetClinicMultiRoleDashboard> createState() => _VetClinicMultiRoleDashboardState();
}

class _VetClinicMultiRoleDashboardState extends State<VetClinicMultiRoleDashboard> {
  UserRole _currentRole = UserRole.admin;
  bool _isCollarConnected = false;
  
  // DYNAMIC MOCK DATA LIST
  final List<PatientMock> _patients = [
    PatientMock(name: "Oyen", owner: "Ali", complaint: "Vaksin", status: "Waiting", time: "10:00 AM"),
    PatientMock(name: "Comel", owner: "Siti", complaint: "Demam", status: "In Treatment", time: "10:30 AM"),
  ];

  void _registerNewPatient() {
    setState(() {
      _patients.add(PatientMock(
        name: "New Cat ${_patients.length + 1}",
        owner: "Guest Owner",
        complaint: "General Checkup",
        status: "Waiting",
        time: "11:00 AM",
      ));
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("New Patient Registered (Mock)")));
  }

  void _toggleCollar() {
    setState(() => _isCollarConnected = !_isCollarConnected);
  }

  void _updatePatientStatus(int index) {
    setState(() {
      _patients[index].status = _patients[index].status == "Waiting" ? "Completed" : "Waiting";
    });
  }

  void _openDiagnosisDialog(String catName) {
    final diagController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Medical Record for $catName"),
        content: TextField(
          controller: diagController,
          maxLines: 3,
          decoration: const InputDecoration(hintText: "Enter diagnosis and treatment..."),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Record saved for $catName: ${diagController.text}")));
            },
            child: const Text("Save Record"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDesktop = MediaQuery.of(context).size.width > 1000;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      body: Row(
        children: [
          if (isDesktop) _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(30),
                    child: _currentRole == UserRole.admin ? _buildAdminView() : _buildVetView(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => setState(() => _currentRole = _currentRole == UserRole.admin ? UserRole.vet : UserRole.admin),
        label: Text("Switch to ${_currentRole == UserRole.admin ? 'Vet' : 'Admin'}"),
        backgroundColor: const Color(0xFF008080),
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 260,
      color: Colors.white,
      child: Column(
        children: [
          const SizedBox(height: 50),
          const Icon(Icons.pets, color: Color(0xFF008080), size: 40),
          const SizedBox(height: 50),
          _sidebarItem(Icons.dashboard, "Dashboard"),
          _sidebarItem(Icons.monitor_heart, "Simulation"),
          const Spacer(),
          _sidebarItem(Icons.logout, "Logout"),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _sidebarItem(IconData icon, String label) {
    return ListTile(leading: Icon(icon, color: const Color(0xFF008080)), title: Text(label));
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(25),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("Klinik Dr. Mia - ${_currentRole == UserRole.admin ? 'Counter Portal' : 'Medical Portal'}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(_currentRole == UserRole.admin ? "Staff Ali (Admin)" : "Dr. Mia (Vet)", style: const TextStyle(color: Color(0xFF008080), fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildAdminView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("QUICK ACTIONS", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 20),
        Row(
          children: [
            _actionCard("+ Register Patient", Colors.green, _registerNewPatient),
            const SizedBox(width: 20),
            _actionCard("Simulation Collar", _isCollarConnected ? Colors.blue : Colors.grey, _toggleCollar),
          ],
        ),
        const SizedBox(height: 40),
        const Text("TODAY'S QUEUE", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 20),
        _buildPatientList(isAdmin: true),
      ],
    );
  }

  Widget _buildVetView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(color: const Color(0xFF008080), borderRadius: BorderRadius.circular(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("CURRENT PATIENT", style: TextStyle(color: Colors.white70)),
              Text(_patients.isNotEmpty ? _patients.first.name : "No Patients", style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: 40),
        _buildPatientList(isAdmin: false),
      ],
    );
  }

  Widget _actionCard(String title, Color color, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 100,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(15)),
          child: Center(child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        ),
      ),
    );
  }

  Widget _buildPatientList({required bool isAdmin}) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: _patients.length,
      itemBuilder: (context, index) {
        final p = _patients[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.pets)),
            title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("Owner: ${p.owner} | Status: ${p.status}"),
            trailing: isAdmin 
              ? ElevatedButton(onPressed: () => _updatePatientStatus(index), child: const Text("Toggle Status"))
              : ElevatedButton(onPressed: () => _openDiagnosisDialog(p.name), child: const Text("Write Medical Record")),
          ),
        );
      },
    );
  }
}
