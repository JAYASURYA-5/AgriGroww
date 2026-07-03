import 'package:flutter/material.dart';
import '../services/livestock_storage.dart';

void showAnimalDetailSheet(BuildContext context, Map<String, dynamic> animal, VoidCallback onDataChanged) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return AnimalDetailBottomSheet(animal: animal, onDataChanged: onDataChanged);
    },
  );
}

class AnimalDetailBottomSheet extends StatefulWidget {
  final Map<String, dynamic> animal;
  final VoidCallback onDataChanged;

  const AnimalDetailBottomSheet({
    Key? key,
    required this.animal,
    required this.onDataChanged,
  }) : super(key: key);

  @override
  State<AnimalDetailBottomSheet> createState() => _AnimalDetailBottomSheetState();
}

class _AnimalDetailBottomSheetState extends State<AnimalDetailBottomSheet> {
  bool _isEditing = false;
  late Map<String, dynamic> _currentAnimal;

  // Controllers for editing
  late TextEditingController _nameController;
  late TextEditingController _breedController;
  late TextEditingController _ageController;
  late TextEditingController _weightController;
  late TextEditingController _locationController;
  late TextEditingController _imageUrlController;
  late String _selectedType;
  late String _selectedStatus;

  final Map<String, String> _typeImages = {
    "Cattle": "https://images.unsplash.com/photo-1570042225831-d98fa7577f1e?w=500&q=80",
    "Horses": "https://images.unsplash.com/photo-1553284965-83fd3e82fa5a?w=500&q=80",
    "Chickens": "https://images.unsplash.com/photo-1548550023-2bdb3c5beed7?w=500&q=80",
    "Sheep": "https://images.unsplash.com/photo-1484557985045-ebd25e0887e2?w=500&q=80",
    "Goats": "https://images.unsplash.com/photo-1524413840807-0c3cb6fa808d?w=500&q=80",
    "Pigs": "https://images.unsplash.com/photo-1516467508483-a7212febe31a?w=500&q=80",
  };

  @override
  void initState() {
    super.initState();
    _currentAnimal = Map<String, dynamic>.from(widget.animal);
    _initFields();
  }

  void _initFields() {
    _nameController = TextEditingController(text: _currentAnimal["name"]);
    _breedController = TextEditingController(text: _currentAnimal["breed"]);
    _ageController = TextEditingController(text: _currentAnimal["age"]);
    _weightController = TextEditingController(text: _currentAnimal["weight"]);
    _locationController = TextEditingController(text: _currentAnimal["location"]);
    _imageUrlController = TextEditingController(text: _currentAnimal["img"]);
    
    // Normalize type and status to match options
    final type = _currentAnimal["type"] ?? "Cattle";
    _selectedType = ["Cattle", "Sheep", "Goats", "Pigs", "Chickens", "Horses"].contains(type) ? type : "Cattle";
    
    final status = _currentAnimal["status"] ?? "Healthy";
    if (status.toString().toLowerCase() == "attention" || status.toString().toLowerCase() == "needs attention") {
      _selectedStatus = "Attention";
    } else if (status.toString().toLowerCase() == "critical") {
      _selectedStatus = "Critical";
    } else {
      _selectedStatus = "Healthy";
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _locationController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Color _getStatusBg(String status) {
    switch (status.toLowerCase()) {
      case "healthy":
        return const Color(0xFFEAF8F2);
      case "attention":
      case "needs attention":
        return const Color(0xFFFFFBEB);
      case "critical":
        return const Color(0xFFFFF0F0);
      default:
        return const Color(0xFFEAF8F2);
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status.toLowerCase()) {
      case "healthy":
        return const Color(0xFF0F5A3E);
      case "attention":
      case "needs attention":
        return const Color(0xFFC26100);
      case "critical":
        return const Color(0xFFD32F2F);
      default:
        return const Color(0xFF0F5A3E);
    }
  }

  void _saveEdits() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Name is required!")),
      );
      return;
    }

    final updated = {
      "id": _currentAnimal["id"],
      "name": name,
      "type": _selectedType,
      "breed": _breedController.text.trim().isEmpty ? "Unknown" : _breedController.text.trim(),
      "age": _ageController.text.trim().isEmpty ? "Unknown" : _ageController.text.trim(),
      "weight": _weightController.text.trim().isEmpty ? "Unknown" : _weightController.text.trim(),
      "location": _locationController.text.trim().isEmpty ? "Barn A" : _locationController.text.trim(),
      "status": _selectedStatus,
      "img": _imageUrlController.text.trim().isNotEmpty
          ? _imageUrlController.text.trim()
          : (_typeImages[_selectedType] ?? _typeImages["Cattle"]),
      "lastCheckup": _currentAnimal["lastCheckup"] ?? "Just updated"
    };

    await LivestockStorageService.updateAnimal(updated);
    widget.onDataChanged();

    setState(() {
      _currentAnimal = updated;
      _isEditing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${updated["name"]} details updated successfully!"),
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
          title: const Text("Delete Animal"),
          content: Text("Are you sure you want to delete ${_currentAnimal["name"]}?\nThis will also delete all associated health and vaccination records."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context); // close confirm dialog
                Navigator.pop(this.context); // close bottom sheet
                
                await LivestockStorageService.deleteAnimal(_currentAnimal["id"]);
                widget.onDataChanged();

                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content: Text("${_currentAnimal["name"]} deleted successfully."),
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
    final status = _currentAnimal["status"] ?? "Healthy";
    final cleanStatus = (status == "Attention" || status == "Needs Attention") ? "Needs Attention" : status;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Animal Details",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Animal Image with status badge overlay
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                _currentAnimal["img"] ?? "",
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 180,
                  color: Colors.grey[200],
                  alignment: Alignment.center,
                  child: const Icon(Icons.pets, size: 60, color: Colors.grey),
                ),
              ),
            ),
            // Status tag
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusBg(status).withOpacity(0.95),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  cleanStatus,
                  style: TextStyle(
                    color: _getStatusTextColor(status),
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Animal Name & Breed
        Text(
          _currentAnimal["name"] ?? "",
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
        ),
        const SizedBox(height: 4),
        Text(
          _currentAnimal["breed"] ?? "Unknown Breed",
          style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),

        // Metadata grid
        Row(
          children: [
            Expanded(child: _buildDetailCard("Type", _currentAnimal["type"] ?? "Cattle", Icons.category_outlined)),
            const SizedBox(width: 12),
            Expanded(child: _buildDetailCard("Age", _currentAnimal["age"] ?? "Unknown", Icons.calendar_today_outlined)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildDetailCard("Weight", _currentAnimal["weight"] ?? "Unknown", Icons.monitor_weight_outlined)),
            const SizedBox(width: 12),
            Expanded(child: _buildDetailCard("Location/Pen", _currentAnimal["location"] ?? "Unknown", Icons.location_on_outlined)),
          ],
        ),
        const SizedBox(height: 16),

        // Last Checkup info text
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              const Icon(Icons.healing_outlined, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                "Last checkup: ${_currentAnimal["lastCheckup"] ?? "Not recorded"}",
                style: const TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Action Buttons Row
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _confirmDelete,
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                label: const Text("Delete Animal", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
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
                label: const Text("Edit Details", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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

  Widget _buildDetailCard(String title, String val, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[500]),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 10.5, color: Colors.grey, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(val, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
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
                  _initFields(); // Reset edit fields to current animal info
                });
              },
            ),
            const Text(
              "Edit Animal Details",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Animal Photo Edit
        const Text(
          "Animal Photo",
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Current photo preview
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                _imageUrlController.text.trim().isNotEmpty 
                    ? _imageUrlController.text.trim()
                    : (_typeImages[_selectedType] ?? _currentAnimal["img"] ?? ""),
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 80,
                  height: 80,
                  color: const Color(0xFFF3F4F6),
                  alignment: Alignment.center,
                  child: const Icon(Icons.pets, color: Colors.grey, size: 36),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      // Set a mock new animal picture to simulate upload
                      final mockPics = [
                        "https://images.unsplash.com/photo-1596733430284-f7437764b1a9?w=500&q=80", // cow 2
                        "https://images.unsplash.com/photo-1516467508483-a7212febe31a?w=500&q=80", // pig
                        "https://images.unsplash.com/photo-1545468830-4e1b09b53fde?w=500&q=80", // horse 2
                        "https://images.unsplash.com/photo-1532467411038-57680e3dc0f1?w=500&q=80", // goat 2
                        "https://images.unsplash.com/photo-1589923188900-85dae523342b?w=500&q=80", // sheep 2
                      ];
                      final nextPic = mockPics[(DateTime.now().millisecond) % mockPics.length];
                      setState(() {
                        _imageUrlController.text = nextPic;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Mock photo uploaded successfully!"),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    icon: const Icon(Icons.upload_rounded, color: Color(0xFF22C55E), size: 16),
                    label: const Text(
                      "Upload New Photo",
                      style: TextStyle(color: Color(0xFF22C55E), fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF22C55E)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Packs preloaded pictures or enter URL below.",
                    style: TextStyle(fontSize: 10.5, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Custom URL textfield
        TextField(
          controller: _imageUrlController,
          onChanged: (val) {
            // Trigger state reload to show the preview update instantly
            setState(() {});
          },
          decoration: InputDecoration(
            hintText: "Enter custom photo URL",
            labelText: "Photo URL",
            labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF22C55E), width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Name Field
        const Text("Name *", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 6),
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            hintText: "e.g., Bella",
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF22C55E), width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Type Selector Dropdown
        const Text("Type *", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedType,
              isExpanded: true,
              items: ["Cattle", "Sheep", "Goats", "Pigs", "Chickens", "Horses"]
                  .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedType = value;
                  });
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Breed Field
        const Text("Breed", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 6),
        TextField(
          controller: _breedController,
          decoration: InputDecoration(
            hintText: "e.g., Holstein Friesian",
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF22C55E), width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Row for Age & Weight
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Age", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _ageController,
                    decoration: InputDecoration(
                      hintText: "e.g., 4 years",
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF22C55E), width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Weight", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _weightController,
                    decoration: InputDecoration(
                      hintText: "e.g., 650 kg",
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF22C55E), width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Location/Pen Field
        const Text("Location/Pen", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 6),
        TextField(
          controller: _locationController,
          decoration: InputDecoration(
            hintText: "e.g., North Pasture",
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF22C55E), width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Status Field Dropdown
        const Text("Health Status *", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
              items: ["Healthy", "Attention", "Critical"]
                  .map((status) => DropdownMenuItem(
                        value: status,
                        child: Text(status == "Attention" ? "Needs Attention" : status),
                      ))
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

        // Save and Cancel buttons Row
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _isEditing = false;
                    _initFields(); // Reset edit fields to current animal info
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
