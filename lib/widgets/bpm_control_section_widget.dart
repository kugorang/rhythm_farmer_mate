import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
// Song 모델 필요 시 (현재는 BPM 값만 받음)

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
    this.slowBpm = 60,
    this.normalBpm = 90,
    this.fastBpm = 120,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final isDisabled = isLoadingSong || isChallengeRunning;

    return Column(
      children: <Widget>[
        // BPM 표시기 원형 컨트롤
        Semantics(
          label: '현재 BPM: $currentManualBpm',
          hint: '탭하여 BPM 측정하기',
          excludeSemantics: true,
          button: true,
          enabled: !isDisabled,
          onTap: isDisabled ? null : onHandleTapForBpm,
          child: GestureDetector(
            onTap: isDisabled ? null : onHandleTapForBpm,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDisabled ? theme.colorScheme.muted : bpmIndicatorColor,
                border: Border.all(
                  color:
                      isDisabled
                          ? theme.colorScheme.border
                          : bpmChangedByTap
                          ? theme.colorScheme.primary
                          : theme.colorScheme.border,
                  width: 2,
                ),
              ),
              child: Center(
                child: AnimatedScale(
                  scale: bpmIndicatorScale,
                  duration: const Duration(milliseconds: 50),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        'BPM',
                        style: theme.textTheme.muted.copyWith(fontSize: 18),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        currentManualBpm.toString(),
                        style: TextStyle(
                          fontSize: 48,
                          color:
                              isDisabled
                                  ? theme.colorScheme.mutedForeground
                                  : bpmTextColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // BPM 빠르기 프리셋 버튼 그룹
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // 느리게 버튼
            Semantics(
              label: '느린 템포로 변경',
              value: '$slowBpm BPM',
              button: true,
              enabled: !isDisabled,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: ShadButton(
                  size: ShadButtonSize.lg,
                  onPressed:
                      isDisabled ? null : () => onChangeBpmToPreset(slowBpm),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      '느리게',
                      style: theme.textTheme.p.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // 중간 버튼
            Semantics(
              label: '보통 템포로 변경',
              value: '$normalBpm BPM',
              button: true,
              enabled: !isDisabled,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: ShadButton(
                  size: ShadButtonSize.lg,
                  onPressed:
                      isDisabled ? null : () => onChangeBpmToPreset(normalBpm),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      '보통',
                      style: theme.textTheme.p.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // 빠르게 버튼
            Semantics(
              label: '빠른 템포로 변경',
              value: '$fastBpm BPM',
              button: true,
              enabled: !isDisabled,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: ShadButton(
                  size: ShadButtonSize.lg,
                  onPressed:
                      isDisabled ? null : () => onChangeBpmToPreset(fastBpm),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      '빠르게',
                      style: theme.textTheme.p.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // BPM 미세 조절 버튼
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // 감소 버튼
            Semantics(
              label: 'BPM 감소',
              value: '1 단위로 감소',
              button: true,
              enabled: !isDisabled,
              child: Listener(
                onPointerDown:
                    isDisabled
                        ? null
                        : (event) {
                          onStartBpmAdjustTimer?.call(0);
                        },
                onPointerUp:
                    isDisabled ? null : (_) => onStopBpmAdjustTimer?.call(),
                onPointerCancel:
                    isDisabled ? null : (_) => onStopBpmAdjustTimer?.call(),
                child: ShadButton(
                  size: ShadButtonSize.lg,
                  onPressed: isDisabled ? null : () => onChangeBpm?.call(-1),
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(Icons.remove, size: 24),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 24),

            // 증가 버튼
            Semantics(
              label: 'BPM 증가',
              value: '1 단위로 증가',
              button: true,
              enabled: !isDisabled,
              child: Listener(
                onPointerDown:
                    isDisabled
                        ? null
                        : (event) {
                          onStartBpmAdjustTimer?.call(0);
                        },
                onPointerUp:
                    isDisabled ? null : (_) => onStopBpmAdjustTimer?.call(),
                onPointerCancel:
                    isDisabled ? null : (_) => onStopBpmAdjustTimer?.call(),
                child: ShadButton(
                  size: ShadButtonSize.lg,
                  onPressed: isDisabled ? null : () => onChangeBpm?.call(1),
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(Icons.add, size: 24),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
