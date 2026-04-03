import 'package:flutter/material.dart';
import 'package:google_sign_in_web/web_only.dart' as google_web;

import 'stub.dart';

Widget buildGoogleSignInButton({
  HandleGoogleSignInFn? onPressed,
  bool isLoading = false,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SizedBox(
        height: 44,
        child: google_web.renderButton(
          configuration: google_web.GSIButtonConfiguration(
            theme: google_web.GSIButtonTheme.outline,
            size: google_web.GSIButtonSize.large,
            text: google_web.GSIButtonText.signinWith,
            shape: google_web.GSIButtonShape.rectangular,
            minimumWidth: 320,
          ),
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'Choisissez directement votre compte Google USMBA dans la fenetre qui s ouvre.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
    ],
  );
}
