import 'package:rotafacil/utils/document_validator.dart';
import 'package:rotafacil/utils/role_utils.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rotafacil/config/app_config.dart';
import 'package:rotafacil/models/user_role.dart';
import 'package:rotafacil/pages/auth/login_screen.dart';
import 'package:rotafacil/pages/auth/welcome_screen.dart';
import 'package:rotafacil/pages/auth/profile_choice_screen.dart';
import 'package:rotafacil/pages/auth/register_screen.dart';
import 'package:rotafacil/pages/guide/guide_shell.dart';
import 'package:rotafacil/pages/agency/agency_shell.dart';
import 'package:rotafacil/pages/tourist/tourist_shell.dart';
import 'package:rotafacil/services/api_client.dart';
import 'package:rotafacil/services/auth_gateway.dart';
import 'package:rotafacil/services/local_auth_service.dart';
import 'package:rotafacil/state/app_store.dart';
import 'package:rotafacil/widgets/role_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Fazer login abre diretamente e-mail e senha', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: WelcomeScreen()));
    await tester.tap(find.text('Fazer login'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(ProfileChoiceScreen), findsNothing);
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.text('E-mail'), findsOneWidget);
    expect(find.textContaining('CPF'), findsNothing);
    expect(find.textContaining('CNPJ'), findsNothing);
  });

  for (final role in UserRole.values) {
    testWidgets('Criar conta escolhe ${role.title} e abre cadastro', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: WelcomeScreen()));
      await tester.tap(find.text('Criar conta'));
      await tester.pumpAndSettle();
      expect(find.byType(ProfileChoiceScreen), findsOneWidget);
      final card = find.byWidgetPredicate(
        (widget) => widget is RoleCard && widget.role == role,
      );
      await tester.ensureVisible(card);
      await tester.tap(card);
      await tester.pumpAndSettle();
      expect(
        tester.widget<RegisterScreen>(find.byType(RegisterScreen)).role,
        role,
      );
      expect(find.byType(LoginScreen), findsNothing);
      expect(
        find.text('CPF'),
        role == UserRole.guide ? findsOneWidget : findsNothing,
      );
      expect(
        find.text('CNPJ'),
        role == UserRole.agency ? findsOneWidget : findsNothing,
      );
    });
  }

  for (final account in [
    ('turista', 'thiago@email.com', TouristShell),
    ('guia', 'guia@email.com', GuideShell),
    ('agencia', 'contato@aventuraprime.com', AgencyShell),
  ]) {
    test(
      'Login local identifica ${account.$1} pelo e-mail e rejeita senha incorreta',
      () async {
        expect(
          await LocalAuthService.instance.login(
            email: account.$2,
            password: '123456',
          ),
          account.$1,
        );
        expect(
          await LocalAuthService.instance.login(
            email: account.$2,
            password: 'errada',
          ),
          isNull,
        );
      },
    );

    testWidgets('Login abre a home de ${account.$1}', (tester) async {
      tester.view.physicalSize = const Size(1000, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await AppStore.instance.initialize();
      AppStore.instance.pushNotifications = false;
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
      await tester.enterText(find.byType(TextField).at(0), account.$2);
      await tester.enterText(find.byType(TextField).at(1), '123456');
      await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
      await tester.pumpAndSettle();
      expect(find.byType(account.$3), findsOneWidget);
    }, skip: AppConfig.useBackend);

    test('API determina perfil ${account.$1} sem seleção prévia', () async {
      final role = account.$1 == 'turista' ? 'usuario' : account.$1;
      final gateway = AuthGateway(
        api: ApiClient(
          client: MockClient((request) async {
            expect(jsonDecode(request.body), {
              'email': account.$2,
              'senha': 'senha123',
            });
            return http.Response(
              jsonEncode({'token': 'test-token', 'id': 'u1', 'tipo': role}),
              200,
            );
          }),
        ),
      );
      expect(
        (await gateway.login(email: account.$2, password: 'senha123'))?.role,
        role,
      );
    }, skip: !AppConfig.useBackend);
  }

  test('Recuperação local identifica conta por e-mail', () async {
    await LocalAuthService.instance.resetPassword(
      email: 'guia@email.com',
      newPassword: 'nova123',
    );
    expect(
      await LocalAuthService.instance.login(
        email: 'guia@email.com',
        password: 'nova123',
      ),
      'guia',
    );
  });
  test('Aliases compartilham normalização e validação de cadastro', () {
    for (final role in ['Agência', 'agencia', 'agency']) {
      expect(normalizeRoleKey(role), 'agencia');
      expect(DocumentValidator.labelForRole(role), 'CNPJ');
      expect(
        DocumentValidator.isValidForRole(role, '11.222.333/0001-81'),
        isTrue,
      );
      expect(DocumentValidator.isValidForRole(role, '52998224725'), isFalse);
    }
    for (final role in ['Guia', 'guide']) {
      expect(normalizeRoleKey(role), 'guia');
      expect(DocumentValidator.isValidForRole(role, '52998224725'), isTrue);
      expect(DocumentValidator.isValidForRole(role, '11111111111'), isFalse);
    }
    for (final role in ['usuario', 'turista', 'tourist']) {
      expect(normalizeRoleKey(role), 'turista');
    }
  });
  testWidgets(
    'Cadastro valida documento antes de avançar e preserva dados ao voltar',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: RegisterScreen(role: UserRole.agency)),
      );
      await tester.enterText(find.byType(TextField).at(0), 'Agência de teste');
      await tester.enterText(find.byType(TextField).at(4), '11111111111111');
      await tester.ensureVisible(find.byIcon(Icons.arrow_forward));
      await tester.tap(find.byIcon(Icons.arrow_forward));
      await tester.pumpAndSettle();
      expect(find.text('CNPJ'), findsOneWidget);
      expect(find.text('E-mail'), findsNothing);
      await tester.enterText(
        find.byType(TextField).at(4),
        '11.222.333/0001-81',
      );
      await tester.tap(find.byIcon(Icons.arrow_forward));
      await tester.pumpAndSettle();
      expect(find.text('E-mail'), findsOneWidget);
      expect(find.text('Senha'), findsOneWidget);
      await tester.ensureVisible(find.text('Voltar aos dados'));
      await tester.tap(find.text('Voltar aos dados'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        'Agência de teste',
      );
      expect(
        tester.widget<TextField>(find.byType(TextField).at(4)).controller!.text,
        '11.222.333/0001-81',
      );
    },
  );
}
