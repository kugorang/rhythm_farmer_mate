import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class TimerDisplayWidget extends StatelessWidget {
  final bool isLoadingSong;
  final String timerText;
  final BorderRadiusGeometry borderRadius;

  const TimerDisplayWidget({
    super.key,
    required this.isLoadingSong,
    required this.timerText,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isLoadingSong ? theme.colorScheme.muted : theme.colorScheme.card,
        borderRadius: borderRadius,
        border: Border.all(color: theme.colorScheme.border),
      ),
      child: Center(
        child:
            isLoadingSong
                ? Text(
                  "노래 로딩 중...",
                  style: theme.textTheme.h4.copyWith(
                    color: theme.colorScheme.mutedForeground,
                  ),
                )
                : Text(
                  timerText,
                  style: theme.textTheme.h1.copyWith(
                    fontFamily: 'monospace',
                    color: theme.colorScheme.foreground,
                  ),
                ),
      ),
    );
  }
}
