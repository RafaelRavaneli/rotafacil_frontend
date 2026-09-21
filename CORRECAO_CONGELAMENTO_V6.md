# Correção de congelamento — V6

O principal ajuste desta versão foi a arquitetura das abas.

## Problema encontrado

As shells de Turista, Guia e Agência usavam:

```dart
IndexedStack(
  index: index,
  children: tabs,
)
```

O `IndexedStack` mantém todas as abas montadas ao mesmo tempo.
Isso significa que, ao entrar como Guia ou Agência, o Flutter construía
simultaneamente:

- dashboard;
- lista de trilhas;
- agenda;
- mensagens/guias;
- perfil;
- imagens locais e remotas;
- vários `AnimatedBuilder`.

No Chrome isso pode deixar a interface muito pesada, principalmente
quando já existem fotos salvas como `data:image;base64`.

## Correção

Agora cada Shell usa um `switch` e monta apenas a aba selecionada.

Exemplo:

```dart
Widget _currentPage() {
  switch (index) {
    case 0:
      return const GuideDashboardTab();
    case 1:
      return const TrailsManagementScreen(isAgency: false);
    ...
  }
}
```

Também foi removido o `IndexedStack`.

## Otimização de imagens

`ProfileAvatar` e `NetworkImageBox` agora guardam os bytes decodificados
no `State` do widget. O Base64 não é convertido de novo em todo rebuild.

As novas fotos também são reduzidas antes de serem armazenadas:

- Perfil: largura máxima 640, qualidade 60;
- Trilha: largura máxima 900, qualidade 60.

Isso reduz o custo do `shared_preferences` no navegador.

## Teste

Depois de extrair:

```powershell
flutter create .
flutter pub get
flutter analyze
flutter run -d chrome
```

Teste:

1. Guia > Painel > Trilhas > Agenda > Mensagens > Perfil.
2. Agência > Painel > Guias > Trilhas > Agendamentos > Perfil.
3. Volte várias vezes entre as abas.

Nenhuma aba escondida permanece sendo renderizada.
