# 0016 — Idioma do código e da interface, comentários no código

- **Status:** Aceita
- **Data:** 2026-10-11
- **Decisores:** @jon
- **Relacionados:** ADR 0010, ADR 0014, ADR 0015

## Contexto

Nenhum documento definia em que idioma o código e a interface são escritos. Na prática, PRD, ADRs, `CLAUDE.md` e commits estavam em português; o README e o modelo de dados (`notebooks`, `blocks`, `deleted_at`, `POST /sync/upload`) em inglês; os exemplos de nome de teste em português. O código do app ainda é o template do `flutter create`, então a decisão chega antes da primeira tela.

As datas são gravadas em UTC e exibidas no fuso e no formato do usuário, o que já exige o pacote `intl` e um locale configurado.

Também não havia regra sobre comentários no código.

## Decisão

1. **Código em inglês:** identificadores, nomes de arquivo e descrições de teste, no app e no server. As instruções do agente (`CLAUDE.md` e `.claude/docs`) também ficam em inglês. PRD, ADRs e commits seguem em português.
2. **Interface só em PT-BR na fase 1, já com localização do Flutter:** `flutter_localizations` + `gen-l10n`, um único `app_pt.arb`. Chaves em inglês (`newNotebook`), texto em português. Nenhuma string de interface escrita direto no widget.
3. **Sem comentários explicativos no código.** Doc comments (`///`) são permitidos. Diretivas (`// ignore:` e afins) e `TODO` só entram depois de revisadas por @jon.

## Alternativas descartadas

- **Identificadores em português** — alinharia código e docs, mas misturaria com o modelo de dados, as APIs do Flutter/.NET e os pacotes, todos em inglês.
- **Strings da interface direto no código** — mais rápido na primeira tela, mas trocar depois exige passar por todas as telas e testes de widget.
- **PT-BR e EN desde a fase 1** — dobra o trabalho de texto e de teste de cada tela sem usuário pedindo. Com o ARB pronto, o inglês vira só um `app_en.arb` quando fizer sentido.
- **Comentários livres** — tendem a repetir o que o código diz e a ficar desatualizados.

## Consequências

- `flutter_localizations` e `intl` entram nas dependências do app, e `generate: true` no `pubspec.yaml`, quando a estrutura do app for montada.
- Testes de widget montam o `MaterialApp` com os delegates de localização.
- Os comentários do template do `flutter create` saem quando o `main.dart` for substituído.
- As regras ficam no `CLAUDE.md` da raiz (código e comentários) e no do app (interface).
- Os nomes de páginas e artboards do canvas de design continuam em português, como estão no canvas.
