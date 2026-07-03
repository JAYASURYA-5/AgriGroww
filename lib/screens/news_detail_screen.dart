import 'package:flutter/material.dart';

import '../models/news_item.dart';

class NewsDetailScreen extends StatelessWidget {
  final NewsItem item;

  const NewsDetailScreen({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final bodyMedium = textTheme.bodyMedium;
    final bodyLarge = textTheme.bodyLarge;
    final titleMedium = textTheme.titleMedium;
    final headlineSmall = textTheme.headlineSmall;

    return Scaffold(
      appBar: AppBar(
        title: const Text('News Details'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            item.title.trim().isEmpty ? 'Untitled news' : item.title,
            style: headlineSmall != null
                ? headlineSmall.copyWith(fontWeight: FontWeight.bold)
                : null,
          ),
          const SizedBox(height: 12),
          if (item.publishedAt != null)
            Text(
              'Published: ${item.publishedAt!.toLocal().toString().split('.').first}',
              style: bodyMedium != null
                  ? bodyMedium.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    )
                  : null,
            ),
          const SizedBox(height: 12),
          Text(
            item.description.trim().isEmpty
                ? 'No description available for this item.'
                : item.description,
            style: bodyLarge,
          ),
          const SizedBox(height: 18),
          Text(
            'Professional QA',
            style: titleMedium != null
                ? titleMedium.copyWith(fontWeight: FontWeight.bold)
                : null,
          ),
          const SizedBox(height: 8),
          Builder(
            builder: (context) {
              final qa = item.qa;
              final hasQa = qa.isNotEmpty;

              if (!hasQa) {
                return Text(
                  'QA not available for this item.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7),
                      ),
                );
              }

              final entries = qa.entries.where((e) {
                final k = e.key.trim();
                final v = e.value.trim();
                return k.isNotEmpty && v.isNotEmpty;
              }).toList();

              if (entries.isEmpty) {
                return Text(
                  'QA not available for this item.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7),
                      ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: entries.map((e) {
                  final k = e.key.trim();
                  final v = e.value.trim();
                  final formattedKey =
                      '${k.isNotEmpty ? k[0].toUpperCase() : ''}'
                      '${k.length > 1 ? k.substring(1) : ''}:';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formattedKey,
                          style: bodyMedium != null
                              ? bodyMedium.copyWith(fontWeight: FontWeight.w600)
                              : null,
                        ),
                        const SizedBox(height: 4),
                        Text(v.isEmpty ? 'Not specified' : v,
                            style: bodyMedium),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
