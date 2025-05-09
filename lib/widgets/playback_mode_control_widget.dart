import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../screens/my_home_page.dart' show PlayMode;

class PlaybackModeControlWidget extends StatelessWidget {
  final PlayMode currentPlayMode;
  final Function(PlayMode) onPlayModeChanged;
  final bool isDisabled;

  const PlaybackModeControlWidget({
    super.key,
    required this.currentPlayMode,
    required this.onPlayModeChanged,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    // 재생 모드에 따른 아이콘과 텍스트 결정
    IconData getModeIcon(PlayMode mode) {
      switch (mode) {
        case PlayMode.normal:
          return Icons.play_arrow;
        case PlayMode.repeat:
          return Icons.repeat_one;
        case PlayMode.allSongs:
          return Icons.repeat;
        case PlayMode.shuffle:
          return Icons.shuffle;
      }
    }

    String getModeText(PlayMode mode) {
      switch (mode) {
        case PlayMode.normal:
          return '일반 재생';
        case PlayMode.repeat:
          return '한 곡 반복';
        case PlayMode.allSongs:
          return '전체 재생';
        case PlayMode.shuffle:
          return '랜덤 재생';
      }
    }

    // 현재 선택된 모드의 아이콘과 텍스트
    final currentModeIcon = getModeIcon(currentPlayMode);
    final currentModeText = getModeText(currentPlayMode);

    return Card(
      color: theme.colorScheme.card,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 현재 재생 모드 표시
                Row(
                  children: [
                    Icon(
                      currentModeIcon,
                      color:
                          isDisabled
                              ? theme.colorScheme.mutedForeground
                              : theme.colorScheme.primary,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '재생 모드: $currentModeText',
                      style: theme.textTheme.p.copyWith(
                        color:
                            isDisabled
                                ? theme.colorScheme.mutedForeground
                                : theme.colorScheme.foreground,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                // 모드 변경 버튼들
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final mode in PlayMode.values)
                      Padding(
                        padding: const EdgeInsets.only(left: 2),
                        child: IconButton(
                          icon: Icon(
                            getModeIcon(mode),
                            size: 20,
                            color:
                                currentPlayMode == mode
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.mutedForeground,
                          ),
                          onPressed:
                              isDisabled ? null : () => onPlayModeChanged(mode),
                          tooltip: getModeText(mode),
                          style: IconButton.styleFrom(
                            backgroundColor:
                                currentPlayMode == mode
                                    ? theme.colorScheme.primary.withOpacity(0.1)
                                    : Colors.transparent,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
