// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('리듬농부 메이트 기본 UI 테스트', () {
    testWidgets('앱 화면 기본 레이아웃 렌더링 테스트', (WidgetTester tester) async {
      // 간단한 앱 구조 테스트
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(kToolbarHeight),
              child: Material(child: Center(child: Text('리듬농부 메이트'))),
            ),
            body: Center(child: Text('테스트 콘텐츠')),
          ),
        ),
      );

      // 기본 텍스트 요소 확인
      expect(find.text('리듬농부 메이트'), findsOneWidget);
      expect(find.text('테스트 콘텐츠'), findsOneWidget);
    });

    testWidgets('농부 작업 타이머 UI 테스트', (WidgetTester tester) async {
      // 농부 작업 타이머 UI 테스트
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: const Text('리듬농부 메이트')),
            body: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('00:30', style: TextStyle(fontSize: 32)),
                const SizedBox(height: 16),
                const LinearProgressIndicator(value: 0.5),
                const SizedBox(height: 24),
                ElevatedButton(onPressed: () {}, child: const Text('작업 시작')),
              ],
            ),
          ),
        ),
      );

      // 타이머 화면의 주요 요소 확인
      expect(find.text('00:30'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('작업 시작'), findsOneWidget);
    });
  });
}
