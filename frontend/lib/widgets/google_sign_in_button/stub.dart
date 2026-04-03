import 'dart:async';

import 'package:flutter/material.dart';

typedef HandleGoogleSignInFn = Future<void> Function();

Widget buildGoogleSignInButton({
  HandleGoogleSignInFn? onPressed,
  bool isLoading = false,
}) {
  return const SizedBox.shrink();
}
