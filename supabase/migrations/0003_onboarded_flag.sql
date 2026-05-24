-- 0003 · profile onboarding flag
alter table public.profiles
  add column if not exists onboarded boolean not null default false;
