-- Elenco iniziale dei topic. I client non possono scriverli (nessuna policy di
-- insert su topics): si aggiungono solo con una migrazione.

insert into public.topics (name, description) values
  ('Università', 'Pagine spotted di atenei e facoltà'),
  ('Scuola', 'Pagine spotted di scuole e istituti'),
  ('Città', 'Pagine spotted di città e quartieri'),
  ('Sport', 'Pagine spotted legate a sport e palestre'),
  ('Eventi', 'Pagine spotted di eventi, locali e serate'),
  ('Musica', 'Pagine spotted di concerti e scene musicali'),
  ('Lavoro', 'Pagine spotted di aziende e luoghi di lavoro')
on conflict (name) do nothing;
