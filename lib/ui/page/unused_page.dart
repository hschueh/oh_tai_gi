import 'package:flutter/material.dart';
import 'package:oh_tai_gi/destination.dart';

/// Placeholder for destinations that are not implemented yet.
class UnfinishedPage extends StatelessWidget {
  const UnfinishedPage({super.key, required this.destination});

  final Destination destination;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(destination.title),
        backgroundColor: destination.color,
      ),
      backgroundColor: destination.color[50],
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.announcement, size: 120),
            Text('功能開發中...',
                style: Theme.of(context).textTheme.headlineSmall),
          ],
        ),
      ),
    );
  }
}
