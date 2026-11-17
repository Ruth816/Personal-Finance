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

-- Proof of payment (assoc dues, property tax): a private folder, photos or PDFs up to 10 MB.
-- Kept until you delete the payment; not affected by the 1-year receipt photo limit.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('proofs', 'proofs', false, 10485760, array['image/jpeg', 'application/pdf'])
on conflict (id) do nothing;

drop policy if exists "own proofs: read" on storage.objects;
create policy "own proofs: read" on storage.objects
  for select to authenticated
  using (bucket_id = 'proofs' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "own proofs: upload" on storage.objects;
create policy "own proofs: upload" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'proofs' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "own proofs: replace" on storage.objects;
create policy "own proofs: replace" on storage.objects
  for update to authenticated
  using (bucket_id = 'proofs' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "own proofs: delete" on storage.objects;
create policy "own proofs: delete" on storage.objects
  for delete to authenticated
  using (bucket_id = 'proofs' and (storage.foldername(name))[1] = auth.uid()::text);
