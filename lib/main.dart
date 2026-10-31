import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ui/fire_distinguisher_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: IndustrialColors.backgroundDark,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    const ProviderScope(
      child: FireDistinguisherApp(),
    ),
  );
}

/// Root Material 3 application with a dark industrial theme.
class FireDistinguisherApp extends StatelessWidget {
  const FireDistinguisherApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseDarkTheme = ThemeData.dark(useMaterial3: true);

    return MaterialApp(
      title: 'Fire Distinguisher',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: baseDarkTheme.copyWith(
        scaffoldBackgroundColor: IndustrialColors.backgroundDark,
        colorScheme: const ColorScheme.dark(
          primary: IndustrialColors.safetyOrange,
          onPrimary: IndustrialColors.backgroundDark,
          secondary: IndustrialColors.hazardAmber,
          onSecondary: IndustrialColors.backgroundDark,
          surface: IndustrialColors.panelGrey,
          onSurface: IndustrialColors.readoutWhite,
          error: IndustrialColors.fireRed,
        ),
      ),
      home: const FireDistinguisherScreen(),
    );
  }
}
