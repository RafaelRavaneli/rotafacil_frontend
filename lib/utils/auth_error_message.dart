import 'dart:async';

import 'package:http/http.dart' as http;

import '../services/api_client.dart';

String authErrorMessage(Object error) {
  if (error is ApiException) {
    return error.message;
  }

  if (error is TimeoutException) {
    return 'A solicitação demorou demais. Tente novamente.';
  }

  if (error is http.ClientException) {
    return 'Não foi possível conectar ao servidor. '
        'Verifique sua conexão com a internet e tente novamente.';
  }

  final raw = error.toString().trim();
  final normalized = raw.toLowerCase();

  if (normalized.contains('xmlhttprequest error') ||
      normalized.contains('failed host lookup') ||
      normalized.contains('connection refused') ||
      normalized.contains('network is unreachable') ||
      normalized.contains('connection reset') ||
      normalized.contains('connection closed') ||
      normalized.contains('socketexception')) {
    return 'Não foi possível conectar ao servidor. '
        'Verifique sua conexão com a internet e tente novamente.';
  }

  var message = raw;

  const removablePrefixes = <String>['Exception: ', 'Bad state: '];

  for (final prefix in removablePrefixes) {
    if (message.startsWith(prefix)) {
      message = message.substring(prefix.length).trim();
      break;
    }
  }

  if (message.isNotEmpty && !message.contains('\n') && message.length <= 180) {
    return message;
  }

  return 'Não foi possível concluir a operação. Tente novamente.';
}
