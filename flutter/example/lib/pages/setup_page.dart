import 'package:flutter/material.dart';

/// Shown when the demo was built without an app ID.
class SetupPage extends StatelessWidget {
  const SetupPage({super.key});

  @override
  Widget build(BuildContext context) {
    final TextStyle? code = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace');

    return Scaffold(
      appBar: AppBar(title: const Text('Pylon Chat')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'No app ID',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            const Text(
              'Grab your app ID from app.usepylon.com under '
              'Settings → Chat Widget, then run the demo with it:',
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'flutter run --dart-define=PYLON_APP_ID=your-app-id',
                style: code,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Or copy env.example to .env and run ./run.sh, which passes every '
              'value in it through for you.',
            ),
          ],
        ),
      ),
    );
  }
}
