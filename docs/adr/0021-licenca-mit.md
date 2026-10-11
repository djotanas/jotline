# 0021 — Licença MIT

- **Status:** Aceita
- **Data:** 2026-10-11
- **Decisores:** @jon
- **Relacionados:** Nenhum

## Contexto

O repositório não tinha nenhum arquivo `LICENSE`; o `README.md` listava a licença como "A definir". O modelo de negócio do produto ainda é uma questão aberta do PRD (§11), mas o repositório precisa de uma licença explícita desde já, para que qualquer visitante saiba como o código pode ser usado.

## Decisão

Adotar a licença MIT, com `Copyright (c) 2026 Jonatas Sennas`, num arquivo `LICENSE` na raiz do repositório. O `README.md` substitui "A definir" por uma seção "License" que declara MIT e linka o arquivo.

## Alternativas descartadas

- **Todos os direitos reservados (sem licença aberta)** — mais conservador para um modelo de negócio ainda indefinido, mas fecha o código a qualquer colaboração ou auditoria externa antes de haver uma razão concreta para isso.
- **Apache-2.0** — adiciona uma licença de patentes explícita, útil para projetos maiores com múltiplas empresas contribuindo; desproporcional para um projeto solo em fase 1.
- **AGPL-3.0** — forçaria qualquer fork hospedado como serviço a abrir seu código; entraria em conflito com um futuro modelo de negócio pago antes dessa decisão existir.

## Consequências

- `LICENSE` na raiz com o texto MIT padrão e o copyright de 2026.
- O modelo de negócio (PRD §11, ainda aberto) pode decidir mais tarde cobrar pelo serviço hospedado sem contradizer a licença do código: MIT permite isso.
- Uma mudança de licença mais restritiva no futuro não afeta cópias já distribuídas sob MIT.
