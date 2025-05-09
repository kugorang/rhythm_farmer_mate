import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
// 올바른 경로로 수정 필요 (프로젝트 이름이 rhythm_farmer_mate라고 가정)
import 'package:rhythm_farmer_mate/screens/splash_screen.dart';
import 'package:rhythm_farmer_mate/screens/my_home_page.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appTextTheme = ShadTextTheme(
      h1: const TextStyle(fontSize: 60 * 1.05, fontWeight: FontWeight.bold),
      h2: const TextStyle(fontSize: 30 * 1.1, fontWeight: FontWeight.bold),
      h4: const TextStyle(fontSize: 18 * 1.1, fontWeight: FontWeight.w600),
      p: const TextStyle(fontSize: 15 * 1.15),
      small: const TextStyle(fontSize: 12 * 1.1),
      large: const TextStyle(fontSize: 18 * 1.1),
    );
    return ShadApp.material(
      title: '리듬농부 메이트',
      theme: ShadThemeData(
        brightness: Brightness.light,
        // 이전 논의에서 최종적으로 ShadZincColorScheme 사용하기로 함
        colorScheme: const ShadZincColorScheme.light(),
        radius: BorderRadius.circular(6.0),
        textTheme: appTextTheme,
      ),
      darkTheme: ShadThemeData(
        brightness: Brightness.dark,
        colorScheme: const ShadZincColorScheme.dark(),
        radius: BorderRadius.circular(6.0),
        textTheme: appTextTheme,
      ),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      builder: (context, child) => ShadToaster(child: child!),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/home': (context) => const MyHomePage(),
      },
    );
  }
}
