import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ad_service.dart';
import 'course_detail_screen.dart';
import 'upload_video_screen.dart';

class LmsScreen extends StatefulWidget {
  const LmsScreen({Key? key}) : super(key: key);

  @override
  State<LmsScreen> createState() => _LmsScreenState();
}

class _LmsScreenState extends State<LmsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';

  // Profile data
  String? _profileName;
  String? _profileCrop;
  String? _profileLocation;

  final List<String> _categories = [
    'All',
    'Soil Health',
    'Irrigation',
    'Organic Farming',
    'Pest Control',
    'Crop Management',
    'Schemes'
  ];

  // Stateful list of courses (uses Course and Module from course_detail_screen.dart)
  final List<Course> _courses = [
    Course(
      title: "Soil Preparation Basics",
      instructor: "Dr. Anil Kumar",
      description: "Learn the fundamentals of soil preparation for maximum crop yield.",
      rating: 4.8,
      students: "2.5K",
      modules: 8,
      duration: "20 min",
      level: "Beginner",
      category: "Soil Health",
      imageUrl: "https://images.unsplash.com/photo-1592417817098-8f3d6eb19675?w=500&q=80",
      modulesList: [
        Module(
          title: "Understanding Soil Types",
          duration: "20 min",
          description: "This module covers important aspects of understanding soil types. You'll learn practical techniques and best practices that you can apply directly to your farm.",
          objectives: [
            "Fundamental concepts and principles",
            "Hands-on practical applications",
            "Common challenges and solutions",
            "Best practices from experienced farmers"
          ],
        ),
        Module(
          title: "Soil Composition Analysis",
          duration: "25 min",
          description: "Deep dive into sand, silt, and clay ratios and how they affect soil quality.",
          objectives: [
            "Textural class triangle",
            "Soil jar test instructions",
            "Nutrient absorption capacities"
          ],
        ),
        Module(
          title: "pH Levels & Nutrients",
          duration: "22 min",
          description: "Learn how pH levels dictate nutrient availability and how to adjust them.",
          objectives: [
            "Measuring soil pH",
            "Liming and sulfur applications",
            "Essential macronutrients"
          ],
        ),
        Module(
          title: "Testing and Analysis",
          duration: "28 min",
          description: "A step-by-step walkthrough of collection and laboratory soil test report parsing.",
          objectives: [
            "How to take clean soil samples",
            "Reading nutrient analysis reports"
          ],
        ),
        Module(
          title: "Soil Quality Improvement",
          duration: "24 min",
          description: "Methods to restore depleted soils using green manure, crop residues, and biochar.",
          objectives: [
            "Adding organic matter",
            "Cover cropping basics"
          ],
        ),
        Module(
          title: "Preparation Techniques",
          duration: "26 min",
          description: "Tillage systems compared: zero-till, minimum tillage, and deep tillage.",
          objectives: [
            "Selecting tillage tools",
            "Compaction management"
          ],
        ),
        Module(
          title: "Tilling & Plowing Best Practices",
          duration: "23 min",
          description: "Safety, timing, and environmental impacts of mechanical cultivation.",
          objectives: [
            "Erosion prevention",
            "Timing tillage with moisture"
          ],
        ),
        Module(
          title: "Quiz: Soil Fundamentals",
          duration: "20 min",
          description: "Assess your understanding of modules 1 through 7.",
          objectives: [
            "Multiple choice test",
            "Case study review"
          ],
        ),
      ],
    ),
    Course(
      title: "Modern Irrigation Techniques",
      instructor: "Er. Rajesh Patel",
      description: "Explore drip and sprinkler irrigation setups for efficient water utilization.",
      rating: 4.7,
      students: "1.8K",
      modules: 5,
      duration: "35 min",
      level: "Intermediate",
      category: "Irrigation",
      imageUrl: "https://images.unsplash.com/photo-1563514223300-b3b3a3a854a2?w=500&q=80",
      modulesList: [
        Module(
          title: "Overview of Irrigation Systems",
          duration: "15 min",
          description: "Comparative analysis of surface, sprinkler, and drip irrigation setups.",
          objectives: [
            "Efficiency ratios compared",
            "Water source requirements"
          ],
        ),
        Module(
          title: "Designing Drip Irrigation",
          duration: "30 min",
          description: "Mainline sizing, emitter spacing, and pressure regulators selection guidelines.",
          objectives: [
            "Calculating flow rates",
            "Layout diagrams"
          ],
        ),
        Module(
          title: "Sprinkler Systems Installation",
          duration: "25 min",
          description: "Nozzle selections, spacing calculations, and automated timers setup.",
          objectives: [
            "Coverage uniformity",
            "Wind distortion correction"
          ],
        ),
        Module(
          title: "Water Conservation Strategies",
          duration: "20 min",
          description: "Mulching, alternate wetting and drying, and soil moisture sensor controls.",
          objectives: [
            "AWD in paddy fields",
            "Scheduling based on sensors"
          ],
        ),
        Module(
          title: "Maintenance & Diagnostics",
          duration: "18 min",
          description: "Emitter clogging remedies, pump repairs, and winterizing procedures.",
          objectives: [
            "Acid flushing filters",
            "Pressure testing"
          ],
        ),
      ],
    ),
    Course(
      title: "Government Schemes & Subsidies",
      instructor: "Anita Verma",
      description: "Understand and access financial aid, crop insurance, and equipment subsidies.",
      rating: 4.6,
      students: "3.5K",
      modules: 4,
      duration: "25 min",
      level: "Beginner",
      category: "Schemes",
      imageUrl: "https://images.unsplash.com/photo-1542601906990-b4d3fb778b09?w=500&q=80",
      modulesList: [
        Module(
          title: "Introduction to Agrarian Subsidies",
          duration: "20 min",
          description: "Overview of national and state schemes supporting smallholder farmers.",
          objectives: [
            "Eligibility criteria",
            "Where to apply"
          ],
        ),
        Module(
          title: "Crop Insurance Policy Walkthrough",
          duration: "25 min",
          description: "PM Fasal Bima Yojana details, premiums, and claims processing timelines.",
          objectives: [
            "Claim documents list",
            "Assessing yield loss"
          ],
        ),
        Module(
          title: "Credit & Low-interest Loans",
          duration: "30 min",
          description: "Kisan Credit Card (KCC) benefits, interest subvention, and repayment.",
          objectives: [
            "Applying for KCC",
            "Scale of finance"
          ],
        ),
        Module(
          title: "Equipment Subsidy Application Guide",
          duration: "15 min",
          description: "How to purchase tractors and custom equipment with up to 50% subsidy.",
          objectives: [
            "SMAM portal registration",
            "Uploading invoice details"
          ],
        ),
      ],
    ),
    Course(
      title: "Organic Composting Guide",
      instructor: "Dr. S. Ranganathan",
      description: "Master the science of making nutrient-rich vermicompost and compost teas.",
      rating: 4.9,
      students: "4.2K",
      modules: 4,
      duration: "18 min",
      level: "Beginner",
      category: "Organic Farming",
      imageUrl: "https://images.unsplash.com/photo-1589923188900-85dae44094ad?w=500&q=80",
      modulesList: [
        Module(
          title: "Vermicompost Principles",
          duration: "12 min",
          description: "Harnessing earthworms (Eisenia fetida) to convert organic residue into compost.",
          objectives: [
            "Worm bin conditions",
            "Feed materials"
          ],
        ),
        Module(
          title: "Raw Material Selection",
          duration: "18 min",
          description: "Carbon to Nitrogen (C:N) ratios balancing: browns and greens.",
          objectives: [
            "Ideal C:N ratio",
            "Avoiding pests"
          ],
        ),
        Module(
          title: "Compost Pile Construction",
          duration: "24 min",
          description: "Piling layers, windrows, turning schedules, and moisture monitoring.",
          objectives: [
            "Aerobic conditions",
            "Temperature checkpoints"
          ],
        ),
        Module(
          title: "Curing & Usage",
          duration: "15 min",
          description: "Determining when compost is mature, sieving, storage, and application rates.",
          objectives: [
            "Maturity indicators",
            "Direct field application"
          ],
        ),
      ],
    ),
    Course(
      title: "Eco-friendly Pest Control",
      instructor: "Prof. Meera Sen",
      description: "Deter whiteflies, aphids, and nematodes naturally using organic biological controls.",
      rating: 4.5,
      students: "1.2K",
      modules: 4,
      duration: "45 min",
      level: "Intermediate",
      category: "Pest Control",
      imageUrl: "https://images.unsplash.com/photo-1463123081488-729f555ee3f2?w=500&q=80",
      modulesList: [
        Module(
          title: "Introduction to Integrated Pest Management",
          duration: "20 min",
          description: "Understanding insect life cycles, economic injury levels, and thresholds.",
          objectives: [
            "IPM pyramid",
            "Monitoring techniques"
          ],
        ),
        Module(
          title: "Natural Repellents & Trap Crops",
          duration: "22 min",
          description: "Using castor, marigold, and basil trap plants to safeguard cash crops.",
          objectives: [
            "Border planting setup",
            "Repellent companion spacing"
          ],
        ),
        Module(
          title: "Biological Control Agents",
          duration: "25 min",
          description: "Releasing ladybugs, trichogramma wasps, and praying mantises against aphids/borers.",
          objectives: [
            "Sourcing biologicals",
            "Optimal release times"
          ],
        ),
        Module(
          title: "Organic Pesticide Preparation",
          duration: "18 min",
          description: "Brewing neem seed kernel extract (NSKE) and organic garlic sprays.",
          objectives: [
            "Step-by-step recipes",
            "Safe application rates"
          ],
        ),
      ],
    ),
    Course(
      title: "High-yield Sugarcane Growth",
      instructor: "Dr. Suresh Nair",
      description: "Advanced practices in row spacing, timing, and fertilizer schedules for sugarcane.",
      rating: 4.8,
      students: "950",
      modules: 4,
      duration: "50 min",
      level: "Expert",
      category: "Crop Management",
      imageUrl: "https://images.unsplash.com/photo-1500937386664-56d159f87b81?w=500&q=80",
      modulesList: [
        Module(
          title: "Land Selection & Preparation",
          duration: "30 min",
          description: "Deep plowing, subsoiling, and furrow layout styles for sugarcane setts.",
          objectives: [
            "Optimal soil depth",
            "Spacing methods"
          ],
        ),
        Module(
          title: "Seed Piece Selection & Planting",
          duration: "45 min",
          description: "Choosing healthy 2-3 budded setts, treating with fungicide, and planting.",
          objectives: [
            "Seed rates",
            "Setts treatment guidelines"
          ],
        ),
        Module(
          title: "Sugarcane Fertilizer Management",
          duration: "35 min",
          description: "NPK schedules, micro-nutrient application, and trash mulching benefits.",
          objectives: [
            "Urea timing",
            "Zinc/Iron deficiencies"
          ],
        ),
        Module(
          title: "Harvesting Timing & Techniques",
          duration: "28 min",
          description: "Maturity indicators, hand cutting vs mechanical harvest, and ratoon management.",
          objectives: [
            "Brix meter reading",
            "Stubble shaving"
          ],
        ),
      ],
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Course> get _filteredCourses {
    return _courses.where((course) {
      final matchesCategory = _selectedCategory == 'All' || course.category == _selectedCategory;
      final matchesSearch = course.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          course.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          course.instructor.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  void _openProfileDialog() {
    final nameCtrl = TextEditingController(text: _profileName);
    final cropCtrl = TextEditingController(text: _profileCrop);
    final locCtrl = TextEditingController(text: _profileLocation);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create / Edit Profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Full Name *',
                    hintText: 'e.g. Jayasurya K',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: cropCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Main Crop *',
                    hintText: 'e.g. Wheat, Tomato',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: locCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Location / District *',
                    hintText: 'e.g. Coimbatore, Tamil Nadu',
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
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty || cropCtrl.text.trim().isEmpty || locCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill in all fields')),
                  );
                  return;
                }
                setState(() {
                  _profileName = nameCtrl.text.trim();
                  _profileCrop = cropCtrl.text.trim();
                  _profileLocation = locCtrl.text.trim();
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile completed successfully!')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF22C55E),
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Save Profile',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _checkAndOpenCourse(Course course) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = "${now.year}-${now.month}-${now.day}";

    final savedDate = prefs.getString('lms_unlocked_date') ?? '';
    List<String> unlockedCourses = prefs.getStringList('lms_unlocked_courses') ?? [];

    if (savedDate != today) {
      unlockedCourses = [course.title];
      await prefs.setString('lms_unlocked_date', today);
      await prefs.setStringList('lms_unlocked_courses', unlockedCourses);
      _navigateToCourseDetail(course);
    } else {
      if (unlockedCourses.contains(course.title)) {
        _navigateToCourseDetail(course);
      } else {
        _showUnlockCourseDialog(course, unlockedCourses, today);
      }
    }
  }

  void _navigateToCourseDetail(Course course) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CourseDetailScreen(
          course: course,
          profileName: _profileName,
        ),
      ),
    );
  }

  void _showUnlockCourseDialog(Course course, List<String> unlockedCourses, String today) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Unlock Course"),
        content: Text("You have already accessed a course today. Watch a quick sponsored video to unlock '${course.title}'!"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              AdService.showRewardedAd(context, () async {
                final prefs = await SharedPreferences.getInstance();
                unlockedCourses.add(course.title);
                await prefs.setStringList('lms_unlocked_courses', unlockedCourses);
                if (mounted) {
                  _navigateToCourseDetail(course);
                }
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF22C55E),
            ),
            child: const Text("Watch Ad", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final headerBg = const Color(0xFF1E3A5F);
    final primaryGreen = const Color(0xFF22C55E);
    final isProfileCompleted = _profileName != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. ACADEMY HEADER
            Container(
              color: headerBg,
              padding: const EdgeInsets.fromLTRB(16, 48, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: const [
                      Text(
                        '🎓',
                        style: TextStyle(fontSize: 28),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'AgriGrow Learning Academy',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Learn farming at your own pace with expert guidance',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _openProfileDialog,
                          icon: Icon(
                            isProfileCompleted ? Icons.check_circle : Icons.person_add,
                            color: Colors.white,
                            size: 18,
                          ),
                          label: Text(
                            isProfileCompleted ? 'Edit Profile' : 'Complete Profile',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryGreen,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => UploadVideoScreen(
                                  onCourseUploaded: (newCourse) {
                                    setState(() {
                                      _courses.insert(0, newCourse);
                                    });
                                  },
                                ),
                              ),
                            );
                          },
                          icon: Icon(Icons.cloud_upload_outlined, color: headerBg, size: 18),
                          label: Text(
                            'Upload Video',
                            style: TextStyle(
                              color: headerBg,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (isProfileCompleted) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Color(0xFF4ADE80), size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Profile Active: $_profileName ($_profileCrop - $_profileLocation)',
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // 2. SEARCH BAR & CATEGORIES SECTION
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Colors.grey),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              hintText: 'Search courses...',
                              hintStyle: TextStyle(color: Colors.grey),
                              border: InputBorder.none,
                            ),
                            onChanged: (val) {
                              setState(() {
                                _searchQuery = val;
                              });
                            },
                          ),
                        ),
                        if (_searchQuery.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    height: 38,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final cat = _categories[index];
                        final isSelected = _selectedCategory == cat;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCategory = cat;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: isSelected ? headerBg : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? headerBg : Colors.grey[200]!,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                cat,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : const Color(0xFF475569),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // 3. COURSES LIST GRID
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        '📖',
                        style: TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'All Courses (${_filteredCourses.length})',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: headerBg,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _filteredCourses.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Text(
                              'No courses found matching search criteria.',
                              style: TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _filteredCourses.length,
                          itemBuilder: (context, index) {
                            final course = _filteredCourses[index];
                            return GestureDetector(
                              onTap: () => _checkAndOpenCourse(course),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.02),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                          child: Image.network(
                                            course.imageUrl,
                                            height: 180,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Container(
                                                height: 180,
                                                width: double.infinity,
                                                color: headerBg,
                                                child: const Icon(Icons.school, color: Colors.white, size: 48),
                                              );
                                            },
                                          ),
                                        ),
                                        Positioned(
                                          top: 12,
                                          right: 12,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: headerBg.withOpacity(0.9),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              course.level,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 12,
                                          right: 12,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(0.75),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.play_circle_fill, color: Colors.white, size: 12),
                                                const SizedBox(width: 4),
                                                Text(
                                                  course.duration,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            course.title,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1E293B),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              const Text('👨‍🏫', style: TextStyle(fontSize: 13)),
                                              const SizedBox(width: 4),
                                              Text(
                                                course.instructor,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            course.description,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey[600],
                                              height: 1.4,
                                            ),
                                          ),
                                          const SizedBox(height: 12),

                                          Row(
                                            children: [
                                              const Icon(Icons.star, color: Colors.amber, size: 16),
                                              const SizedBox(width: 4),
                                              Text(
                                                course.rating.toString(),
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              const Icon(Icons.people_outline, color: Colors.grey, size: 16),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${course.students} students',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Divider(color: Colors.grey[200]),
                                          const SizedBox(height: 8),

                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                '${course.modules} Modules',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                  color: headerBg,
                                                ),
                                              ),
                                              Text(
                                                course.category,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Why Choose AgriGrow\nLMS?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: headerBg,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildLmsFeatureCard(
                    icon: Icons.videocam_outlined,
                    title: 'Video Learning',
                    description: 'Expert-led video courses with step-by-step guidance',
                  ),
                  _buildLmsFeatureCard(
                    icon: Icons.access_time,
                    title: 'Learn at Your Pace',
                    description: 'Flexible scheduling - learn whenever you want',
                  ),
                  _buildLmsFeatureCard(
                    icon: Icons.bar_chart,
                    title: 'Assessments',
                    description: 'Quiz and practical assignments after each module',
                  ),
                  _buildLmsFeatureCard(
                    icon: Icons.bookmark_outline,
                    title: 'Certificates',
                    description: 'Earn recognized certificates on completion',
                  ),
                  _buildLmsFeatureCard(
                    icon: Icons.language,
                    title: 'Multilingual',
                    description: 'Available in regional languages',
                  ),
                  _buildLmsFeatureCard(
                    icon: Icons.download,
                    title: 'Offline Access',
                    description: 'Download courses for offline learning',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildLmsFeatureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: const Color(0xFF1E3A5F),
            size: 36,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF475569),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
