import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
// Song 모델 필요 시 (현재는 BPM 값만 받음)

class SpeedControlSectionWidget extends StatelessWidget {
  final bool isLoadingSong;
  final bool isPomodoroActive;
  // final int currentManualBpm;
  // final bool beatHighlighter;
  // final bool bpmChangedByTap;
  // final double bpmIndicatorScale;
  // final Color bpmIndicatorColor;
  // final Color bpmTextColor;
  // final BorderRadiusGeometry defaultBorderRadius;
  // final List<DateTime> tapTimestamps;

  final Function(int) onChangeSpeedPreset;
  final Function(int) onChangeSpeed;
  final Function(int) onStartSpeedAdjustTimer;
  final Function() onStopSpeedAdjustTimer;
  // final Function() onHandleTapForBpm;

  // 프리셋 값들은 이제 속도 배율을 나타내는 구분자로 사용 (예: 0.5x, 1.0x, 1.5x)
  final int speedPresetSlow;
  final int speedPresetNormal;
  final int speedPresetFast;

  const SpeedControlSectionWidget({
    super.key,
    required this.isLoadingSong,
    required this.isPomodoroActive,
    // required this.currentManualBpm,
    // required this.beatHighlighter,
    // required this.bpmChangedByTap,
    // required this.bpmIndicatorScale,
    // required this.bpmIndicatorColor,
    // required this.bpmTextColor,
    // required this.defaultBorderRadius,
    // required this.tapTimestamps,
    required this.onChangeSpeedPreset,
    required this.onChangeSpeed,
    required this.onStartSpeedAdjustTimer,
    required this.onStopSpeedAdjustTimer,
    // required this.onHandleTapForBpm,
    this.speedPresetSlow = 0,
    this.speedPresetNormal = 1,
    this.speedPresetFast = 2,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final isDisabled = isLoadingSong || isPomodoroActive;

    return Column(
      children: <Widget>[
        // BPM 표시기 원형 컨트롤
        // const SizedBox(height: 24),
        Text(
          '재생 속도 조절',
          style: theme.textTheme.h4.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),

        // BPM 빠르기 프리셋 버튼 그룹
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // 느리게 버튼
            Semantics(
              label: '느리게 (0.5배)',
              button: true,
              enabled: !isDisabled,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: ShadButton(
                  size: ShadButtonSize.lg,
                  onPressed:
                      isDisabled
                          ? null
                          : () => onChangeSpeedPreset(speedPresetSlow),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      '0.5배',
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
              label: '보통 (1.0배)',
              button: true,
              enabled: !isDisabled,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: ShadButton(
                  size: ShadButtonSize.lg,
                  onPressed:
                      isDisabled
                          ? null
                          : () => onChangeSpeedPreset(speedPresetNormal),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      '1.0배',
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
              label: '빠르게 (1.5배)',
              button: true,
              enabled: !isDisabled,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: ShadButton(
                  size: ShadButtonSize.lg,
                  onPressed:
                      isDisabled
                          ? null
                          : () => onChangeSpeedPreset(speedPresetFast),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      '1.5배',
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
              label: '속도 감소 (-0.1배)',
              button: true,
              enabled: !isDisabled,
              child: Listener(
                onPointerDown:
                    isDisabled
                        ? null
                        : (event) => onStartSpeedAdjustTimer?.call(-1),
                onPointerUp:
                    isDisabled ? null : (_) => onStopSpeedAdjustTimer?.call(),
                onPointerCancel:
                    isDisabled ? null : (_) => onStopSpeedAdjustTimer?.call(),
                child: ShadButton(
                  size: ShadButtonSize.lg,
                  onPressed: isDisabled ? null : () => onChangeSpeed(-1),
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
              label: '속도 증가 (+0.1배)',
              button: true,
              enabled: !isDisabled,
              child: Listener(
                onPointerDown:
                    isDisabled
                        ? null
                        : (event) => onStartSpeedAdjustTimer?.call(1),
                onPointerUp:
                    isDisabled ? null : (_) => onStopSpeedAdjustTimer?.call(),
                onPointerCancel:
                    isDisabled ? null : (_) => onStopSpeedAdjustTimer?.call(),
                child: ShadButton(
                  size: ShadButtonSize.lg,
                  onPressed: isDisabled ? null : () => onChangeSpeed(1),
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
