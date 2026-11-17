-- Ruth's Expenses Log: receipts inbox
-- Run once, after schema.sql: Supabase → SQL Editor → New query → paste → Run.
-- Safe to run again.

-- 1. Each expense can keep the photo of its receipt
alter table public.expenses add column if not exists receipt_path text;

-- 2. Photos uploaded but not yet added to the log
create table if not exists public.receipts (
  id         uuid primary key,
  user_id    uuid not null default auth.uid() references auth.users (id) on delete cascade,
  path       text not null,
  created_at timestamptz not null default now()
);
alter table public.receipts enable row level security;
drop policy if exists "own receipts" on public.receipts;
create policy "own receipts" on public.receipts
  for all to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- 3. A private folder for the photos (JPEG only, at most 5 MB each)
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('receipts', 'receipts', false, 5242880, array['image/jpeg'])
on conflict (id) do nothing;

-- Each user can only see, upload and delete photos in their own folder (<user id>/...)
drop policy if exists "own receipt photos: read" on storage.objects;
create policy "own receipt photos: read" on storage.objects
  for select to authenticated
  using (bucket_id = 'receipts' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "own receipt photos: upload" on storage.objects;
create policy "own receipt photos: upload" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'receipts' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "own receipt photos: delete" on storage.objects;
create policy "own receipt photos: delete" on storage.objects
  for delete to authenticated
  using (bucket_id = 'receipts' and (storage.foldername(name))[1] = auth.uid()::text);
