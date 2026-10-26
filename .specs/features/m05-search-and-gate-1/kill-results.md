# Resultado do kill test (KILL-06)

Registro da execução de `app/tool/kill_test.sh` no aparelho, em build `--profile` de `integration_test/kill/kill_app.dart`.

## Ambiente

- Aparelho: Samsung SM-A356E, Android 16, adb sem fio (192.168.1.2).
- Comando: `ANDROID_SERIAL=<aparelho> KILL_SEED=2026 bash app/tool/kill_test.sh 100`
- Seed base 2026; o atraso da iteração `i` vem de `KILL_SEED + i` (0,5 a 6 s).

## Execução de 100 iterações

```
100/100 iterations, 0 divergences
```

Código de saída 0. As iterações vão de seed 2027 a 2126.

## Verificação com falha injetada

Mudança temporária em `kill_app.dart`: ao iniciar, antes de comparar, o app apaga (soft delete) o último bloco salvo da página. Comando: `KILL_SEED=9 bash app/tool/kill_test.sh 5`.

Resultado: `5/5 iterations, 5 divergences`, cada divergência com seed, conteúdo esperado e conteúdo encontrado, e código de saída 1. A mudança foi descartada; `kill_app.dart` voltou ao estado commitado.
