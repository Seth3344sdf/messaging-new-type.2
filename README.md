# Messaging

AI-native, privacy-first team chat. Flutter on iOS, web, and macOS; Supabase
on the backend.

```
warm cream + terracotta · DM Serif Display headlines · Inter body
⌘K palette · slash commands · pin-as-decision memory · Briefing tab
```

## Run it now

```bash
flutter run -d chrome \
  --web-port=5500 \
  --dart-define-from-file=messaging.dart-defines.json
```

Live backend kicks in if `SUPABASE_URL` + `SUPABASE_ANON_KEY` are present in
that file. Without them the app runs in mock-data mode — no auth, no real
data, but every UI surface is reachable. See `BACKEND.md` to wire your own
Supabase project.

## Project layout

```
lib/
  app.dart                root + auth/onboarding gate
  main.dart               Supabase init + Sentry + ChangeNotifier wiring
  config/env.dart         --dart-define readers
  models/                 user, conversation, message, workspace
  services/
    backend.dart          Backend interface
    supabase_backend.dart live implementation
  state/app_state.dart    cache + optimistic mutations + heartbeat
  screens/                every full-screen surface (chats, groups,
                          briefing, onboarding, sign in, slack import…)
  widgets/                composer, message bubble, avatar,
                          attachment preview, command palette, pill button…
  theme/                  colors, typography, theme
  data/                   mock data + avatar library

supabase/
  migrations/0001_init.sql               schema + RLS
  migrations/0002_workspaces_*.sql       workspaces + storage buckets
  migrations/0003_onboarded_flag.sql     profile.onboarded
  functions/daily_digest/index.ts        Deno Edge Function

landing/                  Next.js 15 marketing site (deploys to Vercel)
.github/workflows/ci.yml  analyze + web build + landing build
```

## Documentation

- [`LAUNCH.md`](LAUNCH.md) — every step to ship to App Store + web
- [`BACKEND.md`](BACKEND.md) — provisioning Supabase end-to-end
- [`SECURITY.md`](SECURITY.md) — the E2EE plan (don't fork Signal, use MLS)
- [`PRIVACY.md`](PRIVACY.md) — template privacy policy
- [`TERMS.md`](TERMS.md) — template terms of service

## Status

See `LAUNCH.md` § "Status at a glance" — auth, live conversations, realtime
typing + message inserts, presence, group management, avatar + attachment
uploads, workspaces, and Slack import are all wired. Push notifications,
Sign-in-with-Apple provider config in Supabase, and E2EE are deferred.

## License

All rights reserved. Don't ship copies as your own product. Internal forks
and contributions welcome.
