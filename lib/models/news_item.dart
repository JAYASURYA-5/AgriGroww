class NewsItem {
  final String id;
  final String title;
  final String description;
  final String? source;
  final String? url;
  final DateTime? publishedAt;
  final String category;

  final Map<String, String> qa;

  /// Weather icon/image hint.
  /// UI will map this into an icon.
  final String? iconKind;

  NewsItem({
    required this.id,
    required this.title,
    required this.description,
    this.source,
    this.url,
    this.publishedAt,
    required this.category,
    required this.qa,
    this.iconKind,
  });

  factory NewsItem.fromMap(Map<String, dynamic> map) {
    final qaMap = <String, String>{};
    final rawQa = map['qa'];
    if (rawQa is Map) {
      for (final entry in rawQa.entries) {
        qaMap[entry.key.toString()] = entry.value.toString();
      }
    }

    DateTime? published;
    final rawPublished = map['publishedAt'];
    if (rawPublished is String && rawPublished.isNotEmpty) {
      published = DateTime.tryParse(rawPublished);
    }

    return NewsItem(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      source: map['source']?.toString(),
      url: map['url']?.toString(),
      publishedAt: published,
      category: map['category']?.toString() ?? 'General',
      qa: qaMap,
      iconKind: map['iconKind']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'source': source,
      'url': url,
      'publishedAt': publishedAt?.toIso8601String(),
      'category': category,
      'qa': qa,
      'iconKind': iconKind,
    };
  }
}

