-- RLW App: loans you lend to friends and household (kept apart from expenses; never counted as spending)
-- Run once: Supabase → SQL Editor → New query → paste → Run. Safe to run again.
-- Run supabase/sharing.sql first if you share the app with a second login.

create table if not exists public.loans (
  id         uuid primary key,
  user_id    uuid not null default auth.uid() references auth.users (id) on delete cascade,
  data       jsonb not null default '{}'::jsonb,  -- borrower, date, amount, account, due date, notes, repayments
  updated_at timestamptz not null default now()
);
alter table public.loans enable row level security;

drop policy if exists "own loans" on public.loans;
create policy "own loans" on public.loans
  for all to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- The shared login may add, change and remove loans, like expenses.
drop policy if exists "shared loans" on public.loans;
create policy "shared loans" on public.loans
  for all to authenticated
  using (user_id = public.my_owner())
  with check (user_id = public.my_owner());
