# Backend setup

Step-by-step to wire the app to a real Supabase project. Takes ~30 minutes
the first time.

## What this gets you

After you finish this guide:

- Real signup + sign-in (magic-link email)
- Persistent conversations + messages in Postgres
- Live message delivery via Supabase Realtime
- Row-level security so users only see their own chats
- A schema ready for attachments (storage bucket setup below)

What it does **not** yet get you:

- iOS/Android/web push notifications (see "Push" section at the bottom —
  separate setup)
- End-to-end encryption (see `SECURITY.md`)
- The Flutter UI consuming the live backend everywhere. This is **phase
  2** — see "Wiring AppState" at the bottom. Today, `BackendService` is
  available via `Provider<Backend?>` but most screens still read mock
  data from `AppState`.

## 1 · Create the Supabase project

1. Sign up at https://supabase.com
2. **New Project** → name it `messaging` (or whatever)
3. Pick a region close to your users. Set a strong DB password and save
   it in your password manager.
4. Wait ~2 minutes for provisioning.

## 2 · Apply the schema

1. In Studio, open **SQL Editor → New query**
2. Paste the contents of `supabase/migrations/0001_init.sql`
3. Click **Run**

You should see "Success. No rows returned" and the tables `profiles`,
`conversations`, `conversation_members`, `messages`, `reactions`,
`attachments`, and `device_tokens` in the **Table editor**.

### Verify Realtime is on

The migration enables Realtime for `messages`, `reactions`, and
`conversation_members`. Double-check in **Database → Replication**:
those three tables should show a green dot in the `supabase_realtime`
publication.

## 3 · Configure auth

1. Studio → **Authentication → Providers**
2. **Email** is on by default — leave **Enable email confirmations** ON
3. Add Apple / Google providers later if you want one-tap social login
4. **URL Configuration** → set:
   - **Site URL** to your production web URL (e.g. `https://your-app.com`)
     or `http://localhost:5500` while developing
   - **Redirect URLs** → add every URL you want magic-link emails to land
     on, one per line. For iOS deeplinks you'll add e.g.
     `com.messaging://auth/callback` later.

## 4 · (Optional) Storage bucket for attachments

1. Studio → **Storage → New bucket**
2. Name: `attachments`, **Public bucket**: OFF (private)
3. Open the bucket → **Policies** → New policy. Allow `select`,
   `insert`, `update`, `delete` to `authenticated` users with check
   `bucket_id = 'attachments'`. (Tighter per-conversation policies can
   come later.)

## 5 · Grab your project credentials

1. Studio → **Project settings → API**
2. Copy:
   - **Project URL** (looks like `https://xxxxxxxxxxx.supabase.co`)
   - **anon / public** API key (it's safe to ship — it does nothing
     without RLS, which we've enabled)

**Never** commit the `service_role` key — it bypasses RLS.

## 6 · Plug into the Flutter app

The app reads two `--dart-define` values. Run the app like this:

```bash
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://xxxxxxxxxxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOi...
```

For iOS:

```bash
flutter run -d <ios-device-id> \
  --dart-define=SUPABASE_URL=https://xxxxxxxxxxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOi...
```

For macOS:

```bash
flutter run -d macos \
  --dart-define=SUPABASE_URL=https://xxxxxxxxxxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOi...
```

Or persist them with a build profile. Create
`messaging.dart-defines.json` (gitignored) and pass
`--dart-define-from-file=messaging.dart-defines.json`. Vercel, GitHub
Actions, and Xcode all support this format.

At app start you'll see in the console:

```
[backend] Supabase initialized at https://xxxxxxxxxxx.supabase.co
```

If you see `running in mock-data mode` instead, the env vars didn't get
through — double-check the spelling and the value (no quotes).

## 7 · Make your first real user

Once you have at least the auth flow rendering a real session in the
app, you can also seed yourself directly:

1. Studio → **Authentication → Users → Add user**
2. Use a real email; you'll receive the magic-link
3. The `handle_new_user` trigger auto-creates your `profiles` row

## 8 · Wiring `AppState` through `Backend` (phase 2)

The interface exists; screens haven't been cut over yet. The migration
plan, in order:

1. **Auth gate**: in `app.dart`, if `Backend` is non-null and
   `currentUser` is null, render a sign-in screen instead of the
   `HomeShell`. (Sign-in screen: one text field for email, one Send pill,
   subtitle telling them to check email.)
2. **Conversation list**: replace `AppState.directChats` /
   `groupChats` calls with `backend.listConversations()`. Hold the list
   in `AppState`; refresh on pull-to-refresh and on a "new message"
   realtime event.
3. **Chat detail**: replace `convo.messages` reads with a paginated
   `backend.listMessages(convoId)` call, plus a
   `backend.subscribeToMessages(convoId)` stream that appends to the
   local cache.
4. **Send**: `AppState.sendMessage` → `backend.sendMessage`.
5. **Reactions, pins, mute, archive**: same pattern.

Do these in five separate PRs. Don't try to land all at once.

## Push notifications (separate spec)

This is its own chunk of work. Rough plan:

### iOS

1. In Apple Developer Portal, create an **APNs Auth Key** (Keys → +
   → Apple Push Notifications service). Download the `.p8`.
2. Studio → **Authentication → Providers → Apple** (for Sign In with
   Apple) and **Settings → Push notifications** (when this lands in
   Supabase) — upload your APNs key.
3. In Flutter, add `firebase_messaging` or `flutter_apns_only`.
   Personally I'd skip Firebase and go direct to APNs.
4. Create a Supabase Edge Function `on_message_insert` that:
   - Triggers on `messages` insert
   - Looks up conversation members
   - For each non-sender, looks up their `device_tokens`
   - Sends an APNs push with the message body (or an encrypted envelope
     once E2EE is in)

### Web

1. Generate VAPID keys for Web Push.
2. Use the browser's Notification API + service worker (Flutter web
   doesn't auto-handle this; you'd write a tiny `sw.js`).
3. Same Edge Function, different transport.

### macOS

1. Apple Developer + APNs entitlement in `macos/Runner/*.entitlements`.
2. Use Flutter's `flutter_local_notifications` for in-app surfacing.
3. For background pushes, the same APNs auth-key path as iOS.

Plan **at least a week** of focused work for push, mostly fighting Apple
Developer Portal and certificate provisioning.
