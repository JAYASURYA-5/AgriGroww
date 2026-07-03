import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/news_item.dart';
import '../services/news_api_service.dart';
import '../services/ad_service.dart';
import 'news_detail_screen.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({Key? key}) : super(key: key);

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _initialLoading = true;
  bool _loadingMore = false;
  String? _error;

  /// Prevents firing multiple infinite-scroll requests once we hit the end.
  bool _hasMore = true;

  final Set<String> _seenIds = <String>{};

  List<NewsItem> _items = [];
  List<NewsItem> _filtered = [];

  String _selectedCategory = 'All';
  final List<String> _categories = [
    'All',
    'Weather',
    'Policy',
    'Market',
    'Research',
    'Technology',
    'Agriculture',
  ];

  int _pageSize = 150;

  @override
  void initState() {
    super.initState();
    _load();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_initialLoading || _loadingMore) return;
    if (!_hasMore) return;

    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final current = _scrollController.position.pixels;

    // Trigger when the user is close to the bottom.
    const threshold = 250.0;
    if (current >= maxScroll - threshold) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _initialLoading) return;
    if (!_hasMore) return;

    setState(() {
      _loadingMore = true;
      _error = null;
    });

    try {
      // Fetch another batch (service-side best-effort spanning + date windows).
      // We keep it simple: just request more and merge/dedupe.
      final nextItems =
          await NewsApiService().fetchAgricultureNewsSpanning1950ToNow(
        count: _pageSize,
        excludeIds: _seenIds,
      );

      // If the API returns nothing, assume we reached the end for this session.
      final bool apiReturnedAnything = nextItems.isNotEmpty;

      final normalized = apiReturnedAnything
          ? nextItems
          : (NewsApiService.buildFallback(count: _pageSize));

      final out = normalized
          .where(
            (n) => !NewsApiService.isExcludedByKeywords(n.title, n.description),
          )
          .toList();

      setState(() {
        // If API returned nothing, we assume end-of-data for this session.
        if (!apiReturnedAnything) {
          if (out.isEmpty) {
            _hasMore = false;
          }
          _loadingMore = false;
          if (out.isNotEmpty) {
            _items = [..._items, ...out];
            _seenIds.addAll(out.map((e) => e.id));
            _applyFilters();
          }
          return;
        }

        // API responded, but after filtering/dedupe we may have nothing new.
        if (out.isEmpty) {
          // Keep _hasMore true because:
          // - API can return items that are removed by keyword/category filters
          // - user might change query/category
          // - we use best-effort spanning; stopping early would be wrong
          _loadingMore = false;
          return;
        }

        final beforeLen = _items.length;

        _items = [..._items, ...out];

        // Track seen IDs to keep pagination stable.
        _seenIds.addAll(out.map((e) => e.id));

        _applyFilters();

        // If we actually appended new items, we can keep loading.
        // Otherwise, treat as end-of-data.
        _hasMore = _items.length > beforeLen;
        _loadingMore = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loadingMore = false;
        // Keep _hasMore as-is; user can retry by scrolling again.
      });
    }
  }

  Future<void> _load() async {
    setState(() {
      _initialLoading = true;
      _error = null;
      _hasMore = true;
    });

    try {
      final items =
          await NewsApiService().fetchAgricultureNewsSpanning1950ToNow(
        count: _pageSize,
      );

      final normalized = items.isNotEmpty
          ? items
          : NewsApiService.buildFallback(count: _pageSize);

      // Client-side extra filtering to remove crop health keywords.
      final out = normalized
          .where(
            (n) => !NewsApiService.isExcludedByKeywords(n.title, n.description),
          )
          .toList();

      setState(() {
        _items = out;
        _seenIds
          ..clear()
          ..addAll(out.map((e) => e.id));
        _filtered = out;
        _initialLoading = false;

        _loadingMore = false;
        _hasMore = out.isNotEmpty;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _items = NewsApiService.buildFallback(count: _pageSize);
        _filtered = _items;
        _initialLoading = false;
        _loadingMore = false;
        _hasMore = true;
      });
    }
  }

  void _applyFilters() {
    final q = _searchController.text.trim().toLowerCase();

    setState(() {
      _filtered = _items.where((n) {
        final matchesCategory = _selectedCategory == 'All' ||
            n.category.toLowerCase() == _selectedCategory.toLowerCase() ||
            (_selectedCategory == 'Agriculture' &&
                n.category.toLowerCase() == 'agriculture');

        final matchesQuery = q.isEmpty ||
            n.title.toLowerCase().contains(q) ||
            n.description.toLowerCase().contains(q);

        return matchesCategory && matchesQuery;
      }).toList();
    });
  }

  String _formatPublishedAt(DateTime? date) {
    if (date == null) return 'Date unknown';
    return DateFormat.yMMMMd().format(date.toLocal());
  }

  Widget _categoryBadge(String category, {String? iconKind}) {
    final kind = (iconKind ?? category).toLowerCase();
    final icon = _iconForCategory(category, iconKind: iconKind);
    final background = kind == 'weather'
        ? const Color(0xFFE0F7FA)
        : kind == 'policy'
            ? const Color(0xFFE8F5E9)
            : kind == 'market'
                ? const Color(0xFFFFF3E0)
                : kind == 'research'
                    ? const Color(0xFFEDE7F6)
                    : kind == 'technology'
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFF3E5F5);
    final foreground = kind == 'weather'
        ? const Color(0xFF0288D1)
        : kind == 'policy'
            ? const Color(0xFF2E7D32)
            : kind == 'market'
                ? const Color(0xFFF57C00)
                : kind == 'research'
                    ? const Color(0xFF4527A0)
                    : kind == 'technology'
                        ? const Color(0xFF37474F)
                        : const Color(0xFF6A1B9A);

    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Icon(icon, color: foreground, size: 28),
      ),
    );
  }

  IconData _iconForCategory(String category, {String? iconKind}) {
    final kind = (iconKind ?? '').toLowerCase();
    if (kind == 'weather' || category.toLowerCase() == 'weather')
      return Icons.cloud;
    if (kind == 'policy' || category.toLowerCase() == 'policy')
      return Icons.policy;
    if (kind == 'market' || category.toLowerCase() == 'market')
      return Icons.trending_up;
    if (kind == 'research' || category.toLowerCase() == 'research')
      return Icons.science;
    if (kind == 'technology' || category.toLowerCase() == 'technology')
      return Icons.memory;
    return Icons.newspaper;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('News'),
        actions: [
          if (_initialLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
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
                  'Agriculture News Desk',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Trusted policy, market, weather, research and technology news for agri professionals.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),

              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Search agriculture news',
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
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() {
                      _selectedCategory = v;
                    });
                    _applyFilters();
                  },
                ),
              ],
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Text(
                'Could not load from API. Showing offline results.\n$_error',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          Expanded(
            child: _initialLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    controller: _scrollController,
                    itemCount: _filtered.length * 2 + (_loadingMore ? 1 : 0),
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      if (index >= _filtered.length * 2) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      if (index % 2 == 1) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: AdService.getNativeAdWidget(height: 85),
                        );
                      }

                      final n = _filtered[index ~/ 2];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        leading:
                            _categoryBadge(n.category, iconKind: n.iconKind),
                        title: Text(
                          n.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 6),
                            Text(
                              n.description,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _formatPublishedAt(n.publishedAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                        trailing: Text(
                          n.category,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.65),
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => NewsDetailScreen(item: n),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
