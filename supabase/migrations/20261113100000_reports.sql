-- Segnalazioni (0.5.0, parte 2).
--
-- Chiunque può segnalare uno spot o un commento visibili (non i propri). Le
-- segnalazioni le vede e le gestisce il proprietario del canale in cui sta il
-- contenuto; la vista globale per l'admin arriva con la 0.8.0.
--
-- `reports` si chiude ai client: nessuno, nemmeno il proprietario, vede chi ha
-- segnalato. Si usano solo funzioni (security definer, solo `authenticated`):
--   report_spot(spot_id, reason, details)         segnala uno spot
--   report_comment(comment_id, reason, details)   segnala un commento
--   channel_reports_page(channel, limit, offset)  segnalazioni aperte (proprietario)
--   resolve_report(report_id, status)             resolved | dismissed (proprietario)
--
-- Errori: segnalare due volte lo stesso contenuto dà 23505 (ConflictFailure),
-- un motivo o un testo non validi 23514 (ValidationFailure), segnalare un
-- proprio contenuto 42501 (PermissionFailure). Chi non è proprietario riceve
-- 42501 sulle funzioni del proprietario.

-- ============================================================
-- Motivi fissi, testo limitato, niente doppie segnalazioni
-- ============================================================

-- `not valid`: i controlli valgono per le nuove righe senza rileggere quelle
-- esistenti.
alter table public.reports
  add constraint reports_reason_check
    check (reason = any (array['spam', 'offensive', 'hate', 'other'])) not valid,
  add constraint reports_details_check
    check (details is null or length(details) <= 500) not valid;

create unique index reports_reporter_spot_key
  on public.reports (reporter_id, spot_id) where spot_id is not null;
create unique index reports_reporter_comment_key
  on public.reports (reporter_id, comment_id) where comment_id is not null;

-- ============================================================
-- Chiusura della tabella ai client
-- ============================================================

revoke all on public.reports from anon, authenticated;
drop policy if exists "Users create their own reports" on public.reports;
drop policy if exists "Users read their own reports" on public.reports;

-- ============================================================
-- Segnalare
-- ============================================================

-- true se la segnalazione è stata creata, false se lo spot non esiste o non è
-- pubblicato.
create or replace function public.report_spot(
  p_spot_id uuid,
  p_reason text,
  p_details text default null
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_author uuid;
begin
  if (select auth.uid()) is null then
    raise exception 'not authenticated' using errcode = '42501';
  end if;

  select s.author_id into v_author
  from public.spots s
  where s.id = p_spot_id and s.status = 'published';

  if not found then
    return false;
  end if;
  if v_author = (select auth.uid()) then
    raise exception 'cannot report own content' using errcode = '42501';
  end if;

  insert into public.reports (reporter_id, spot_id, reason, details)
  values (
    (select auth.uid()), p_spot_id, p_reason, nullif(btrim(p_details), '')
  );
  return true;
end;
$$;

-- true se la segnalazione è stata creata, false se il commento non esiste o
-- non è visibile (commento nascosto o spot non pubblicato).
create or replace function public.report_comment(
  p_comment_id uuid,
  p_reason text,
  p_details text default null
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_author uuid;
begin
  if (select auth.uid()) is null then
    raise exception 'not authenticated' using errcode = '42501';
  end if;

  select c.author_id into v_author
  from public.comments c
  join public.spots s on s.id = c.spot_id
  where c.id = p_comment_id
    and c.status = 'published'
    and s.status = 'published';

  if not found then
    return false;
  end if;
  if v_author = (select auth.uid()) then
    raise exception 'cannot report own content' using errcode = '42501';
  end if;

  insert into public.reports (reporter_id, comment_id, reason, details)
  values (
    (select auth.uid()), p_comment_id, p_reason, nullif(btrim(p_details), '')
  );
  return true;
end;
$$;

-- ============================================================
-- Gestione da parte del proprietario del canale
-- ============================================================

-- Segnalazioni aperte sui contenuti del canale, dalla più recente. Non c'è mai
-- chi ha segnalato. `spot_id` è lo spot segnalato o quello del commento
-- segnalato; `kind` vale 'spot' o 'comment'. Restano fuori i contenuti già
-- rimossi.
create or replace function public.channel_reports_page(
  p_channel_id uuid,
  p_limit int,
  p_offset int
)
returns table (
  id uuid,
  kind text,
  spot_id uuid,
  spot_title text,
  content text,
  reason text,
  details text,
  created_at timestamptz
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not public.is_channel_owner(p_channel_id) then
    raise exception 'not the channel owner' using errcode = '42501';
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
      r.created_at
    from public.reports r
    left join public.comments c on c.id = r.comment_id
    join public.spots s on s.id = coalesce(r.spot_id, c.spot_id)
    where r.status = 'open'
      and s.channel_id = p_channel_id
      and s.status <> 'removed'
    order by r.created_at desc, r.id
    limit least(greatest(p_limit, 1), 100)
    offset greatest(p_offset, 0);
end;
$$;

-- true se lo stato è cambiato. Si chiude solo una segnalazione aperta; stato non
-- valido: 23514.
create or replace function public.resolve_report(
  p_report_id uuid,
  p_status text
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_channel_id uuid;
  v_current text;
begin
  if p_status is null or p_status <> all (array['resolved', 'dismissed']) then
    raise exception 'invalid status' using errcode = '23514';
  end if;

  select s.channel_id, r.status into v_channel_id, v_current
  from public.reports r
  left join public.comments c on c.id = r.comment_id
  join public.spots s on s.id = coalesce(r.spot_id, c.spot_id)
  where r.id = p_report_id;

  if v_channel_id is null then
    return false;
  end if;
  if not public.is_channel_owner(v_channel_id) then
    raise exception 'not the channel owner' using errcode = '42501';
  end if;
  if v_current <> 'open' then
    return false;
  end if;

  update public.reports set status = p_status where id = p_report_id;
  return true;
end;
$$;

-- ============================================================
-- Permessi: solo gli utenti autenticati
-- ============================================================

revoke execute on function public.report_spot(uuid, text, text) from public, anon;
revoke execute on function public.report_comment(uuid, text, text) from public, anon;
revoke execute on function public.channel_reports_page(uuid, int, int) from public, anon;
revoke execute on function public.resolve_report(uuid, text) from public, anon;

grant execute on function public.report_spot(uuid, text, text) to authenticated;
grant execute on function public.report_comment(uuid, text, text) to authenticated;
grant execute on function public.channel_reports_page(uuid, int, int) to authenticated;
grant execute on function public.resolve_report(uuid, text) to authenticated;
