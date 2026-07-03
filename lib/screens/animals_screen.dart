import 'package:flutter/material.dart';
import '../services/livestock_storage.dart';
import 'animal_detail_sheet.dart';

class AnimalsScreen extends StatefulWidget {
  final bool openAddForm;
  final bool hideBackButton;
  const AnimalsScreen({
    Key? key,
    this.openAddForm = false,
    this.hideBackButton = false,
  }) : super(key: key);

  @override
  State<AnimalsScreen> createState() => _AnimalsScreenState();
}

class _AnimalsScreenState extends State<AnimalsScreen> {
  List<Map<String, dynamic>> _allAnimals = [];
  List<Map<String, dynamic>> _filteredAnimals = [];
  bool _isLoading = true;

  String _searchQuery = "";
  String _selectedCategory = "All";
  String _selectedStatus = "All Status";
  bool _isGridView = true;

  final List<String> _categories = ["All", "Cattle", "Sheep", "Goats", "Pigs", "Chickens", "Horses"];
  final List<String> _statuses = ["All Status", "Healthy", "Attention", "Critical"];

  // Default images map based on animal type
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
    _loadAnimals();
    if (widget.openAddForm) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showAddAnimalSheet();
      });
    }
  }

  Future<void> _loadAnimals() async {
    setState(() {
      _isLoading = true;
    });
    final animals = await LivestockStorageService.getAnimals();
    setState(() {
      _allAnimals = animals;
      _isLoading = false;
      _applyFilters();
    });
  }

  void _applyFilters() {
    List<Map<String, dynamic>> temp = List.from(_allAnimals);

    // Search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      temp = temp.where((animal) {
        final name = (animal["name"] ?? "").toString().toLowerCase();
        final breed = (animal["breed"] ?? "").toString().toLowerCase();
        return name.contains(query) || breed.contains(query);
      }).toList();
    }

    // Category filter
    if (_selectedCategory != "All") {
      temp = temp.where((animal) {
        final type = (animal["type"] ?? "").toString().toLowerCase();
        return type == _selectedCategory.toLowerCase();
      }).toList();
    }

    // Status filter
    if (_selectedStatus != "All Status") {
      final cleanStatus = _selectedStatus == "Attention" ? "attention" : _selectedStatus.toLowerCase();
      temp = temp.where((animal) {
        final status = (animal["status"] ?? "").toString().toLowerCase();
        return status == cleanStatus;
      }).toList();
    }

    setState(() {
      _filteredAnimals = temp;
    });
  }

  void _showAddAnimalSheet() {
    final nameController = TextEditingController();
    final breedController = TextEditingController();
    final ageController = TextEditingController();
    final weightController = TextEditingController();
    final locationController = TextEditingController();
    String selectedType = "Cattle";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              "Add New Animal",
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Enter the details of your new animal below.",
                              style: TextStyle(fontSize: 13, color: Colors.grey),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Animal Photo Selection Mockup
                    const Text(
                      "Animal Photo",
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFD1D5DB),
                              style: BorderStyle.solid,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.add_photo_alternate_outlined, color: Colors.grey),
                              SizedBox(height: 4),
                              Text("Add Photo", style: TextStyle(fontSize: 10, color: Colors.grey)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Camera selected. Loading library... (Mock)")),
                                );
                              },
                              icon: const Icon(Icons.upload_rounded, color: Color(0xFF22C55E), size: 16),
                              label: const Text(
                                "Upload Photo",
                                style: TextStyle(color: Color(0xFF22C55E), fontWeight: FontWeight.bold),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF22C55E)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              "JPG, PNG or WebP. Max 5MB.",
                              style: TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Name Field
                    const Text("Name *", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameController,
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

                    // Type Dropdown
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
                          value: selectedType,
                          isExpanded: true,
                          items: ["Cattle", "Sheep", "Goats", "Pigs", "Chickens", "Horses"]
                              .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setSheetState(() {
                                selectedType = value;
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
                      controller: breedController,
                      decoration: InputDecoration(
                        hintText: "e.g., Holstein",
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
                                controller: ageController,
                                decoration: InputDecoration(
                                  hintText: "e.g., 2 years",
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
                                controller: weightController,
                                decoration: InputDecoration(
                                  hintText: "e.g., 450 kg",
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
                      controller: locationController,
                      decoration: InputDecoration(
                        hintText: "e.g., Barn A",
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFF22C55E), width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Actions buttons Row
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
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
                            onPressed: () async {
                              final name = nameController.text.trim();
                              if (name.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Name is required!")),
                                );
                                return;
                              }

                              final newAnimal = {
                                "name": name,
                                "type": selectedType,
                                "breed": breedController.text.trim().isEmpty ? "Unknown" : breedController.text.trim(),
                                "age": ageController.text.trim().isEmpty ? "Unknown" : ageController.text.trim(),
                                "weight": weightController.text.trim().isEmpty ? "Unknown" : weightController.text.trim(),
                                "location": locationController.text.trim().isEmpty ? "Barn A" : locationController.text.trim(),
                                "status": "Healthy", // Default new animal is Healthy
                                "img": _typeImages[selectedType] ?? _typeImages["Cattle"],
                                "lastCheckup": "Just added"
                              };

                              await LivestockStorageService.addAnimal(newAnimal);
                              Navigator.pop(context); // Close sheet
                              _loadAnimals(); // Refresh list

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("$name added successfully!"),
                                  backgroundColor: const Color(0xFF22C55E),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF22C55E),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text("Add Animal", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar/Header row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  if (!widget.hideBackButton) ...[
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Color(0xFF22C55E)),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.pets, color: Color(0xFF22C55E), size: 24),
                            SizedBox(width: 8),
                            Text(
                              "Animals",
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          "Manage and monitor all your livestock",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _showAddAnimalSheet,
                    icon: const Icon(Icons.add, color: Colors.white, size: 16),
                    label: const Text("Add Animal", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22C55E),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
            
            // Search and grid/list toggles
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                          _applyFilters();
                        });
                      },
                      decoration: InputDecoration(
                        hintText: "Search animals by name or breed...",
                        hintStyle: const TextStyle(fontSize: 13),
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        fillColor: Colors.white,
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Grid View Toggle
                  Container(
                    decoration: BoxDecoration(
                      color: _isGridView ? const Color(0xFF22C55E) : Colors.white,
                      border: Border.all(color: const Color(0xFF22C55E)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.grid_view_rounded, color: _isGridView ? Colors.white : const Color(0xFF22C55E)),
                      onPressed: () {
                        setState(() {
                          _isGridView = true;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 6),
                  // List View Toggle
                  Container(
                    decoration: BoxDecoration(
                      color: !_isGridView ? const Color(0xFF22C55E) : Colors.white,
                      border: Border.all(color: const Color(0xFF22C55E)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.view_list_rounded, color: !_isGridView ? Colors.white : const Color(0xFF22C55E)),
                      onPressed: () {
                        setState(() {
                          _isGridView = false;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Horizontal filters list
            _buildCategoryFilters(),
            _buildStatusFilters(),

            // Animals count text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Showing ${_filteredAnimals.length} of ${_allAnimals.length} animals",
                  style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            // Animals list body
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF22C55E)))
                  : _filteredAnimals.isEmpty
                      ? const Center(child: Text("No animals found matching filters."))
                      : _isGridView
                          ? _buildAnimalsGrid()
                          : _buildAnimalsList(),
            ),
          ],
        ),
      ),
    );
  }

  // Horizontal category list builder
  Widget _buildCategoryFilters() {
    return Container(
      height: 38,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = cat == _selectedCategory;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                cat,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 12.5,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedCategory = cat;
                    _applyFilters();
                  });
                }
              },
              selectedColor: const Color(0xFF22C55E),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: isSelected ? Colors.transparent : const Color(0xFFE5E7EB)),
              ),
            ),
          );
        },
      ),
    );
  }

  // Horizontal status list builder
  Widget _buildStatusFilters() {
    return Container(
      height: 38,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _statuses.length,
        itemBuilder: (context, index) {
          final status = _statuses[index];
          final isSelected = status == _selectedStatus;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                status,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 12.5,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedStatus = status;
                    _applyFilters();
                  });
                }
              },
              selectedColor: const Color(0xFF22C55E),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: isSelected ? Colors.transparent : const Color(0xFFE5E7EB)),
              ),
            ),
          );
        },
      ),
    );
  }

  // Grid view builder
  Widget _buildAnimalsGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.74,
      ),
      itemCount: _filteredAnimals.length,
      itemBuilder: (context, index) {
        final animal = _filteredAnimals[index];
        return _buildAnimalCard(animal);
      },
    );
  }

  // List view builder
  Widget _buildAnimalsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredAnimals.length,
      itemBuilder: (context, index) {
        final animal = _filteredAnimals[index];
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            onTap: () => showAnimalDetailSheet(context, animal, _loadAnimals),
            leading: CircleAvatar(
              backgroundImage: NetworkImage(animal["img"] ?? ""),
              radius: 24,
            ),
            title: Text(animal["name"] ?? "", style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("${animal["breed"]} • ${animal["location"]}"),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusBg(animal["status"]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                animal["status"] ?? "Healthy",
                style: TextStyle(
                  fontSize: 11,
                  color: _getStatusText(animal["status"]),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Animal card builder helper
  Widget _buildAnimalCard(Map<String, dynamic> animal) {
    final status = animal["status"] ?? "Healthy";
    final isHealthy = status.toString().toLowerCase() == "healthy";
    final isAttention = status.toString().toLowerCase() == "attention";
    
    Color statusBg = const Color(0xFFE8F5E9);
    Color statusTextColor = const Color(0xFF1B4332);
    if (isAttention) {
      statusBg = const Color(0xFFFFFBEB);
      statusTextColor = const Color(0xFFD97706);
    } else if (status.toString().toLowerCase() == "critical") {
      statusBg = const Color(0xFFFFEBEE);
      statusTextColor = const Color(0xFFB71C1C);
    }

    return InkWell(
      onTap: () => showAnimalDetailSheet(context, animal, _loadAnimals),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image and status tag
          Expanded(
            flex: 6,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Image.network(
                    animal["img"] ?? "",
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.pets, color: Colors.grey, size: 40),
                    ),
                  ),
                ),
                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.0),
                        Colors.black.withOpacity(0.5),
                      ],
                    ),
                  ),
                ),
                // Status tag
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusBg.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status == "Attention" ? "Needs Attention" : status,
                      style: TextStyle(
                        color: statusTextColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
                // Name & Breed overlay
                Positioned(
                  bottom: 10,
                  left: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        animal["name"] ?? "",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        animal["breed"] ?? "",
                        style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Animal details (Age, Weight, Location, Checkup)
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Age", style: TextStyle(fontSize: 10, color: Colors.grey)),
                          const SizedBox(height: 2),
                          Text(
                            animal["age"] ?? "Unknown",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Weight", style: TextStyle(fontSize: 10, color: Colors.grey)),
                          const SizedBox(height: 2),
                          Text(
                            animal["weight"] ?? "Unknown",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          animal["location"] ?? "Unknown",
                          style: const TextStyle(fontSize: 11, color: Colors.black87),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  Text(
                    "Last checkup: ${animal["lastCheckup"]}",
                    style: const TextStyle(fontSize: 10.5, color: Colors.grey, fontStyle: FontStyle.italic),
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

  // Helper colors for List View status badges
  Color _getStatusBg(String? status) {
    switch (status?.toLowerCase()) {
      case "healthy":
        return const Color(0xFFE8F5E9);
      case "attention":
        return const Color(0xFFFFFBEB);
      case "critical":
        return const Color(0xFFFFEBEE);
      default:
        return const Color(0xFFE8F5E9);
    }
  }

  Color _getStatusText(String? status) {
    switch (status?.toLowerCase()) {
      case "healthy":
        return const Color(0xFF1B4332);
      case "attention":
        return const Color(0xFFD97706);
      case "critical":
        return const Color(0xFFB71C1C);
      default:
        return const Color(0xFF1B4332);
    }
  }
}
