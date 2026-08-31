# Órbita — protótipo de gestão de projetos

Ferramenta compartilhada de gestão dos projetos da consultoria. **Protótipo navegável**, para a equipe usar e criticar antes de qualquer construção com dados reais.

Projeto novo e independente — **não segue** o `CLAUDE.md` do Copiloto SR.

## Como abrir

Duplo clique em `index.html`. Feito para computador. **Precisa de internet agora** — o login fala de verdade com um banco de dados (Supabase); antes disso não era preciso.

## Login

O login é real, não mais teatro. Cada pessoa cria a própria conta: e-mail da empresa, um PIN de 6 dígitos como senha, nome e cor do avatar escolhidos na hora. Guardado de verdade, com sessão de verdade — recarregar a página mantém você logado, como qualquer site com login funciona.

Só e-mail **@redesaoroque.com.br** consegue se cadastrar — quem tenta com outro domínio é recusado, tanto na tela (para dar o aviso na hora) quanto no próprio banco (a checagem que vale de verdade; a da tela é só conveniência).

O que o login faz:

- Define quem é "você" no app — a saudação da página inicial, o autor dos comentários novos, o responsável padrão ao criar tarefa e entregável — a partir do perfil de verdade, não de um personagem fictício
- Fecha o acesso a quem não tem conta — sem login, não existe caminho para ler nem escrever nada no banco (as tabelas exigem `authenticated`, não aceitam a chave pública sozinha)
- Tem **Sair**, no rodapé da barra lateral, que encerra a sessão de verdade e devolve à tela de login

**Espaços e Projetos são reais e salvos no banco.** Quem cria, edita e apaga um Espaço ou Projeto vê a mudança persistir de verdade — sobrevive a recarregar a página, e aparece para qualquer outra conta que logar. **Editar e apagar são restritos a quem tem `admin = true`** no próprio perfil, e a trava vale no banco (política de RLS), não só escondendo o botão na tela — quem tentar chamar a API direto, sem passar pela interface, esbarra na mesma recusa. Criar um Espaço ou Projeto continua aberto a qualquer pessoa logada.

**Tarefas, Sprints, Entregas, comentários e anexos também são reais e salvos no banco.** É o mesmo padrão: criar, mudar a fase arrastando ou pela etiqueta, comentar, anexar um link, marcar subtarefa, tudo persiste de verdade e sobrevive a recarregar. Diferente de Espaço/Projeto, aqui não há gate de admin — qualquer pessoa logada cria e edita, porque é o trabalho do dia a dia de quem executa. Apagar uma tarefa leva junto (no próprio banco) suas subtarefas, comentários, anexos e o rastro dela no feed de Atualizações; apagar uma entrega solta as tarefas ligadas em vez de apagá-las, do jeito que já era localmente.

**O que ainda não existe:** criar ou apagar uma subtarefa (só marcar/desmarcar — a tela nunca teve um jeito de adicionar uma), e apagar uma sprint (só criar e corrigir datas). Nenhum dos dois foi pedido ainda; o banco já suporta os dois no dia em que forem.

**Detalhe técnico:** ver `supabase-schema.sql` (e as quatro migrações numeradas, se você recriar o banco do zero, use só o schema — as migrações existem porque o schema mudou de forma ao longo da construção, sobre um banco que já existia). O schema sempre teve as dez tabelas — foi rodado por inteiro antes mesmo do login virar Auth real — então esta etapa não precisou de nenhuma migração nova, só ligar o JavaScript nas tabelas que já existiam. O cadastro aceita ou recusa o e-mail dentro de um gatilho no Postgres (`lidar_novo_usuario`), não no JavaScript — por isso a regra vale mesmo se alguém tentar burlar a tela.

## A estrutura

**Espaço → Projeto → tarefas.**

Um Espaço é só um agrupador com nome e cor — a ferramenta não impõe se ele é um cliente, uma frente de trabalho ou um time. A ferramenta abre **sem nenhum** Espaço ou Projeto: quem usar cria os seus.

## A página inicial

Três cartões de resumo no topo e dois painéis lado a lado: **Atualizações** e **Próximos prazos**.

Os cartões de resumo não são número grande com rótulo cinza. Cada um carrega a própria micro-visualização, e o desenho **é** o dado:

- **Projetos ativos** — uma barra por projeto, na cor do Espaço, com altura proporcional ao progresso. Dá para ver a distribuição entre Espaços de relance.
- **Vencem em 7 dias** — uma tira dos próximos sete dias, com marca nos dias que têm vencimento.
- **Tarefas no prazo** — um segmento por tarefa aberta; os vencidos ficam vermelhos.

## A aposta visual

**O acento do app é uma variável CSS viva.** Entrar num Espaço transiciona a cor de tudo ao mesmo tempo — logo, navegação ativa, botões, barras de progresso, anel de foco, realce dos modais. Você sabe onde está pela cor, sem ler.

Isso só funciona porque o acento mora no elemento `<html>`, que sobrevive a cada redesenho da tela. Se ele fosse escrito junto com o conteúdo, a cor trocaria de estalo em vez de transicionar.

Seis matizes disponíveis para Espaços: índigo, rosa, menta, âmbar, ciano e violeta.

Cada matiz tem **quatro tons**, e a distinção importa:

| Tom | Onde entra |
| --- | --- |
| `c` vivo | pontos, barras, preenchimentos — nunca recebe texto |
| `cb` sólido | o único que recebe texto branco em cima, calibrado para AA |
| `cd` fundo | texto colorido sobre fundo claro |
| `cf` lavagem | fundos tingidos, estados ativos |

Texto branco sobre o menta vivo dava 2,25:1. É por isso que o botão primário usa `cb` e não `c`.

**Tipografia:** Plus Jakarta Sans, com salto forte de peso. JetBrains Mono só em datas e contadores.

## O quadro

Quatro etapas, cada uma com **moldura própria**: A fazer **azul**, Fazendo **amarelo**, Em revisão **violeta**, Feito **verde**.

As cores não saem do azul/amarelo/verde crus — passam pelos quatro tons da identidade. O amarelo puro é o motivo: como moldura ele dava 1,07 de contraste contra o fundo, ou seja, sumia. A moldura dele puxa para âmbar (#DAAE33) e chega a 1,88; o rótulo escrito usa um âmbar bem mais fundo, que passa em AA.

Esta é a **única cor do app que não segue o acento do Espaço** — o fluxo de trabalho é o mesmo em todo lugar, então não faz sentido ele mudar de cor conforme o cliente.

**Em revisão exige dizer quem revisa.** Tanto arrastar quanto trocar a etiqueta dentro da tarefa abrem a pergunta "Quem revisa?" antes de mover. A sugestão é alguém diferente do responsável. No cartão, o revisor aparece com um anel violeta ao lado do responsável.

**Arrastar ficou mais fácil.** Antes só o topo da lista aceitava a soltura. Agora o alvo é a **coluna inteira** — cabeçalho, espaço vazio, o miolo entre cartões — e ela inteira se acende com um retângulo tracejado mostrando onde o cartão vai cair.

**Só há dois jeitos de mudar a fase de uma tarefa:** arrastar o cartão, ou trocar a etiqueta de Situação dentro da tarefa. Não existe seta no cartão, não existe tique de concluir na lista, e o rodapé da tarefa não tem botão de "Concluir" — ele só fecha. Mover é sempre um gesto deliberado.

Quem usa teclado abre a tarefa e troca a etiqueta: o cartão é alcançável por Tab e responde a Enter e Espaço.

**O cartão inteiro abre a tarefa.** Clicar em qualquer ponto da moldura funciona, não só no nome.

## Backlog e calendário

Terceira aba dentro do projeto, ao lado de Quadro e Lista. **Entregáveis são uma entidade própria** — o que o cliente recebe e quando — e existem independentemente das tarefas.

Cada entregável carrega nome, descrição, **período (começa em / entrega em)**, situação (planejado · em curso · entregue) e um responsável, que pode ser diferente de quem executa as tarefas. **Atrasado não é uma situação que se escolhe**: é derivado da data de entrega.

O período não pode se inverter — nem ao criar, nem ao corrigir. Para uma entrega de um dia só, basta usar a mesma data nos dois campos.

Na lista, **a data lidera cada linha** — um bloco à esquerda com dia e mês, na cor da situação. A backlog é sobre datas de entrega, então a data vem primeiro; é o que a distingue visualmente de um cartão de tarefa.

O **calendário** mostra os dois: o entregável é uma **barra contínua** que atravessa os dias do seu período, e o prazo de tarefa é um chip pontual com um ponto colorido. Navega por mês, e o botão "Hoje" só aparece quando você saiu do mês corrente. Clicar abre o item.

A barra quebra ao virar a semana e ganha um `‹` ou `›` na ponta cortada, para ficar claro que continua na linha de cima ou de baixo.

**A pista de cada barra é decidida uma vez para o mês inteiro**, não semana a semana. Sem isso, uma entrega de três semanas apareceria na segunda linha numa semana e na terceira na seguinte — pulando de altura a cada quebra. Barras que não se cruzam no tempo dividem a mesma pista, então a grade não cresce à toa.

**A cor "em curso" é o acento do Espaço** — o entregável ativo brilha na cor do cliente, em vez de eu inventar uma quinta família de cores.

### Vínculo com as tarefas

Ao criar uma tarefa há um campo **Entregável**, opcional. Trocar o projeto no formulário atualiza a lista de entregáveis disponíveis. O vínculo também pode ser feito depois, dentro da tarefa.

Dentro do entregável, as tarefas ligadas aparecem em lista com a cor da fase e uma barra de progresso. Clicar numa delas abre a tarefa; fechar devolve ao entregável.

Apagar um entregável **não apaga as tarefas** — elas continuam, apenas soltas. A confirmação diz isso.

## Sprints

Cada projeto tem as suas, e **você escolhe as datas no calendário** — início e fim, sem duração fixa imposta.

O chip no topo do projeto mostra a sprint em curso e abre a gestão delas. A tarefa criada dentro de um período fica marcada com aquela sprint, e o cartão mostra a etiqueta (S1, S2…). Passar o mouse mostra o período completo.

**Errou a data? Clique na sprint.** A linha vira formulário no próprio lugar, com as duas datas, Cancelar e Salvar. Não abre outra tela.

Duas recusas com mensagem própria, tanto ao criar quanto ao corrigir: sprint que termina antes de começar, e período que encosta numa sprint existente (a mensagem diz qual). Ao recusar, o cursor vai para o campo culpado — o de fim quando as datas estão invertidas, o de início quando há sobreposição.

Corrigir datas **não renumera** as sprints. A Sprint 2 continua sendo a Sprint 2, porque as tarefas criadas nela carregam esse nome. A lista se reordena por data; se o número sair de ordem, é porque as datas realmente saíram.

**Não dá para apagar uma sprint** — você pediu para poder alterar as datas, e é só isso que existe. Se apagar fizer falta, é um pedido separado.

## Documentos anexados

Cole o link e pronto. **O tipo é reconhecido pelo próprio link** e vira um ícone colorido, clicável, que abre em aba nova:

| Reconhece | Vira |
| --- | --- |
| `docs.google.com/spreadsheets`, `.xlsx`, `.csv` | Planilha (verde) |
| `docs.google.com/document`, `.docx` | Documento (azul) |
| `docs.google.com/presentation`, `.pptx` | Apresentação (âmbar) |
| `.pdf` | PDF (vermelho) |
| qualquer outro | Link (cinza) |

Link sem `https://` ganha o prefixo sozinho. Sem nome, o anexo se chama pelo tipo e pelo domínio.

**Google Drive** aparece no lugar certo, marcado como **em breve** — foi pedido como possibilidade futura, então está sinalizado, não fingido.

## Apagar uma tarefa

Dentro da tarefa, no rodapé. O primeiro clique não apaga: o rodapé vira uma confirmação — "Apagar esta tarefa de vez? Não dá para desfazer" — com `Cancelar` e `Apagar`. `Esc` durante a confirmação cancela só a confirmação, sem fechar a tarefa.

Não é um segundo modal empilhado. A confirmação acontece no próprio rodapé, no lugar onde o botão estava.

Apagar **não deixa ponta solta**: se outra tarefa dependia da que sumiu, a dependência é limpa (e ela deixa de aparecer como bloqueada); as entradas do feed sobre a tarefa apagada saem junto, para o painel de Atualizações não mostrar linha vazia nem contar a mais.

**Não há desfazer.** É por isso que a confirmação existe.

## Descrição

Campo de texto livre na tarefa, para complementar a explicação. Aparece resumida em duas linhas no cartão do quadro, e o cartão ganha um ícone indicando que há descrição. Também dá para preencher já na criação.

## O que dá para fazer

Criar Espaço (escolhendo a cor), criar projeto, criar tarefa. Quem é admin também edita e apaga Espaço e Projeto — apagar um Espaço só funciona se ele estiver sem projetos dentro; apagar um Projeto leva junto tarefas, entregas e sprints dele, sem confirmação dupla além do aviso no próprio modal. Abrir a tarefa em modal: mudar situação, responsável e prazo, marcar subtarefas, comentar, anexar um link, e — atrás de um "mais opções" fechado — recorrência e dependência. Apagar uma tarefa leva junto suas subtarefas, comentários, anexos e o rastro dela no feed.

Criar e corrigir datas de Sprint, com a mesma checagem de sobreposição valendo no banco. Criar, editar e apagar Entrega — apagar solta as tarefas ligadas em vez de apagá-las.

No projeto, alternar entre **Quadro** e **Lista**. As duas vistas usam os mesmos quatro nomes de fase e as mesmas quatro cores — na Lista, o cabeçalho de cada grupo carrega a cor da fase.

Toda ação sua alimenta o painel de Atualizações da página inicial.

## Nada aqui é falso

Espaço, Projeto, Tarefa, Sprint, Entrega, comentário e anexo — tudo é real e fica salvo no banco, sobrevive a recarregar a página, e aparece igual para qualquer outra conta que logar (ver seção Login).

Os prazos de tarefa são guardados como **deslocamento em dias a partir de hoje** só na memória do navegador — no banco, `tarefas.prazo` é uma data real; a conversão acontece só na borda de leitura/escrita (`offDe()`/`isoDe()`), do mesmo jeito que já valia para o prazo do Projeto. O protótipo abre em qualquer data e continua coerente porque essa conversão acontece de novo a cada carregamento.

## O que ficou de fora, de propósito

**Remover conta, ou recuperar PIN esquecido.** Criar conta já existe (ver seção Login). O que não existe ainda é uma pessoa apagar a própria conta, nem um "esqueci o PIN" — hoje isso é resolvido pelo painel do Supabase, na mão.

**Prioridade e etiquetas.** Toda ferramenta traz por padrão. Com poucos projetos, prioridade é uma conversa de dois minutos, não um campo — e assim que tudo vira "alta", o campo mente.

**Também fora:** horas e faturamento, orçamento e rentabilidade, automações, wiki interna, permissões e convidados, notificações, integrações, tema escuro. Hierarquia profunda, pontos de sprint, campos e status customizados, metas, painéis por widget, chat embutido e tudo de IA.

**Integração com o Google Drive** está sinalizada na tela como *em breve*, por ter sido pedida como possibilidade futura. Anexar por link já funciona hoje.

Horas, orçamento e rentabilidade são o núcleo das ferramentas de consultoria (Productive, Scoro) e são a evolução natural quando a operação crescer.

## Verificado

**Integridade da folha de estilo** — contar as regras no CSSOM e conferir que as quatro media queries existem. Um seletor duplicado (`.cal-legenda{.cal-legenda{`) já derrubou 123 regras de uma vez, matando `.aviso` e todo o responsivo sem gerar um único erro de JavaScript. CSS quebrado é silencioso: só se pega medindo.

**Bug de contraste pré-existente, achado ao construir o login:** os avatares de Rafael, Camila e Diego usavam a cor viva da pessoa como fundo com texto branco — 3,34 / 2,25 / 2,36 de contraste, bem abaixo do mínimo. Estava assim desde o início do projeto, silencioso porque avatar em miniatura não chama atenção. A tela de login deixou isso visível ao ampliar o avatar, e a correção (trocar pela variante `--cb` de cada tom, já calibrada em outro lugar do app) resolve em toda a ferramenta de uma vez, não só no login: agora os quatro ficam entre 4,80 e 5,39.

- Login antigo (PIN sem conta, versão descartada): perfil errado nunca autenticava, PIN errado era recusado — testado com clique e digitação reais na época
- **Login atual (Supabase, e-mail + PIN de 6 dígitos):** cadastro com e-mail fora do domínio é recusado, tanto na tela quanto no banco (o gatilho `lidar_novo_usuario` recusa mesmo chamando a API direto, sem passar pela tela); PIN de confirmação diferente do PIN definido é recusado antes de qualquer chamada de rede; e-mail/PIN errados no login são recusados com mensagem própria, distinta de "muitas tentativas seguidas" (código 429, verificado com um teste real de limite); sessão sobrevive a recarregar a página de verdade; Sair encerra a sessão de verdade, não só o estado da tela; testado com uma conta real criada de propósito para isso, com clique e digitação reais em cada passo — não simulação de estado
- Um bug real só apareceu testando o caminho de auto-envio do PIN (que dispara sem clicar em botão): o e-mail não estava sendo sincronizado nesse caminho, então o login falhava silenciosamente. Corrigido lendo o campo direto do DOM na hora de enviar, não importa por onde o envio foi disparado
- Outro bug real: a permissão de leitura da tabela `pessoas` tinha sido revogada numa migração anterior e nunca devolvida para o papel `authenticated` — RLS certo, mas sem a permissão de base por baixo, a leitura do perfil sempre falhava. Corrigido com um `GRANT` (migração 3)
- **CRUD de Espaço/Projeto (migração 4), testado com uma conta real criada de propósito, promovida a admin por SQL e depois apagada:** sem `admin = true`, os botões de editar/apagar não aparecem, e uma tentativa de chamar `update`/`delete` direto pela API (contornando a tela) volta sem erro mas sem afetar nenhuma linha — a política de RLS recusa de verdade, não é só a tela escondendo o botão; criar Espaço e Projeto persiste no banco e sobrevive a recarregar a página; com `admin = true`, editar prefila os campos certos e salva; apagar um Espaço com projeto dentro é recusado com aviso próprio ("ainda tem projetos dentro"); apagar o Projeto de dentro dele funciona e depois o Espaço, já vazio, também apaga
- **Tarefas/Sprints/Entregas/comentários/anexos no banco, testado com uma conta real de propósito, sem nenhuma migração nova** (o schema já tinha as dez tabelas desde o início): criar Sprint, Entrega e Tarefa (vinculada à entrega e pegando a sprint em curso automaticamente) persiste e sobrevive a recarregar a página; mudar a situação de uma tarefa, comentar e anexar um link gravam e sobrevivem a recarregar; remover um anexo apaga a linha certa no banco (pelo id da linha, não mais pela posição na lista); apagar uma tarefa apaga em cascata, no próprio banco, suas subtarefas/comentários/anexos e o rastro dela no feed de Atualizações — conferido direto por `select` no Supabase, não só pelo estado local; apagar uma Entrega solta a tarefa ligada (`entrega_id` vira `null` sozinho) em vez de apagá-la; criar uma Sprint que encosta na existente é recusado do lado do cliente com a mesma mensagem de antes, antes mesmo de chegar no banco
- Sair zera a sessão de verdade: sem `.lateral`, só a tela de login, e um segundo login como outra pessoa troca a identidade corretamente
- Saudação da página inicial, autor de comentário e responsável padrão de tarefa/entregável acompanham quem logou
- **Contraste AA em todos os pares de texto** — os seis matizes, os quatro rótulos de coluna (5,52 a 6,97), as pílulas de situação e os três níveis de tinta. Zero reprovações. Elementos gráficos acima de 3:1, incluindo os cinco ícones de documento (3,37 a 4,98) e as quatro molduras (1,88 a 2,21 contra o fundo).
- Soltar um cartão no **cabeçalho** da coluna funciona — era exatamente o que falhava antes
- Ir para Em revisão pede revisor pelos dois caminhos; cancelar não move a tarefa
- Detecção de tipo conferida nos cinco casos, inclusive link sem protocolo
- Sprint recusa período invertido e período sobreposto, com mensagem específica — ao criar e ao corrigir
- Corrigir datas: cancelar descarta, salvar aplica, e o chip do projeto acompanha (inclusive deixando de dizer "em curso" se a sprint sair de hoje)
- Editar uma sprint e clicar noutra não vaza valores entre as duas
- Apagar tarefa: o primeiro clique só confirma, cancelar e `Esc` desfazem a intenção, e a exclusão limpa dependência órfã e entradas do feed
- Contraste do destrutivo: branco sobre vermelho 6,0 · texto da confirmação 5,25
- Backlog e calendário: os nove pares de cor (seis matizes em curso, mais entregue, atrasado e planejado) entre 4,68 e 6,31. Zero reprovações
- Calendário sem estouro a 1024px, com célula de 102px e chip cabendo dentro
- Trocar o projeto na criação de tarefa atualiza a lista de entregáveis e o vínculo é gravado
- Apagar entregável solta as tarefas em vez de apagá-las
- Barras contínuas conferidas em três meses seguidos: **zero sobreposições** e **pista estável** — a mesma entrega nunca muda de altura entre semanas
- Período recusa inversão nos dois campos, ao criar e ao corrigir ao vivo
- Grades usam `minmax(0,1fr)` e títulos usam `overflow-wrap:anywhere`: nenhuma palavra longa consegue esticar uma coluna
- Cabeçalhos do projeto, da backlog e do calendário quebram em linhas quando a janela aperta, em vez de cortar
- Quadro em duas colunas entre 820 e 1180px, uma coluna abaixo disso
- Sem estouro horizontal em 1440px nem em 1024px, incluindo modais
- Todos os elementos clicáveis são focáveis por teclado; `Esc` fecha modais
- O cartão abre pela moldura inteira, por Tab e por Enter — não só pelo nome
- Nenhum caminho além de arrastar e da etiqueta de Situação muda a fase de uma tarefa
- Arrasto conferido com o cartão como `div role="button"`, escolhido no lugar de `<button draggable>` porque este último falha no Firefox
- `prefers-reduced-motion` respeitado
- Campos digitados sobrevivem ao redesenho da tela

## Detalhe técnico

Arquivo único, HTML + CSS + JavaScript puros. Sem build, sem dependências, sem framework. Estado em memória.

As animações usam `animation-fill-mode: backwards`, não `both`: com `both`, um conteúdo que começa em opacidade 0 fica invisível para sempre se a animação não chegar a rodar.

## Arquivo descartado

`prancheta-descartado.html` é a primeira tentativa — cinza-ardósia, sóbria, sem hierarquia de Espaços. Rejeitada por parecer escritório em vez de sistema. Mantida só para comparação; pode apagar.
