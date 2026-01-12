import 'package:flutter/material.dart';

class TopicsWordCloud extends StatelessWidget {
  final List<String> topics;

  const TopicsWordCloud({
    super.key,
    required this.topics,
  });

  @override
  Widget build(BuildContext context) {
    if (topics.isEmpty) {
      return Card(
        child: Container(
          height: 200,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'No topics yet',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Container(
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(minHeight: 200),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: topics.asMap().entries.map((entry) {
            final index = entry.key;
            final topic = entry.value;

            // Size decreases for lower ranked topics
            final fontSize = _getFontSize(index, topics.length);
            final color = _getColor(context, index);

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withAlpha(100)),
              ),
              child: Text(
                topic,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  double _getFontSize(int index, int totalCount) {
    // First topic is largest (24), gradually decreases to 12
    if (index == 0) return 24.0;
    if (index == 1) return 20.0;
    if (index == 2) return 18.0;
    if (index <= 4) return 16.0;
    return 14.0;
  }

  Color _getColor(BuildContext context, int index) {
    final colors = [
      Theme.of(context).colorScheme.primary,
      Theme.of(context).colorScheme.secondary,
      Theme.of(context).colorScheme.tertiary,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];

    return colors[index % colors.length];
  }
}
