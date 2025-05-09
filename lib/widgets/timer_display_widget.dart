import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class TimerDisplayWidget extends StatelessWidget {
  final bool isLoadingSong;
  final String timerText;
  final BorderRadius borderRadius;

  const TimerDisplayWidget({
    super.key,
    required this.isLoadingSong,
    required this.timerText,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    // 타이머 시간 문자열 분석 및 접근성 텍스트 생성
    String accessibilityText = '타이머: $timerText';
    if (timerText.contains(':')) {
      final parts = timerText.split(':');
      if (parts.length == 2) {
        final minutes = int.tryParse(parts[0]) ?? 0;
        final seconds = int.tryParse(parts[1]) ?? 0;
        accessibilityText = '타이머: $minutes분 $seconds초';
      }
    }

    return Semantics(
      label: accessibilityText,
      excludeSemantics: true,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 20.0),
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child:
            isLoadingSong
                ? const ShadSkeleton(
                  width: double.infinity,
                  height: 48,
                  className: 'my-2',
                )
                : Text(
                  timerText,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.h1.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.foreground,
                    letterSpacing: 1.5,
                  ),
                ),
      ),
    );
  }
}
