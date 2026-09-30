import 'package:flutter/material.dart';
import 'auth_error_message.dart';

Future<bool> runAction(
  BuildContext context,
  Future<void> Function() action,
) async {
  try {
    await action();
    return true;
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
    }
    return false;
  }
}
