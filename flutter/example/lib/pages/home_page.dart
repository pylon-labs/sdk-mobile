import 'package:flutter/material.dart';
import 'package:pylon_chat/pylon_chat.dart';

import '../env.dart';
import '../event_log.dart';
import '../widgets/section.dart';
import '../widgets/unread_badge.dart';
import 'second_page.dart';

/// Exercises everything [PylonChatController] can do.
class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.controller,
    required this.events,
    required this.user,
    required this.onUserChanged,
  });

  final PylonChatController controller;
  final EventLog events;
  final PylonUser? user;
  final ValueChanged<PylonUser?> onUserChanged;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _message = TextEditingController(
    text: 'Hi! I need a hand with my account.',
  );
  final TextEditingController _ticketForm = TextEditingController();
  final TextEditingController _article = TextEditingController();

  @override
  void dispose() {
    _message.dispose();
    _ticketForm.dispose();
    _article.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final PylonChatController controller = widget.controller;

    return Scaffold(
      // The widget is an overlay above the Navigator, so it sizes itself to the
      // screen and handles the keyboard on its own.
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Pylon Chat'),
        actions: <Widget>[
          UnreadBadge(unreadCount: controller.unreadCount),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: <Widget>[
          Section(
            title: 'Chat window',
            children: <Widget>[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  FilledButton(
                    onPressed: controller.openChat,
                    child: const Text('Open'),
                  ),
                  OutlinedButton(
                    onPressed: controller.closeChat,
                    child: const Text('Close'),
                  ),
                  OutlinedButton(
                    onPressed: controller.showChatBubble,
                    child: const Text('Show bubble'),
                  ),
                  OutlinedButton(
                    onPressed: controller.hideChatBubble,
                    child: const Text('Hide bubble'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Hiding the bubble does not disable the chat — "Open" still '
                'works, which is how you drive it from your own UI.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          Section(
            title: 'Start a conversation',
            children: <Widget>[
              TextField(
                controller: _message,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  border: OutlineInputBorder(),
                ),
                minLines: 1,
                maxLines: 3,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  FilledButton(
                    onPressed: () =>
                        controller.showNewMessage(_message.text),
                    child: const Text('Send as text'),
                  ),
                  OutlinedButton(
                    onPressed: () => controller.showNewMessage(
                      '<p><strong>${_message.text}</strong></p>',
                      isHtml: true,
                    ),
                    child: const Text('Send as HTML'),
                  ),
                ],
              ),
            ],
          ),
          Section(
            title: 'Forms and articles',
            children: <Widget>[
              _LookupRow(
                controller: _ticketForm,
                label: 'Ticket form slug',
                buttonLabel: 'Show form',
                onSubmit: (String value) => controller.showTicketForm(value),
              ),
              const SizedBox(height: 8),
              _LookupRow(
                controller: _article,
                label: 'Knowledge base article ID',
                buttonLabel: 'Show article',
                onSubmit: (String value) =>
                    controller.showKnowledgeBaseArticle(value),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () {
                  controller.setTicketFormFields(<String, Object?>{
                    'subject': 'Issue from the Flutter demo',
                    'description': 'Pre-filled by setTicketFormFields().',
                  });
                  _toast('Ticket form fields set');
                },
                child: const Text('Pre-fill ticket form'),
              ),
            ],
          ),
          Section(
            title: 'Metadata',
            children: <Widget>[
              Text(
                'Custom fields are attached to whatever issue this session '
                'creates next.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () {
                  controller.setNewIssueCustomFields(<String, Object?>{
                    'source': 'flutter-demo',
                    'app_version': '0.1.0',
                    'platform': Theme.of(context).platform.name,
                  });
                  _toast('Custom fields set');
                },
                child: const Text('Set custom fields'),
              ),
            ],
          ),
          Section(
            title: 'Identity',
            children: <Widget>[
              Text(
                widget.user == null
                    ? 'Anonymous — Pylon will ask for an email in the chat.'
                    : 'Signed in as ${widget.user!.email}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  FilledButton.tonal(
                    onPressed: widget.user == null
                        ? () => widget.onUserChanged(Env.user)
                        : null,
                    child: const Text('Sign in'),
                  ),
                  OutlinedButton(
                    onPressed: widget.user == null
                        ? null
                        : () => widget.onUserChanged(null),
                    child: const Text('Sign out'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Switching user rebuilds the widget, so the next conversation '
                'starts clean.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          Section(
            title: 'Touch pass-through',
            children: <Widget>[
              Text(
                'The widget covers this whole screen, but only the bubble takes '
                'touches. Scroll under it, and tap the button below through it.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () =>
                    Navigator.of(context).pushNamed(SecondPage.route),
                child: const Text('Push another route'),
              ),
            ],
          ),
          Section(
            title: 'Events',
            children: <Widget>[
              ValueListenableBuilder<List<String>>(
                valueListenable: widget.events,
                builder: (BuildContext context, List<String> events, _) {
                  if (events.isEmpty) {
                    return Text(
                      'Nothing yet.',
                      style: Theme.of(context).textTheme.bodySmall,
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      for (final String event in events)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            event,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: widget.events.clear,
                          child: const Text('Clear'),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _LookupRow extends StatelessWidget {
  const _LookupRow({
    required this.controller,
    required this.label,
    required this.buttonLabel,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final String label;
  final String buttonLabel;
  final ValueChanged<String> onSubmit;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: () {
            final String value = controller.text.trim();
            if (value.isNotEmpty) onSubmit(value);
          },
          child: Text(buttonLabel),
        ),
      ],
    );
  }
}
