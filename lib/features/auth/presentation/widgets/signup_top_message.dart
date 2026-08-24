import 'package:flutter/material.dart';
import '../../../../core/extensions/context_extensions.dart';

void showSignupTopMessage(
  BuildContext context,
  String message, {
  required bool isSuccess,
}) {
  context.showTopSnack(message, isError: !isSuccess);
}

