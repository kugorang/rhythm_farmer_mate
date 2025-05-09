import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class MetronomeSettingsDialogWidget extends StatelessWidget {
  final bool isMetronomeSoundEnabled;
  final Function(bool) onMetronomeSoundToggled;

  const MetronomeSettingsDialogWidget({
    Key? key,
    required this.isMetronomeSoundEnabled,
    required this.onMetronomeSoundToggled,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return AlertDialog(
      title: const Text('메트로놈 설정'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
            title: Text('메트로놈 소리', style: theme.textTheme.p),
            subtitle: Text('BPM 표시할 때 소리 출력', style: theme.textTheme.small),
            value: isMetronomeSoundEnabled,
            onChanged: onMetronomeSoundToggled,
            activeColor: theme.colorScheme.primary,
          ),
          const SizedBox(height: 8),
          Text(
            '메트로놈 소리를 켜면 BPM에 맞춰 메트로놈 소리가 함께 재생됩니다.',
            style: theme.textTheme.muted,
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('닫기'),
        ),
      ],
    );
  }
}
