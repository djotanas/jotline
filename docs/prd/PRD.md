# PRD — Jotline: app de notas offline-first

Oct 10, 2026 · @jon · Status: rascunho v0.1 · Nome do produto provisório

## Sobre este documento

Este é um PRD com um resumo técnico acoplado: diz o que o produto faz, para quem, e quais tecnologias entram em cada fase e por quê.

No mercado, esses papéis costumam ficar em três documentos separados, e este os junta enquanto o time é pequeno:

| Documento | Responde | Quem escreve | Muda com que frequência |
| --- | --- | --- | --- |
| PRD (Product Requirements Document) | O quê, para quem, por quê, como medir sucesso | Produto | A cada fase |
| Design técnico (RFC ou TDD) | Como: arquitetura, dados, sync, segurança | Engenharia | A cada mudança de arquitetura |
| ADR (Architecture Decision Record) | Por que escolhemos X em vez de Y, naquele contexto | Quem tomou a decisão | Nunca: uma ADR nova substitui a antiga |

Quando o projeto crescer, a regra prática é mover as seções 6 a 8 para um design técnico próprio e cada linha da seção 10 para um arquivo ADR no repositório (`docs/adr/0001-sqlite-local.md`).

## 1. Visão e problema

Jotline é um app mobile de notas organizado em cadernos, que funciona inteiro sem internet e sincroniza sozinho quando a conexão volta. A experiência de referência é um caderno de papel de bolso: abrir e escrever na hora, sem tela de carregamento, sem aviso de "sem conexão".

O problema: a maioria dos apps de notas trata o offline como exceção. Na prática, isso aparece como notas que não abrem no metrô, edições perdidas ao alternar entre celular e tablet e conflitos que sobrescrevem texto em silêncio.

Princípio do produto: o dispositivo é a fonte da verdade para quem está escrevendo, e a nuvem é backup, ponte entre dispositivos e, mais tarde, ponte entre pessoas. O app nasce individual, mas o modelo de dados já trata todo caderno como compartilhável: um caderno pessoal é um caderno com um único membro.

## 2. Objetivos, métricas e não-objetivos

O sucesso é medido por confiança: o usuário nunca perde texto e nunca espera para escrever. As metas abaixo são propostas iniciais, a validar com os primeiros usuários.

| Objetivo | Métrica | Meta proposta |
| --- | --- | --- |
| Escrever na hora | Tempo do toque no ícone até o cursor numa página nova | Menos de 1 s em aparelho intermediário |
| Nunca perder dados | Edições perdidas reportadas ou detectadas | Zero |
| Sync confiável | Uploads pendentes há mais de 24 h com o aparelho online | Menos de 0,1% dos usuários |
| Conflitos visíveis | Conflitos resolvidos sem cópia de conflito, em edições simultâneas | Acompanhar; meta definida na fase 3 |
| Retenção | Usuários que escrevem em 3 dias diferentes na primeira semana | Definir após o beta |

Não-objetivos (fora do escopo até nova decisão):

- Coedição em tempo real no mesmo parágrafo, estilo Google Docs. Entra só na fase 4, se os dados de uso justificarem.
- Versão web ou desktop. A arquitetura não impede, mas não é prioridade.
- Recursos de IA, como resumo ou transcrição.
- Importação de outros apps de notas na primeira versão.
- Sync peer-to-peer entre aparelhos sem servidor.

## 3. Público e personas

O público inicial é quem escreve à mão ou em notas soltas e quer o mesmo conforto no celular, inclusive sem sinal. As personas abaixo são hipóteses de trabalho, a confirmar com entrevistas.

| Persona | Contexto | O que precisa | Fase em que é atendida |
| --- | --- | --- | --- |
| Ana, a anotadora em trânsito | Escreve no transporte, em viagens, em lugares com sinal ruim | Abrir e escrever sem esperar; confiar que nada se perde | Fase 1 |
| Bruno, o multi-dispositivo | Usa celular e tablet, às vezes ao mesmo tempo | Ver no tablet o que escreveu no celular; conflitos que não apagam texto | Fase 2 |
| Carla e equipe | Pequeno grupo que mantém um caderno comum (projeto, viagem, estudos) | Convidar pessoas, papéis de editor e leitor, saber quem mudou o quê | Fase 3 |
| Grupo de estudos ao vivo | Várias pessoas escrevendo na mesma página ao mesmo tempo | Coedição e presença em tempo real | Fase 4, opcional |

## 4. Requisitos funcionais por fase

Cada requisito tem um código (RF-xx) para ser citado em tarefas, PRs e testes. Prioridade segue MoSCoW: Must, Should, Could.

| Código | Requisito | Fase | Prioridade |
| --- | --- | --- | --- |
| RF-01 | Criar, renomear, arquivar e excluir cadernos, com capa e cor; arquivar vale só para quem arquiva | 1 | Must |
| RF-02 | Criar páginas num caderno e reordená-las | 1 | Must |
| RF-03 | Editor de blocos: texto rico, títulos, listas, checklist | 1 | Must |
| RF-04 | Tudo funciona sem conta e sem internet | 1 | Must |
| RF-05 | Busca local por título e conteúdo | 1 | Should |
| RF-06 | Desenho à mão livre num bloco | 1 | Could |
| RF-07 | Criar conta e entrar com e-mail e senha ou Google; dados criados antes do login passam para a conta | 2 | Must |
| RF-08 | Sync automático entre dispositivos, sem botão de sincronizar | 2 | Must |
| RF-09 | Indicador discreto de estado: sincronizado, pendente, erro | 2 | Must |
| RF-10 | Conflito no mesmo bloco gera cópia visível, nunca sobrescrita silenciosa | 2 | Must |
| RF-11 | Anexar imagens; o upload acontece quando houver rede | 2 | Should |
| RF-12 | Lixeira com restauração; na fase 1 é só local, e a limpeza definitiva chega com o servidor na fase 2 | 1 | Should |
| RF-13 | Convidar pessoas para um caderno por link ou e-mail | 3 | Must |
| RF-14 | Papéis por caderno: dono, editor, leitor | 3 | Must |
| RF-15 | Mostrar quem editou cada bloco e quando | 3 | Should |
| RF-16 | Histórico de versões de uma página, com restauração | 3 | Should |
| RF-17 | Ao perder acesso a um caderno, oferecer salvar as edições pendentes num caderno pessoal | 3 | Must |
| RF-18 | Notificação leve de atualização em caderno compartilhado | 3 | Could |
| RF-19 | Coedição em tempo real no mesmo bloco | 4 | Could |
| RF-20 | Presença: quem está vendo ou editando a página agora | 4 | Could |

A lixeira (RF-12) entra na fase 1 só no aparelho: lista o que foi excluído (`deleted_at` preenchido) e restaura limpando `deleted_at`. Como o app nunca apaga fisicamente (RNF-05), a limpeza definitiva só existe a partir da fase 2, feita pelo servidor; o prazo de 30 dias vale para essa limpeza, é uma proposta e pode mudar.

## 5. Requisitos não funcionais

O requisito que manda em todos os outros: nenhuma tela lê da rede. A UI lê e escreve só no banco local, e o sync trabalha em segundo plano.

| Código | Área | Requisito |
| --- | --- | --- |
| RNF-01 | Offline | Toda leitura e escrita vai ao SQLite local; a rede nunca bloqueia a UI |
| RNF-02 | Offline | A fila de upload sobrevive a fechar o app, reiniciar o aparelho e trocar de rede |
| RNF-03 | Idempotência | Reenviar o mesmo lote ao servidor não duplica nem corrompe dados |
| RNF-04 | Identidade | IDs gerados no cliente (UUID v7), sem depender do servidor para criar algo |
| RNF-05 | Exclusão | Soft delete (`deleted_at`) para que exclusões também sincronizem |
| RNF-06 | Desempenho | Lista de páginas e abertura de página sem carregamento perceptível com 10 mil páginas locais |
| RNF-07 | Segurança | Toda escrita no servidor é autorizada pelo usuário do token, nunca pelo payload |
| RNF-08 | Segurança | Um único serviço de autorização (`INotebookAccess`) usado por todos os endpoints, coberto por testes |
| RNF-09 | Privacidade | Cadernos pessoais nunca saem da conta do dono; o sync só envia cadernos em que o usuário é membro |
| RNF-10 | Privacidade | Avaliar criptografia do banco local (SQLCipher ou equivalente) antes da fase 2 |
| RNF-11 | Observabilidade | Logs e traces com OpenTelemetry no backend; métricas de fila pendente no app |
| RNF-12 | Portabilidade | Nenhuma tela ou regra de negócio importa a lib de sync diretamente |

O volume de 10 mil páginas (RNF-06) é uma referência de teste de carga, não um limite do produto.

## 6. Arquitetura e stack

Leitura e escrita seguem caminhos diferentes. Na leitura, o PowerSync replica o Postgres e envia a cada aparelho só os cadernos de que o usuário é membro. Na escrita, o app grava no SQLite local e uma fila envia as operações à API .NET, que valida, resolve conflitos e grava no Postgres.

O .NET é a autoridade das escritas desde o primeiro dia. Por isso, trocar a lib de sync no futuro significa substituir só o caminho de leitura.

&#91;embedded content: arquitetura · caminhos de leitura e escrita\]

A escrita sai da fila local e passa pela API .NET; a leitura volta pelo PowerSync. Nenhuma tela espera a rede para mostrar ou gravar uma nota.

### O que usar, para quê e quando

| Camada | Tecnologia | Para quê | Entra na fase | Plano de saída |
| --- | --- | --- | --- | --- |
| App | Flutter + Riverpod | UI e estado, lendo streams do banco local | 1 | — |
| Banco local | SQLite com Drift | Fonte da verdade no aparelho; consultas tipadas e reativas | 1 | Continua mesmo trocando o sync |
| Banco local com sync | SQLite gerenciado pelo PowerSync, com Drift por cima | O mesmo banco passa a ter fila de upload e replicação | 2 | Volta a ser SQLite puro no sync próprio |
| Preferências | hive\_ce | Tema, último caderno aberto; nada que sincronize | 1 | — |
| Editor | flutter\_quill, appflowy\_editor ou super\_editor | Edição em blocos com texto rico | 1, após um spike de 1 semana | — |
| Desenho | perfect\_freehand | Traços vetoriais salvos como JSON | 1 (Could) | — |
| IDs e ordem | UUID v7 + índice fracionário | Criar offline; reordenar alterando uma linha só | 1 | — |
| Sync | PowerSync Cloud | Replicar Postgres para o SQLite por usuário | 2 | Self-host do PowerSync ou sync próprio em .NET |
| Autenticação | Supabase Auth (JWT) | Login; o mesmo token vale para o .NET e o PowerSync | 2 | Keycloak ou ASP.NET Identity emitindo JWT |
| Banco servidor | Postgres no Supabase | Dados oficiais e origem da replicação | 2 | Qualquer Postgres gerenciado |
| Backend | ASP.NET Core 10, Minimal APIs, monolito modular | Upload do sync, autorização, convites, anexos | 2 | — |
| Acesso a dados | EF Core 10 + Npgsql | Persistência e migrações | 2 | — |
| Anexos | Supabase Storage, URL pré-assinada emitida pelo .NET | Upload direto do app, sem passar arquivo pela API | 2 | S3 ou compatível |
| Dev local | .NET Aspire | Sobe API, Postgres e PowerSync com um comando | 2 | — |
| Observabilidade | OpenTelemetry | Traces e métricas do sync e da API | 2 | — |
| Tempo real leve | SignalR | Avisos: convite recebido, caderno atualizado | 3 | — |
| Histórico | Tabela `block_history` alimentada pelo .NET | Versões e restauração | 3 | — |
| CRDT (opcional) | Yrs via flutter\_rust\_bridge no app; YDotNet no servidor | Coedição no mesmo bloco | 4 | Só se os dados da fase 3 justificarem |

### Por que não Hive ou Isar como banco principal

O PowerSync traz o próprio SQLite no cliente; usar Hive ou Isar obrigaria a manter dois bancos e copiar dados entre eles. Além disso, o Isar original está sem manutenção e o Hive sobrevive em fork comunitário (hive\_ce). O hive\_ce fica restrito a preferências locais.

## 7. Modelo de dados

Todo caderno tem membros desde a fase 1, mesmo que o único membro seja o dono. Assim, compartilhar vira inserir uma linha em `notebook_members`, sem migração de dados.

| Tabela | Campos principais | Observação | Fase |
| --- | --- | --- | --- |
| `notebooks` | id, title, cover, color, created\_by, created\_at, deleted\_at | O "Moleskine" | 1 |
| `notebook_members` | notebook\_id, user\_id, role, added\_by, created\_at, archived\_at | role = owner, editor ou viewer; arquivar é por membro (ADR 0012) | 1 (só owner) |
| `pages` | id, notebook\_id, title, position, updated\_at, updated\_by, deleted\_at | position em índice fracionário | 1 |
| `blocks` | id, page\_id, type, content\_json, position, version, updated\_at, updated\_by | A unidade de conflito é o bloco | 1 |
| `attachments` | id, block\_id, storage\_key, mime, size, upload\_status | Arquivo local primeiro; upload depois | 2 |
| `invites` | id, notebook\_id, token, role, expires\_at, accepted\_by | Criado e aceito só online | 3 |
| `block_history` | id, block\_id, content\_json, version, changed\_by, changed\_at | Escrita só pelo .NET | 3 |
| `page_updates` | id, page\_id, update\_blob, created\_by, created\_at | Só inserções; usada apenas com CRDT | 4 |

Convenções que valem para todas as tabelas:

- IDs em UUID v7, gerados no cliente (`Guid.CreateVersion7()` no .NET).
- Datas em UTC; o servidor grava a própria data de recebimento além da enviada pelo cliente.
- Nada é apagado fisicamente pelo app; o .NET faz a limpeza definitiva depois do prazo da lixeira.
- `updated_by` existe desde a fase 1, para que o histórico da fase 3 não comece vazio de autoria.
- Antes do login, as colunas de autoria (`created_by`, `user_id`, `added_by`, `updated_by`) recebem o id de um usuário local anônimo gerado no aparelho. No login, uma transação troca esse id pelo da conta antes do primeiro upload; dados locais são somados aos que a conta já tem (ADR 0011).

## 8. Sync, conflitos e compartilhamento

A regra de sync é uma só para cadernos pessoais e compartilhados: o aparelho recebe todo caderno em que o usuário aparece em `notebook_members`.

### Escrita: o endpoint de upload

`POST /sync/upload` recebe lotes de operações PUT, PATCH e DELETE vindos da fila do app. Regras obrigatórias:

1. Idempotente: o mesmo lote pode chegar duas vezes se a conexão cair no meio.
2. Autoriza cada operação pelo usuário do token e pelo papel no caderno; leitor não grava.
3. Erro permanente (validação, acesso revogado) não trava a fila: a operação vai para uma tabela de rejeitados e o app é avisado.
4. Grava em transação e registra `block_history` a partir da fase 3.

### Conflitos em degraus

| Degrau | Como funciona | Quando |
| --- | --- | --- |
| 1. Last-write-wins por bloco | Edições em blocos diferentes nunca colidem | Fase 2 |
| 1b. Cópia de conflito | O app envia a `version` em que se baseou; se o servidor tem versão mais nova, cria uma cópia do bloco em vez de sobrescrever. Só o servidor incrementa `version` (ADR 0013) | Fase 2 |
| 2. Histórico de versões | Toda escrita gera uma linha em `block_history`; dá para ver e restaurar | Fase 3 |
| 3. CRDT | Conteúdo vira atualizações Yjs numa tabela só de inserções; o .NET compacta em snapshots | Fase 4, opcional |

### Compartilhamento

Convidar, aceitar convite e mudar papéis exigem internet, porque o servidor precisa ser a autoridade de permissões. Depois de aceito, o caderno compartilhado funciona offline como qualquer outro.

Caso crítico: alguém edita offline um caderno do qual foi removido. Ao voltar, o .NET rejeita as edições e o app oferece salvá-las num caderno pessoal (RF-17). Remover alguém também apaga o caderno do aparelho dessa pessoa no próximo sync.

Presença e cursores (fase 4) passam por SignalR, nunca pelo banco: são dados efêmeros que não precisam existir offline.

## 9. Roadmap

As fases não têm datas ainda: nesta etapa, a ordem e os critérios de passagem importam mais que o calendário.

&#91;embedded content: roadmap · 4 fases, 3 gates\]

A fase 4 é tracejada porque só existe se o gate 3 mostrar que as pessoas editam o mesmo bloco ao mesmo tempo. Critérios de cada gate:

- Gate 1: spike do editor concluído, schema com membros e blocos fechado, nenhuma perda de dados no uso interno.
- Gate 2: nenhuma pendência antiga na fila em testes de campo, autorização coberta por testes, migração dos dados sem login validada.
- Gate 3: métricas de conflito por bloco e pedidos explícitos de coedição justificam o custo do CRDT.

## 10. Registro de decisões (ADRs)

Cada linha vira um arquivo em `docs/adr/` quando o repositório existir, no formato Contexto, Decisão, Consequências. Uma decisão nunca é editada: uma ADR nova a substitui e aponta para a antiga.

| ADR | Decisão | Alternativas descartadas | Motivo principal |
| --- | --- | --- | --- |
| 0001 | SQLite com Drift como banco local | Hive, Isar | Compatível com PowerSync; formato padrão que sobrevive à troca de sync |
| 0002 | PowerSync na fase 2, isolado atrás de uma interface própria | Supabase direto, Couchbase Lite, Ditto | Sync pronto com escrita via API própria; baixo lock-in |
| 0003 | Escritas sempre passam pela API .NET | App gravando direto no Supabase | Autorização e conflitos num só lugar; metade do protocolo já é nossa |
| 0004 | Todo caderno tem membros desde a fase 1 | Modelo separado para pessoal e compartilhado | Compartilhar sem migração de dados |
| 0005 | Conteúdo em blocos, conflito por bloco | Página inteira como um texto | Menos colisões; caminho aberto para CRDT |
| 0006 | Cópia de conflito em vez de sobrescrita | Last-write-wins puro | Requisito de nunca perder texto |
| 0007 | Monolito modular em ASP.NET Core 10 | Microsserviços | Escala atual não justifica a complexidade |
| 0008 | Supabase Auth no início | Identity próprio desde o começo | Menos código na fase 2; JWT padrão permite trocar depois |
| 0009 | CRDT adiado para a fase 4 | Yjs desde o início | Bibliotecas Dart imaturas; degraus 1 e 2 cobrem o uso assíncrono |
| 0011 | Usuário local anônimo antes do login, trocado pelo da conta no login | Colunas nulas até o login; id local permanente | Autoria `NOT NULL` desde a fase 1, sem script de reparo |
| 0012 | Arquivamento de caderno por membro (`notebook_members.archived_at`) | `notebooks.archived_at`, global | Na fase 3, quem arquiva não tira o caderno da lista dos outros |
| 0013 | Só o servidor incrementa `blocks.version` | App incrementa a cada edição | Uma única fonte de verdade para detectar conflito |

Uma alternativa evitada de propósito: Realm com Atlas Device Sync, que a MongoDB descontinuou.

## 11. Riscos e questões em aberto

| Risco | Impacto | Mitigação |
| --- | --- | --- |
| Vazamento de caderno entre usuários | Crítico | Serviço único de autorização com testes; regras de sync por membro revisadas a cada mudança |
| Fila de upload travada por um erro permanente | Alto | Tabela de rejeitados; métrica de pendências antigas |
| Lock-in no PowerSync Cloud | Médio | Interface própria no app; escrita já via .NET; opção de self-host |
| Editor de blocos escolhido não se adaptar ao modelo | Médio | Spike de 1 semana na fase 1 antes de fixar |
| CRDT no Flutter imaturo | Médio | Adiar para a fase 4; avaliar Yrs via flutter\_rust\_bridge |
| YDotNet ainda inicial e mirando net8.0 | Baixo, só na fase 4 | Testar no .NET 10 antes de adotar |
| Dados criados sem login se perderem ao criar conta | Alto | Teste dedicado da migração local para a conta (RF-07) |
| Rejeição na App Store pela regra 4.8 (login com Google sem Sign in with Apple) | Médio, só no iOS | E-mail e senha como opção equivalente; reavaliar Sign in with Apple se o review rejeitar |

Questões em aberto:

- [ ] O compartilhamento será assíncrono (cada um contribui com suas páginas) ou com coedição simultânea? Define se a fase 4 existe.
- [ ] Qual editor de blocos adotar?
- [ ] Criptografia do banco local entra na fase 2 ou depois?
- [ ] Modelo de negócio: grátis com limite de cadernos compartilhados, assinatura, ou outro?
- [ ] Prazo final da lixeira: 30 dias é suficiente?
- [x] Lixeira local da fase 1 (RF-12): excluir um caderno leva as páginas dele para a lixeira e restaurar o caderno as traz de volta juntas? Há "esvaziar lixeira" na fase 1, sabendo que o app não apaga fisicamente? Resolvida na ADR 0023.
- [ ] Logout e troca de conta no mesmo aparelho: o que acontece com os dados locais da conta anterior? (RNF-09)

### Fontes

- [PowerSync: SDK Dart/Flutter usa SQLite no aparelho](https://pub.dev/documentation/powersync/latest/)
- [PowerSync: escritas locais vão para uma fila e sobem à API do backend](https://www.powersync.com)
- [PowerSync: bancos de origem suportados](https://docs.powersync.com/intro/)
- [PowerSync: SQL Server e SDK .NET em beta](https://releases.powersync.com/announcements/ann_BR17TjxTcOSZ9)
- [Isar original sem manutenção; migração para isar\_community](https://pub.dev/packages/feature_flags_toggly_isar/changelog)
- [hive\_ce, edição comunitária do Hive](https://pub.dev/packages/http_hive_cache)
- [y\_crdt, porta Dart do Yjs](https://pub.dev/packages/y_crdt/install)
- [yjs\_dart, tradução em Dart puro do Yjs](https://pub.dev/packages/yjs_dart/install)
- [YDotNet, bindings .NET do Yrs](https://github.com/y-crdt/ydotnet)
- [YDotNet.Server 0.6.0 no NuGet](https://nubrowse.com/packages/YDotNet.Server)
