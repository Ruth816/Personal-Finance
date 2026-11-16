-- Ruth's Expenses Log: database tables
-- Run once in Supabase → SQL Editor → New query → paste → Run.
-- Row Level Security makes every row readable and writable only by the signed-in user who owns it.

create table if not exists public.expenses (
  id       uuid primary key,
  user_id  uuid not null default auth.uid() references auth.users (id) on delete cascade,
  date     date not null,
  cat      text not null,
  descr    text not null check (char_length(descr) between 1 and 120),
  amt      numeric(14,2) not null check (amt > 0),
  acct     text not null,
  notes    text not null default '' check (char_length(notes) <= 200),
  ts       bigint not null,                       -- time created (ms); orders items on the same day
  created_at timestamptz not null default now()
);
create index if not exists expenses_user_date on public.expenses (user_id, date);

create table if not exists public.budgets (
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  cat     text not null,
  amount  numeric(14,2) not null check (amount > 0),
  primary key (user_id, cat)
);

alter table public.expenses enable row level security;
alter table public.budgets  enable row level security;

drop policy if exists "own expenses" on public.expenses;
create policy "own expenses" on public.expenses
  for all to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

drop policy if exists "own budgets" on public.budgets;
create policy "own budgets" on public.budgets
  for all to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());
