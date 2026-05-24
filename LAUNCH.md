# Launch checklist

Everything you need to ship this app on iOS and on the web.

## Accounts to create

| Account | What for | Cost |
|---|---|---|
| Apple Developer Program | iOS App Store + push notifications | $99/year |
| GitHub | Source hosting + CI | Free |
| Vercel **or** Cloudflare Pages **or** Netlify | Web hosting | Free tier covers MVP |
| Supabase **or** Clerk | Auth + Postgres + realtime | Free tier OK to start |
| A domain registrar | Custom domain | ~$12/year |
| (Optional) Pusher / Ably | Realtime if you don't use Supabase | Free tier |
| (Optional) Sentry | Error reporting | Free tier |
| (Optional) Mixpanel / PostHog | Product analytics | Free tier |

## Backend gap

The app currently runs **entirely on mocked data in memory**. To have real
users you need to build:

- **Auth**: email magic-link is simplest. Supabase Auth or Clerk both fine.
- **Database**: Postgres schema with `users`, `conversations`,
  `conversation_members`, `messages`, `reactions`, `pinned_decisions`.
- **Realtime**: WebSocket or Postgres `LISTEN/NOTIFY`. Supabase Realtime
  handles this. Alternatives: Ably, Pusher, custom Phoenix/Elixir.
- **File storage**: Supabase Storage, Cloudflare R2, or S3 for attachments.
- **Push notifications**: APNs via Firebase Cloud Messaging is the path
  of least resistance. Web Push for browsers.

Plan ~2–3 weeks of focused work to wire all of this against the existing
UI.

## iOS launch path

### Local build

```bash
flutter build ios --release
open ios/Runner.xcworkspace   # open in Xcode
```

Once Xcode is open:
1. Pick your team in **Signing & Capabilities**
2. Set a unique **Bundle Identifier** (e.g. `com.yourname.messaging`)
3. Click **Product → Archive** when you're ready to submit
4. From the Organizer, **Distribute App → App Store Connect**

### App Store Connect prep

Before you can submit, create the app entry in
[App Store Connect](https://appstoreconnect.apple.com):

- **App icon**: 1024×1024 PNG, no transparency, no rounded corners
- **Screenshots**: at least one set, per device (6.7" iPhone is required)
- **Description, keywords, support URL, marketing URL**
- **Privacy policy URL** — required
- **Privacy nutrition label** — answer the questionnaire honestly. With
  the current code we collect "no data". With a real backend you'll
  declare email + device IDs at minimum.
- **App Review Information**: a demo account if auth is required

### iOS gotchas

- **Sign In with Apple is required** if you offer other social login
  (Apple's rule, not ours)
- **TestFlight beta** before public submit — invite ~20 friends, ship a
  build, get a week of usage feedback
- First Apple review usually takes 24–48 hours. Plan for 1–2 rejection
  rounds. Read every rejection carefully — most are simple to fix.

## Web launch path

```bash
flutter build web --release --web-renderer=canvaskit
# build/web/  contains a static site
```

### Vercel (recommended)

```bash
npm i -g vercel
cd build/web && vercel --prod
```

Set a custom domain in the Vercel dashboard. Vercel auto-handles SSL.

### Cloudflare Pages

```bash
npx wrangler pages deploy build/web --project-name messaging
```

### Things to verify on web

- PWA installable — Chrome shows the "install" button after a few visits.
  The manifest is at `web/manifest.json` and is already tuned for the
  app's warm-cream theme.
- iOS Safari opens in "standalone" mode when added to home screen
- OG image renders on social link previews — replace
  `web/icons/Icon-512.png` with a branded preview image (1200×630
  preferred) and update `og:image` in `index.html`

## Assets to make

These don't exist yet and **must** be created before submitting:

- [ ] 1024×1024 app icon (master)
- [ ] iOS icon set (Xcode's `Assets.xcassets/AppIcon.appiconset`) —
      use [appicon.co](https://appicon.co) to auto-generate
- [ ] Web favicon + 192/512 PNGs (Flutter scaffolded placeholders;
      replace before launch)
- [ ] iOS launch screen (`ios/Runner/Assets.xcassets/LaunchImage.imageset`)
- [ ] 5–8 App Store screenshots
- [ ] OG / social share image (1200×630)
- [ ] App Store preview video (optional but recommended)

## Legal

- [ ] **Privacy policy** — required for App Store and web. Cover what
      data you collect, how long you keep it, how users can delete it.
- [ ] **Terms of service**
- [ ] **Cookie / tracking notice** for web (EU users)
- [ ] If you handle EU data: **DPA** + GDPR-compliant retention
- [ ] If you handle health data: **HIPAA BAA** with hosting provider

## Pre-flight before first ship

- [ ] Real auth wired (no more mock user)
- [ ] Persistent storage (no more in-memory data)
- [ ] Push notifications working on iOS test device
- [ ] Privacy policy URL live
- [ ] App Store assets uploaded
- [ ] TestFlight build distributed to ≥10 testers for a week
- [ ] No "not wired" buttons anywhere
- [ ] Sentry or equivalent capturing real-device crashes
- [ ] `SECURITY.md` reviewed and Phase 1 (TLS only) plan committed to

## Day-of-ship

1. Publish privacy policy + ToS at known URLs
2. `vercel --prod` for web
3. Submit iOS build via Xcode Archive
4. While Apple reviews (1–2 days), warm up the web link with a small
   group
5. Once Apple approves, schedule the iOS release for the same time as
   the web public link goes out

## After ship

- Set up an on-call rotation for the first month
- Watch Sentry + Apple's crash reporter daily
- Read every App Store review — respond to the rough ones publicly
- Plan Phase 2 of `SECURITY.md` (E2EE) for ~6 weeks post-launch
