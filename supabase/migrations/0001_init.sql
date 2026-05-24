-- ============================================================================
-- Messaging schema · 0001_init
--
-- Run this once against a fresh Supabase project:
--   supabase db push
-- or paste into Supabase Studio's SQL editor.
--
-- All tables are protected by Row Level Security. A user can only see and
-- write data for conversations they participate in.
-- ============================================================================

-- ── Profiles ────────────────────────────────────────────────────────────────
-- Public-facing user data. One row per auth.users row, linked by id.
create table if not exists public.profiles (
  id          uuid primary key references auth.users on delete cascade,
  name        text not null,
  status      text,
  initials    text not null,
  avatar_tone text not null default 'paper'
              check (avatar_tone in ('paper', 'warm', 'cool', 'ink')),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create index if not exists profiles_name_idx on public.profiles (name);

-- ── Conversations ───────────────────────────────────────────────────────────
create type conversation_kind as enum ('direct', 'group');

create table if not exists public.conversations (
  id           uuid primary key default gen_random_uuid(),
  kind         conversation_kind not null,
  -- For groups only.
  name         text,
  avatar_id    text,
  created_by   uuid not null references auth.users on delete set null,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

-- ── Members ─────────────────────────────────────────────────────────────────
create type member_role as enum ('owner', 'admin', 'member');

create table if not exists public.conversation_members (
  conversation_id uuid not null references public.conversations on delete cascade,
  user_id         uuid not null references auth.users        on delete cascade,
  role            member_role not null default 'member',
  joined_at       timestamptz not null default now(),
  last_read_at    timestamptz not null default now(),
  muted           boolean     not null default false,
  archived        boolean     not null default false,
  primary key (conversation_id, user_id)
);

create index if not exists conversation_members_user_idx
  on public.conversation_members (user_id);

-- ── Messages ────────────────────────────────────────────────────────────────
create table if not exists public.messages (
  id              uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations on delete cascade,
  author_id       uuid not null references auth.users          on delete cascade,
  body            text not null,
  reply_to_id     uuid references public.messages on delete set null,
  pinned          boolean not null default false,
  is_ai           boolean not null default false,
  created_at      timestamptz not null default now()
);

create index if not exists messages_conversation_created_idx
  on public.messages (conversation_id, created_at desc);
create index if not exists messages_pinned_idx
  on public.messages (conversation_id) where pinned;

-- ── Reactions ───────────────────────────────────────────────────────────────
create type reaction_kind as enum
  ('heart', 'thumbs_up', 'laugh', 'fire', 'eyes');

create table if not exists public.reactions (
  message_id uuid not null references public.messages on delete cascade,
  user_id    uuid not null references auth.users    on delete cascade,
  kind       reaction_kind not null,
  created_at timestamptz   not null default now(),
  primary key (message_id, user_id, kind)
);

-- ── Attachments (file storage refs) ─────────────────────────────────────────
create type attachment_kind as enum
  ('photo', 'file', 'voice', 'location', 'poll');

create table if not exists public.attachments (
  id          uuid primary key default gen_random_uuid(),
  message_id  uuid not null references public.messages on delete cascade,
  kind        attachment_kind not null,
  storage_path text,            -- path in the 'attachments' Storage bucket
  filename     text,
  mime_type    text,
  size_bytes   bigint,
  metadata     jsonb,           -- e.g. {"lat":..,"lng":..} for location
  created_at  timestamptz not null default now()
);

create index if not exists attachments_message_idx on public.attachments (message_id);

-- ── Device push tokens ──────────────────────────────────────────────────────
create type device_platform as enum ('ios', 'android', 'web', 'macos');

create table if not exists public.device_tokens (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references auth.users on delete cascade,
  platform   device_platform not null,
  token      text not null,
  created_at timestamptz not null default now(),
  unique (user_id, token)
);

-- ============================================================================
-- Row Level Security
-- ============================================================================
alter table public.profiles              enable row level security;
alter table public.conversations         enable row level security;
alter table public.conversation_members  enable row level security;
alter table public.messages              enable row level security;
alter table public.reactions             enable row level security;
alter table public.attachments           enable row level security;
alter table public.device_tokens         enable row level security;

-- profiles ─ everyone signed in can read; you can only update your own.
create policy "profiles_read_all"
  on public.profiles for select
  to authenticated using (true);

create policy "profiles_insert_self"
  on public.profiles for insert
  to authenticated with check (id = auth.uid());

create policy "profiles_update_self"
  on public.profiles for update
  to authenticated using (id = auth.uid());

-- helper: am I a member of this conversation?
create or replace function public.is_member(c uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.conversation_members
    where conversation_id = c and user_id = auth.uid()
  );
$$;

-- conversations ─ you see conversations you're a member of.
create policy "conversations_read"
  on public.conversations for select
  to authenticated using (public.is_member(id));

create policy "conversations_insert"
  on public.conversations for insert
  to authenticated with check (created_by = auth.uid());

create policy "conversations_update_admins"
  on public.conversations for update
  to authenticated using (
    exists (
      select 1 from public.conversation_members
      where conversation_id = conversations.id
        and user_id = auth.uid()
        and role in ('owner', 'admin')
    )
  );

-- conversation_members ─ you see members of conversations you're in.
create policy "members_read"
  on public.conversation_members for select
  to authenticated using (public.is_member(conversation_id));

create policy "members_insert_self_to_open_conv"
  on public.conversation_members for insert
  to authenticated with check (
    user_id = auth.uid()
    or exists (
      select 1 from public.conversation_members m
      where m.conversation_id = conversation_members.conversation_id
        and m.user_id = auth.uid()
        and m.role in ('owner', 'admin')
    )
  );

create policy "members_update_self_or_admin"
  on public.conversation_members for update
  to authenticated using (
    user_id = auth.uid()
    or exists (
      select 1 from public.conversation_members m
      where m.conversation_id = conversation_members.conversation_id
        and m.user_id = auth.uid()
        and m.role in ('owner', 'admin')
    )
  );

-- messages ─ you see messages in conversations you're a member of.
create policy "messages_read"
  on public.messages for select
  to authenticated using (public.is_member(conversation_id));

create policy "messages_insert_member"
  on public.messages for insert
  to authenticated with check (
    author_id = auth.uid() and public.is_member(conversation_id)
  );

create policy "messages_update_author_or_admin"
  on public.messages for update
  to authenticated using (
    author_id = auth.uid()
    or exists (
      select 1 from public.conversation_members
      where conversation_id = messages.conversation_id
        and user_id = auth.uid()
        and role in ('owner', 'admin')
    )
  );

-- reactions ─ visible to members; insert your own.
create policy "reactions_read"
  on public.reactions for select
  to authenticated using (
    exists (
      select 1 from public.messages m
      where m.id = reactions.message_id and public.is_member(m.conversation_id)
    )
  );

create policy "reactions_insert_self"
  on public.reactions for insert
  to authenticated with check (user_id = auth.uid());

create policy "reactions_delete_self"
  on public.reactions for delete
  to authenticated using (user_id = auth.uid());

-- attachments ─ visible to members of the message's conversation.
create policy "attachments_read"
  on public.attachments for select
  to authenticated using (
    exists (
      select 1 from public.messages m
      where m.id = attachments.message_id and public.is_member(m.conversation_id)
    )
  );

create policy "attachments_insert_via_own_message"
  on public.attachments for insert
  to authenticated with check (
    exists (
      select 1 from public.messages m
      where m.id = attachments.message_id and m.author_id = auth.uid()
    )
  );

-- device_tokens ─ only you can manage your tokens.
create policy "device_tokens_self"
  on public.device_tokens for all
  to authenticated using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- ============================================================================
-- Trigger: auto-create a profile when a new auth user signs up.
-- ============================================================================
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  full_name text;
  inits     text;
begin
  full_name := coalesce(new.raw_user_meta_data->>'name', split_part(new.email, '@', 1));
  -- crude 2-letter monogram
  inits := upper(left(regexp_replace(full_name, '\s+', '', 'g'), 2));
  insert into public.profiles (id, name, initials)
  values (new.id, full_name, inits)
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ============================================================================
-- Realtime: enable broadcast for messages + reactions + conversation_members.
-- (Supabase: also toggle these tables on in Database → Replication UI.)
-- ============================================================================
alter publication supabase_realtime add table public.messages;
alter publication supabase_realtime add table public.reactions;
alter publication supabase_realtime add table public.conversation_members;
