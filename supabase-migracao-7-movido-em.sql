-- ============================================================
-- ÓRBITA — migração 7: quando a tarefa mudou de coluna
--
-- As colunas do quadro ordenavam por prazo, então o cartão mais
-- antigo ficava no topo de "Feito" — justamente o contrário do
-- que se quer ver. Para ordenar pelo mais recente é preciso
-- saber QUANDO cada tarefa entrou na coluna em que está.
--
-- Rodar uma vez no SQL Editor do Supabase.
-- ============================================================

alter table public.tarefas add column movido_em timestamptz;

-- Quem nunca se mexeu vale pela data de criação.
update public.tarefas set movido_em = criado_em where movido_em is null;

-- Quem já se mexeu: o registro de atividade guarda a hora de cada
-- passagem de coluna, então dá para recuperar o histórico real em
-- vez de jogar todo mundo na data de criação. Só os verbos de
-- movimento contam — comentário e anexo não movem a tarefa.
update public.tarefas t
   set movido_em = sub.quando
  from (
    select tarefa_id, max(criado_em) as quando
      from public.atividades
     where verbo in ('criou','começou','enviou para revisão','concluiu','moveu')
     group by tarefa_id
  ) sub
 where sub.tarefa_id = t.id
   and sub.quando > t.movido_em;

alter table public.tarefas alter column movido_em set default now();
alter table public.tarefas alter column movido_em set not null;
