# Messaging — landing page

A minimal Next.js 15 (App Router) marketing page. Deploys cleanly to
Vercel as its own project.

## Local

```bash
cd landing
npm install
npm run dev
```

## Deploy

```bash
cd landing
npx vercel --prod
```

When pointing this at your domain, also update `app.example.com` and
`hello@example.com` in `app/page.tsx`.
