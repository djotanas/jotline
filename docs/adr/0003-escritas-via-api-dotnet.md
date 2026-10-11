# 0003 — Escritas sempre passam pela API .NET

- **Status:** Aceita
- **Data:** 2026-10-10
- **Decisores:** @jon
- **Relacionados:** PRD §5 (RNF-03, RNF-07, RNF-08), §8; ADR 0002, ADR 0006

## Contexto

Com cadernos compartilhados (fase 3), o servidor precisa decidir quem pode gravar o quê e resolver conflitos entre edições feitas offline. Se o app gravasse direto no banco do servidor, essas regras ficariam espalhadas entre clientes e políticas do banco.

## Decisão

O app grava no SQLite local e uma fila envia as operações para **`POST /sync/upload` na API .NET**, que valida, autoriza, resolve conflitos e grava no Postgres. O .NET é a autoridade das escritas desde o primeiro dia.

Regras obrigatórias do endpoint:

1. Idempotente: o mesmo lote pode chegar duas vezes (RNF-03).
2. Autoriza cada operação pelo usuário do token e pelo papel no caderno; leitor não grava (RNF-07).
3. Erro permanente não trava a fila: a operação vai para uma tabela de rejeitados e o app é avisado.
4. Grava em transação; a partir da fase 3, registra `block_history`.

## Alternativas descartadas

- **App gravando direto no Supabase** — autorização e conflitos ficariam fora de um lugar único.

## Consequências

- Autorização e conflitos num só lugar, num único `INotebookAccess` coberto por testes (RNF-08).
- Metade do protocolo de sync já é nossa: trocar a lib de sync afeta só a leitura.
- Escrever exige o backend no ar; o app tolera isso porque a fila sobrevive a falhas e reinícios (RNF-02).
