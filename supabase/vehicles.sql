-- RLW App: family cars (Vehicles page and the dashboard card)
-- Run once: Supabase → SQL Editor → New query → paste → Run. Safe to run again.
-- Run supabase/sharing.sql first if you share the app with a second login.

create table if not exists public.vehicles (
  id         uuid primary key,
  user_id    uuid not null default auth.uid() references auth.users (id) on delete cascade,
  data       jsonb not null default '{}'::jsonb,  -- make/model, year, plate, used by, loan or paid, registration, insurance, maintenance
  updated_at timestamptz not null default now()
);
alter table public.vehicles enable row level security;

drop policy if exists "own vehicles" on public.vehicles;
create policy "own vehicles" on public.vehicles
  for all to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- The shared login can see the cars but not change them.
drop policy if exists "shared vehicles: read" on public.vehicles;
create policy "shared vehicles: read" on public.vehicles
  for select to authenticated using (user_id = public.my_owner());
