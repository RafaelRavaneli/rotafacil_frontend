import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // Salvar os dados do usuário
  static Future<void> cadastrarUsuario({
    required String nome,
    required String email,
    required String telefone,
    required String senha,
    required String tipoPerfil,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('nome', nome);
    await prefs.setString('email', email);
    await prefs.setString('telefone', telefone);
    await prefs.setString('senha', senha);
    await prefs.setString('tipoPerfil', tipoPerfil);
  }

  // Verificar login
  static Future<bool> fazerLogin({
    required String email,
    required String senha,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final emailSalvo = prefs.getString('email');
    final senhaSalva = prefs.getString('senha');

    if (emailSalvo == email && senhaSalva == senha) {
      return true;
    }

    return false;
  }

  // Pegar o nome do usuário
  static Future<String?> getNome() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString('nome');
  }

  // Pegar o tipo de perfil
  static Future<String?> getTipoPerfil() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString('tipoPerfil');
  }

  // Verificar se existe usuário cadastrado
  static Future<bool> existeUsuario() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.containsKey('email');
  }

  // Apagar os dados do usuário
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.clear();
  }
}