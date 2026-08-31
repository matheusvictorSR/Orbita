-- ============================================================
-- ÓRBITA — migração 2: login vira Auth de verdade
--
-- Roda em cima do banco já criado por supabase-schema.sql.
-- Troca o PIN solto (sem conta, sem sessão) por Auth de verdade
-- do Supabase: cada pessoa cria a própria conta com e-mail
-- @redesaoroque.com.br e um PIN de 6 dígitos como senha, escolhe
-- nome e cor no cadastro.
--
-- Descarta as 4 pessoas fictícias inseridas na primeira rodada —
-- elas não têm conta de verdade por trás, e nada mais no banco
-- aponta pra elas ainda (nenhuma tarefa real foi criada).
--
-- Como rodar: cole tudo no SQL Editor do Supabase e execute uma
-- vez, no projeto que você já criou.
-- ============================================================

delete from public.pessoas;

drop function if exists public.conferir_pin(uuid, text);
drop function if exists public.definir_pin(uuid, text, text);
drop policy if exists "leitura publica dos perfis" on public.pessoas;
revoke all on public.pessoas from anon, authenticated;

-- pessoas passa a exigir uma conta real do Auth por trás. Sem
-- senha nem PIN guardado aqui — isso já vira trabalho do Auth.
alter table public.pessoas drop column pin_hash;

alter table public.pessoas
  add constraint pessoas_id_fkey
  foreign key (id) references auth.users (id) on delete cascade;

-- Cor vem de uma paleta fechada — as mesmas seis usadas nos
-- Espaços, já calibradas para o texto branco do avatar não
-- reprovar em contraste. Sem isso, alguém escolhendo uma cor
-- clara reabriria o mesmo bug que corrigi no protótipo.
alter table public.pessoas
  add constraint pessoas_cor_permitida
  check (cor in ('#5B4BFF','#D91060','#007A55','#AD5E00','#007E9E','#8B35F0'));

-- Cria o perfil sozinho quando alguém se cadastra, com o nome e
-- a cor que a pessoa escolheu na tela (chegam via metadata do
-- signUp). Recusa de cara qualquer e-mail que não seja da empresa.
create or replace function public.lidar_novo_usuario()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  v_nome     text;
  v_cor      text;
  v_iniciais text;
begin
  if new.email !~* '@redesaoroque\.com\.br$' then
    raise exception 'Cadastro permitido só para e-mail @redesaoroque.com.br';
  end if;

  v_nome := coalesce(new.raw_user_meta_data->>'nome', split_part(new.email, '@', 1));
  v_cor  := coalesce(new.raw_user_meta_data->>'cor', '#5B4BFF');

  v_iniciais := upper(
    left(split_part(v_nome, ' ', 1), 1) || left(split_part(v_nome, ' ', 2), 1)
  );
  if v_iniciais = '' then
    v_iniciais := upper(left(v_nome, 2));
  end if;

  insert into public.pessoas (id, nome, iniciais, cor)
  values (new.id, v_nome, v_iniciais, v_cor);

  return new;
end;
$$;

drop trigger if exists ao_criar_usuario on auth.users;
create trigger ao_criar_usuario
  after insert on auth.users
  for each row execute function public.lidar_novo_usuario();

alter table public.pessoas enable row level security;

create policy "le todo mundo, edita so o proprio" on public.pessoas
  for select to authenticated using (true);
create policy "cada um edita so o proprio perfil" on public.pessoas
  for update to authenticated using (auth.uid() = id) with check (auth.uid() = id);

-- As outras nove tabelas estavam liberadas para "anon" (sem
-- login nenhum, era o único jeito de funcionar antes). Agora que
-- existe login de verdade, só quem autenticou entra — troca o
-- "to anon" por "to authenticated" em cada uma.
drop policy if exists "equipe acessa tudo" on public.espacos;
drop policy if exists "equipe acessa tudo" on public.projetos;
drop policy if exists "equipe acessa tudo" on public.sprints;
drop policy if exists "equipe acessa tudo" on public.entregas;
drop policy if exists "equipe acessa tudo" on public.tarefas;
drop policy if exists "equipe acessa tudo" on public.subtarefas;
drop policy if exists "equipe acessa tudo" on public.comentarios;
drop policy if exists "equipe acessa tudo" on public.anexos;
drop policy if exists "equipe acessa tudo" on public.atividades;

create policy "equipe autenticada acessa tudo" on public.espacos
  for all to authenticated using (true) with check (true);
create policy "equipe autenticada acessa tudo" on public.projetos
  for all to authenticated using (true) with check (true);
create policy "equipe autenticada acessa tudo" on public.sprints
  for all to authenticated using (true) with check (true);
create policy "equipe autenticada acessa tudo" on public.entregas
  for all to authenticated using (true) with check (true);
create policy "equipe autenticada acessa tudo" on public.tarefas
  for all to authenticated using (true) with check (true);
create policy "equipe autenticada acessa tudo" on public.subtarefas
  for all to authenticated using (true) with check (true);
create policy "equipe autenticada acessa tudo" on public.comentarios
  for all to authenticated using (true) with check (true);
create policy "equipe autenticada acessa tudo" on public.anexos
  for all to authenticated using (true) with check (true);
create policy "equipe autenticada acessa tudo" on public.atividades
  for all to authenticated using (true) with check (true);
