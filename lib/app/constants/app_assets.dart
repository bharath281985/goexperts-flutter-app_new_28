/// Centralized asset paths used by the app.
class AppAssets {
  AppAssets._();

  static const String logo = 'assets/logo/logo.png';
  static const String logo2 = 'assets/logo/logo2.png';
  static const String appLogo = 'assets/new/appicon.png';
  static const String appLogo2 = 'assets/new/appicon2.png';
  static const String appLogo3 = 'assets/new/appicon3.png';
  static const String bannerImage = 'assets/images/banner.png';
  static const String fullBannerImage = 'assets/images/full_banner.png';
  static const String splashVideo = 'assets/videos/video.mp4';
  static const String splashImage = 'assets/images/splash_screen.png';
  static const String backIcon = 'assets/icons/backicon.png';
  static const String menuIcon = 'assets/icons/menu.png';

  // Fallback Data
  static String? dynamicLogo ; // Can be updated when API is fetched

  static const List<Map<String, String>> fallbackOnboarding = [
    {
      'title': 'Discover Go Experts',
      'description': 'Find verified freelancers, investors, clients, and founders in one place.',
      'image': 'assets/images/1.png',
      'mediaType': 'image',
    },
    {
      'title': 'Connect With the Right People',
      'description': 'Use smart matching to build your network and start meaningful conversations.',
      'image': 'assets/images/2.png',
      'mediaType': 'image',
    },
    {
      'title': 'Build, Fund, and Scale',
      'description': 'Manage opportunities, projects, funding, and growth from your workspace.',
      'image': 'assets/images/3.png',
      'mediaType': 'image',
    },
  ];
}
