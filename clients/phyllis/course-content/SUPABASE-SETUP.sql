-- ============================================================
-- CLIENT NOTES TABLE — Phyllis Course Content Tracker
-- ============================================================
-- Paste this into Lovable Cloud SQL Editor and click "Run".
-- One-time setup. Safe to re-run (uses IF NOT EXISTS).
-- ============================================================

-- 1. Create the table
create table if not exists public.client_notes (
  id uuid primary key default gen_random_uuid(),
  client_slug text not null,
  note_key text not null,
  content text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (client_slug, note_key)
);

-- 2. Index for fast lookups by client
create index if not exists client_notes_slug_idx
  on public.client_notes (client_slug);

-- 3. Updated_at auto-bump trigger
create or replace function public.client_notes_touch_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_client_notes_touch on public.client_notes;
create trigger trg_client_notes_touch
  before update on public.client_notes
  for each row execute function public.client_notes_touch_updated_at();

-- 4. Enable Row Level Security
alter table public.client_notes enable row level security;

-- 5. RLS policies — allow anon to read/write notes for 'phyllis' only
--    (Ken's viewer page uses anon key; Phyllis's tracker uses anon key)

drop policy if exists "anon can read phyllis notes" on public.client_notes;
create policy "anon can read phyllis notes"
  on public.client_notes for select
  to anon
  using (client_slug = 'phyllis');

drop policy if exists "anon can insert phyllis notes" on public.client_notes;
create policy "anon can insert phyllis notes"
  on public.client_notes for insert
  to anon
  with check (client_slug = 'phyllis');

drop policy if exists "anon can update phyllis notes" on public.client_notes;
create policy "anon can update phyllis notes"
  on public.client_notes for update
  to anon
  using (client_slug = 'phyllis')
  with check (client_slug = 'phyllis');

-- 6. Verify
select 'client_notes table ready' as status, count(*) as existing_rows
from public.client_notes;
