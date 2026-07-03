import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/scheme_item.dart';
import '../services/scheme_service.dart';

class SchemeDetailScreen extends StatelessWidget {
  final SchemeItem scheme;

  const SchemeDetailScreen({Key? key, required this.scheme}) : super(key: key);

  Future<void> _openSchemeLink(BuildContext context) async {
    final uri =
        Uri.tryParse(scheme.link ?? '') ?? Uri.parse(SchemeService.fallbackUrl);
    final effectiveUri =
        uri.scheme.isEmpty ? Uri.parse(SchemeService.fallbackUrl) : uri;

    if (await canLaunchUrl(effectiveUri)) {
      await launchUrl(effectiveUri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Unable to open the scheme link. Redirecting to fallback.'),
        ),
      );
      await launchUrl(Uri.parse(SchemeService.fallbackUrl),
          mode: LaunchMode.externalApplication);
    }
  }

  Widget _section(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scheme Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              scheme.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              scheme.subtitle,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                Chip(label: Text('Launched ${scheme.launchYear}')),
                Chip(label: Text(scheme.category)),
              ],
            ),
            const SizedBox(height: 22),
            _section('Scheme Purpose', scheme.description),
            _section('Financial Support', scheme.financialSupport),
            _section(
                'Productivity Improvement', scheme.productivityImprovement),
            _section('Risk Protection', scheme.riskProtection),
            _section('Training & Awareness', scheme.trainingAwareness),
            _section('Infrastructure Support', scheme.infrastructureSupport),
            _section('Market Support', scheme.marketSupport),
            _section('Weather & Advisory Services', scheme.weatherAdvisory),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: () => _openSchemeLink(context),
              icon: const Icon(Icons.open_in_new),
              label: Text(scheme.link != null
                  ? 'Open official scheme page'
                  : 'Open fallback portal'),
            ),
          ],
        ),
      ),
    );
  }
}
