import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/livestock_storage.dart';

void showHealthRecordDetailSheet(
  BuildContext context,
  Map<String, dynamic> record,
  List<Map<String, dynamic>> animals,
  VoidCallback onDataChanged,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return HealthRecordDetailBottomSheet(
        record: record,
        animals: animals,
        onDataChanged: onDataChanged,
      );
    },
  );
}

class HealthRecordDetailBottomSheet extends StatefulWidget {
  final Map<String, dynamic> record;
  final List<Map<String, dynamic>> animals;
  final VoidCallback onDataChanged;

  const HealthRecordDetailBottomSheet({
    Key? key,
    required this.record,
    required this.animals,
    required this.onDataChanged,
  }) : super(key: key);

  @override
  State<HealthRecordDetailBottomSheet> createState() => _HealthRecordDetailBottomSheetState();
}

class _HealthRecordDetailBottomSheetState extends State<HealthRecordDetailBottomSheet> {
  bool _isEditing = false;
  late Map<String, dynamic> _currentRecord;

  // Controllers for editing
  late TextEditingController _titleController;
  late TextEditingController _notesController;
  late TextEditingController _doctorController;
  late TextEditingController _dateDisplayController;
  
  late String _selectedAnimalId;
  late String _selectedRecordType;
  late String _selectedStatus;
  DateTime? _selectedDueDate;

  @override
  void initState() {
    super.initState();
    _currentRecord = Map<String, dynamic>.from(widget.record);
    _initFields();
  }

  void _initFields() {
    _titleController = TextEditingController(text: _currentRecord["title"]);
    _notesController = TextEditingController(text: _currentRecord["notes"]);
    _doctorController = TextEditingController(text: _currentRecord["doctor"] ?? "Dr. Jayasurya");
    
    final dueDateStr = _currentRecord["dueDate"] ?? "";
    _dateDisplayController = TextEditingController(text: dueDateStr);
    if (dueDateStr.isNotEmpty) {
      try {
        _selectedDueDate = DateTime.parse(dueDateStr);
      } catch (e) {
        _selectedDueDate = null;
      }
    } else {
      _selectedDueDate = null;
    }

    // Find if the original animal exists in the animals list
    final animId = _currentRecord["animalId"].toString();
    final animalExists = widget.animals.any((a) => a["id"].toString() == animId);
    _selectedAnimalId = animalExists ? animId : (widget.animals.isNotEmpty ? widget.animals.first["id"].toString() : "");

    // Record type
    final type = _currentRecord["type"] ?? "Vaccination";
    _selectedRecordType = ["Health Check", "Vaccination", "Treatment"].contains(type) ? type : "Vaccination";

    // Status
    final status = _currentRecord["status"] ?? "completed";
    _selectedStatus = ["completed", "scheduled"].contains(status) ? status : "completed";
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _doctorController.dispose();
    _dateDisplayController.dispose();
    super.dispose();
  }

  void _saveEdits() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Title is required!")),
      );
      return;
    }

    if (widget.animals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("An animal must be selected.")),
      );
      return;
    }

    final selectedAnimal = widget.animals.firstWhere((a) => a["id"].toString() == _selectedAnimalId);

    final updated = {
      "id": _currentRecord["id"],
      "animalId": selectedAnimal["id"],
      "animalName": selectedAnimal["name"],
      "animalType": selectedAnimal["type"],
      "type": _selectedRecordType,
      "title": title,
      "notes": _notesController.text.trim().isEmpty ? "Healthy record entry" : _notesController.text.trim(),
      "date": _currentRecord["date"] ?? DateFormat('MMM dd, yyyy').format(DateTime.now()),
      "doctor": _doctorController.text.trim().isEmpty ? "Dr. Jayasurya" : _doctorController.text.trim(),
      "status": _selectedStatus,
      "dueDate": _selectedDueDate == null ? "" : DateFormat('yyyy-MM-dd').format(_selectedDueDate!)
    };

    await LivestockStorageService.updateHealthRecord(updated);
    widget.onDataChanged();

    setState(() {
      _currentRecord = updated;
      _isEditing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Record for ${selectedAnimal["name"]} updated successfully!"),
        backgroundColor: const Color(0xFF22C55E),
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Delete Record"),
          content: Text("Are you sure you want to delete this health record?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context); // close confirm dialog
                Navigator.pop(this.context); // close bottom sheet
                
                await LivestockStorageService.deleteHealthRecord(_currentRecord["id"]);
                widget.onDataChanged();

                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(
                    content: Text("Record deleted successfully."),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text("Delete", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: _isEditing ? _buildEditLayout() : _buildViewLayout(),
      ),
    );
  }

  Widget _buildViewLayout() {
    final isCompleted = _currentRecord["status"] == "completed";
    final typeColor = _currentRecord["type"] == "Vaccination"
        ? const Color(0xFFF57C00)
        : (_currentRecord["type"] == "Treatment" ? const Color(0xFFE53935) : const Color(0xFF22C55E));
    final typeBg = _currentRecord["type"] == "Vaccination"
        ? const Color(0xFFFFF3E0)
        : (_currentRecord["type"] == "Treatment" ? const Color(0xFFFFF0F0) : const Color(0xFFEAF8F2));

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Record Details",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Record type and status badges
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: typeBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _currentRecord["type"] ?? "Vaccination",
                style: TextStyle(
                  color: typeColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isCompleted ? const Color(0xFFEAF8F2) : const Color(0xFFFFF7E6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _currentRecord["status"] ?? "completed",
                style: TextStyle(
                  color: isCompleted ? const Color(0xFF0F5A3E) : const Color(0xFFC26100),
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Title and notes
        Text(
          _currentRecord["title"] ?? "Record Title",
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
        ),
        const SizedBox(height: 12),
        const Text(
          "Notes",
          style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Text(
            _currentRecord["notes"] ?? "No notes recorded.",
            style: const TextStyle(fontSize: 14, color: Color(0xFF374151), height: 1.4),
          ),
        ),
        const SizedBox(height: 20),

        // Metadata rows
        _buildMetaRow(Icons.pets, "Animal", "${_currentRecord["animalName"]} (${_currentRecord["animalType"]})"),
        const SizedBox(height: 12),
        _buildMetaRow(Icons.calendar_today, "Recorded Date", _currentRecord["date"] ?? "Today"),
        const SizedBox(height: 12),
        if (_currentRecord["dueDate"] != null && _currentRecord["dueDate"].toString().isNotEmpty) ...[
          _buildMetaRow(Icons.event, "Next Due Date", _currentRecord["dueDate"]),
          const SizedBox(height: 12),
        ],
        _buildMetaRow(Icons.person_outline, "Examiner/Doctor", _currentRecord["doctor"] ?? "Vet"),
        const SizedBox(height: 28),

        // Action Buttons Row
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _confirmDelete,
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                label: const Text("Delete Record", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isEditing = true;
                  });
                },
                icon: const Icon(Icons.edit_outlined, color: Colors.white, size: 18),
                label: const Text("Edit Record", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22C55E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildMetaRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[500]),
        const SizedBox(width: 12),
        Text(
          "$label: ",
          style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _buildEditLayout() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  _initFields(); // Reset edit fields to current info
                });
              },
            ),
            const Text(
              "Edit Health Record",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Animal Dropdown
        const Text("Animal *", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedAnimalId,
              isExpanded: true,
              items: widget.animals
                  .map((a) => DropdownMenuItem<String>(
                        value: a["id"].toString(),
                        child: Text("${a["name"]} (${a["type"]} - ${a["breed"]})"),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedAnimalId = value;
                  });
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Record Type Dropdown
        const Text("Record Type *", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedRecordType,
              isExpanded: true,
              items: ["Health Check", "Vaccination", "Treatment"]
                  .map((type) => DropdownMenuItem<String>(value: type, child: Text(type)))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedRecordType = value;
                  });
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Title Field
        const Text("Title *", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 6),
        TextField(
          controller: _titleController,
          decoration: InputDecoration(
            hintText: "e.g., Annual Vaccination",
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF22C55E), width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Notes Field
        const Text("Notes", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 6),
        TextField(
          controller: _notesController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: "Add details about health check, diagnosis, or meds...",
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF22C55E), width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Next Due Date (DatePicker)
        const Text("Next Due Date", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 6),
        TextField(
          controller: _dateDisplayController,
          readOnly: true,
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedDueDate ?? DateTime.now().add(const Duration(days: 7)),
              firstDate: DateTime.now().subtract(const Duration(days: 30)),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: Color(0xFF22C55E),
                      onPrimary: Colors.white,
                      onSurface: Colors.black,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              setState(() {
                _selectedDueDate = picked;
                _dateDisplayController.text = DateFormat('yyyy-MM-dd').format(picked);
              });
            }
          },
          decoration: InputDecoration(
            hintText: "Click to select a due date (Optional)",
            suffixIcon: _selectedDueDate != null
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      setState(() {
                        _selectedDueDate = null;
                        _dateDisplayController.clear();
                      });
                    },
                  )
                : const Icon(Icons.calendar_today, color: Colors.grey, size: 18),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 16),

        // Examiner / Doctor
        const Text("Examiner/Vet Doctor", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 6),
        TextField(
          controller: _doctorController,
          decoration: InputDecoration(
            hintText: "e.g., Dr. Smith",
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF22C55E), width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Status Dropdown
        const Text("Status *", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedStatus,
              isExpanded: true,
              items: ["completed", "scheduled"]
                  .map((status) => DropdownMenuItem<String>(value: status, child: Text(status)))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedStatus = value;
                  });
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 28),

        // Action Buttons Row
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _isEditing = false;
                    _initFields(); // Reset edit fields to current record info
                  });
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF22C55E)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text("Cancel", style: TextStyle(color: Color(0xFF22C55E), fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _saveEdits,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22C55E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text("Save Changes", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
