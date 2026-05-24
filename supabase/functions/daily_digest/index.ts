// Daily digest Edge Function — runs once a morning, sends each user a short
// summary of yesterday's activity. Deploy with:
//
//   supabase functions deploy daily_digest
//
// Schedule with Supabase's cron (Database → Cron → New job):
//
//   select net.http_post(
//     url := 'https://<ref>.supabase.co/functions/v1/daily_digest',
//     headers := jsonb_build_object(
//       'Authorization', 'Bearer ' || (select decrypted_secret from vault.decrypted_secrets where name = 'service_role')
//     )
//   );
//
// Required secrets in `supabase secrets`:
//   - RESEND_API_KEY        (or any email service; this code uses Resend)
//   - DIGEST_FROM_EMAIL     ("Messaging <hello@yourdomain.com>")
//   - OPENAI_API_KEY        (optional; if absent we use a templated summary)
//
// Required env automatically provided by Supabase:
//   - SUPABASE_URL
//   - SUPABASE_SERVICE_ROLE_KEY

// deno-lint-ignore-file no-explicit-any
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const RESEND_KEY = Deno.env.get("RESEND_API_KEY") ?? "";
const FROM = Deno.env.get("DIGEST_FROM_EMAIL") ?? "Messaging <hello@example.com>";
const OPENAI_KEY = Deno.env.get("OPENAI_API_KEY") ?? "";

const supabase = createClient(SUPABASE_URL, SERVICE_ROLE);

interface Profile {
  id: string;
  name: string;
  email: string | null;
}

interface MessageRow {
  conversation_id: string;
  author_id: string;
  body: string;
  created_at: string;
}

async function summarize(messages: MessageRow[], name: string): Promise<string> {
  if (!OPENAI_KEY || messages.length === 0) {
    // Templated fallback — no LLM call.
    const sample = messages.slice(0, 5).map((m) => "• " + m.body).join("\n");
    return `Hi ${name}, here's what your team talked about in the last 24h:\n\n${sample}`;
  }
  const res = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: "Bearer " + OPENAI_KEY,
    },
    body: JSON.stringify({
      model: "gpt-4o-mini",
      temperature: 0.4,
      messages: [
        {
          role: "system",
          content:
            "Summarize the following messages from a work chat for a colleague named " +
            name +
            ". Two short paragraphs. Highlight decisions and action items. No greeting.",
        },
        {
          role: "user",
          content: messages
            .map((m) => "[" + m.created_at + "] " + m.body)
            .join("\n"),
        },
      ],
    }),
  });
  if (!res.ok) {
    return "Hi " + name + ", we had ${messages.length} messages across your chats yesterday.";
  }
  const json = await res.json();
  return json.choices?.[0]?.message?.content ?? "(summary unavailable)";
}

async function sendEmail(to: string, subject: string, body: string) {
  if (!RESEND_KEY) {
    console.log("[digest] no RESEND_API_KEY; skipping email to", to);
    return;
  }
  await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      Authorization: "Bearer " + RESEND_KEY,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      from: FROM,
      to,
      subject,
      text: body,
    }),
  });
}

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("POST only", { status: 405 });
  }
  const since = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString();

  // Pull users who haven't opted out and have email on their auth record.
  const { data: profiles } = await supabase
    .from("profiles")
    .select("id, name");
  const { data: usersList } = await supabase.auth.admin.listUsers();
  const emailById = new Map<string, string>();
  for (const u of usersList?.users ?? []) {
    if (u.id && u.email) emailById.set(u.id, u.email);
  }

  let sent = 0;
  for (const p of (profiles as Profile[]) ?? []) {
    const email = emailById.get(p.id);
    if (!email) continue;

    // All messages from yesterday in conversations the user is in.
    const { data: members } = await supabase
      .from("conversation_members")
      .select("conversation_id")
      .eq("user_id", p.id);
    const convIds = (members ?? []).map((m: any) => m.conversation_id);
    if (convIds.length === 0) continue;

    const { data: msgs } = await supabase
      .from("messages")
      .select("conversation_id, author_id, body, created_at")
      .in("conversation_id", convIds)
      .neq("author_id", p.id)
      .gte("created_at", since);

    const list = (msgs as MessageRow[]) ?? [];
    if (list.length === 0) continue;

    const body = await summarize(list, p.name);
    await sendEmail(email, `Your morning briefing`, body);
    sent++;
  }

  return new Response(JSON.stringify({ ok: true, sent }), {
    headers: { "Content-Type": "application/json" },
  });
});
