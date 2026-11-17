-- RLW App: properties (rent and assoc dues tracking)
-- Run once: Supabase → SQL Editor → New query → paste → Run. Safe to run again.
-- Title numbers are deliberately not stored.

create table if not exists public.properties (
  id         uuid primary key,
  user_id    uuid not null default auth.uid() references auth.users (id) on delete cascade,
  data       jsonb not null default '{}'::jsonb,  -- name, area, rent, contract dates, payments
  updated_at timestamptz not null default now()
);
alter table public.properties enable row level security;
drop policy if exists "own properties" on public.properties;
create policy "own properties" on public.properties
  for all to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());
