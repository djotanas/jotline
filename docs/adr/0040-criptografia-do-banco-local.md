# 0040 — Criptografia do banco local

- **Status:** Proposta
- **Data:** 2026-10-22
- **Decisores:** @jon
- **Relacionados:** PRD §11, RNF-10; ADR 0001, ADR 0002; issue #28; spec da M05 (CRYPT-01…CRYPT-05)

## Contexto

O RNF-10 pede avaliar a criptografia do banco local antes da fase 2, e o PRD §11 deixa em aberto se ela entra na fase 2 ou depois. O banco é um arquivo SQLite sem senha (ADR 0001); quem tiver o arquivo lê todas as notas. A M05 fez um spike na branch `spike/28-local-encryption` (nunca mesclada): `test/spike/encryption_spike_test.dart` semeia a biblioteca de 10 mil páginas (LOAD-01) e mede cada opção. O app na `main` continua sem criptografia (CRYPT-05).

As duas opções vêm do pacote `sqlite3`, escolhidas em `pubspec.yaml` com `hooks.user_defines.sqlite3.source`: **SQLite3MultipleCiphers** (`sqlite3mc`) e **SQLCipher** (`sqlcipher`). Em ambas a chave é aplicada com `PRAGMA key` na abertura.

## Resultados do spike

Medido no computador (Linux, `flutter test`), semente de LOAD-01 (211 MB), mediana de 7 aberturas. A tabela traz os valores do computador; os do aparelho estão logo abaixo. A variação entre execuções do mesmo arquivo sem cifra passou de 50% (LOAD-03 de 186 a 315 ms), então só diferenças grandes contam.

| Item | `sqlite3mc` | `sqlcipher` |
| --- | --- | --- |
| **CRYPT-02** — PowerSync no Flutter | Suportado: o SDK Dart 2.0 aceita `EncryptionOptions(key: …)` e a mesma configuração de `hooks` (documentação do PowerSync, "At Rest Encryption > Dart/Flutter"). Não prototipado: PowerSync ainda não está no app. | Igual; a documentação indica que pode ser mais rápido no iOS por usar o `Security.framework`. Não prototipado. |
| Drift e FTS5 (`page_search`) | Funciona: semente, busca e gatilhos com `PRAGMA key`; 12.000 linhas em `page_search` após a migração. | Funciona na semente e na busca. |
| **CRYPT-03** — migrar banco sem cifra | `PRAGMA rekey` no lugar: 1,7 s para 211 MB, `page_search` intacto. | `sqlcipher_export` copiou em 1,3 s, mas **falhou** com o esquema do app (`trigger pages_search_ai already exists`); exigiria recriar o esquema no arquivo novo e copiar as linhas. |
| **CRYPT-03** — LOAD-03 (abrir o caderno de 10 mil páginas) | 402 ms cifrado contra 230 ms sem cifra (semente nova); 340 ms após `rekey`. | 319 ms cifrado contra 315 ms sem cifra. |
| **CRYPT-03** — LOAD-06 (busca "belém") | 162 ms cifrado contra 115 ms sem cifra; 130 ms após `rekey`. | 137 ms cifrado contra 165 ms sem cifra. |
| **CRYPT-03** — tamanho do APK (arm64, release) | 23,39 MB contra 23,12 MB sem cifra: +0,27 MB. | 26,48 MB: +3,35 MB. |
| Semente cifrada | 34,3 s contra 22,8 s. | 30,7 s contra 24,1 s. |
| Arquivo sem a chave | `file is not a database`. | — (não repetido) |
| Licença | Própria (`sqlite3mc`); ver o repositório antes de publicar. | SQLCipher Community Edition, BSD; liga OpenSSL no Android. |

**No aparelho** (Samsung SM-A356E, Android 16, adb sem fio, build de **depuração** via `flutter test integration_test`, mesma semente, mediana de 7 aberturas): os valores absolutos são mais lentos que o build de perfil dos registros de LOAD, então só a diferença relativa serve.

| Aparelho | Sem cifra | `sqlite3mc` cifrado | `sqlite3mc` após `rekey` |
| --- | --- | --- | --- |
| LOAD-03 | 352 ms (`sqlite3`: 490 ms) | 591 ms | 547 ms |
| LOAD-06 | 180 ms (`sqlite3`: 223 ms) | 246 ms | 224 ms |
| Semente | 53 s | 43 s | — |
| `rekey` de 211 MB | — | — | 4,0 s |

A cifra do `sqlite3mc` custa cerca de +55% em LOAD-03 e +35% em LOAD-06 sobre o mesmo binário sem cifra. O `sqlcipher` leu e buscou sem cifra normalmente (375 ms e 195 ms), mas o teste terminou sem concluir ao semear o banco cifrado no aparelho; a causa não foi investigada, e o resultado cifrado do `sqlcipher` no aparelho fica sem medida.

**Guarda da chave (CRYPT-03):** não foi prototipada. A opção natural é gerar a chave aleatória no primeiro uso e guardá-la no Keystore (Android) e no Keychain (iOS) por um pacote como `flutter_secure_storage`; fica por verificar com Context7 e um protótipo antes de adotar.

## Decisão

Proposta, a confirmar pelo decisor (a pergunta do PRD §11 é aberta e não foi decidida sozinha):

1. **A criptografia entra na fase 2, junto com a adoção do PowerSync (ADR 0002),** e não antes. Nessa troca o arquivo do banco é reaberto de qualquer forma, e o SDK já traz `EncryptionOptions`. Fazer antes custaria uma migração e dois caminhos de abertura sem que nada saia do aparelho.
2. **Opção preferida: `sqlite3mc`.** Custa 0,27 MB de APK contra 3,35 MB, migra no lugar com `PRAGMA rekey` e é a única que funciona na web, se um dia houver. O `sqlcipher` fica como alternativa se a medição no aparelho mostrar o `sqlite3mc` fora das metas de LOAD-03 e LOAD-06.
3. **As metas de 100 ms de LOAD-03 e LOAD-06 já estavam perdidas sem cifra** (`load-results.md`); a cifra acrescenta cerca de +35% a +55% sobre isso. Quem decide aceita esse custo ou pede a medição em build de perfil; não há laço de otimização.
4. **Fica fora desta ADR:** a escolha do pacote de guarda da chave, o que acontece com os dados locais ao sair da conta (PRD §11) e a rotação da chave.

## Alternativas descartadas

- **Não cifrar:** deixa as notas legíveis em aparelho com root, backup ou perda. O custo de cifrar é pequeno no `sqlite3mc`.
- **Cifrar na camada do app (campo a campo):** quebra o FTS5 (ADR 0038), que indexa o texto claro, e tira a busca.
- **Cifrar na fase 1:** exige migração antes de qualquer dado sair do aparelho e não protege nada que o sistema de arquivos do aparelho já não proteja.

## Consequências

- O campo do PRD §11 passa a apontar para esta ADR; ele só é marcado como resolvido quando a ADR for aceita.
- **Pendente:** a medição em build de perfil e o `sqlcipher` cifrado no aparelho, que não concluiu. Os valores do aparelho acima são de depuração.
- A branch `spike/28-local-encryption` existe só localmente e não é mesclada nem enviada sem aval (CRYPT-01).
- `pubspec.yaml` da `main` não ganha dependência de criptografia na M05 (CRYPT-05).
