# Testes do app

Como escrever e organizar os testes do app (ADR 0015). Índice em [app/CLAUDE.md](../../CLAUDE.md); invariantes no [CLAUDE.md da raiz](../../../CLAUDE.md).

## Onde fica cada teste

| Nível | Pasta | Roda com |
| --- | --- | --- |
| Unidade, widget e banco | `test/` | `fvm flutter test` (host, sem emulador) |
| Migração Drift | `test/drift/` (gerado pelo `make-migrations`) | `fvm flutter test` |
| E2E | `integration_test/` | `fvm flutter test integration_test` (emulador ou aparelho) |

A organização de `lib/` ainda não foi decidida. Quando for, `test/` espelha `lib/` arquivo a arquivo (`lib/x/y.dart` → `test/x/y_test.dart`).

## Nomes

O código do requisito vem primeiro, quando houver: `test('RF-02: reordenar altera só uma linha', ...)`. Teste de invariante cita o RNF: `test('RNF-05: excluir caderno só preenche deleted_at', ...)`.

## Banco (sempre, com SQLite real)

Todo DAO, repositório e consulta é testado contra um banco em memória novo a cada teste. Não mocke o banco nem os DAOs.

```dart
import 'package:drift/native.dart';

late AppDatabase db;

setUp(() => db = AppDatabase(NativeDatabase.memory()));
tearDown(() => db.close());
```

- Por isso o `AppDatabase` recebe o `QueryExecutor` no construtor; o executor de produção (`drift_flutter`) fica fora da classe.
- Teste pelo que a UI consome: os streams (`watch()`), não só leituras pontuais.

  ```dart
  expectLater(repo.watchPages(notebookId), emitsInOrder([isEmpty, hasLength(1)]));
  await repo.createPage(notebookId, title: 'A');
  ```

## Migrações

1. Configure o banco em `build.yaml` (`drift_dev` → `databases`) quando o `AppDatabase` existir.
2. A cada mudança de tabela: suba `schemaVersion` e rode `fvm dart run drift_dev make-migrations`. O comando exporta o schema da versão para `drift_schemas/`, gera os helpers de migração passo a passo e o teste em `test/drift/`.
3. Escreva a migração `vN → vN+1` com os helpers gerados e complete o teste gerado (`SchemaVerifier`) com dados: linhas criadas na versão antiga precisam sobreviver à nova.
4. Versione o que o comando gerou em `drift_schemas/` e `test/drift/`. Schema exportado não se edita à mão.

## Mocks com mocktail

Mocke só interfaces acima do banco: sync (fase 2), relógio, gerador de id, serviços de plataforma.

```dart
class MockClock extends Mock implements Clock {}

final clock = MockClock();
when(() => clock.now()).thenReturn(DateTime.utc(2026, 10, 11));
```

- Tipo próprio usado com `any()` precisa de `registerFallbackValue(...)` em `setUpAll`.
- Prefira um fake simples (`class FakeX implements X`) quando o teste só precisa de dados, não de verificação de chamadas.

## Riverpod

Injete banco, mocks e fakes por override, nunca por variável global.

```dart
final container = ProviderContainer.test(overrides: [
  databaseProvider.overrideWithValue(db),
  clockProvider.overrideWithValue(clock),
]);
```

`ProviderContainer.test` descarta o container ao fim do teste.

## Widget

Toda tela e componente com lógica tem teste de widget, com o banco em memória e os mesmos overrides:

```dart
await tester.pumpWidget(ProviderScope(
  overrides: [databaseProvider.overrideWithValue(db)],
  child: const MaterialApp(home: NotebooksScreen()),
));
```

- Os streams do Drift usam timers: feche o banco e dê um `pump` antes do fim do teste para não sobrar "A Timer is still pending".
- Sem golden tests por enquanto; o editor de blocos ainda não foi decidido.

## E2E (fluxos principais)

Um arquivo por fluxo em `integration_test/`, começando com `IntegrationTestWidgetsFlutterBinding.ensureInitialized();`. Fluxos da fase 1:

| Fluxo | Requisitos |
| --- | --- |
| Criar, renomear, arquivar e excluir caderno | RF-01 |
| Criar e reordenar páginas | RF-02 |
| Escrever num bloco, fechar e reabrir o app com o texto preservado | RF-03, RF-04 |
| Buscar por título e conteúdo | RF-05 |

O fluxo do RF-03 espera a ADR do editor de blocos. Fluxo principal novo entra nesta tabela no mesmo commit do teste.

## Invariantes com teste fixo

Cada invariante da raiz que vale para o app tem pelo menos um teste de banco ou de unidade:

- excluir só preenche `deleted_at`, e as consultas ignoram registros excluídos (RNF-05);
- IDs são UUID v7, gerados sem rede (RNF-04);
- caderno nasce com a linha do dono em `notebook_members` (ADR 0004);
- `created_by` e `updated_by` vêm do usuário local anônimo antes do login (ADR 0011);
- arquivar preenche `notebook_members.archived_at` da linha do usuário, não `deleted_at` (ADR 0012);
- o app nunca incrementa `blocks.version` (ADR 0013);
- datas gravadas em UTC.

## Processos

- **Bug começa por teste:** escreva o teste que reproduz o bug e veja-o falhar antes de corrigir.
- **Determinismo:** relógio e gerador de UUID ficam atrás de providers e são sobrescritos nos testes. Nada de `DateTime.now()` ou `Uuid()` direto em regra de negócio.
- **Carga (RNF-06):** o teste com 10 mil páginas leva `@Tags(['perf'])`. Ao criar o primeiro, declare a tag em `dart_test.yaml` com `skip`, para ficar fora do `flutter test` padrão, e rode com `fvm flutter test --tags perf --run-skipped` antes de release.
- **Cobertura:** `fvm flutter test --coverage` gera `coverage/lcov.info` (não versionado). Serve de sinal para achar lacunas; não há meta mínima.
