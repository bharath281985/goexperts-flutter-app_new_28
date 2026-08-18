String cleanFieldLabel(String label) {
  return label
      .replaceAll('*', '')
      .replaceAll(
        RegExp(r'\s*\((?:optional|\d+\s+selected)\)', caseSensitive: false),
        '',
      )
      .trim();
}

String enterHintForLabel(String label) => 'Enter ${cleanFieldLabel(label)}';

String selectHintForLabel(String label) => 'Select ${cleanFieldLabel(label)}';
