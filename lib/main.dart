import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/splash/presentation/screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeController.instance.load();
  runApp(const BizpaddiApp());
}

class BizpaddiApp extends StatelessWidget {
  const BizpaddiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'Bizpaddi',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeController.instance.themeMode,
          themeAnimationDuration: const Duration(milliseconds: 300),
          themeAnimationCurve: Curves.easeOut,
          // Status / nav bar icons follow the active theme on every screen
          // (the app has no AppBars to do this for us).
          builder: (context, child) {
            final dark = Theme.of(context).brightness == Brightness.dark;
            // Respect the user's font size, but cap it so fixed-size UI (OTP
            // boxes, nav bar, chips) never breaks at very large settings.
            final media = MediaQuery.of(context);
            child = MediaQuery(
              data: media.copyWith(textScaler: media.textScaler.clamp(minScaleFactor: 0.85, maxScaleFactor: 1.3)),
              child: child!,
            );
            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark).copyWith(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: Colors.transparent,
                systemNavigationBarIconBrightness: dark ? Brightness.light : Brightness.dark,
              ),
              child: child,
            );
          },
          home: const SplashScreen(startWithGreen: true),
        );
      },
    );
  }
}
