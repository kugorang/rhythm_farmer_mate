import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class MetronomeSettingsDialogWidget extends StatelessWidget {
  final bool initialMetronomeSoundEnabled;
  final Function(bool) onMetronomeSoundChanged;

  const MetronomeSettingsDialogWidget({
    super.key,
    required this.initialMetronomeSoundEnabled,
    required this.onMetronomeSoundChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    bool isMetronomeSoundEnabled = initialMetronomeSoundEnabled;

    return StatefulBuilder(
      builder: (context, setDialogState) {
        return ShadDialog(
          title: const Text('메트로놈 설정'),
          actions: <Widget>[
            ShadButton.ghost(
              child: const Text('닫기'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text('메트로놈 소리 켜기', style: theme.textTheme.p),
                ShadSwitch(
                  value: isMetronomeSoundEnabled,
                  onChanged: (bool value) {
                    setDialogState(() {
                      isMetronomeSoundEnabled = value;
                    });
                    onMetronomeSoundChanged(value);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
