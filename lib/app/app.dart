import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/connectivity/connectivity_cubit.dart';

import '../core/network/global_error_bus.dart';
import '../core/notifications/device_token_registration_service.dart';
import '../core/notifications/notification_router.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../core/notifications/push_notification_service.dart';
import '../core/storage/local_storage.dart';
import '../core/auth/session_handler.dart';

import '../core/widgets/app_offline_banner.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/subscriptions/domain/repositories/subscription_repository.dart';
import '../l10n/app_localizations.dart';
import 'constants/app_strings.dart';
import 'dependency_injection/service_locator.dart';
import 'locale/locale_cubit.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';
import 'theme/theme_cubit.dart';
import '../core/extensions/context_extensions.dart';

class GoExpertsApp extends StatefulWidget {
  const GoExpertsApp({super.key});

  @override
  State<GoExpertsApp> createState() => _GoExpertsAppState();
}

class _GoExpertsAppState extends State<GoExpertsApp> {
  late final AuthBloc _authBloc;
  late final GoRouter _router;
  StreamSubscription<String>? _errorSub;
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    _authBloc = AuthBloc(sl<AuthRepository>(), sl<SubscriptionRepository>());
    _router = createRouter(_authBloc);
    sl<SessionHandler>().onSessionExpired = (message) {
      _authBloc.add(const AuthLoggedOut(remote: false));
      GlobalErrorBus.instance.emit(message);
    };
    _bootstrapPushAndUpdates();
    _authSub = _authBloc.stream.listen((state) {
      if (state.status == AuthStatus.authenticated) {
        sl<DeviceTokenRegistrationService>().registerIfPossible();
      }
    });
    _errorSub = GlobalErrorBus.instance.stream.listen((message) {
      final ctx = _router.routerDelegate.navigatorKey.currentContext;
      if (ctx != null && ctx.mounted) {
        ctx.showTopSnack(message, isError: true);
      }
    });
  }

  Future<void> _bootstrapPushAndUpdates() async {
    final push = sl<PushNotificationService>();
    final deviceTokens = sl<DeviceTokenRegistrationService>();
    deviceTokens.listenForTokenRefresh();
    await push.initialize();
    await FirebaseAnalytics.instance.logAppOpen();
    push.setOnMessageOpenedHandler((data) {
      NotificationRouter(_router).handle(data);
    });
    push.setOnForegroundMessage((data) {
      final ctx = _router.routerDelegate.navigatorKey.currentContext;
      if (ctx != null && ctx.mounted) {
        ctx.showTopSnack(data['title']?.toString() ?? 'New notification');
      }
    });
  }

  @override
  void dispose() {
    _errorSub?.cancel();
    _authSub?.cancel();
    _authBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: _authBloc),
        BlocProvider<ThemeCubit>(create: (_) => ThemeCubit(sl<LocalStorage>())),
        BlocProvider<LocaleCubit>(
          create: (_) => LocaleCubit(sl<LocalStorage>()),
        ),
        BlocProvider<ConnectivityCubit>.value(value: sl<ConnectivityCubit>()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return BlocBuilder<LocaleCubit, Locale>(
            builder: (context, locale) {
              return MaterialApp.router(
                title: AppStrings.appName,
                debugShowCheckedModeBanner: false,
                theme: AppTheme.light,
                darkTheme: AppTheme.dark,
                themeMode: themeMode,
                locale: locale,
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                routerConfig: _router,
                builder: (context, child) {
                  return BlocBuilder<ConnectivityCubit, ConnectivityState>(
                    builder: (context, connectivity) {
                      return Column(
                        children: [
                          if (!connectivity.isOnline)
                            AppOfflineBanner(
                              onRetry: () =>
                                  context.read<ConnectivityCubit>().retry(),
                            ),
                          Expanded(child: child ?? const SizedBox.shrink()),
                        ],
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
