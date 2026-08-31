-- ============================================================
-- ÓRBITA — migração 4: editar/apagar Espaço e Projeto, só admin
--
-- Adiciona uma coluna "admin" em pessoas, e separa as políticas
-- de espacos/projetos: ler e criar continuam abertos pra equipe
-- toda (como já era); editar e apagar passam a exigir admin=true
-- no perfil de quem está pedindo. Isso vale de verdade no banco,
-- não só escondendo o botão na tela — quem tentar chamar a API
-- direto, sem passar pela interface, esbarra na mesma trava.
-- ============================================================

alter table public.pessoas add column admin boolean not null default false;

-- --- espacos: abre select/insert pra todo mundo, fecha update/delete pra admin
drop policy if exists "equipe autenticada acessa tudo" on public.espacos;

create policy "equipe le espacos" on public.espacos
  for select to authenticated using (true);
create policy "equipe cria espacos" on public.espacos
  for insert to authenticated with check (true);
create policy "so admin edita espacos" on public.espacos
  for update to authenticated
  using (exists (select 1 from public.pessoas where id = auth.uid() and admin = true))
  with check (exists (select 1 from public.pessoas where id = auth.uid() and admin = true));
create policy "so admin apaga espacos" on public.espacos
  for delete to authenticated
  using (exists (select 1 from public.pessoas where id = auth.uid() and admin = true));

-- --- projetos: mesmo padrão
drop policy if exists "equipe autenticada acessa tudo" on public.projetos;

create policy "equipe le projetos" on public.projetos
  for select to authenticated using (true);
create policy "equipe cria projetos" on public.projetos
  for insert to authenticated with check (true);
create policy "so admin edita projetos" on public.projetos
  for update to authenticated
  using (exists (select 1 from public.pessoas where id = auth.uid() and admin = true))
  with check (exists (select 1 from public.pessoas where id = auth.uid() and admin = true));
create policy "so admin apaga projetos" on public.projetos
  for delete to authenticated
  using (exists (select 1 from public.pessoas where id = auth.uid() and admin = true));

-- ============================================================
-- PRÓXIMO PASSO — depois de rodar isto
--
-- Se você ainda não tem sua própria conta (e-mail + PIN) criada
-- pela tela do app, crie primeiro. Depois, rode isto UMA VEZ,
-- trocando o e-mail pelo seu de verdade, pra virar admin:
--
-- update public.pessoas set admin = true
-- where id = (select id from auth.users where email = 'SEU-EMAIL-AQUI@redesaoroque.com.br');
--
-- Sem isso, ninguém vê os botões de editar/apagar — nem você.
-- ============================================================
