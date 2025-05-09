import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class ProgressDisplayWidget extends StatelessWidget {
  final bool isLoadingSong;
  final bool isChallengeRunning;
  final double progressPercent;

  const ProgressDisplayWidget({
    super.key,
    required this.isLoadingSong,
    required this.isChallengeRunning,
    required this.progressPercent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Column(
      children: [
        ShadProgress(
          value: isLoadingSong ? 0 : progressPercent * 100,
          minHeight: 12,
          color: theme.colorScheme.primary,
          backgroundColor: theme.colorScheme.muted,
        ),
        const SizedBox(height: 12),
        Visibility(
          visible:
              !isLoadingSong && (isChallengeRunning || progressPercent > 0),
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
          child: Center(
            child: Text(
              '진행도: ${(progressPercent * 100).toStringAsFixed(0)}%',
              style: theme.textTheme.small.copyWith(
                color: theme.colorScheme.mutedForeground,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
