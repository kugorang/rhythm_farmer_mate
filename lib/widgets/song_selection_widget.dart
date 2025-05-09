import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../models/song.dart';

class SongSelectionWidget extends StatelessWidget {
  final List<Song> songList;
  final Song selectedSong;
  final bool isLoading;
  final bool isChallengeRunning; // 챌린지 중에는 비활성화 하기 위함
  final Function(Song?) onSongChanged;

  const SongSelectionWidget({
    super.key,
    required this.songList,
    required this.selectedSong,
    required this.isLoading,
    required this.isChallengeRunning,
    required this.onSongChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final canInteract = !isChallengeRunning && !isLoading;

    if (isChallengeRunning || isLoading) {
      // 챌린지 중이거나 로딩 중일 때는 현재 선택된 곡 제목만 표시 (선택 불가)
      return Padding(
        padding: const EdgeInsets.only(bottom: 24.0),
        child: ShadCard(
          title: Text(
            '현재 곡',
            style: theme.textTheme.muted.copyWith(fontSize: 12),
          ),
          description: Text(selectedSong.title, style: theme.textTheme.p),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: ShadSelect<Song>(
        placeholder: Text(
          '노동요를 선택하세요',
          style: theme.textTheme.p.copyWith(
            color: theme.colorScheme.mutedForeground,
          ),
        ),
        options:
            songList
                .map(
                  (song) => ShadOption(
                    value: song,
                    child: Text(song.title, style: theme.textTheme.p),
                  ),
                )
                .toList(),
        selectedOptionBuilder:
            (context, value) => Text(value.title, style: theme.textTheme.p),
        onChanged: canInteract ? onSongChanged : null,
        initialValue: selectedSong,
        enabled: canInteract, // 활성화/비활성화 상태
      ),
    );
  }
}
