-- ============================================================
-- ÓRBITA — migração 5: mais de um responsável por tarefa
--
-- Troca a coluna única "tarefas.responsavel_id" por uma tabela de
-- junção, mesmo padrão de subtarefas/comentários/anexos: uma linha
-- por pessoa vinculada, cascata quando a tarefa some.
-- ============================================================

create table public.tarefas_responsaveis (
  tarefa_id  uuid not null references public.tarefas (id) on delete cascade,
  pessoa_id  uuid not null references public.pessoas (id) on delete cascade,
  primary key (tarefa_id, pessoa_id)
);
create index idx_tarefas_resp_pessoa on public.tarefas_responsaveis (pessoa_id);

alter table public.tarefas_responsaveis enable row level security;
create policy "equipe autenticada acessa tudo" on public.tarefas_responsaveis
  for all to authenticated using (true) with check (true);

-- migra quem já tinha responsavel_id preenchido
insert into public.tarefas_responsaveis (tarefa_id, pessoa_id)
  select id, responsavel_id from public.tarefas where responsavel_id is not null;

alter table public.tarefas drop column responsavel_id;
drop index if exists idx_tarefas_responsavel;
