extension StringCasingExtension on String {
  String toTitleCase() {
    if (trim().isEmpty) return '';
    return trim()
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }
}
