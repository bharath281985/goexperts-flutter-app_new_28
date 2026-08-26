import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';

Widget? countryFlagWidget(String? countryName, {double width = 24}) {
  final code = countryToIsoCode(countryName);
  if (code == null) return null;

  return CountryFlag.fromCountryCode(
    code,
    width: width,
    height: width * 0.67,
  );
}

String? countryToIsoCode(String? countryName) {
  if (countryName == null || countryName.trim().isEmpty) return null;

  final normalized = _normalize(countryName);
  final map = <String, String>{
    'india': 'IN',
    'unitedstates': 'US',
    'usa': 'US',
    'unitedkingdom': 'GB',
    'uk': 'GB',
    'uae': 'AE',
    'unitedarabemirates': 'AE',
    'singapore': 'SG',
    'canada': 'CA',
    'australia': 'AU',
    'brazil': 'BR',
    'germany': 'DE',
    'france': 'FR',
    'italy': 'IT',
    'spain': 'ES',
    'japan': 'JP',
    'southkorea': 'KR',
    'korea': 'KR',
    'china': 'CN',
    'pakistan': 'PK',
    'bangladesh': 'BD',
    'srilanka': 'LK',
    'nepal': 'NP',
    'saudiarabia': 'SA',
    'qatar': 'QA',
    'oman': 'OM',
    'kuwait': 'KW',
    'bahrain': 'BH',
  };

  return map[normalized];
}

String _normalize(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]'), '');
}
