import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';
import '../../../../app/constants/app_assets.dart';
import '../../../../app/constants/app_colors.dart';
import '../../../../app/dependency_injection/service_locator.dart';
import '../../../../core/network/app_runtime_config_service.dart';
import '../../../../core/services/app_update_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/storage/local_storage.dart';
import '../bloc/auth_bloc.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _videoController;
  Timer? _bootTimer;
  bool _isVideoReady = false;
  bool _bootRequested = false;
  late bool _isFirstLaunch;

  late final AnimationController _animController;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _progressFade;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _logoScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _progressFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
      ),
    );

    final storage = sl<LocalStorage>();
    _isFirstLaunch = !storage.getBool('splash_video_played');

    if (_isFirstLaunch) {
      storage.setBool('splash_video_played', true);
      _videoController = VideoPlayerController.asset(AppAssets.splashVideo)
        ..setLooping(false)
        ..setVolume(1);
      _initializeVideo();
    } else {
      _animController.forward();
      // Fast boot on non-first launch
      _bootTimer = Timer(const Duration(milliseconds: 600), _boot);
    }
  }

  Future<void> _initializeVideo() async {
    try {
      await _videoController?.initialize();
      if (!mounted) return;
      setState(() => _isVideoReady = true);
      await _videoController?.play();
      _startBootTimer(dur: const Duration(seconds: 3));
    } catch (_) {
      _startBootTimer();
    }
  }

  void _startBootTimer({Duration dur = const Duration(seconds: 2)}) {
    _bootTimer ??= Timer(dur, _boot);
  }

  Future<void> _boot() async {
    if (_bootRequested) return;
    _bootRequested = true;

    // Immediately trigger authentication check so navigation is instant
    if (mounted) {
      context.read<AuthBloc>().add(const AuthCheckRequested());
    }

    // Run background configuration & update checks asynchronously without blocking the user
    unawaited(
      Future.wait([
        sl<AppRuntimeConfigService>().load(),
        const LocationService().requestPermission().catchError((_) {}),
        sl<AppUpdateService>().check().then((update) async {
          if (!mounted) return;
          switch (update.action) {
            case AppUpdateAction.maintenance:
              await AppUpdateService.showMaintenanceDialog(context, update);
              break;
            case AppUpdateAction.forceUpdate:
              await AppUpdateService.showUpdateDialog(
                context,
                update,
                force: true,
              );
              break;
            case AppUpdateAction.softUpdate:
              await AppUpdateService.showUpdateDialog(
                context,
                update,
                force: false,
              );
              break;
            case AppUpdateAction.none:
              break;
          }
        }),
      ]).catchError((_) => []),
    );
  }

  @override
  void dispose() {
    _bootTimer?.cancel();
    _videoController?.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: AppColors.white),
          if (_isFirstLaunch && _isVideoReady && _videoController != null)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _videoController!.value.size.width,
                height: _videoController!.value.size.height,
                child: VideoPlayer(_videoController!),
              ),
            )
          else if (!_isFirstLaunch)
            Stack(
              fit: StackFit.expand,
              children: [
                FadeTransition(
                  opacity: _logoFade,
                  child: ScaleTransition(
                    scale: _logoScale,
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width,
                      height: double.infinity,
                      child: Image.asset(
                        AppAssets.splashImage,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 60,
                  left: MediaQuery.of(context).size.width * 0.175,
                  right: MediaQuery.of(context).size.width * 0.175,
                  child: FadeTransition(
                    opacity: _progressFade,
                    child: SizedBox(
                      height: 4,
                      child: LinearProgressIndicator(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
