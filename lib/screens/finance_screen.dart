import 'package:flutter/material.dart';
import '../services/ad_service.dart';

class Transaction {
  final String date;
  final String type; // 'INCOME' or 'EXPENSE'
  final String category;
  final double amount;
  final String description;

  Transaction({
    required this.date,
    required this.type,
    required this.category,
    required this.amount,
    required this.description,
  });
}

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({Key? key}) : super(key: key);

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  String selectedType = 'Income';
  String selectedCategory = 'Crop Sale';
  double amount = 0;
  String selectedDate =
      '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';
  String description = '';

  String _reportFormat = 'Monthly'; // 'Monthly', 'Yearly', 'Custom Range'
  String _selectedReportMonth = 'October';
  String _selectedReportYear = '2025';
  String _selectedReportStart = '2025-10-01';
  String _selectedReportEnd = '2025-10-31';

  final List<String> _reportMonths = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  final List<String> _reportYears = ['2023', '2024', '2025', '2026'];

  final List<String> incomeCategories = [
    'Crop Sale',
    'Government Subsidy',
    'Other Income',
    'Dairy Products',
    'Livestock Sale',
  ];

  final List<String> expenseCategories = [
    'Seeds & Fertilizers',
    'Labor Cost',
    'Equipment Rental',
    'Pesticides',
    'Transportation',
    'Other Expenses',
  ];

  List<Transaction> transactions = [
    Transaction(
      date: '2025-10-27',
      type: 'INCOME',
      category: 'Crop Sale',
      amount: 15000.00,
      description: 'rice sale',
    ),
    Transaction(
      date: '2025-10-27',
      type: 'EXPENSE',
      category: 'Other Income',
      amount: -35000.00,
      description: 'travelling expenses',
    ),
    Transaction(
      date: '2025-10-26',
      type: 'INCOME',
      category: 'Government Subsidy',
      amount: 25000.00,
      description: 'Crop subsidy received',
    ),
    Transaction(
      date: '2025-10-25',
      type: 'EXPENSE',
      category: 'Seeds & Fertilizers',
      amount: -12000.00,
      description: 'Purchased seeds for next season',
    ),
  ];

  Map<String, Map<String, double>> getMonthlyReports() {
    Map<String, Map<String, double>> reports = {};
    for (var t in transactions) {
      try {
        final parts = t.date.split('-');
        if (parts.length == 3) {
          final year = parts[0];
          final monthInt = int.parse(parts[1]);
          final monthName = _getMonthName(monthInt);
          final monthKey = "$monthName $year";
          
          if (!reports.containsKey(monthKey)) {
            reports[monthKey] = {'INCOME': 0.0, 'EXPENSE': 0.0};
          }
          if (t.type == 'INCOME') {
            reports[monthKey]!['INCOME'] = reports[monthKey]!['INCOME']! + t.amount;
          } else {
            reports[monthKey]!['EXPENSE'] = reports[monthKey]!['EXPENSE']! + t.amount.abs();
          }
        }
      } catch (_) {}
    }
    return reports;
  }
  
  String _getMonthName(int month) {
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    if (month >= 1 && month <= 12) {
      return months[month - 1];
    }
    return 'Unknown';
  }

  Widget _buildReportStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  double getTotalIncome() {
    return transactions.where((t) => t.type == 'INCOME').fold(0, (sum, t) => sum + t.amount);
  }

  double getTotalExpense() {
    return transactions
        .where((t) => t.type == 'EXPENSE')
        .fold(0, (sum, t) => sum + (t.amount.abs()));
  }

  Map<String, double> getIncomeByCategory() {
    Map<String, double> categoryTotals = {};
    for (var transaction in transactions.where((t) => t.type == 'INCOME')) {
      categoryTotals[transaction.category] =
          (categoryTotals[transaction.category] ?? 0) + transaction.amount;
    }
    return categoryTotals;
  }

  Map<String, double> getExpenseByCategory() {
    Map<String, double> categoryTotals = {};
    for (var transaction in transactions.where((t) => t.type == 'EXPENSE')) {
      categoryTotals[transaction.category] =
          (categoryTotals[transaction.category] ?? 0) + transaction.amount.abs();
    }
    return categoryTotals;
  }

  void addTransaction() {
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    setState(() {
      transactions.insert(
        0,
        Transaction(
          date: selectedDate,
          type: selectedType.toUpperCase(),
          category: selectedCategory,
          amount: selectedType == 'Income' ? amount : -amount,
          description: description.isEmpty ? 'Transaction' : description,
        ),
      );

      // Reset form
      amount = 0;
      selectedCategory = selectedType == 'Income' ? 'Crop Sale' : 'Seeds & Fertilizers';
      description = '';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transaction added successfully!')),
    );
  }

  Widget _buildDownloadReportCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF1E40AF),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: const [
                Icon(Icons.file_download, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Export & Download Reports',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildFormatTab('Monthly'),
                    const SizedBox(width: 8),
                    _buildFormatTab('Yearly'),
                    const SizedBox(width: 8),
                    _buildFormatTab('Custom Range'),
                  ],
                ),
                const SizedBox(height: 16),
                
                if (_reportFormat == 'Monthly') ...[
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Month', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color(0xFFE5E7EB)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedReportMonth,
                                  isExpanded: true,
                                  items: _reportMonths.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                                  onChanged: (val) {
                                    if (val != null) setState(() { _selectedReportMonth = val; });
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Year', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color(0xFFE5E7EB)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedReportYear,
                                  isExpanded: true,
                                  items: _reportYears.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                                  onChanged: (val) {
                                    if (val != null) setState(() { _selectedReportYear = val; });
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ] else if (_reportFormat == 'Yearly') ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Select Year', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedReportYear,
                            isExpanded: true,
                            items: _reportYears.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() { _selectedReportYear = val; });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('From Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: () => _selectReportDate(true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: const Color(0xFFE5E7EB)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(_selectedReportStart, style: const TextStyle(fontSize: 14)),
                                    const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('To Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: () => _selectReportDate(false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: const Color(0xFFE5E7EB)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(_selectedReportEnd, style: const TextStyle(fontSize: 14)),
                                    const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
                
                const SizedBox(height: 20),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _downloadReportFlow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22C55E),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.video_library, color: Colors.black, size: 18),
                    label: const Text(
                      'Download Report (Watch Ad)',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatTab(String format) {
    final isSelected = _reportFormat == format;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _reportFormat = format;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1E40AF) : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? const Color(0xFF1E40AF) : const Color(0xFFE5E7EB),
            ),
          ),
          child: Center(
            child: Text(
              format,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectReportDate(bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      final formatted = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      setState(() {
        if (isStart) {
          _selectedReportStart = formatted;
        } else {
          _selectedReportEnd = formatted;
        }
      });
    }
  }

  void _downloadReportFlow() {
    AdService.showRewardedAd(context, () {
      String desc = '';
      if (_reportFormat == 'Monthly') {
        desc = 'Monthly Report for $_selectedReportMonth $_selectedReportYear';
      } else if (_reportFormat == 'Yearly') {
        desc = 'Yearly Report for $_selectedReportYear';
      } else {
        desc = 'Report from $_selectedReportStart to $_selectedReportEnd';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 $desc downloaded successfully to your device!'),
          backgroundColor: const Color(0xFF22C55E),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  void _deleteTransaction(Transaction transaction) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Transaction'),
          content: const Text('Are you sure you want to delete this transaction?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  transactions.remove(transaction);
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Transaction deleted successfully!')),
                );
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void _editTransaction(Transaction transaction) {
    final int index = transactions.indexOf(transaction);
    if (index == -1) return;

    String editType = transaction.type == 'INCOME' ? 'Income' : 'Expense';
    String editCategory = transaction.category;
    double editAmount = transaction.amount.abs();
    String editDate = transaction.date;
    String editDescription = transaction.description;

    final TextEditingController amountController =
        TextEditingController(text: editAmount.toStringAsFixed(2));
    final TextEditingController descriptionController =
        TextEditingController(text: editDescription);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Transaction'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type dropdown
                    const Text('Type', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: editType,
                          isExpanded: true,
                          items: const ['Income', 'Expense']
                              .map((type) => DropdownMenuItem(
                                    value: type,
                                    child: Text(type),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(() {
                                editType = value;
                                editCategory = editType == 'Income'
                                    ? 'Crop Sale'
                                    : 'Seeds & Fertilizers';
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Category dropdown
                    const Text('Category', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: editCategory,
                          isExpanded: true,
                          items: (editType == 'Income' ? incomeCategories : expenseCategories)
                              .map((category) => DropdownMenuItem(
                                    value: category,
                                    child: Text(category),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(() {
                                editCategory = value;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Amount Field
                    const Text('Amount (₹)', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Date Picker Field
                    const Text('Date', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      readOnly: true,
                      decoration: InputDecoration(
                        hintText: editDate,
                        suffixIcon: const Icon(Icons.calendar_today),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onTap: () async {
                        DateTime initialDate = DateTime.now();
                        try {
                          final parts = editDate.split('-');
                          if (parts.length == 3) {
                            if (parts[0].length == 4) {
                              initialDate = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
                            } else {
                              initialDate = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
                            }
                          }
                        } catch (_) {}

                        final DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: initialDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (pickedDate != null) {
                          setDialogState(() {
                            editDate = '${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}';
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Description Field
                    const Text('Description', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descriptionController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    final double? parsedAmount = double.tryParse(amountController.text);
                    if (parsedAmount == null || parsedAmount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a valid amount')),
                      );
                      return;
                    }

                    setState(() {
                      transactions[index] = Transaction(
                        date: editDate,
                        type: editType.toUpperCase(),
                        category: editCategory,
                        amount: editType == 'Income' ? parsedAmount : -parsedAmount,
                        description: descriptionController.text.isEmpty
                            ? 'Transaction'
                            : descriptionController.text,
                      );
                    });

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Transaction updated successfully!')),
                    );
                  },
                  child: const Text('Save', style: TextStyle(color: Color(0xFF22C55E))),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalIncome = getTotalIncome();
    final totalExpense = getTotalExpense();
    final netAmount = totalIncome - totalExpense;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Finance Dashboard',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Cards
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          title: 'Total Income',
                          amount: totalIncome,
                          color: const Color(0xFF22C55E),
                          icon: Icons.trending_up,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SummaryCard(
                          title: 'Total Expense',
                          amount: totalExpense,
                          color: const Color(0xFFEF4444),
                          icon: Icons.trending_down,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: _SummaryCard(
                      title: 'Net Balance',
                      amount: netAmount,
                      color: netAmount >= 0 ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                      icon: netAmount >= 0 ? Icons.account_balance_wallet : Icons.warning,
                    ),
                  ),
                ],
              ),
            ),

            // Charts Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Analytics',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            // Income vs Expenses Pie Chart
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Income vs Expenses',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: _PieChart(
                        income: totalIncome,
                        expense: totalExpense,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Income & Expenses by Category
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Income & Expenses by Category',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _BarChart(
                      incomeByCategory: getIncomeByCategory(),
                      expenseByCategory: getExpenseByCategory(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Add Transaction Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Color(0xFF22C55E),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      child: const Text(
                        'Add Transaction',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Type Dropdown
                          const Text(
                            'Type',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFFE5E7EB)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButton<String>(
                              value: selectedType,
                              isExpanded: true,
                              underline: const SizedBox(),
                              items: ['Income', 'Expense']
                                  .map((type) => DropdownMenuItem(
                                        value: type,
                                        child: Text(type),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedType = value ?? 'Income';
                                  selectedCategory = selectedType == 'Income'
                                      ? 'Crop Sale'
                                      : 'Seeds & Fertilizers';
                                });
                              },
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Category Dropdown
                          const Text(
                            'Category',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFFE5E7EB)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButton<String>(
                              value: selectedCategory,
                              isExpanded: true,
                              underline: const SizedBox(),
                              items:
                                  (selectedType == 'Income' ? incomeCategories : expenseCategories)
                                      .map((category) => DropdownMenuItem(
                                            value: category,
                                            child: Text(category),
                                          ))
                                      .toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedCategory = value ?? selectedCategory;
                                });
                              },
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Amount Field
                          const Text(
                            'Amount (₹)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: '0',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                              ),
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            onChanged: (value) {
                              setState(() {
                                amount = double.tryParse(value) ?? 0;
                              });
                            },
                          ),

                          const SizedBox(height: 16),

                          // Date Field
                          const Text(
                            'Date',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            readOnly: true,
                            decoration: InputDecoration(
                              hintText: selectedDate,
                              suffixIcon: const Icon(Icons.calendar_today),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                              ),
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            onTap: () async {
                              final DateTime? pickedDate = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (pickedDate != null) {
                                setState(() {
                                  selectedDate =
                                      '${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}';
                                });
                              }
                            },
                          ),

                          const SizedBox(height: 16),

                          // Description Field
                          const Text(
                            'Description',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: 'Optional description',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                              ),
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            onChanged: (value) {
                              setState(() {
                                description = value;
                              });
                            },
                          ),

                          const SizedBox(height: 16),

                          // Add Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: addTransaction,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF22C55E),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Add Transaction',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            _buildDownloadReportCard(),

            const SizedBox(height: 24),

            // Monthly Reports Section (Farm Expense Tracker)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Monthly Reports',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Builder(
                    builder: (context) {
                      final reports = getMonthlyReports();
                      if (reports.isEmpty) {
                        return const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text('No monthly reports generated yet.'),
                          ),
                        );
                      }
                      
                      final monthKeys = reports.keys.toList();
                      List<Widget> reportWidgets = [];
                      
                      for (int i = 0; i < monthKeys.length; i++) {
                        final monthKey = monthKeys[i];
                        final income = reports[monthKey]!['INCOME'] ?? 0.0;
                        final expense = reports[monthKey]!['EXPENSE'] ?? 0.0;
                        final net = income - expense;
                        final netColor = net >= 0 ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
                        
                        reportWidgets.add(
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE5E7EB)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "$monthKey Report",
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: netColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        net >= 0 ? "SURPLUS" : "DEFICIT",
                                        style: TextStyle(
                                          color: netColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildReportStat("Income", "+₹${income.toStringAsFixed(0)}", const Color(0xFF22C55E)),
                                    _buildReportStat("Expenses", "-₹${expense.toStringAsFixed(0)}", const Color(0xFFEF4444)),
                                    _buildReportStat("Net Savings", "₹${net.toStringAsFixed(0)}", netColor),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                        
                        if (i != monthKeys.length - 1) {
                          reportWidgets.add(
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: AdService.getNativeAdWidget(height: 70),
                            ),
                          );
                        }
                      }
                      return Column(children: reportWidgets);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Transaction History
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1E40AF),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                    ),
                    child: const Text(
                      'Transaction History',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 20,
                        columns: const [
                          DataColumn(label: Text('DATE')),
                          DataColumn(label: Text('TYPE')),
                          DataColumn(label: Text('CATEGORY')),
                          DataColumn(label: Text('AMOUNT')),
                          DataColumn(label: Text('DESCRIPTION')),
                          DataColumn(label: Text('ACTIONS')),
                        ],
                        rows: transactions.map((transaction) {
                          return DataRow(
                            cells: [
                              DataCell(Text(transaction.date)),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: transaction.type == 'INCOME'
                                        ? const Color(0xFFDCFCE7)
                                        : const Color(0xFFFECACA),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    transaction.type,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: transaction.type == 'INCOME'
                                          ? const Color(0xFF22C55E)
                                          : const Color(0xFFEF4444),
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(Text(transaction.category)),
                              DataCell(
                                Text(
                                  '${transaction.amount >= 0 ? '+' : ''}₹${transaction.amount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: transaction.amount >= 0
                                        ? const Color(0xFF22C55E)
                                        : const Color(0xFFEF4444),
                                  ),
                                ),
                              ),
                              DataCell(Text(transaction.description)),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () => _editTransaction(transaction),
                                    ),
                                    const SizedBox(width: 12),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () => _deleteTransaction(transaction),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    Key? key,
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _PieChart extends StatelessWidget {
  final double income;
  final double expense;

  const _PieChart({
    Key? key,
    required this.income,
    required this.expense,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final total = income + expense;
    final incomePercentage = total > 0 ? (income / total * 100).toDouble() : 0.0;
    final expensePercentage = total > 0 ? (expense / total * 100).toDouble() : 0.0;

    return SizedBox(
      height: 180,
      child: Column(
        children: [
          SizedBox(
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  painter: _PieChartPainter(
                    incomePercentage: incomePercentage,
                    expensePercentage: expensePercentage,
                  ),
                  size: const Size(120, 120),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${incomePercentage.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Color(0xFF22C55E),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Income: ₹${income.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Expense: ₹${expense.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PieChartPainter extends CustomPainter {
  final double incomePercentage;
  final double expensePercentage;

  _PieChartPainter({
    required this.incomePercentage,
    required this.expensePercentage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw Income (Green)
    paint.color = const Color(0xFF22C55E);
    final incomeSweep = (incomePercentage / 100) * 2 * 3.14159;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159 / 2,
      incomeSweep,
      true,
      paint,
    );

    // Draw Expense (Red)
    paint.color = const Color(0xFFEF4444);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159 / 2 + incomeSweep,
      (expensePercentage / 100) * 2 * 3.14159,
      true,
      paint,
    );
  }

  @override
  bool shouldRepaint(_PieChartPainter oldDelegate) => false;
}

class _BarChart extends StatefulWidget {
  final Map<String, double> incomeByCategory;
  final Map<String, double> expenseByCategory;

  const _BarChart({
    Key? key,
    required this.incomeByCategory,
    required this.expenseByCategory,
  }) : super(key: key);

  @override
  State<_BarChart> createState() => _BarChartState();
}

class _BarChartState extends State<_BarChart> {
  String? selectedCategory;

  @override
  Widget build(BuildContext context) {
    final allCategories = {
      ...widget.incomeByCategory,
      ...widget.expenseByCategory,
    }.keys.toList();

    final maxValue = [...widget.incomeByCategory.values, ...widget.expenseByCategory.values]
        .fold(0.0, (max, val) => val > max ? val : max);

    return SizedBox(
      height: 220,
      child: Column(
        children: [
          // Y-axis labels
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 50,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${maxValue.toStringAsFixed(0)}', style: const TextStyle(fontSize: 10)),
                      Text('${(maxValue * 0.75).toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 10)),
                      Text('${(maxValue * 0.5).toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 10)),
                      Text('${(maxValue * 0.25).toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 10)),
                      const Text('0', style: TextStyle(fontSize: 10)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Stack(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: List.generate(
                          allCategories.length,
                          (index) {
                            final category = allCategories[index];
                            final income = widget.incomeByCategory[category] ?? 0;
                            final expense = widget.expenseByCategory[category] ?? 0;
                            final isSelected = selectedCategory == category;

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedCategory = isSelected ? null : category;
                                });
                              },
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (income > 0)
                                    Container(
                                      width: 16,
                                      height: (income / maxValue) * 140,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xFF22C55E)
                                            : const Color(0xFF22C55E),
                                        borderRadius:
                                            BorderRadius.vertical(top: Radius.circular(4)),
                                        boxShadow: isSelected
                                            ? [
                                                BoxShadow(
                                                  color: const Color(0xFF22C55E).withOpacity(0.5),
                                                  blurRadius: 8,
                                                  spreadRadius: 2,
                                                )
                                              ]
                                            : [],
                                      ),
                                    ),
                                  if (expense > 0)
                                    Container(
                                      width: 16,
                                      height: (expense / maxValue) * 140,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xFFEF4444)
                                            : const Color(0xFFEF4444),
                                        borderRadius:
                                            BorderRadius.vertical(top: Radius.circular(4)),
                                        boxShadow: isSelected
                                            ? [
                                                BoxShadow(
                                                  color: const Color(0xFFEF4444).withOpacity(0.5),
                                                  blurRadius: 8,
                                                  spreadRadius: 2,
                                                )
                                              ]
                                            : [],
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      // Tooltip
                      if (selectedCategory != null)
                        Positioned(
                          left: 0,
                          top: 0,
                          child: _CategoryTooltip(
                            category: selectedCategory!,
                            income: widget.incomeByCategory[selectedCategory!] ?? 0,
                            expense: widget.expenseByCategory[selectedCategory!] ?? 0,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // X-axis labels
          Padding(
            padding: const EdgeInsets.only(left: 58),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: allCategories
                  .map(
                    (category) => SizedBox(
                      width: 60,
                      child: Text(
                        category,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 10),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 8),
          // Legend
          Padding(
            padding: const EdgeInsets.only(left: 58),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      color: const Color(0xFFEF4444),
                    ),
                    const SizedBox(width: 4),
                    const Text('Expenses', style: TextStyle(fontSize: 10)),
                  ],
                ),
                const SizedBox(width: 16),
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      color: const Color(0xFF22C55E),
                    ),
                    const SizedBox(width: 4),
                    const Text('Income', style: TextStyle(fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTooltip extends StatelessWidget {
  final String category;
  final double income;
  final double expense;

  const _CategoryTooltip({
    Key? key,
    required this.category,
    required this.income,
    required this.expense,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            category,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Expenses : ',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '₹${expense.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFEF4444),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                'Income : ',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '₹${income.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF22C55E),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
