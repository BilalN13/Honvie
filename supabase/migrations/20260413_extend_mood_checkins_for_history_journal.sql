alter table public.mood_checkins
  add column if not exists selected_place_name text,
  add column if not exists place_status text,
  add column if not exists written_note text;

comment on column public.mood_checkins.selected_place_name is
  'Chosen place name attached to the emotional check-in.';

comment on column public.mood_checkins.place_status is
  'Journal status for the selected place: favorite, later, or visited.';

comment on column public.mood_checkins.written_note is
  'Optional written note attached to the check-in entry.';
