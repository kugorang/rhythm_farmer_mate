import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class ChallengeControlButtonWidget extends StatelessWidget {
  final bool isLoadingSong;
  final bool isChallengeRunning;
  final VoidCallback onPressed;

  const ChallengeControlButtonWidget({
    super.key,
    required this.isLoadingSong,
    required this.isChallengeRunning,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return ShadButton(
      size: ShadButtonSize.lg,
      onPressed: isLoadingSong ? null : onPressed,
      child: Text(
        isLoadingSong ? '노래 로딩 중...' : (isChallengeRunning ? '작업 중지' : '작업 시작'),
        style: theme.textTheme.large.copyWith(
          color:
              isChallengeRunning
                  ? theme.colorScheme.destructiveForeground
                  : theme.colorScheme.primaryForeground,
        ),
      ),
      // 챌린지 실행 중일 때 destructive 스타일을 적용하려면 variant나 다른 방식 필요
      // 현재는 Text 색상으로만 구분
    );
  }
}

