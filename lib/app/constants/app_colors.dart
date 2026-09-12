import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:goexperts_app/app/config/app_config.dart';

import 'package:goexperts_app/core/utils/enums.dart';

import '../../core/storage/secure_storage.dart';

class AppColors {
  AppColors._();

  // ============================================================
  // ROLE COLORS
  // Default colors
  // These will be replaced by API colors
  // ============================================================

  static Color clientColor = const Color(0xFF0284C7);

  static Color founderColor = const Color(0xFF16A34A);

  static Color freelancerColor = const Color(0xFF7C3AED);

  static Color investorColor = const Color(0xFFFF7515);

  // ============================================================
  // API - LOAD ROLE COLORS
  // ============================================================

  static Future<void> loadRoleColors() async {
    try {
      final dio = Dio();

      final response = await dio.get(
        '${AppConfig.baseUrl}/public/settings/role-color',
      );

      debugPrint(
        'Colors API response: ${response.data}',
      );

      final data = response.data["colors"];

      if (data is! Map) {
        debugPrint('Invalid colors API response');
        return;
      }

      // CLIENT
      if (data['Client'] != null) {
        clientColor = _hexToColor(
          data['Client'].toString(),
          clientColor,
        );
      }

      // FOUNDER
      if (data['Founder'] != null) {
        founderColor = _hexToColor(
          data['Founder'].toString(),
          founderColor,
        );
      }

      // FREELANCER
      if (data['Freelancer'] != null) {
        freelancerColor = _hexToColor(
          data['Freelancer'].toString(),
          freelancerColor,
        );
      }

      // INVESTOR
      if (data['Investor'] != null) {
        investorColor = _hexToColor(
          data['Investor'].toString(),
          investorColor,
        );
      }

      debugPrint('Client: $clientColor');
      debugPrint('Founder: $founderColor');
      debugPrint('Freelancer: $freelancerColor');
      debugPrint('Investor: $investorColor');
    } catch (e) {
      debugPrint(
        'Role colors API error: $e',
      );
    }
  }



  static Color _hexToColor(
    String hex,
    Color fallback,
  ) {
    try {
      hex = hex.replaceFirst('#', '');

      if (hex.length == 6) {
        hex = 'FF$hex';
      }

      if (hex.length != 8) {
        return fallback;
      }

      return Color(
        int.parse(
          hex,
          radix: 16,
        ),
      );
    } catch (e) {
      debugPrint(
        'Invalid color: $hex',
      );

      return fallback;
    }
  }

static const Color defaultPrimary = Color(0xFFeb5234);

// ============================================================
// ROLE
// ============================================================

static String? role;

static final ValueNotifier<Color> primaryNotifier =
    ValueNotifier<Color>(defaultPrimary);

// ============================================================
// LOAD ROLE
// ============================================================

static Future<void> loadRole() async {
  final storage = SecureStorage();

  role = await storage.role;

  debugPrint('AppColors role: $role');

  primaryNotifier.value = getRoleColor(role);

  debugPrint('AppColors primary: ${primaryNotifier.value}');
}

// ============================================================
// GET ROLE COLOR
// ============================================================

static Color getRoleColor(String? role) {
  switch (role?.trim().toUpperCase()) {
    case "CLIENT":
      return clientColor;

    case "FOUNDER":
      return founderColor;

    case "FREELANCER":
      return freelancerColor;

    case "INVESTOR":
      return investorColor;

    default:
      return defaultPrimary;
  }
}

// ============================================================
// PRIMARY
// ============================================================

static Color get primary => primaryNotifier.value;

  static const Color secondary = Color.fromARGB(
    255,
    20,
    5,
    241,
  );

  static const Color secondaryPrimary = Color(0xFFD4AF37);

  static const Color mediumGold = Color(0xFFD4AF37);

  static const Color gold = Color(0xFFD4AF37);

  static const Color primaryBlack = Color(0xFF111111);

  // ============================================================
  // TEXT
  // ============================================================

  static const Color darkText = Color(0xFF202124);

  static const Color mutedText = Color(0xFF6B7280);

  static const Color subtleText = Color(0xFF9AA0A6);

  // ============================================================
  // SURFACES
  // ============================================================

  static const Color background = Color(0xFFF8F9FC);

  static const Color card = Color(0xFFFFFFFF);

  static const Color cardGoldSurface = Color(0xFFFFFDF5);

  static const Color border = Color(0xFFE7EAF3);

  static const Color cardGoldBorder = Color(0xFFEEDDAA);

  // ============================================================
  // STATUS
  // ============================================================

  static const Color success = Color(0xFF16A34A);

  static const Color warning = Color(0xFFF59E0B);

  static const Color danger = Color(0xFFDC2626);

  static const Color info = Color(0xFF0EA5E9);

  // ============================================================
  // DARK MODE
  // ============================================================

  static const Color darkBackground = Color(0xFF0E0E10);

  static const Color darkCard = Color(0xFF17171A);

  static const Color darkBorder = Color(0xFF26262B);

  static const Color darkText2 = Color(0xFFECEDEE);

  // ============================================================
  // UTILITY
  // ============================================================

  static const Color white = Color(0xFFFFFFFF);

  static const Color black = Color(0xFF091C47);

  static const Color shadow = Color(0x14000000);

  // ============================================================
  // PROJECT
  // ============================================================

  static const Color projectText = Color(0xFF10172A);

  static const Color projectSecondaryText = Color(0xFF4B5563);

  static const Color projectBodyText = Color(0xFF667085);

  static const Color projectPurple = Color(0xFF5B35F5);

  static const Color projectPurpleText = Color(0xFF4F35D9);

  static const Color projectPurpleSoft = Color(0xFFF2F0FF);

  static const Color projectPurpleSurface = Color(0xFFF1EEFF);

  static const Color projectAvatarRing = Color(0xFFE5DEFF);

  static const Color projectSoftBorder = Color(0xFFE9EAF3);

  static const Color projectPanelBorder = Color(0xFFE5E7EB);

  static const Color projectDash = Color(0xFFDDE1EC);

  static const Color projectVerified = Color(0xFF2F80ED);

  static const Color projectTailwind = Color(0xFF38BDF8);

  static const Color projectSuccessText = Color(0xFF166534);

  static const Color projectWarningText = Color(0xFF92400E);

  // ============================================================
  // STARTUP
  // ============================================================

  static const Color startupHeaderRed = Color(0xFFE30613);

  static const Color startupHeaderDarkRed = Color(0xFFC80010);

  static const Color startupHeaderHighlight = Color(0x22FFFFFF);

  static const Color startupTagSurface = Color(0x33FFFFFF);

  static const Color startupTagText = Color(0xFFFFFFFF);

  static const Color startupChipSurface = Color(0xFFFFE8EA);

  static const Color startupChipText = Color(0xFFC80010);

  static const Color startupIconGreenSurface = Color(0xFFE6F8EE);

  static const Color startupIconBlueSurface = Color(0xFFEAF1FF);

  static const Color startupIconPurpleSurface = Color(0xFFF1EAFF);

  // ============================================================
  // GRADIENTS
  // ============================================================

  static  LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
    AppColors.primary.withValues(alpha: .80),
      AppColors.secondary.withValues(alpha: .50),
    ],
    stops: const [
    0,
    0.80,
  ],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFD4AF37),
      Color(0xFFC59B27),
    ],
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color.fromARGB(255, 1, 1, 94),
      Color.fromARGB(255, 87, 1, 1),
    ],
  );

  // ============================================================
  // SEED
  // ============================================================

  static Color fromSeed(String seed) {
    const palette = [
      Color(0xFFE30613),
      Color(0xFF0EA5E9),
      Color(0xFF16A34A),
      Color(0xFFF59E0B),
      Color(0xFF7C3AED),
      Color(0xFFDB2777),
      Color(0xFF0891B2),
      Color(0xFF4F46E5),
    ];

    var hash = 0;

    for (final code in seed.codeUnits) {
      hash = code + ((hash << 5) - hash);
    }

    return palette[hash.abs() % palette.length];
  }
}