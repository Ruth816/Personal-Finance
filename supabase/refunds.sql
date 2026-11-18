-- RLW App: refunds and cash back, kept separate from expenses (they do not change spending totals)
-- Run once: Supabase → SQL Editor → New query → paste → Run. Safe to run again.

create table if not exists public.refunds (
  id       uuid primary key,
  user_id  uuid not null default auth.uid() references auth.users (id) on delete cascade,
  date     date not null,
  descr    text not null check (char_length(descr) between 1 and 120),
  amt      numeric(14,2) not null check (amt > 0),
  acct     text not null,
  notes    text not null default '' check (char_length(notes) <= 200),
  ts       bigint not null default 0
);
create index if not exists refunds_user_date on public.refunds (user_id, date);
alter table public.refunds enable row level security;
drop policy if exists "own refunds" on public.refunds;
create policy "own refunds" on public.refunds
  for all to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());
