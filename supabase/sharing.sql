-- RLW App: let a second login (e.g. your husband) share your records.
-- Run once: Supabase → SQL Editor → New query → paste → Run. Safe to run again.
--
-- What the shared login can do with YOUR records:
--   Expenses log, refunds & cash back, receipts inbox, income figures: view, add, edit, delete
--   Everything else (budgets, rented and own-use properties, proofs): view only
-- Your own login is unchanged.

-- 1. Who shares whose records. Only you add rows here, from the SQL Editor (step 3 below).
create table if not exists public.members (
  member_id  uuid primary key references auth.users (id) on delete cascade,
  owner_id   uuid not null references auth.users (id) on delete cascade,
  name       text not null default '' check (char_length(name) <= 40),
  created_at timestamptz not null default now()
);
alter table public.members enable row level security;
drop policy if exists "see own membership" on public.members;
create policy "see own membership" on public.members
  for select to authenticated
  using (member_id = auth.uid() or owner_id = auth.uid());

-- The owner whose records the signed-in login shares (null for your own login).
create or replace function public.my_owner() returns uuid
  language sql stable security definer set search_path = public
  as $$ select owner_id from public.members where member_id = auth.uid() $$;

-- Each expense remembers which login entered it, so the log can show "added by …".
alter table public.expenses add column if not exists added_by uuid default auth.uid();

-- 2. What the shared login may do
-- Expenses, refunds, receipts inbox: full access
drop policy if exists "shared expenses" on public.expenses;
create policy "shared expenses" on public.expenses
  for all to authenticated
  using (user_id = public.my_owner()) with check (user_id = public.my_owner());

drop policy if exists "shared refunds" on public.refunds;
create policy "shared refunds" on public.refunds
  for all to authenticated
  using (user_id = public.my_owner()) with check (user_id = public.my_owner());

drop policy if exists "shared receipts" on public.receipts;
create policy "shared receipts" on public.receipts
  for all to authenticated
  using (user_id = public.my_owner()) with check (user_id = public.my_owner());

-- Budgets: view all; income figures (kept as 'inc:…' rows) may be added, changed and removed
drop policy if exists "shared budgets: read" on public.budgets;
create policy "shared budgets: read" on public.budgets
  for select to authenticated using (user_id = public.my_owner());
drop policy if exists "shared income: add" on public.budgets;
create policy "shared income: add" on public.budgets
  for insert to authenticated with check (user_id = public.my_owner() and cat like 'inc:%');
drop policy if exists "shared income: change" on public.budgets;
create policy "shared income: change" on public.budgets
  for update to authenticated
  using (user_id = public.my_owner() and cat like 'inc:%')
  with check (user_id = public.my_owner() and cat like 'inc:%');
drop policy if exists "shared income: remove" on public.budgets;
create policy "shared income: remove" on public.budgets
  for delete to authenticated using (user_id = public.my_owner() and cat like 'inc:%');

-- Properties: view only
drop policy if exists "shared properties: read" on public.properties;
create policy "shared properties: read" on public.properties
  for select to authenticated using (user_id = public.my_owner());

-- Receipt photos: view, upload, delete in your folder. Proofs of payment: view only.
drop policy if exists "shared receipt photos: read" on storage.objects;
create policy "shared receipt photos: read" on storage.objects
  for select to authenticated
  using (bucket_id = 'receipts' and (storage.foldername(name))[1] = public.my_owner()::text);
drop policy if exists "shared receipt photos: upload" on storage.objects;
create policy "shared receipt photos: upload" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'receipts' and (storage.foldername(name))[1] = public.my_owner()::text);
drop policy if exists "shared receipt photos: delete" on storage.objects;
create policy "shared receipt photos: delete" on storage.objects
  for delete to authenticated
  using (bucket_id = 'receipts' and (storage.foldername(name))[1] = public.my_owner()::text);
drop policy if exists "shared proofs: read" on storage.objects;
create policy "shared proofs: read" on storage.objects
  for select to authenticated
  using (bucket_id = 'proofs' and (storage.foldername(name))[1] = public.my_owner()::text);

-- 3. Link the logins. First create his login (Authentication → Users → Add user → Create new user,
--    tick Auto Confirm User). Then replace the two emails and the name below, and run just these lines:
--
-- insert into public.members (member_id, owner_id, name)
-- select h.id, o.id, 'HIS NAME'
-- from auth.users h, auth.users o
-- where h.email = 'his-email@example.com' and o.email = 'your-email@example.com'
-- on conflict (member_id) do update set owner_id = excluded.owner_id, name = excluded.name;
--
-- To stop sharing later: delete from public.members where name = 'HIS NAME';
