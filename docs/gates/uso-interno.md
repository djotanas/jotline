# Roteiro do uso interno e da verificação do editor (Gate 1)

Critérios manuais do Gate 1 (#29): duas semanas de uso interno no Android físico e a lista de verificação do editor (#67) no iPhone e no Android físico. O resultado entra em `docs/gates/gate-1.md`.

- **Início do período de uso interno:** _a preencher pelo usuário (AAAA-MM-DD)._
- **Fim previsto:** início + 14 dias.
- **Aparelho do uso interno:** Samsung SM-A356E, Android 16.

## 1. Instalar o build de perfil no Android

Dentro de `app/`, com o aparelho no `adb devices`:

```bash
fvm flutter pub get
fvm dart run build_runner build --delete-conflicting-outputs
fvm flutter build apk --profile
adb install -r build/app/outputs/flutter-apk/app-profile.apk
```

Abra o app uma vez (`adb shell am start -n com.jon.jotline/.MainActivity`) e espere alguns segundos: o `integrity.log` só existe depois da primeira abertura. Confirme que o log é legível com `adb shell run-as com.jon.jotline ls files`; se aparecer `package not debuggable`, pare e avise antes de iniciar o período.

Não use `pm clear` nem desinstale o app durante o período: apagaria os dados e o `integrity.log`.

Use o app como caderno de verdade: criar cadernos e páginas, escrever, desenhar, buscar, apagar e restaurar. Feche o app de formas variadas (voltar, tela de recentes, `adb shell am force-stop com.jon.jotline`, bateria acabando).

## 2. Ler o `integrity.log`

A cada abertura o app acrescenta uma linha com data UTC, versão, `pass` ou `fail` e, nas falhas, a invariante e os ids. O arquivo fica em `files/integrity.log` do app:

```bash
adb exec-out run-as com.jon.jotline cat files/integrity.log > /tmp/integrity.log
wc -l < /tmp/integrity.log
grep -c ' pass' /tmp/integrity.log
grep ' fail' /tmp/integrity.log
```

Anexe o arquivo ao resumo do Gate (`gate-1.md`): total de linhas, quantas `pass`, quantas `fail`. Qualquer `fail` abre uma issue `data-loss`.

## 3. Abrir uma issue `data-loss`

Abra uma issue com o rótulo `data-loss` sempre que algo escrito sumir, voltar diferente do que foi salvo ou o `integrity.log` registrar `fail`. Inclua: o que foi escrito, o que apareceu, data e hora, versão do app (linha do `integrity.log`) e o que se fazia (fechar o app, trocar de app, bateria). Ao resolver, escreva na issue o desfecho (causa e correção ou "não reproduzido").

O rótulo precisa existir antes (uma vez: `gh label create data-loss`).

```bash
gh issue create --label data-loss --title "Perda de dados: <resumo>"
```

## 4. Lista de verificação do editor (#67)

Telas: Cadernos → um caderno → uma página → tocar num bloco Texto. Rodar em um iPhone (teclado iOS pt-BR) e no Android físico (Gboard pt-BR, sem teclado físico), com o app da milestone (`fvm flutter run --profile -d <aparelho>`). A lista vem do relatório do spike (`spikes/m04-editor/REPORT.md`, seção "Manual checklist", na branch `spike/22-block-editor`), adaptada ao editor real:

1. Tocar no fim de um parágrafo e digitar `nao voce acao ` com autocorreção ligada: o texto salvo fica `Não você ação ` (ou outra correção do teclado), sem caracteres duplicados, faltando ou sobrando.
2. Segurar `a` e escolher `ã` no painel de acentos. No iOS, segurar `e` e deslizar até `é`: um único caractere acentuado salvo.
3. Digitar `naçã` e escolher uma sugestão: a palavra é trocada, não duplicada.
4. iOS: segurar a barra de espaço (cursor flutuante) para mover dentro do parágrafo e digitar: o texto entra no cursor.
5. Enter no meio de um parágrafo: dois blocos. Backspace no início do de baixo: um bloco.
6. Enter no fim de um item marcado de um bloco Checklist: novo item desmarcado. Enter de novo no item vazio: bloco Texto.
7. Tocar em um checkbox: só aquele item muda e o teclado não abre.
8. Com o teclado aberto, a barra de blocos fica logo acima dele e o fundo do bloco em edição continua alinhado ao rolar.
9. iOS: ditado em um parágrafo: texto salvo.
10. Colocar o app em segundo plano logo após digitar, encerrar e reabrir: o texto digitado está lá.

Registre na issue #67, por aparelho: modelo, versão do sistema, teclado e o resultado de cada passo (passou, falhou com descrição). **Se qualquer item falhar,** pare: a ADR 0035 (`super_editor`) precisa ser substituída por uma nova ADR antes de o Gate 1 ser marcado como passado (GATE-06).

## 5. Encerramento

Ao fim das duas semanas, puxe o `integrity.log` (seção 2), liste as issues `data-loss` com o desfecho e escreva `docs/gates/gate-1.md`. Um critério sem evidência é "não atendido" e o Gate não passa.
