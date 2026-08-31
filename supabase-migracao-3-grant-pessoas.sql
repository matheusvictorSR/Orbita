-- ============================================================
-- ÓRBITA — migração 3: corrige permissão faltando em "pessoas"
--
-- Bug meu: na migração 2, dei "revoke all ... from anon,
-- authenticated" na tabela pessoas (herdado da versão com PIN
-- sem Auth) e só devolvi acesso pra "anon" — nunca pra
-- "authenticated", que é o papel que passou a importar depois
-- que o login virou de verdade. Resultado: toda leitura de
-- perfil dava "permission denied for table pessoas", mesmo com
-- as políticas de RLS corretas — RLS só entra em jogo depois
-- que a permissão de base já libera a tabela.
--
-- As outras nove tabelas não têm esse problema: foram criadas
-- com a exposição automática ligada, que já concede a permissão
-- de base sozinha.
-- ============================================================

grant select, update on public.pessoas to authenticated;
