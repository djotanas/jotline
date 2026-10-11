# 0019 — Riverpod sem geração de código

- **Status:** Aceita
- **Data:** 2026-10-11
- **Decisores:** @jon
- **Relacionados:** ADR 0015, ADR 0018

## Contexto

O `flutter_riverpod` já está nas dependências do app, mas nenhum documento definia se os providers seriam escritos à mão ou gerados com `riverpod_generator`/`@riverpod`. O banco e as preferências deste milestone já precisam de um provider cada (`databaseProvider`, `preferencesStoreProvider`), então o estilo chega antes da primeira tela.

O repo já depende de `build_runner` para o Drift e o `gen-l10n`; cada gerador adicional pesa no ciclo de `pub get` → `build_runner build` → testar.

## Decisão

Providers são declarados à mão, com as classes do `flutter_riverpod` (`Provider`, `NotifierProvider`, etc.), sem `riverpod_annotation` nem `riverpod_generator`. O `pubspec.yaml` não depende de nenhum dos dois. O root widget é sempre envolvido em `ProviderScope`, e todo provider usado em teste é sobrescrito via `overrides`, nunca lido de uma variável global.

## Alternativas descartadas

- **`riverpod_generator` com `@riverpod`** — reduz boilerplate e dá `autoDispose`/`family` de graça, mas adiciona mais um passo de `build_runner` num repo que já gera código do Drift e do `gen-l10n` a cada mudança. Mesmo raciocínio da ADR 0015 sobre o mockito: um gerador a menos é um ciclo de teste mais rápido.
- **Riverpod sem `ProviderScope` (estado global via `GetIt` ou singletons)** — perderia a troca de implementação por `overrides` que os testes de banco e preferências já assumem.

## Consequências

- `app/pubspec.yaml` não lista `riverpod_annotation` nem `riverpod_generator`.
- Cada provider é escrito manualmente (`final xProvider = Provider<X>((ref) => ...)`), sem anotação e sem arquivo `.g.dart` correspondente.
- Testes sempre passam por `ProviderContainer.test` ou `ProviderScope` com overrides explícitos; um provider sem override lançado em teste aponta exatamente o que falta.
- O `app/CLAUDE.md` deixa de listar o estilo do Riverpod como indecidido.
