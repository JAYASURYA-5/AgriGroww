import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/app_state.dart';
import '../services/firebase_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _activeTab = 'Activity';

  Future<void> _pickProfilePhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFF22C55E))),
        );

        String? finalPhotoPath = image.path;
        if (FirebaseService().isAvailable) {
          try {
            finalPhotoPath = await FirebaseService().uploadImage(File(image.path), 'profiles');
          } catch (e) {
            debugPrint('Error uploading profile picture to storage: $e');
          }
        }

        if (mounted) Navigator.pop(context);

        if (finalPhotoPath != null) {
          await AppState().updateCurrentUser({'photo': finalPhotoPath});
          setState(() {});
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile photo updated successfully!'), backgroundColor: Color(0xFF22C55E)),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error picking profile picture: $e');
    }
  }

  void _showEditProfileDialog() {
    final user = AppState().currentUser;
    final nameController = TextEditingController(text: user?['fullName'] ?? '');
    final phoneController = TextEditingController(text: user?['mobile'] ?? '');
    final locationController = TextEditingController(text: user?['location'] ?? '');
    final farmSizeController = TextEditingController(text: user?['farmSize'] ?? '');
    final keyCropsController = TextEditingController(text: user?['keyCrops'] ?? '');
    String selectedGender = user?['gender'] ?? 'Not set';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final textCol = Theme.of(context).colorScheme.onSurface;
            return AlertDialog(
              backgroundColor: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                'Edit Profile',
                style: TextStyle(fontWeight: FontWeight.bold, color: textCol),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Full Name input
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Full Name'),
                    ),
                    const SizedBox(height: 12),
                    // Phone input
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Phone'),
                    ),
                    const SizedBox(height: 12),
                    // Gender selection row
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Gender',
                        style: TextStyle(fontSize: 12, color: textCol.withOpacity(0.6)),
                      ),
                    ),
                    Row(
                      children: ['Male', 'Female', 'Not set'].map((g) {
                        final isSel = selectedGender == g;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0, top: 4.0),
                          child: ChoiceChip(
                            label: Text(g),
                            selected: isSel,
                            onSelected: (selected) {
                              if (selected) {
                                setDialogState(() {
                                  selectedGender = g;
                                });
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    // Location input
                    TextField(
                      controller: locationController,
                      decoration: const InputDecoration(labelText: 'Location'),
                    ),
                    const SizedBox(height: 12),
                    // Farm Size input
                    TextField(
                      controller: farmSizeController,
                      decoration: const InputDecoration(labelText: 'Farm Size (e.g. 5 Acres)'),
                    ),
                    const SizedBox(height: 12),
                    // Key Crops input
                    TextField(
                      controller: keyCropsController,
                      decoration: const InputDecoration(labelText: 'Key Crops (e.g. Rice, Turmeric)'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final updated = {
                      'fullName': nameController.text.trim(),
                      'mobile': phoneController.text.trim(),
                      'gender': selectedGender,
                      'location': locationController.text.trim(),
                      'farmSize': farmSizeController.text.trim().isEmpty ? 'N/A' : farmSizeController.text.trim(),
                      'keyCrops': keyCropsController.text.trim().isEmpty ? 'N/A' : keyCropsController.text.trim(),
                    };
                    await AppState().updateCurrentUser(updated);
                    Navigator.pop(context);
                    setState(() {});
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF22C55E)),
                  child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEA580C)),
            child: const Text('Logout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AppState().logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AppState().currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textCol = Theme.of(context).colorScheme.onSurface;
    final cardBg = Theme.of(context).cardColor;
    final dividerCol = Theme.of(context).dividerColor;

    // Handle profile photo resolving
    final photo = user?['photo']?.toString();
    ImageProvider imgProvider;
    if (photo == null || photo.isEmpty) {
      imgProvider = const NetworkImage('https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=120&q=80');
    } else if (photo.startsWith('http')) {
      imgProvider = NetworkImage(photo);
    } else {
      imgProvider = FileImage(File(photo));
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF111827) : const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textCol),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'My Profile',
          style: TextStyle(color: textCol, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _handleLogout,
            child: const Text(
              'Logout',
              style: TextStyle(
                color: Color(0xFFEA580C),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),

            // Large Profile Photo Box
            Center(
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: _pickProfilePhoto,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF22C55E), width: 3),
                      ),
                      child: CircleAvatar(
                        radius: 54,
                        backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                        backgroundImage: imgProvider,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: _pickProfilePhoto,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFF22C55E),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Name & subtitle
            Text(
              user?['fullName'] ?? 'Google User',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textCol),
            ),
            const SizedBox(height: 4),
            const Text(
              'Your Farm',
              style: TextStyle(fontSize: 14, color: Color(0xFFEA580C), fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Edit Profile Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _showEditProfileDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00FF00), // Vibrant green matching layout
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Edit Profile',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Personal Information Card
            _buildSectionHeader('Personal Information', textCol),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: dividerCol.withOpacity(0.3), width: 1),
                ),
                child: Column(
                  children: [
                    _buildRow(Icons.phone_outlined, 'Phone', user?['mobile'] ?? 'N/A', textCol),
                    Divider(color: dividerCol, height: 24),
                    _buildRow(Icons.person_outline, 'Gender', user?['gender'] ?? 'Not set', textCol),
                    Divider(color: dividerCol, height: 24),
                    _buildRow(Icons.mail_outline, 'Email', user?['email'] ?? 'user@gmail.com', textCol),
                  ],
                ),
              ),
            ),

            // Farm Details Card
            _buildSectionHeader('Farm Details', textCol),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: dividerCol.withOpacity(0.3), width: 1),
                ),
                child: Column(
                  children: [
                    _buildRow(Icons.grid_view_outlined, 'Farm Size', user?['farmSize'] ?? 'N/A', textCol),
                    Divider(color: dividerCol, height: 24),
                    _buildRow(Icons.location_on_outlined, 'Location', user?['location'] ?? 'Tiruppur', textCol),
                    Divider(color: dividerCol, height: 24),
                    _buildRow(Icons.eco_outlined, 'Key Crops', user?['keyCrops'] ?? 'N/A', textCol),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Segmented selector tab
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: ['Activity', 'My Videos', 'Upload History', 'Certificates'].map((tab) {
                    final isActive = _activeTab == tab;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _activeTab = tab;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isActive ? const Color(0xFF00FF00) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              tab,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isActive 
                                    ? Colors.white 
                                    : (isDark ? Colors.grey[400] : Colors.grey[600]),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tab View Body
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _buildTabViewBody(cardBg, textCol, dividerCol),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color textCol) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textCol.withOpacity(0.8)),
        ),
      ),
    );
  }

  Widget _buildRow(IconData icon, String title, String value, Color textCol) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF22C55E), size: 22),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(fontSize: 15, color: textCol.withOpacity(0.7), fontWeight: FontWeight.w500),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(fontSize: 15, color: textCol, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildTabViewBody(Color cardBg, Color textCol, Color dividerCol) {
    if (_activeTab == 'Activity') {
      return Column(
        children: [
          _buildActivityItem(Icons.show_chart, 'Sensor data checked', 'Today, 10:45 AM', cardBg, textCol, dividerCol),
          _buildActivityItem(Icons.pets, 'Added livestock record (Bella)', '2 days ago', cardBg, textCol, dividerCol),
          _buildActivityItem(Icons.check_circle_outline, 'Profile registered successfully', 'Joined AgriGrow', cardBg, textCol, dividerCol),
        ],
      );
    } else {
      // Empty/mock state for other tabs
      return Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: dividerCol.withOpacity(0.3)),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.folder_open, color: const Color(0xFF22C55E).withOpacity(0.5), size: 36),
              const SizedBox(height: 8),
              Text(
                'No ${_activeTab.toLowerCase()} records yet.',
                style: TextStyle(fontSize: 14, color: textCol.withOpacity(0.5)),
              )
            ],
          ),
        ),
      );
    }
  }

  Widget _buildActivityItem(
    IconData icon,
    String title,
    String time,
    Color cardBg,
    Color textCol,
    Color dividerCol,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dividerCol.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFDCFCE7),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF22C55E), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textCol),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(fontSize: 12, color: textCol.withOpacity(0.5)),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
