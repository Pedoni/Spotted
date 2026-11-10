-- Spot (0.3.0): pubblicazione anonima, feed per canale, "i miei spot".
--
-- Già in baseline: `author_id` non è leggibile dai client (grant per colonna),
-- le policy RLS di lettura (solo spot `published`), inserimento e cancellazione
-- da parte dell'autore. Questa migrazione:
--   * restringe l'insert alle sole colonne scrivibili (niente `status`,
--     `created_at`, `updated_at` decisi dal client);
--   * toglie la modifica degli spot agli autori (si possono solo cancellare);
--   * aggiunge i vincoli di lunghezza di titolo (1-100) e testo (1-2000);
--   * aggiunge `my_spots_page(limit, offset)`: i propri spot, con nome e slug
--     del canale, paginati.

-- Insert: solo queste colonne. `status` resta 'published' per default.
revoke insert on public.spots from anon, authenticated;
grant insert (author_id, channel_id, title, content)
  on public.spots to authenticated;

-- Gli spot non si modificano.
drop policy if exists "Authors update their own spots" on public.spots;
revoke update on public.spots from anon, authenticated;

alter table public.spots
  add constraint spots_title_length
    check (char_length(btrim(title)) between 1 and 100),
  add constraint spots_content_length
    check (char_length(btrim(content)) between 1 and 2000);

create or replace function public.my_spots_page(p_limit int, p_offset int)
returns table (
  id uuid,
  channel_id uuid,
  channel_name text,
  channel_slug text,
  title text,
  content text,
  created_at timestamptz
)
language sql
security definer
set search_path = ''
as $$
  select s.id, s.channel_id, c.name, c.slug, s.title, s.content, s.created_at
  from public.spots s
  join public.channels c on c.id = s.channel_id
  where s.author_id = (select auth.uid())
    and s.status = 'published'
  order by s.created_at desc, s.id
  limit least(greatest(p_limit, 1), 100)
  offset greatest(p_offset, 0);
$$;

revoke execute on function public.my_spots_page(int, int) from public, anon;
grant execute on function public.my_spots_page(int, int) to authenticated;
