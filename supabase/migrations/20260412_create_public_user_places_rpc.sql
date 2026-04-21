create or replace function public.get_public_user_places()
returns table (
  name text,
  type text,
  mood_tags text[],
  latitude double precision,
  longitude double precision,
  created_at timestamptz
)
language sql
security definer
set search_path = public
as $$
  select
    user_places.name,
    user_places.type,
    user_places.mood_tags,
    user_places.latitude,
    user_places.longitude,
    user_places.created_at
  from public.user_places;
$$;

revoke all on function public.get_public_user_places() from public;
grant execute on function public.get_public_user_places() to anon;
grant execute on function public.get_public_user_places() to authenticated;
