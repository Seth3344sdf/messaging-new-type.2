-- ============================================================================
-- 0002 · workspaces, presence, status auto-expiry, attachments bucket
-- ============================================================================

-- ── workspaces ─────────────────────────────────────────────────────────────
create table if not exists public.workspaces (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  slug        text not null unique,
  created_by  uuid not null references auth.users on delete set null,
  created_at  timestamptz not null default now()
);

create table if not exists public.workspace_members (
  workspace_id uuid not null references public.workspaces on delete cascade,
  user_id      uuid not null references auth.users      on delete cascade,
  role         member_role not null default 'member',
  joined_at    timestamptz not null default now(),
  primary key (workspace_id, user_id)
);

create index if not exists workspace_members_user_idx
  on public.workspace_members (user_id);

-- Link conversations to a workspace. NULL = personal / cross-workspace DM.
alter table public.conversations
  add column if not exists workspace_id uuid references public.workspaces on delete cascade;

create index if not exists conversations_workspace_idx
  on public.conversations (workspace_id);

-- ── status fields on profiles ──────────────────────────────────────────────
alter table public.profiles
  add column if not exists status_expires_at timestamptz;

-- Soft delete + last seen.
alter table public.profiles
  add column if not exists last_seen_at timestamptz;

-- ── reply_to_id index (we added the column in 0001 but no index) ───────────
create index if not exists messages_reply_to_idx on public.messages (reply_to_id)
  where reply_to_id is not null;

-- ── Helper: am I a member of this workspace? ───────────────────────────────
create or replace function public.is_workspace_member(w uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.workspace_members
    where workspace_id = w and user_id = auth.uid()
  );
$$;

-- ── Default workspace seeding on new user ──────────────────────────────────
-- When a profile row is created, also drop the user into a personal workspace
-- so they have somewhere to start.
create or replace function public.create_default_workspace_for_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  new_ws_id uuid;
  slug_base text;
  attempt   int := 0;
  unique_slug text;
begin
  slug_base := lower(regexp_replace(coalesce(new.name, 'workspace'), '\W+', '-', 'g'));
  loop
    unique_slug := slug_base || case when attempt = 0 then '' else '-' || attempt::text end;
    begin
      insert into public.workspaces (name, slug, created_by)
      values (coalesce(new.name, 'My Workspace') || '''s Workspace',
              unique_slug, new.id)
      returning id into new_ws_id;
      exit;
    exception when unique_violation then
      attempt := attempt + 1;
      if attempt > 50 then raise; end if;
    end;
  end loop;
  insert into public.workspace_members (workspace_id, user_id, role)
  values (new_ws_id, new.id, 'owner');
  return new;
end;
$$;

drop trigger if exists on_profile_created on public.profiles;
create trigger on_profile_created
  after insert on public.profiles
  for each row execute procedure public.create_default_workspace_for_new_user();

-- ── RLS for workspaces ─────────────────────────────────────────────────────
alter table public.workspaces        enable row level security;
alter table public.workspace_members enable row level security;

create policy "workspaces_read_members"
  on public.workspaces for select
  to authenticated using (public.is_workspace_member(id));

create policy "workspaces_insert_self"
  on public.workspaces for insert
  to authenticated with check (created_by = auth.uid());

create policy "workspace_members_read"
  on public.workspace_members for select
  to authenticated using (public.is_workspace_member(workspace_id));

create policy "workspace_members_insert_owner"
  on public.workspace_members for insert
  to authenticated with check (
    user_id = auth.uid()
    or exists (
      select 1 from public.workspace_members m
      where m.workspace_id = workspace_members.workspace_id
        and m.user_id = auth.uid()
        and m.role in ('owner', 'admin')
    )
  );

-- ── Attachments storage bucket ─────────────────────────────────────────────
-- Created idempotently. Policies allow authenticated users to manage their
-- own uploads under user-id-prefixed paths.
insert into storage.buckets (id, name, public)
values ('attachments', 'attachments', false)
on conflict (id) do nothing;

insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do nothing;

-- Storage policies (idempotent re-create).
drop policy if exists "attachments_user_read"   on storage.objects;
drop policy if exists "attachments_user_write"  on storage.objects;
drop policy if exists "attachments_user_delete" on storage.objects;
drop policy if exists "avatars_public_read"     on storage.objects;
drop policy if exists "avatars_user_write"      on storage.objects;
drop policy if exists "avatars_user_delete"     on storage.objects;

create policy "attachments_user_read"
  on storage.objects for select
  to authenticated
  using (bucket_id = 'attachments');

create policy "attachments_user_write"
  on storage.objects for insert
  to authenticated
  with check (bucket_id = 'attachments' and auth.uid()::text = (storage.foldername(name))[1]);

create policy "attachments_user_delete"
  on storage.objects for delete
  to authenticated
  using (bucket_id = 'attachments' and auth.uid()::text = (storage.foldername(name))[1]);

create policy "avatars_public_read"
  on storage.objects for select
  to public
  using (bucket_id = 'avatars');

create policy "avatars_user_write"
  on storage.objects for insert
  to authenticated
  with check (bucket_id = 'avatars' and auth.uid()::text = (storage.foldername(name))[1]);

create policy "avatars_user_delete"
  on storage.objects for delete
  to authenticated
  using (bucket_id = 'avatars' and auth.uid()::text = (storage.foldername(name))[1]);

-- Profile avatar URL column.
alter table public.profiles
  add column if not exists avatar_url text;
