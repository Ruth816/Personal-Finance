-- RLW App: short text notes (e.g. the Notes column in Income tracking)
-- Run once: Supabase → SQL Editor → New query → paste → Run. Safe to run again.
-- Run supabase/sharing.sql first if you share the app with a second login.

create table if not exists public.notes (
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  key     text not null check (char_length(key) <= 80),
  note    text not null check (char_length(note) between 1 and 200),
  primary key (user_id, key)
);
alter table public.notes enable row level security;

drop policy if exists "own notes" on public.notes;
create policy "own notes" on public.notes
  for all to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- The shared login may add, change and remove income notes ('inc:…'), like the income figures.
drop policy if exists "shared income notes" on public.notes;
create policy "shared income notes" on public.notes
  for all to authenticated
  using (user_id = public.my_owner() and key like 'inc:%')
  with check (user_id = public.my_owner() and key like 'inc:%');
