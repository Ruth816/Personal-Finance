-- RLW App: insurance policies (Insurance page and the dashboard card)
-- Run once: Supabase → SQL Editor → New query → paste → Run. Safe to run again.
-- Run supabase/sharing.sql first if you share the app with a second login.

create table if not exists public.policies (
  id         uuid primary key,
  user_id    uuid not null default auth.uid() references auth.users (id) on delete cascade,
  data       jsonb not null default '{}'::jsonb,  -- insurer, plan, insured, cover, dates, premiums, payment, agent, notes
  updated_at timestamptz not null default now()
);
alter table public.policies enable row level security;

drop policy if exists "own policies" on public.policies;
create policy "own policies" on public.policies
  for all to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- The shared login can see the policies but not change them.
drop policy if exists "shared policies: read" on public.policies;
create policy "shared policies: read" on public.policies
  for select to authenticated using (user_id = public.my_owner());
