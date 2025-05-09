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
      width: double.infinity,
      onPressed: isLoadingSong ? null : onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
        child: Text(
          isLoadingSong
              ? '노래 준비 중...'
              : (isChallengeRunning ? '작업 중단하기' : '작업 시작하기'),
          style: theme.textTheme.large.copyWith(
            color:
                isChallengeRunning
                    ? theme.colorScheme.destructiveForeground
                    : theme.colorScheme.primaryForeground,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
