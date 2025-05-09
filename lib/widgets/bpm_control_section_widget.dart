import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../models/song.dart'; // Song 모델 필요 시 (현재는 BPM 값만 받음)

class BpmControlSectionWidget extends StatelessWidget {
  final bool isLoadingSong;
  final bool isChallengeRunning;
  final int currentManualBpm;
  final bool beatHighlighter;
  final bool bpmChangedByTap;
  final double bpmIndicatorScale;
  final Color bpmIndicatorColor;
  final Color bpmTextColor;
  final BorderRadiusGeometry defaultBorderRadius;
  final List<DateTime> tapTimestamps;

  final Function(int) onChangeBpmToPreset;
  final Function(int) onChangeBpm;
  final Function(int) onStartBpmAdjustTimer;
  final Function() onStopBpmAdjustTimer;
  final Function() onHandleTapForBpm;

  // 프리셋 BPM 값들
  final int slowBpm;
  final int normalBpm;
  final int fastBpm;

  const BpmControlSectionWidget({
    super.key,
    required this.isLoadingSong,
    required this.isChallengeRunning,
    required this.currentManualBpm,
    required this.beatHighlighter,
    required this.bpmChangedByTap,
    required this.bpmIndicatorScale,
    required this.bpmIndicatorColor,
    required this.bpmTextColor,
    required this.defaultBorderRadius,
    required this.tapTimestamps,
    required this.onChangeBpmToPreset,
    required this.onChangeBpm,
    required this.onStartBpmAdjustTimer,
    required this.onStopBpmAdjustTimer,
    required this.onHandleTapForBpm,
    required this.slowBpm,
    required this.normalBpm,
    required this.fastBpm,
  });

  Widget buildBpmPresetButton(
    BuildContext context,
    String label,
    int presetBpm,
  ) {
    final theme = ShadTheme.of(context);
    final isSelected = currentManualBpm == presetBpm;
    final onPressed =
        !isChallengeRunning && !isLoadingSong
            ? () => onChangeBpmToPreset(presetBpm)
            : null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ShadButton.outline(
        size: ShadButtonSize.sm,
        onPressed: onPressed,
        child: Text(
          label,
          style: theme.textTheme.p.copyWith(
            color:
                onPressed == null
                    ? theme.colorScheme.mutedForeground
                    : (isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.foreground.withOpacity(0.7)),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final canInteractWithSettings = !isChallengeRunning && !isLoadingSong;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            buildBpmPresetButton(context, '느리게', slowBpm),
            buildBpmPresetButton(context, '보통', normalBpm),
            buildBpmPresetButton(context, '빠르게', fastBpm),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap:
                  canInteractWithSettings && currentManualBpm > 30
                      ? () => onChangeBpm(-5)
                      : null,
              onLongPressStart:
                  canInteractWithSettings && currentManualBpm > 30
                      ? (details) => onStartBpmAdjustTimer(-1)
                      : null,
              onLongPressEnd:
                  canInteractWithSettings
                      ? (details) => onStopBpmAdjustTimer()
                      : null,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  Icons.remove_circle_outline,
                  size: 30,
                  color:
                      !(canInteractWithSettings && currentManualBpm > 30)
                          ? theme.colorScheme.mutedForeground
                          : theme.colorScheme.foreground,
                ),
              ),
            ),
            Expanded(
              child: AnimatedContainer(
                duration: Duration(
                  milliseconds: (60000 /
                          (currentManualBpm > 0 ? currentManualBpm : 60) /
                          2)
                      .round()
                      .clamp(50, 300),
                ),
                curve: Curves.elasticOut,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                height: 52,
                transform: Matrix4.identity()..scale(bpmIndicatorScale),
                transformAlignment: Alignment.center,
                decoration: BoxDecoration(
                  color: bpmIndicatorColor,
                  borderRadius: defaultBorderRadius,
                  border: Border.all(color: theme.colorScheme.border),
                ),
                child: Center(
                  child:
                      isLoadingSong
                          ? Text(
                            "--",
                            style: theme.textTheme.p.copyWith(
                              color: theme.colorScheme.mutedForeground,
                            ),
                          )
                          : Text(
                            '현재 박자: $currentManualBpm',
                            style: theme.textTheme.p.copyWith(
                              color: bpmTextColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                ),
              ),
            ),
            GestureDetector(
              onTap:
                  canInteractWithSettings && currentManualBpm < 240
                      ? () => onChangeBpm(5)
                      : null,
              onLongPressStart:
                  canInteractWithSettings && currentManualBpm < 240
                      ? (details) => onStartBpmAdjustTimer(1)
                      : null,
              onLongPressEnd:
                  canInteractWithSettings
                      ? (details) => onStopBpmAdjustTimer()
                      : null,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  Icons.add_circle_outline,
                  size: 30,
                  color:
                      !(canInteractWithSettings && currentManualBpm < 240)
                          ? theme.colorScheme.mutedForeground
                          : theme.colorScheme.foreground,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ShadButton(
            size: ShadButtonSize.lg,
            onPressed: canInteractWithSettings ? onHandleTapForBpm : null,
            child: Text(
              '탭하여 박자 입력 (${tapTimestamps.length}번 탭)',
              style: theme.textTheme.p.copyWith(
                color: theme.colorScheme.primaryForeground,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
