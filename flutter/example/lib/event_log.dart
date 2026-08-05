import 'package:flutter/foundation.dart';

/// A rolling list of the widget events the demo has seen.
class EventLog extends ValueNotifier<List<String>> {
  EventLog() : super(const <String>[]);

  static const int _limit = 40;

  void add(String event) {
    final DateTime now = DateTime.now();
    final String stamp =
        '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}';
    value = <String>[
      '$stamp  $event',
      ...value.take(_limit - 1),
    ];
  }

  void clear() => value = const <String>[];
}
