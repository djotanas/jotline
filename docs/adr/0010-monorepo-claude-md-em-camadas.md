# 0010 — Monorepo com CLAUDE.md em camadas

- **Status:** Aceita
- **Data:** 2026-10-10
- **Decisores:** @jon
- **Relacionados:** PRD §6, §8; ADR 0003

## Contexto

O Jotline tem dois projetos: o app Flutter e o backend .NET. O desenvolvimento é feito com agentes de IA (Claude Code).

O contrato de sync (`POST /sync/upload`, `version` por bloco, tabela de rejeitados, regras por membro) existe nos dois lados. Uma mudança nele quase sempre toca app e server ao mesmo tempo.

As instruções para o agente (`CLAUDE.md`) ocupam contexto em toda sessão. As duas stacks têm comandos e convenções diferentes (`fvm` e `dotnet`).

## Decisão

1. **Um único repositório** com o app em `app/`, o backend em `server/` e a documentação em `docs/` (PRD em `docs/prd/`, ADRs em `docs/adr/`).
2. **`CLAUDE.md` em camadas:**
   - **Raiz:** produto, mapa do monorepo, invariantes que valem nos dois lados e ponteiros para PRD e ADRs. Carregado em toda sessão.
   - **`app/CLAUDE.md` e `server/CLAUDE.md`:** stack, comandos e convenções de cada lado. O Claude Code os carrega só quando lê arquivos dentro da pasta.
3. O PRD é lido sob demanda, sem importação com `@`.

## Alternativas descartadas

- **Um repositório por projeto** — o agente não veria o outro lado do contrato de sync numa mesma sessão, e uma mudança que cruza app e server viraria dois PRs.
- **Um `CLAUDE.md` único** — misturaria regras e comandos das duas stacks em toda sessão, gastando contexto e aumentando a chance de aplicar uma regra no lado errado.

## Consequências

- O agente vê app e API na mesma sessão e muda os dois num mesmo PR, com um commit por lado.
- Ordem para mudanças que cruzam os dois lados: contrato, depois server, depois app.
- Regras comuns ficam só na raiz; regras de um lado ficam só na pasta dele.
- Ao fazer o scaffold de cada projeto, a seção "Estrutura" do `CLAUDE.md` correspondente precisa ser preenchida.
