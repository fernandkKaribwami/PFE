import 'package:flutter/material.dart';

import 'stub.dart';

Widget buildGoogleSignInButton({
  HandleGoogleSignInFn? onPressed,
  bool isLoading = false,
}) {
  return OutlinedButton.icon(
    onPressed: isLoading || onPressed == null ? null : onPressed,
    style: OutlinedButton.styleFrom(
      foregroundColor: Colors.black87,
      side: const BorderSide(color: Colors.grey),
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    icon: isLoading
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : const Icon(Icons.login, color: Colors.black87),
    label: Text(
      isLoading ? 'Connexion Google...' : 'Se connecter avec Google',
      style: const TextStyle(color: Colors.black87),
    ),
  );
}
