# Pylon Chat Flutter Demo

A demo app exercising every part of the Flutter SDK.

## Running it

```bash
cp env.example .env     # then add your app ID
./run.sh                # extra args go to `flutter run`, e.g. ./run.sh -d <device>
```

`run.sh` forwards everything in `.env` to `flutter run` as `--dart-define`. If you would rather not use it:

```bash
flutter run --dart-define=PYLON_APP_ID=your-app-id
```

Your app ID is in [app.usepylon.com](https://app.usepylon.com) under Settings → Chat Widget. Without one the app shows a setup screen instead of the widget.

## What it demonstrates

- **The recommended mounting point** — the widget lives in `MaterialApp.builder`, above the `Navigator`, so it stays put across routes and handles the keyboard itself. Push the second route to see it.
- **Touch pass-through** — the widget covers the whole screen, but the list scrolls and every button works underneath it.
- **Imperative control** — open and close the chat, show and hide the bubble, pre-fill a message, open a ticket form or knowledge base article.
- **Unread badge** — driven straight off `controller.unreadCount`, no state of its own.
- **Identity switching** — sign in and out to see the widget rebuild for a new user, and run anonymously when signed out.
- **Events** — every callback the widget fires, logged on screen.

Set `PYLON_DEBUG_MODE=true` in `.env` to draw the SDK's hit test regions over the widget, which is the fastest way to see why a tap is or is not landing.
