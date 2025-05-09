import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

enum PomodoroState {
  work,
  shortBreak,
  stopped, // 초기 또는 정지 상태
}

class PomodoroControlButtonWidget extends StatelessWidget {
  final bool isLoadingSong; // 노래 로딩 중에는 버튼 비활성화
  final PomodoroState currentPomodoroState;
  final VoidCallback onPressed;
  final int cycleCount; // 포모도로 사이클 횟수

  const PomodoroControlButtonWidget({
    super.key,
    required this.isLoadingSong,
    required this.currentPomodoroState,
    required this.onPressed,
    required this.cycleCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    String buttonText;
    Color? buttonColor; // 버튼 색상 (옵션)
    Color? textColor; // 텍스트 색상 (옵션)

    switch (currentPomodoroState) {
      case PomodoroState.stopped:
        buttonText = '농사 시작'; // 25분 작업 시작
        buttonColor = theme.colorScheme.primary;
        textColor = theme.colorScheme.primaryForeground;
        break;
      case PomodoroState.work:
        buttonText = '휴식 시작'; // 5분 휴식 시작
        buttonColor = theme.colorScheme.secondary; // 예시: 휴식은 다른 색상
        textColor = theme.colorScheme.secondaryForeground;
        break;
      case PomodoroState.shortBreak:
        buttonText = '다음 농사 시작'; // 다시 25분 작업 시작
        buttonColor = theme.colorScheme.primary;
        textColor = theme.colorScheme.primaryForeground;
        break;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '완료한 농사: $cycleCount회',
          style: theme.textTheme.p.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ShadButton(
          size: ShadButtonSize.lg,
          width: double.infinity,
          onPressed: isLoadingSong ? null : onPressed,
          backgroundColor:
              buttonColor, // ShadButton에 backgroundColor 직접 지정 가능하면 사용
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 20.0,
              horizontal: 16.0,
            ),
            child: Text(
              isLoadingSong ? '노래 준비 중...' : buttonText,
              style: theme.textTheme.large.copyWith(
                color:
                    textColor ??
                    (buttonColor != null
                        ? theme.colorScheme.foreground
                        : theme.colorScheme.primaryForeground),
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}
