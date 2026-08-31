-- ============================================================
-- ÓRBITA — schema (login por Auth real: e-mail da empresa + PIN)
--
-- Este arquivo é a referência do banco do zero. Se você já rodou
-- uma versão anterior deste schema, NÃO rode este arquivo de novo
-- por cima — use supabase-migracao-2-auth.sql, que ajusta o que
-- já existe em vez de recriar.
--
-- Login é feito pelo Auth do Supabase: e-mail precisa terminar em
-- @redesaoroque.com.br, e a senha é um PIN de 6 dígitos escolhido
-- por cada pessoa. Nome e cor do avatar também são escolhidos no
-- cadastro — não existe uma lista fixa de pessoas mais.
--
-- Como rodar (projeto novo e vazio): cole este arquivo inteiro no
-- SQL Editor do painel do Supabase e execute uma vez. Depois, em
-- Authentication → configurações de senha, baixe o comprimento
-- mínimo para 6 — é o menor valor que o Supabase aceita; abaixo
-- disso, o painel recusa a senha antes de chegar no seu código.
-- ============================================================

create extension if not exists pgcrypto;   -- gen_random_uuid()
create extension if not exists btree_gist; -- exclusion constraint das sprints

-- ============================================================
-- PESSOAS
-- Ligada ao auth.users do Supabase — não guardamos senha nem
-- e-mail aqui, isso já é o Auth. Esta tabela só guarda o que o
-- app precisa mostrar: nome, iniciais, cor do avatar.
-- ============================================================

create table public.pessoas (
  id        uuid primary key references auth.users (id) on delete cascade,
  nome      text not null,
  iniciais  text not null,
  -- mesmas seis cores usadas nos Espaços, já calibradas para o
  -- texto branco do avatar não reprovar em contraste (AA).
  cor       text not null default '#5B4BFF'
            check (cor in ('#5B4BFF','#D91060','#007A55','#AD5E00','#007E9E','#8B35F0')),
  ausente   boolean not null default false,
  -- pode editar/apagar Espaços e Projetos. Ninguém nasce admin —
  -- vira depois de criar a conta, com um UPDATE manual (ver o
  -- fim deste arquivo).
  admin     boolean not null default false,
  criado_em timestamptz not null default now()
);

-- Cria o perfil sozinho quando alguém se cadastra, com o nome e
-- a cor que a pessoa escolheu na tela (chegam via metadata do
-- signUp). Recusa de cara qualquer e-mail que não seja da empresa
-- — é a única barreira contra cadastro aberto para qualquer um
-- que ache a URL pública do GitHub Pages.
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

create trigger ao_criar_usuario
  after insert on auth.users
  for each row execute function public.lidar_novo_usuario();

-- ============================================================
-- ESPAÇOS
-- ============================================================

create table public.espacos (
  id        uuid primary key default gen_random_uuid(),
  nome      text not null,
  tom       text not null check (tom in ('indigo','rosa','menta','ambar','ciano','violeta')),
  descricao text,
  criado_em timestamptz not null default now()
);

-- ============================================================
-- PROJETOS
-- ============================================================

create table public.projetos (
  id         uuid primary key default gen_random_uuid(),
  espaco_id  uuid not null references public.espacos (id) on delete restrict,
  nome       text not null,
  descricao  text,
  prazo      date,
  criado_em  timestamptz not null default now()
);

create index idx_projetos_espaco on public.projetos (espaco_id);

-- ============================================================
-- SPRINTS
-- O número é fixado na criação e nunca muda — mesmo que as datas
-- sejam corrigidas depois e a ordem cronológica saia de lugar,
-- porque tarefas já criadas carregam esse número na etiqueta.
-- ============================================================

create table public.sprints (
  id         uuid primary key default gen_random_uuid(),
  projeto_id uuid not null references public.projetos (id) on delete cascade,
  numero     int not null,
  inicio     date not null,
  fim        date not null,
  criado_em  timestamptz not null default now(),
  constraint sprints_periodo_valido check (fim >= inicio),
  constraint sprints_numero_unico unique (projeto_id, numero)
);

-- O banco recusa sozinho uma sprint cujo período encoste em outra
-- do mesmo projeto — a mesma regra que hoje é checada à mão em
-- validarPeriodo() no JavaScript, aqui garantida pelo Postgres.
alter table public.sprints
  add constraint sprints_sem_sobreposicao
  exclude using gist (
    projeto_id with =,
    daterange(inicio, fim, '[]') with &&
  );

create index idx_sprints_projeto on public.sprints (projeto_id);

-- ============================================================
-- ENTREGAS (backlog)
-- "situacao" guarda só o que a pessoa escolhe. "Atrasado" não
-- entra aqui — continua sendo calculado (fim no passado e ainda
-- não entregue), do mesmo jeito que sitEntrega() faz hoje no app.
-- ============================================================

create table public.entregas (
  id              uuid primary key default gen_random_uuid(),
  projeto_id      uuid not null references public.projetos (id) on delete cascade,
  nome            text not null,
  descricao       text,
  responsavel_id  uuid references public.pessoas (id) on delete set null,
  inicio          date not null,
  fim             date not null,
  situacao        text not null default 'planejado' check (situacao in ('planejado','curso','entregue')),
  criado_em       timestamptz not null default now(),
  constraint entregas_periodo_valido check (fim >= inicio)
);

create index idx_entregas_projeto on public.entregas (projeto_id);

-- ============================================================
-- TAREFAS
-- ============================================================

create table public.tarefas (
  id              uuid primary key default gen_random_uuid(),
  projeto_id      uuid not null references public.projetos (id) on delete cascade,
  entrega_id      uuid references public.entregas (id) on delete set null,
  sprint_id       uuid references public.sprints (id) on delete set null,
  dependencia_id  uuid references public.tarefas (id) on delete set null,
  titulo          text not null,
  descricao       text,
  revisor_id      uuid references public.pessoas (id) on delete set null,
  prazo           date not null,
  situacao        text not null default 'afazer' check (situacao in ('afazer','fazendo','revisao','feito')),
  recorrencia     text check (recorrencia in ('semanal','mensal')),
  criado_em       timestamptz not null default now()
);

create index idx_tarefas_projeto     on public.tarefas (projeto_id);
create index idx_tarefas_entrega     on public.tarefas (entrega_id);
create index idx_tarefas_sprint      on public.tarefas (sprint_id);

-- Responsáveis: várias pessoas por tarefa, uma linha por vínculo
-- (mesmo padrão de subtarefas/comentários/anexos).
create table public.tarefas_responsaveis (
  tarefa_id  uuid not null references public.tarefas (id) on delete cascade,
  pessoa_id  uuid not null references public.pessoas (id) on delete cascade,
  primary key (tarefa_id, pessoa_id)
);
create index idx_tarefas_resp_pessoa on public.tarefas_responsaveis (pessoa_id);

-- ============================================================
-- SUBTAREFAS, COMENTÁRIOS, ANEXOS
-- Hoje vivem como array dentro da tarefa; aqui viram tabela
-- própria, uma linha por item, todas cascata: some a tarefa,
-- some tudo que é só dela.
-- ============================================================

create table public.subtarefas (
  id         uuid primary key default gen_random_uuid(),
  tarefa_id  uuid not null references public.tarefas (id) on delete cascade,
  titulo     text not null,
  concluida  boolean not null default false,
  ordem      int not null default 0,
  criado_em  timestamptz not null default now()
);

create table public.comentarios (
  id         uuid primary key default gen_random_uuid(),
  tarefa_id  uuid not null references public.tarefas (id) on delete cascade,
  autor_id   uuid references public.pessoas (id) on delete set null,
  texto      text not null,
  criado_em  timestamptz not null default now()
);

create table public.anexos (
  id         uuid primary key default gen_random_uuid(),
  tarefa_id  uuid not null references public.tarefas (id) on delete cascade,
  tipo       text not null check (tipo in ('planilha','texto','apresentacao','pdf','link')),
  nome       text not null,
  url        text not null,
  criado_em  timestamptz not null default now()
);

create index idx_subtarefas_tarefa  on public.subtarefas (tarefa_id);
create index idx_comentarios_tarefa on public.comentarios (tarefa_id);
create index idx_anexos_tarefa      on public.anexos (tarefa_id);

-- ============================================================
-- ATIVIDADES (o feed "Atualizações" da página inicial)
-- ============================================================

create table public.atividades (
  id         uuid primary key default gen_random_uuid(),
  tarefa_id  uuid not null references public.tarefas (id) on delete cascade,
  autor_id   uuid references public.pessoas (id) on delete set null,
  verbo      text not null,
  criado_em  timestamptz not null default now()
);

create index idx_atividades_tarefa    on public.atividades (tarefa_id);
create index idx_atividades_criado_em on public.atividades (criado_em desc);

-- ============================================================
-- ROW LEVEL SECURITY
-- Só quem tem conta e está logado (e-mail @redesaoroque.com.br,
-- confirmado pelo gatilho acima) lê e escreve qualquer coisa.
-- Não existe hoje noção de projeto privado — todo autenticado
-- acessa todos os Espaços, igual já era no protótipo.
--
-- "pessoas" é a exceção: todo autenticado LÊ o perfil de todo
-- mundo (precisa, para nome e avatar aparecerem em toda a
-- ferramenta), mas só EDITA o próprio.
-- ============================================================

alter table public.pessoas    enable row level security;
alter table public.espacos    enable row level security;
alter table public.projetos   enable row level security;
alter table public.sprints    enable row level security;
alter table public.entregas   enable row level security;
alter table public.tarefas    enable row level security;
alter table public.tarefas_responsaveis enable row level security;
alter table public.subtarefas enable row level security;
alter table public.comentarios enable row level security;
alter table public.anexos     enable row level security;
alter table public.atividades enable row level security;

create policy "le todo mundo, edita so o proprio" on public.pessoas
  for select to authenticated using (true);
create policy "cada um edita so o proprio perfil" on public.pessoas
  for update to authenticated using (auth.uid() = id) with check (auth.uid() = id);

-- "pessoas" foi a única tabela deste schema que teve a permissão
-- de base revogada manualmente numa versão anterior (quando o
-- login ainda era PIN sem Auth). As outras nove ganham essa
-- permissão sozinhas, pela exposição automática do Supabase — só
-- esta precisa do grant explícito, ou RLS nunca chega a valer.
grant select, update on public.pessoas to authenticated;

-- Ler e criar Espaço/Projeto: qualquer autenticado. Editar e
-- apagar: só quem tem admin=true no próprio perfil — vale no
-- banco, não só escondendo botão na tela.
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
create policy "equipe autenticada acessa tudo" on public.sprints
  for all to authenticated using (true) with check (true);
create policy "equipe autenticada acessa tudo" on public.entregas
  for all to authenticated using (true) with check (true);
create policy "equipe autenticada acessa tudo" on public.tarefas
  for all to authenticated using (true) with check (true);
create policy "equipe autenticada acessa tudo" on public.tarefas_responsaveis
  for all to authenticated using (true) with check (true);
create policy "equipe autenticada acessa tudo" on public.subtarefas
  for all to authenticated using (true) with check (true);
create policy "equipe autenticada acessa tudo" on public.comentarios
  for all to authenticated using (true) with check (true);
create policy "equipe autenticada acessa tudo" on public.anexos
  for all to authenticated using (true) with check (true);
create policy "equipe autenticada acessa tudo" on public.atividades
  for all to authenticated using (true) with check (true);
