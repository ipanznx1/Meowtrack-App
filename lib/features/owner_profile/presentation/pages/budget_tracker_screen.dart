import 'package:flutter/material.dart';
import 'package:meow_track/core/app_state.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class BudgetTrackerScreen extends StatefulWidget {
  const BudgetTrackerScreen({super.key});

  @override
  State<BudgetTrackerScreen> createState() => _BudgetTrackerScreenState();
}

class _BudgetTrackerScreenState extends State<BudgetTrackerScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _selectedCategory = 'Food';

  final List<String> _categories = ['Food', 'Litter', 'Medical', 'Toys', 'Grooming', 'Others'];

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
        title: const Text("MeowBudget", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListenableBuilder(
        listenable: appState,
        builder: (context, _) {
          double total = appState.expenses.fold(0, (sum, item) => sum + item.amount);
          double budget = appState.monthlyBudgetLimit;
          double percent = (total / budget).clamp(0.0, 1.0);
          bool isOverBudget = total > budget;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Total Spending Card
                Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isOverBudget 
                          ? [Colors.redAccent, Colors.red] 
                          : [const Color(0xFF985BEF), const Color(0xFFC084FC)]
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [BoxShadow(color: (isOverBudget ? Colors.red : const Color(0xFF985BEF)).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Jumlah Perbelanjaan", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text("RM ${total.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
                            ],
                          ),
                          GestureDetector(
                            onTap: () => _showEditBudgetDialog(context),
                            child: const Icon(Icons.settings, color: Colors.white, size: 24),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: percent,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          color: Colors.white,
                          minHeight: 10,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Budget: RM ${budget.toInt()}", style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                          Text("${(percent * 100).toInt()}% Used", style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 35),

                // 2. Spending Chart
                const Text("Analisis Kategori", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 15),
                Container(
                  height: 200,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
                  child: appState.expenses.isEmpty 
                    ? const Center(child: Text("Tiada data perbelanjaan lagi."))
                    : PieChart(
                        PieChartData(
                          sections: _generateSections(),
                          centerSpaceRadius: 40,
                          sectionsSpace: 5,
                        ),
                      ),
                ),

                const SizedBox(height: 35),

                // 3. Add Expense Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Sejarah Transaksi", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    TextButton.icon(
                      onPressed: () => _showAddExpenseDialog(context),
                      icon: const Icon(Icons.add, color: Color(0xFF985BEF)),
                      label: const Text("Tambah", style: TextStyle(color: Color(0xFF985BEF), fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                
                // 4. Expense List
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: appState.expenses.length,
                  itemBuilder: (context, index) {
                    final expense = appState.expenses[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: const Color(0xFFF2EEFF), borderRadius: BorderRadius.circular(12)),
                            child: Icon(_getCategoryIcon(expense.category), color: const Color(0xFF985BEF)),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(expense.category, style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text(DateFormat('dd MMM yyyy').format(expense.date), style: TextStyle(color: Colors.grey[600], fontSize: 10)),
                              ],
                            ),
                          ),
                          Text("- RM ${expense.amount.toStringAsFixed(2)}", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddExpenseDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 25, right: 25, top: 25),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Tambah Belanja", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                filled: true, fillColor: const Color(0xFFFBFBFF),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _selectedCategory = v!),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: "Amaun (RM)",
                filled: true, fillColor: const Color(0xFFFBFBFF),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                hintText: "Nota (Opsional)",
                filled: true, fillColor: const Color(0xFFFBFBFF),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 25),
            ElevatedButton(
              onPressed: () {
                if (_amountController.text.isNotEmpty) {
                  appState.addExpense(_selectedCategory, double.parse(_amountController.text), _noteController.text);
                  _amountController.clear();
                  _noteController.clear();
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF985BEF),
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: const Text("Simpan Transaksi", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _generateSections() {
    Map<String, double> catTotals = {};
    for (var e in appState.expenses) {
      catTotals[e.category] = (catTotals[e.category] ?? 0) + e.amount;
    }
    
    final colors = [const Color(0xFF985BEF), const Color(0xFFC084FC), const Color(0xFFFFD54F), const Color(0xFFF48FB1), const Color(0xFF4DB6AC), Colors.orange];
    int colorIdx = 0;
    
    return catTotals.entries.map((entry) {
      final color = colors[colorIdx % colors.length];
      colorIdx++;
      return PieChartSectionData(
        color: color,
        value: entry.value,
        title: entry.key,
        radius: 50,
        titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Food': return Icons.restaurant;
      case 'Litter': return Icons.cleaning_services;
      case 'Medical': return Icons.medical_services;
      case 'Toys': return Icons.toys;
      case 'Grooming': return Icons.brush;
      default: return Icons.shopping_bag;
    }
  }

  void _showEditBudgetDialog(BuildContext context) {
    final controller = TextEditingController(text: appState.monthlyBudgetLimit.toInt().toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Set Monthly Budget"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Budget Amount (RM)", border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null) {
                appState.setMonthlyBudgetLimit(val);
                Navigator.pop(context);
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }
}
