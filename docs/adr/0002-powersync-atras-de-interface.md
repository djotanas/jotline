# 0002 — PowerSync na fase 2, isolado atrás de uma interface própria

- **Status:** Aceita
- **Data:** 2026-10-10
- **Decisores:** @jon
- **Relacionados:** PRD §5 (RNF-12), §6, §11; ADR 0001, ADR 0003

## Contexto

A fase 2 traz sync automático entre dispositivos (RF-08). Leitura e escrita seguem caminhos diferentes: na leitura, o servidor replica o Postgres para o SQLite de cada aparelho, só com os cadernos de que o usuário é membro; na escrita, o app grava local e uma fila envia as operações para a API (ADR 0003).

Construir a replicação do zero é caro. Ao mesmo tempo, depender de um fornecedor de sync cria risco de lock-in.

## Decisão

Usar **PowerSync Cloud** para replicar o Postgres para o SQLite por usuário, a partir da fase 2.

O SDK fica **atrás de uma interface própria no app**: nenhuma tela ou regra de negócio importa a lib de sync diretamente (RNF-12).

## Alternativas descartadas

- **Supabase direto** (app lendo e gravando no Supabase) — sem fila offline pronta; a escrita sairia da API própria.
- **Couchbase Lite** e **Ditto** — trazem o próprio modelo de escrita, sem a escrita via API própria.
- **Realm com Atlas Device Sync** — evitado de propósito: a MongoDB descontinuou o serviço.

## Consequências

- Sync pronto com escrita via API própria; o lock-in fica restrito ao caminho de leitura.
- Trocar a lib no futuro significa substituir só o caminho de leitura, porque as escritas já passam pelo .NET.
- Plano de saída: self-host do PowerSync ou sync próprio em .NET.
- O mesmo JWT do Supabase Auth vale para a API e para o PowerSync (ADR 0008).
