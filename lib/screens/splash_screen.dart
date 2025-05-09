// lib/screens/splash_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
// 라우트 이름을 사용하기 위해 main.dart를 직접 참조하지 않고,
// 라우트 명을 문자열로 직접 사용하거나, 별도의 라우트 상수 파일 생성 고려.

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  // 라우트 이름을 상수로 관리하면 더 좋음
  // static const String routeName = '/';

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home'); // 홈 라우트 이름
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 150,
              height: 150,
            ), // 로고 경로 확인 필요
            const SizedBox(height: 20),
            Text(
              '리듬농부 메이트',
              style: theme.textTheme.h2.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 10),
            CircularProgressIndicator(
              color: theme.colorScheme.primary.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }
}
