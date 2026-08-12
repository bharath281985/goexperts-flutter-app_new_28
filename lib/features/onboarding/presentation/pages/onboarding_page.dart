import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_sizes.dart';
import '../../../../app/constants/app_strings.dart';
import '../../../../app/dependency_injection/service_locator.dart';
import '../../../../app/router/route_names.dart';
import '../../../../core/storage/local_storage.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int currentIndex = 0;
  late AnimationController _animationController;
  late AnimationController _iconAnimationController;
  late Animation<double> _fadeAnimation;

  late final List<_OnboardingData> onboardingData = [
    _OnboardingData(
      title: AppStrings.onboarding[0]['title'] ?? 'Hire & Get Hired',
      description:
          AppStrings.onboarding[0]['subtitle'] ??
          'Connect with Top Freelancers and Businesses to deliver World-Class Projects.',
      image: 'assets/images/1.png',
      icon: Icons.work_outline_rounded,
    ),
    _OnboardingData(
      title: AppStrings.onboarding[1]['title'] ?? 'Fund & Get Funded',
      description:
          AppStrings.onboarding[1]['subtitle'] ??
          'Investors discover High-Potential Startups and Founders Raise Capital with ease.',
      image: 'assets/images/2.png',
      icon: Icons.trending_up_rounded,
    ),
    _OnboardingData(
      title: AppStrings.onboarding[2]['title'] ?? 'Grow Together',
      description:
          AppStrings.onboarding[2]['subtitle'] ??
          'Manage contracts, meetings, payments and deals — all in one secure workspace.',
      image: 'assets/images/3.png',
      icon: Icons.groups_2_outlined,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _iconAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
    _iconAnimationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    _iconAnimationController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      currentIndex = index;
    });
    _animationController.reset();
    _iconAnimationController.reset();
    _animationController.forward();
    _iconAnimationController.forward();
  }

  void _nextPage() {
    if (currentIndex < onboardingData.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _navigateToLogin();
    }
  }

  void _navigateToLogin() {
    sl<LocalStorage>().setBool(LocalStorage.kOnboardingSeen, true);
    context.go(Routes.login);
  }

  void _skipToEnd() {
    _navigateToLogin();
  }

  Widget _buildGradientHighlightedTitle(String title) {
    final words = title.split(' ');
    if (words.isEmpty) return Text(title);

    final lastWord = words.last;
    final precedingWords = words.sublist(0, words.length - 1).join(' ');

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1F2937),
          height: 1.2,
        ),
        children: [
          if (precedingWords.isNotEmpty) TextSpan(text: '$precedingWords '),
          TextSpan(
            text: lastWord,
            style: TextStyle(
              foreground: Paint()
                ..shader = const LinearGradient(
                  colors: [
                    AppColors.primary,
                    Color(0xFFC80010),
                    Color(0xFFFF3B46),
                  ],
                ).createShader(const Rect.fromLTWH(0, 0, 200, 50)),
              fontWeight: FontWeight.bold,
              fontSize: 28,
            ),
          ),
        ],
      ),
    );
  }

  Offset _getSlideOffset(int index) {
    switch (index) {
      case 0:
        return Offset(0, (1 - _fadeAnimation.value) * 50);
      case 1:
        return Offset((1 - _fadeAnimation.value) * 100, 0);
      case 2:
        return Offset((1 - _fadeAnimation.value) * -100, 0);
      default:
        return Offset(0, (1 - _fadeAnimation.value) * 50);
    }
  }

  Widget _buildOnboardingPage(_OnboardingData data) {
    int index = onboardingData.indexOf(data);
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [_introScreenWidget(data, index)],
          ),
        );
      },
    );
  }

  Widget _introScreenWidget(_OnboardingData data, int index) {
    return Column(
      children: [
        FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            height: 280,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSizes.radiusXl),
            ),
            child: Image.asset(
              data.image,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
                  Icon(data.icon, size: 100, color: AppColors.primary),
            ),
          ),
        ),

        const SizedBox(height: AppSizes.xl),
        // Title with slide animation
        Transform.translate(
          offset: _getSlideOffset(index),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: _buildGradientHighlightedTitle(data.title),
          ),
        ),

        const SizedBox(height: AppSizes.md),
        Row(
          children: [
            Expanded(
              child: Divider(
                thickness: 1,
                height: 1,
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Icon(data.icon, color: AppColors.primary, size: 24),
            ),
            Expanded(
              child: Divider(
                thickness: 1,
                height: 1,
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.md),

        // Description with delayed fade
        AnimatedOpacity(
          opacity: _fadeAnimation.value > 0.5 ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: Transform.translate(
            offset: Offset(0, (1 - _fadeAnimation.value) * 20),
            child: Text(
              data.description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIndicator(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: currentIndex == index ? 24 : 8,
      decoration: BoxDecoration(
        color: currentIndex == index
            ? AppColors.primary
            : const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF8F9FF), Color(0xFFFFFFFF)],
              ),
            ),
          ),
          PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: onboardingData.length,
            itemBuilder: (context, index) {
              return _buildOnboardingPage(onboardingData[index]);
            },
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(AppSizes.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Page indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        onboardingData.length,
                        (index) => _buildIndicator(index),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Next button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          currentIndex == onboardingData.length - 1
                              ? 'Get Started'
                              : 'Next',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 50,
            right: 20,
            child: SafeArea(
              child: InkWell(
                onTap: _skipToEnd,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: const Text(
                    'Skip',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingData {
  final String title;
  final String description;
  final String image;
  final IconData icon;

  _OnboardingData({
    required this.title,
    required this.description,
    required this.image,
    required this.icon,
  });
}
