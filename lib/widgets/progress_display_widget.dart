import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import './pomodoro_control_button_widget.dart' show PomodoroState;

class ProgressDisplayWidget extends StatelessWidget {
  final bool isLoadingSong;
  final PomodoroState currentPomodoroState;
  final double progressPercent;

  const ProgressDisplayWidget({
    super.key,
    required this.isLoadingSong,
    required this.currentPomodoroState,
    required this.progressPercent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    bool isActive = currentPomodoroState != PomodoroState.stopped;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isLoadingSong)
          isActive
              ? LinearProgressIndicator(
                value: progressPercent,
                minHeight: 12,
                borderRadius: BorderRadius.circular(6),
                backgroundColor: theme.colorScheme.muted.withOpacity(0.3),
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary,
                ),
              )
              : Text(
                _getHelperText(),
                style: theme.textTheme.p.copyWith(
                  color: theme.colorScheme.mutedForeground,
                ),
                textAlign: TextAlign.center,
              ),
        if (isLoadingSong)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: Text('노래를 불러오는 중입니다...', textAlign: TextAlign.center),
          ),
      ],
    );
  }

  String _getHelperText() {
    switch (currentPomodoroState) {
      case PomodoroState.stopped:
        return '\'농사 시작\' 버튼을 눌러 작업을 시작하세요.';
      case PomodoroState.work:
        return '농사 진행 중! 집중하세요!';
      case PomodoroState.shortBreak:
        return '휴식 시간입니다. 잠시 쉬세요.';
      default:
        return '';
    }
  }
}
