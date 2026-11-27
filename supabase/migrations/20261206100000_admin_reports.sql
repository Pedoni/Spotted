-- Pannello admin per le segnalazioni (#70).
--
-- Un ruolo **admin** vede le segnalazioni aperte di tutti i canali e può
-- chiuderle e agire sul contenuto segnalato. Serve a moderare i contenuti per
-- cui il proprietario del canale non basta (e, più avanti, news ed eventi, che
-- scrive proprio il proprietario).
--
-- Chi è admin lo decide solo il database: la colonna `profiles.is_admin` non è
-- leggibile né scrivibile dai client (le colonne leggibili di `profiles` sono
-- solo `id`, `username` e `created_at`, e l'`update` diretto è chiuso). Si
-- assegna a mano dal SQL editor di Supabase:
--
--   update public.profiles set is_admin = true where username = 'nome_utente';
--
-- Funzioni (security definer, solo `authenticated`):
--   is_admin()                       dice solo a chi chiama se è admin
--   admin_reports_page(limite, offset)
--                                    segnalazioni aperte di tutti i canali
--                                    (solo admin, altrimenti `42501`)
--   admin_act_on_report(id, azione)  solo admin (`42501`). Azioni:
--                                    `dismiss` (ignora), `resolve` (risolta
--                                    senza toccare il contenuto), `hide`
--                                    (nasconde lo spot o il commento) e
--                                    `remove` (rimuove lo spot, definitivo;
--                                    non vale per i commenti). `hide` e
--                                    `remove` chiudono tutte le segnalazioni
--                                    aperte su quel contenuto. `23514` per
--                                    un'azione non valida. `false` se la
--                                    segnalazione non esiste o non è aperta.
--
-- Anonimato: come per il proprietario, nessuno vede chi ha segnalato, e
-- l'admin non vede nemmeno l'autore del contenuto (non gli serve per
-- moderare).

alter table public.profiles
  add column is_admin boolean not null default false;

create function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(
    (select p.is_admin from public.profiles p
     where p.id = (select auth.uid())),
    false
  );
$$;

-- Segnalazioni aperte di tutti i canali, dalla più recente. `report_count` è
-- quante segnalazioni aperte ha lo stesso contenuto. Restano fuori i
-- contenuti già rimossi. `content_status` è lo stato del contenuto segnalato
-- (di uno spot o di un commento): se è già nascosto l'admin lo vede.
create function public.admin_reports_page(p_limit int, p_offset int)
returns table (
  id uuid,
  kind text,
  spot_id uuid,
  spot_title text,
  content text,
  reason text,
  details text,
  created_at timestamptz,
  channel_name text,
  channel_slug text,
  content_status text,
  report_count bigint
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not public.is_admin() then
    raise exception 'not an admin' using errcode = '42501';
  end if;

  return query
    select
      r.id,
      case when r.spot_id is not null then 'spot' else 'comment' end,
      s.id,
      s.title,
      coalesce(c.content, s.content),
      r.reason,
      r.details,
      r.created_at,
      ch.name,
      ch.slug,
      coalesce(c.status, s.status),
      count(*) over (partition by coalesce(r.spot_id, r.comment_id))
    from public.reports r
    left join public.comments c on c.id = r.comment_id
    join public.spots s on s.id = coalesce(r.spot_id, c.spot_id)
    join public.channels ch on ch.id = s.channel_id
    where r.status = 'open'
      and s.status <> 'removed'
    order by r.created_at desc, r.id
    limit least(greatest(p_limit, 1), 100)
    offset greatest(p_offset, 0);
end;
$$;

create function public.admin_act_on_report(p_report_id uuid, p_action text)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_spot_id uuid;
  v_comment_id uuid;
  v_status text;
begin
  if not public.is_admin() then
    raise exception 'not an admin' using errcode = '42501';
  end if;
  if p_action is null
     or p_action <> all (array['dismiss', 'resolve', 'hide', 'remove']) then
    raise exception 'invalid action' using errcode = '23514';
  end if;

  select r.spot_id, r.comment_id, r.status
  into v_spot_id, v_comment_id, v_status
  from public.reports r where r.id = p_report_id;

  if not found or v_status <> 'open' then
    return false;
  end if;

  if p_action = 'dismiss' then
    update public.reports set status = 'dismissed' where id = p_report_id;
    return true;
  end if;
  if p_action = 'resolve' then
    update public.reports set status = 'resolved' where id = p_report_id;
    return true;
  end if;

  -- Nascondere o rimuovere il contenuto, poi chiudere tutte le segnalazioni
  -- aperte su di esso.
  if v_spot_id is not null then
    update public.spots
    set status = case when p_action = 'remove' then 'removed' else 'hidden' end
    where id = v_spot_id and status in ('published', 'hidden');
  else
    -- I commenti si nascondono ma non si rimuovono.
    if p_action = 'remove' then
      raise exception 'comments cannot be removed' using errcode = '23514';
    end if;
    update public.comments set status = 'hidden'
    where id = v_comment_id and status = 'published';
  end if;

  update public.reports
  set status = 'resolved'
  where status = 'open'
    and (spot_id = v_spot_id or comment_id = v_comment_id);
  return true;
end;
$$;

revoke execute on function public.is_admin() from public, anon;
revoke execute on function public.admin_reports_page(int, int)
  from public, anon;
revoke execute on function public.admin_act_on_report(uuid, text)
  from public, anon;

grant execute on function public.is_admin() to authenticated;
grant execute on function public.admin_reports_page(int, int) to authenticated;
grant execute on function public.admin_act_on_report(uuid, text)
  to authenticated;
