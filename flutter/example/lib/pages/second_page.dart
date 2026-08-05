import 'package:flutter/material.dart';

/// Shows that the widget, being above the Navigator, survives route changes.
class SecondPage extends StatelessWidget {
  const SecondPage({super.key});

  static const String route = '/second';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Another route')),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        itemCount: 40,
        itemBuilder: (BuildContext context, int index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'The chat bubble is still there, in the same place, because the '
                'widget lives in MaterialApp.builder rather than in a route.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            );
          }
          return ListTile(
            leading: CircleAvatar(child: Text('$index')),
            title: Text('Scrollable row $index'),
            subtitle: const Text('Scrolls freely underneath the bubble'),
          );
        },
      ),
    );
  }
}
