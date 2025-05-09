import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../models/song.dart';
import '../screens/my_home_page.dart' show PlayMode;

class PlaylistDialogWidget extends StatelessWidget {
  final List<Song> songList;
  final Song currentSelectedSong;
  final Function(Song) onSongSelected;
  final PlayMode currentPlayMode;
  final Function(PlayMode) onOverallPlayModeChanged;

  const PlaylistDialogWidget({
    Key? key,
    required this.songList,
    required this.currentSelectedSong,
    required this.onSongSelected,
    required this.currentPlayMode,
    required this.onOverallPlayModeChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return ShadDialog(
      title: const Text('현재 재생 목록'),
      description: Text('총 ${songList.length}곡'),
      child: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.4,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                '목록 전체 재생 모드:',
                style: theme.textTheme.p.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            DropdownButton<PlayMode>(
              value: currentPlayMode,
              isExpanded: true,
              onChanged: (value) {
                if (value != null) {
                  onOverallPlayModeChanged(value);
                }
              },
              items:
                  PlayMode.values.map((PlayMode mode) {
                    String modeText = '';
                    switch (mode) {
                      case PlayMode.normal:
                        modeText = '선택곡만 재생 (이후 정지)';
                        break;
                      case PlayMode.repeat:
                        modeText = '한 곡 반복 재생';
                        break;
                      case PlayMode.allSongs:
                        modeText = '목록 전체 순차 재생';
                        break;
                      case PlayMode.shuffle:
                        modeText = '목록 전체 랜덤 재생';
                        break;
                    }
                    return DropdownMenuItem<PlayMode>(
                      value: mode,
                      child: Text(modeText, style: theme.textTheme.p),
                    );
                  }).toList(),
            ),
            const Divider(height: 20),
            Expanded(
              child:
                  songList.isEmpty
                      ? const Center(child: Text('재생 목록이 비어있습니다.'))
                      : ListView.builder(
                        shrinkWrap: true,
                        itemCount: songList.length,
                        itemBuilder: (context, index) {
                          final song = songList[index];
                          final bool isCurrentlyPlaying =
                              song.title == currentSelectedSong.title;
                          return ListTile(
                            leading:
                                isCurrentlyPlaying
                                    ? Icon(
                                      Icons.play_arrow_rounded,
                                      color: theme.colorScheme.primary,
                                    )
                                    : const SizedBox(width: 24),
                            title: Text(
                              song.title,
                              style: theme.textTheme.p.copyWith(
                                fontWeight:
                                    isCurrentlyPlaying
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                              ),
                            ),
                            subtitle: Text(
                              'BPM: ${song.bpm}',
                              style: theme.textTheme.small,
                            ),
                            selected: isCurrentlyPlaying,
                            selectedTileColor: theme.colorScheme.primary
                                .withOpacity(0.1),
                            onTap: () => onSongSelected(song),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
      actions: [
        ShadButton(
          child: const Text('닫기'),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
