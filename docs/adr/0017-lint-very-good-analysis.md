# 0017 — Conjunto de lint do app: very_good_analysis

- **Status:** Aceita
- **Data:** 2026-10-11
- **Decisores:** @jon
- **Relacionados:** ADR 0016

## Contexto

O app ainda usava o `flutter_lints` padrão do `flutter create`, um conjunto permissivo pensado para projetos de exemplo. O milestone #01 exige decidir um conjunto de lint antes da primeira tela, para que todo código escrito depois já nasça sob a mesma régua e não exija uma reformatação em massa depois.

## Decisão

Adotar `package:very_good_analysis` no lugar de `flutter_lints`, incluído em `app/analysis_options.yaml` e listado em `dev_dependencies`. O analyzer exclui `**/*.g.dart`, `build/**`, `android/**` e `ios/**`, e a regra `public_member_api_docs` fica desativada: o `CLAUDE.md` raiz já permite doc comments sem exigi-los, e um app não tem consumidores externos de API pública.

## Alternativas descartadas

- **Manter `flutter_lints`** — conjunto do template, pensado para ser permissivo; não captura boa parte dos problemas de estilo e correção que o projeto quer pegar antes da revisão.
- **`flutter_lints` com regras extras manuais** — exigiria escolher e manter cada regra adicional uma a uma, com o risco de divergir do que a comunidade Flutter já consolidou; `very_good_analysis` já entrega esse conjunto testado em produção.

## Consequências

- `fvm flutter analyze` passa a reportar bem mais categorias de problema; o código do template precisa ficar 100% limpo antes deste ADR ser commitado.
- Nenhum `// ignore:` foi necessário para zerar o analyzer nesta troca.
- `public_member_api_docs` desativada: doc comments continuam permitidos, mas não são cobrados pelo lint.
- O `app/CLAUDE.md` deixa de listar o conjunto de lint como indecidido.
