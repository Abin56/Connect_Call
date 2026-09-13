import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';

import 'core/constants/zego_constants.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/home/home_screen.dart';
import 'features/splash/splash_screen.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/calling_provider.dart';
import 'providers/presence_provider.dart';
import 'providers/theme_provider.dart';
import 'services/permissions/notification_permission_flow.dart';

final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (ZegoConstants.isConfigured) {
    ZegoUIKitPrebuiltCallInvitationService().setNavigatorKey(navigatorKey);
    ZegoUIKitPrebuiltCallInvitationService().useSystemCallingUI([
      ZegoUIKitSignalingPlugin(),
    ]);
  }

  runApp(const ProviderScope(child: ConnectCallApp()));
}

class ConnectCallApp extends ConsumerWidget {
  const ConnectCallApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<User?>>(authStateProvider, (previous, next) {
      final user = next.value;
      if (user != null) {
        ref
            .read(callingServiceProvider)
            .init(
              userId: user.uid,
              userName: (user.displayName?.isNotEmpty ?? false)
                  ? user.displayName!
                  : (user.email?.split('@').first ?? user.uid),
            )
            .then((_) {
              // Ask for notification permission now that calling is live --
              // not during splash/login/registration, where it wouldn't
              // matter yet.
              final ctx = navigatorKey.currentContext;
              if (ctx != null && ctx.mounted) {
                const NotificationPermissionFlow().maybeRequest(ctx);
              }
            });
        ref.read(presenceServiceProvider).start(user.uid);
      } else if (previous?.value != null) {
        ref.read(callingServiceProvider).uninit();
        ref.read(presenceServiceProvider).stop();
      }
    });

    final themeMode = ref.watch(themeModeProvider).value ?? ThemeMode.system;

    return MaterialApp(
      title: 'ConnectCall',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash: (_) => const SplashScreen(),
        AppRoutes.login: (_) => const LoginScreen(),
        AppRoutes.register: (_) => const RegisterScreen(),
        AppRoutes.home: (_) => const HomeScreen(),
      },
    );
  }
}
