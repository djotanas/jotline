# ADRs — Jotline

Uma decisão por arquivo, no formato Contexto, Decisão, Alternativas, Consequências. ADR não se edita depois de aceita: uma nova a substitui e aponta para a antiga (status `Substituída por NNNN`).

| ADR | Decisão | Status |
| --- | --- | --- |
| [0001](0001-sqlite-local.md) | SQLite com Drift como banco local | Aceita |
| [0002](0002-powersync-atras-de-interface.md) | PowerSync na fase 2, isolado atrás de interface própria | Aceita |
| [0003](0003-escritas-via-api-dotnet.md) | Escritas sempre passam pela API .NET | Aceita |
| [0004](0004-cadernos-com-membros.md) | Todo caderno tem membros desde a fase 1 | Aceita |
| [0005](0005-conteudo-em-blocos.md) | Conteúdo em blocos, conflito por bloco | Aceita |
| [0006](0006-copia-de-conflito.md) | Cópia de conflito em vez de sobrescrita | Aceita |
| [0007](0007-monolito-modular.md) | Monólito modular em ASP.NET Core 10 | Aceita |
| [0008](0008-supabase-auth.md) | Supabase Auth no início | Aceita |
| [0009](0009-crdt-adiado.md) | CRDT adiado para a fase 4 | Aceita |
| [0010](0010-monorepo-claude-md-em-camadas.md) | Monorepo com CLAUDE.md em camadas | Aceita |
| [0011](0011-usuario-local-anonimo.md) | Usuário local anônimo antes do login | Aceita |
| [0012](0012-arquivamento-por-membro.md) | Arquivamento de caderno por membro | Aceita |
| [0013](0013-versao-do-bloco-pelo-servidor.md) | Só o servidor incrementa `blocks.version` | Aceita |
| [0014](0014-progressive-disclosure-no-harness.md) | Progressive disclosure nas instruções do agente | Aceita |
| [0015](0015-estrategia-de-testes-do-app.md) | Estratégia de testes do app: Drift em memória, mocktail, `integration_test` | Aceita |
| [0016](0016-idioma-e-comentarios-no-codigo.md) | Código em inglês, interface em PT-BR com `gen-l10n`, sem comentários explicativos | Aceita |
| [0017](0017-lint-very-good-analysis.md) | Conjunto de lint do app: `very_good_analysis` | Aceita |
| [0018](0018-estrutura-feature-first.md) | Estrutura do `lib/`: feature-first | Aceita |
| [0019](0019-riverpod-sem-codegen.md) | Riverpod sem geração de código | Aceita |
| [0020](0020-convencao-de-commits.md) | Convenção e verificação de mensagens de commit | Aceita |
| [0021](0021-licenca-mit.md) | Licença MIT | Aceita |
| [0022](0022-tokens-e-fontes.md) | Tokens do tema em `ThemeExtension` e fontes empacotadas | Aceita |
| [0023](0023-lixeira-local-da-fase-1.md) | Lixeira local da fase 1: caderno leva as páginas, sem esvaziar | Aceita |
| [0024](0024-confirmacao-ao-excluir.md) | Confirmação ao excluir: página com desfazer, caderno com diálogo | Aceita |
| [0025](0025-busca-inclui-cadernos-arquivados.md) | Páginas de caderno arquivado continuam na busca | Aceita |

Status possíveis: Proposta · Aceita · Rejeitada · Substituída por NNNN.
