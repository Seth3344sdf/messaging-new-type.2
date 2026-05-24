# Privacy policy

_Last updated: 2026-05-24. Replace this template with text reviewed by a lawyer
before public launch — especially the data-retention and DPA sections._

## What we collect

When you sign up and use Messaging we collect:

- **Account data**: email address, display name, profile initials and avatar
  tone or photo, status text.
- **Conversation data**: the contents of messages you send (text, file
  uploads, reactions), the conversations and groups you participate in, the
  decisions you pin.
- **Operational metadata**: device tokens (if you opt in to push notifications),
  `last_seen_at` timestamps used to compute online/offline presence, IP
  address and user agent of recent sessions (collected by Supabase Auth for
  fraud prevention).
- **Optional uploads**: photos, files, voice notes, and other attachments you
  attach to messages.

## What we do NOT collect

- We do not collect or track your messages on other platforms.
- We do not sell your data to third parties.
- We do not use your messages or files to train AI models.
- We do not place advertising or third-party tracking pixels.

## Where your data lives

- Postgres on Supabase, hosted on AWS in `us-east-1` (will be moved to the
  region of your workspace at General Availability).
- File uploads in Supabase Storage in the same region.
- Edge Function logs are retained for 30 days for debugging and are scrubbed
  for message contents.

## Who can see your data

- **You**: always.
- **Other participants of a conversation**: only messages in that conversation.
- **Workspace admins**: profile data (name, avatar, status). Not message
  bodies.
- **Us (operators)**: only when you grant explicit support access for a
  specific issue, or in response to lawful legal process.

Row Level Security policies in the database (see
`supabase/migrations/0001_init.sql`) enforce these rules at the storage
layer, not just in the app.

## End-to-end encryption (E2EE)

E2EE is on our roadmap (see `SECURITY.md`), targeted for the next major
release after public launch. Until then, your messages are encrypted in
transit (TLS 1.3) and at rest (AES-256 by the database provider), but the
server can technically read them. This is the same security posture as
Slack, Microsoft Teams, and Discord.

## AI processing

If you @-mention Pulse or use a slash command (`/summarize`, `/find`,
`/decide`, `/remind`), we send the relevant excerpt of your conversation to
an LLM provider to generate the response. We do not store the request body
beyond what is needed to display the response in your chat. We do not allow
the LLM provider to use your messages for model training.

## Data retention

- Active messages: retained until you delete them or your account.
- Deleted messages: hard-deleted within 30 days from cold backups.
- Account deletion: request via Profile → Sign out → "Delete my account",
  or email `privacy@example.com`. Full deletion happens within 30 days.

## Your rights (GDPR, CCPA)

You have the right to:

- **Access** the data we hold about you. Export from Profile → "Export my
  data".
- **Correct** inaccurate data through the Profile screen.
- **Delete** your account and associated data at any time.
- **Portability** — your export is a structured JSON document.
- **Object** to processing that relies on legitimate interest (e.g. presence
  inference); contact `privacy@example.com`.

## Children

Messaging is not directed at children under 13 (under 16 in the EU). If you
believe a child has provided us personal data, contact us and we will delete
it promptly.

## Changes to this policy

We will notify you of material changes through an in-app banner at least
14 days before they take effect.

## Contact

`privacy@example.com`
