/// Repairs upload URLs that accidentally expose the backend's filesystem path.
///
/// Example:
/// `https://host//home/app/uploads/user/photo.jpg`
/// becomes `https://host/uploads/user/photo.jpg`.
String normalizeImageUrl(String url) {
  final value = url.trim();
  final uploadsIndex = value.indexOf('/uploads/');
  if (uploadsIndex < 0) return value;

  final uri = Uri.tryParse(value);
  if (uri != null && uri.hasScheme && uri.authority.isNotEmpty) {
    return '${uri.scheme}://${uri.authority}${value.substring(uploadsIndex)}';
  }
  return value.substring(uploadsIndex);
}
