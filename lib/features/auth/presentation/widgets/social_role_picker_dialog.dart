import 'package:flutter/material.dart';

import '../../../../core/utils/enums.dart';
import 'choose_role_view.dart';

/// Lightweight role picker shown before social login when role is not known.
Future<UserRole?> showSocialRolePicker(BuildContext context) {
  return Navigator.of(context).push<UserRole>(
    MaterialPageRoute(
      builder: (context) => ChooseRoleView(
        onRoleSelected: (role) {
          Navigator.of(context).pop(role);
        },
        onBack: () {
          Navigator.of(context).pop();
        },
      ),
    ),
  );
}
