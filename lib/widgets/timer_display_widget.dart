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
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color:
              isLoadingSong
                  ? theme.colorScheme.muted.withOpacity(0.5)
                  : theme.colorScheme.secondary,
          borderRadius: borderRadius,
          border: Border.all(
            color:
                isLoadingSong
                    ? theme.colorScheme.border.withOpacity(0.5)
                    : theme.colorScheme.secondaryForeground.withOpacity(0.2),
          ),
        ),
        child: Center(
          child: Text(
            timerText,
            style: theme.textTheme.h1.copyWith(
              color:
                  isLoadingSong
                      ? theme.colorScheme.mutedForeground
                      : theme.colorScheme.secondaryForeground,
              fontSize: 60,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
            ),
          ),
        ),
      ),
    );
  }
}
