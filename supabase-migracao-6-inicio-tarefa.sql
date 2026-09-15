-- ============================================================
-- ÓRBITA — migração 6: tarefa ganha data de início
--
-- Até aqui a tarefa só tinha "prazo" (a data de entrega). Para
-- desenhar o cronograma — cada tarefa como uma barra que ocupa
-- um período, não um ponto — ela precisa também de onde começa.
--
-- Rodar uma vez no SQL Editor do Supabase.
-- ============================================================

alter table public.tarefas add column inicio date;

-- Quem já existe começa no dia em que foi criada: é a regra que
-- vale para as tarefas novas, aplicada para trás.
update public.tarefas
   set inicio = (criado_em at time zone 'America/Sao_Paulo')::date
 where inicio is null;

-- Ninguém termina antes de começar. Tarefa criada depois do
-- próprio prazo (importada, ou com o prazo puxado para trás)
-- passa a começar no dia do prazo.
update public.tarefas
   set inicio = prazo
 where inicio > prazo;

alter table public.tarefas alter column inicio set default current_date;
alter table public.tarefas alter column inicio set not null;
