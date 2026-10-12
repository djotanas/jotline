# 0032 — Aviso de desfazer de 3 s com pausa ao segurar

- **Status:** Aceita
- **Data:** 2026-10-12
- **Decisores:** @jon
- **Relacionados:** ADR 0024; PRD §4 (RF-01, RF-12)

## Contexto

O ADR 0024 decidiu que excluir uma página não pede confirmação e mostra um aviso com "Desfazer", e deixou em aberto por quanto tempo o aviso fica na tela. O mesmo aviso passou a servir a outras ações reversíveis do app.

## Decisão

1. O aviso de desfazer dura **3 segundos**.
2. Enquanto o usuário segura o aviso, a contagem fica **pausada**; ao soltar, ela segue de onde parou.
3. O aviso aparece depois destas ações: excluir página, excluir caderno (depois do diálogo de confirmação), arquivar caderno, desarquivar caderno e restaurar um item da lixeira.
4. Tocar em "Desfazer" reverte a ação e fecha o aviso.

Isso responde à questão em aberto do ADR 0024, sem editá-lo.

## Alternativas descartadas

- **Aviso fixo até o usuário dispensar** — vira ruído numa ação que o usuário já fez de propósito.
- **Contagem sem pausa** — quem está lendo ou prestes a tocar perde a chance de desfazer.

## Consequências

- Toda ação listada tem caminho de volta imediato, além da lixeira (para exclusões) e do desarquivar.
- Desfazer uma restauração devolve o item à lixeira.
- Novas ações reversíveis usam o mesmo aviso, com a mesma duração e a mesma pausa.
