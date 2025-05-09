import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
// 올바른 경로로 수정 필요 (프로젝트 이름이 rhythm_farmer_mate라고 가정)
import 'package:rhythm_farmer_mate/screens/splash_screen.dart';
import 'package:rhythm_farmer_mate/screens/my_home_page.dart';
import 'package:rhythm_farmer_mate/screens/category_selection_screen.dart';

// 테마 모드 변경을 위한 ValueNotifier
final themeModeNotifier = ValueNotifier(ThemeMode.dark);

// "가요톱텐" 컨셉 색상 스키마 정의
const kGayoTopTenColorSchemeLight = ShadColorScheme(
  primary: Color(0xFF0F64CD), // 강렬한 파란색 (태극기 파랑 참고)
  primaryForeground: Color(0xFFFFFFFF), // 흰색
  secondary: Color(0xFFFFD700), // 금색/노란색 (포인트)
  secondaryForeground: Color(0xFF000000), // 검정색
  destructive: Color(0xFFE53935), // 빨강 (경고/삭제 등)
  destructiveForeground: Color(0xFFFFFFFF),
  card: Color(0xFFFFFFFF),
  cardForeground: Color(0xFF000000),
  popover: Color(0xFFFFFFFF),
  popoverForeground: Color(0xFF000000),
  background: Color(0xFFF0F0F0), // 밝은 회색 배경
  foreground: Color(0xFF000000),
  muted: Color(0xFF9E9E9E), // 회색 계열
  mutedForeground: Color(0xFF616161),
  accent: Color(0xFFFFD700), // 금색/노란색 (다시 강조)
  accentForeground: Color(0xFF000000),
  border: Color(0xFFBDBDBD),
  input: Color(0xFFE0E0E0),
  ring: Color(0xFF0F64CD),
  selection: Color(
    0xFF0F64CD,
  ), // Primary 색상과 동일하게 설정 (ShadOrangeColorScheme 참고)
);

const kGayoTopTenColorSchemeDark = ShadColorScheme(
  primary: Color(0xFF0F64CD), // 강렬한 파란색
  primaryForeground: Color(0xFFFFFFFF),
  secondary: Color(0xFFFFD700), // 금색/노란색
  secondaryForeground: Color(0xFF000000),
  destructive: Color(0xFFD32F2F),
  destructiveForeground: Color(0xFFFFFFFF),
  card: Color(0xFF1E1E1E), // 어두운 카드 배경
  cardForeground: Color(0xFFFFFFFF),
  popover: Color(0xFF2C2C2C),
  popoverForeground: Color(0xFFFFFFFF),
  background: Color(0xFF121212), // 매우 어두운 배경
  foreground: Color(0xFFFFFFFF),
  muted: Color(0xFF616161),
  mutedForeground: Color(0xFF9E9E9E),
  accent: Color(0xFFFFD700),
  accentForeground: Color(0xFF000000),
  border: Color(0xFF424242),
  input: Color(0xFF303030),
  ring: Color(0xFF0F64CD),
  selection: Color(0xFF0F64CD), // Primary 색상과 동일하게 설정
);

// 앱 전체에 적용될 기본 TextTheme 정의 (50대 사용자 친화적으로 크기 조정)
final appTextTheme = ShadTextTheme(
  h1: const TextStyle(
    fontFamily: 'HMFMMUEX',
    fontSize: 50,
    fontWeight: FontWeight.bold,
  ),
  h2: const TextStyle(
    fontFamily: 'HMFMMUEX',
    fontSize: 32,
    fontWeight: FontWeight.bold,
  ),
  h3: const TextStyle(
    fontFamily: 'HMFMMUEX',
    fontSize: 26,
    fontWeight: FontWeight.bold,
  ),
  h4: const TextStyle(
    fontFamily: 'HMFMMUEX',
    fontSize: 22,
    fontWeight: FontWeight.w600,
  ),
  p: const TextStyle(fontFamily: 'HMFMMUEX', fontSize: 18), // 기본 문단 크기 증가
  blockquote: const TextStyle(fontFamily: 'HMFMMUEX', fontSize: 18),
  small: const TextStyle(fontFamily: 'HMFMMUEX', fontSize: 14), // 작은 글씨 크기 증가
  lead: const TextStyle(
    fontFamily: 'HMFMMUEX',
    fontSize: 20,
    fontWeight: FontWeight.w500,
  ),
  large: const TextStyle(
    fontFamily: 'HMFMMUEX',
    fontSize: 24,
    fontWeight: FontWeight.w600,
  ), // 큰 글씨 크기 증가
  muted: const TextStyle(
    fontFamily: 'HMFMMUEX',
    fontSize: 16,
  ), // 음소거/보조 텍스트 크기 증가
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, currentMode, child) {
        final currentColorScheme =
            currentMode == ThemeMode.dark
                ? kGayoTopTenColorSchemeDark
                : kGayoTopTenColorSchemeLight;

        // 현재 테마 모드에 따라 동적으로 TextTheme의 색상 업데이트 (폰트 크기는 appTextTheme 따름)
        final dynamicAppTextTheme = ShadTextTheme(
          h1: appTextTheme.h1.copyWith(color: currentColorScheme.primary),
          h2: appTextTheme.h2.copyWith(color: currentColorScheme.foreground),
          h3: appTextTheme.h3.copyWith(color: currentColorScheme.foreground),
          h4: appTextTheme.h4.copyWith(color: currentColorScheme.foreground),
          p: appTextTheme.p.copyWith(color: currentColorScheme.foreground),
          blockquote: appTextTheme.blockquote.copyWith(
            color: currentColorScheme.foreground,
          ),
          small: appTextTheme.small.copyWith(
            color: currentColorScheme.mutedForeground,
          ),
          lead: appTextTheme.lead.copyWith(
            color: currentColorScheme.foreground,
          ),
          large: appTextTheme.large.copyWith(
            color: currentColorScheme.foreground,
          ),
          muted: appTextTheme.muted.copyWith(
            color: currentColorScheme.mutedForeground,
          ),
        );

        // ShadApp.material 생성자 사용 및 라우팅 복원
        return ShadApp.material(
          title: '리듬농부 메이트',
          themeMode: currentMode,
          theme: ShadThemeData(
            colorScheme: kGayoTopTenColorSchemeLight,
            brightness: Brightness.light,
            textTheme: dynamicAppTextTheme,
            radius: const BorderRadius.all(Radius.circular(6)),
          ),
          darkTheme: ShadThemeData(
            colorScheme: kGayoTopTenColorSchemeDark,
            brightness: Brightness.dark,
            textTheme: dynamicAppTextTheme,
            radius: const BorderRadius.all(Radius.circular(6)),
          ),
          debugShowCheckedModeBanner: false,
          builder: (context, child) => ShadToaster(child: child!),
          initialRoute: '/', // 초기 라우트를 다시 SplashScreen으로 변경
          routes: {
            '/': (context) => const SplashScreen(),
            '/category-selection': (context) => const CategorySelectionScreen(),
            // MyHomePage는 CategorySelectionScreen에서 context.push/Navigator.push로 호출됨
          },
        );
      },
    );
  }
}
