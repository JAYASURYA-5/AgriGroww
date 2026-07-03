import 'package:flutter/material.dart';

import '../models/scheme_item.dart';
import '../services/app_state.dart';
import '../services/scheme_service.dart';
import 'scheme_detail_screen.dart';
import '../services/ad_service.dart';

class SchemeScreen extends StatefulWidget {
  const SchemeScreen({Key? key}) : super(key: key);

  @override
  State<SchemeScreen> createState() => _SchemeScreenState();
}

class _SchemeScreenState extends State<SchemeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _categories = [
    'All',
    'Subsidy',
    'Insurance',
    'Credit',
    'Irrigation',
    'Market',
    'Training',
    'Infrastructure',
    'Sustainability',
    'Agri-Processing',
    'Dairy',
    'Horticulture',
  ];
  String _selectedCategory = 'All';
  bool _loading = true;
  String? _error;
  List<SchemeItem> _schemes = [];
  List<SchemeItem> _filtered = [];

  @override
  void initState() {
    super.initState();
    _loadSchemes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSchemes() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final schemes = await SchemeService().fetchSchemes();
      schemes.sort((a, b) {
        if (a.priority == b.priority)
          return b.launchYear.compareTo(a.launchYear);
        return a.priority ? -1 : 1;
      });
      setState(() {
        _schemes = schemes;
        _filtered = schemes;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _schemes = [];
        _filtered = [];
        _loading = false;
      });
    }
  }

  void _applyFilters() {
    final q = _searchController.text.trim().toLowerCase();
    setState(() {
      _filtered = _schemes.where((scheme) {
        final matchesCategory = _selectedCategory == 'All' ||
            scheme.category.toLowerCase() == _selectedCategory.toLowerCase();
        final matchesQuery = q.isEmpty ||
            scheme.title.toLowerCase().contains(q) ||
            scheme.description.toLowerCase().contains(q) ||
            scheme.subtitle.toLowerCase().contains(q);
        return matchesCategory && matchesQuery;
      }).toList();
    });
  }

  String _buildEligibilityHint() {
    final location = AppState().currentUser?['location']?.toString();
    if (location != null && location.isNotEmpty) {
      return 'Based on your registered location ($location), these schemes are especially relevant for farmers in your region.';
    }
    return 'Find live agriculture schemes useful for farmers, producers, and rural enterprises.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schemes'),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Live Agriculture Schemes',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  _buildEligibilityHint(),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),

              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Search live schemes',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (_) => _applyFilters(),
                ),
                const SizedBox(height: 10),
                DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  items: _categories.map((c) {
                    return DropdownMenuItem(value: c, child: Text(c));
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _selectedCategory = value;
                    });
                    _applyFilters();
                  },
                ),
              ],
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Failed to load schemes. Showing available content.\n$_error',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _filtered.length + (_filtered.length ~/ 3),
                    itemBuilder: (context, index) {
                      // Calculate ad spacing (1 ad after every 3 items)
                      if (index > 0 && (index + 1) % 4 == 0) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: AdService.getNativeAdWidget(height: 85),
                        );
                      }
                      
                      final int adCount = index ~/ 4;
                      final schemeIndex = index - adCount;
                      if (schemeIndex >= _filtered.length) return const SizedBox();
                      
                      final scheme = _filtered[schemeIndex];
                      return Column(
                        children: [
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            leading: CircleAvatar(
                              backgroundColor: scheme.priority
                                  ? const Color(0xFF22C55E)
                                  : const Color(0xFF90A4AE),
                              child: Icon(
                                scheme.priority ? Icons.star : Icons.shield,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              scheme.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 6),
                                Text(
                                  scheme.subtitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Updated ${scheme.launchYear}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.65),
                                  ),
                                ),
                              ],
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      SchemeDetailScreen(scheme: scheme),
                                ),
                              );
                            },
                          ),
                          const Divider(height: 1),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
