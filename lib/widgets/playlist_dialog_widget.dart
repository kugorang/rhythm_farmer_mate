import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../models/song.dart';
import '../screens/my_home_page.dart' show PlayMode; // PlayMode enum을 가져오기 위함

class PlaylistDialogWidget extends StatelessWidget {
  final List<Song> songList;
  final Song selectedSong;
  final PlayMode currentPlayMode;
  final Function(PlayMode) onPlayModeChanged;
  final Function(Song) onSongSelected;

  const PlaylistDialogWidget({
    super.key,
    required this.songList,
    required this.selectedSong,
    required this.currentPlayMode,
    required this.onPlayModeChanged,
    required this.onSongSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    PlayMode localPlayMode = currentPlayMode; // 다이얼로그 내에서 상태 변경을 위해

    return StatefulBuilder(
      builder: (context, setDialogState) {
        return ShadDialog(
          title: const Text('재생 목록 & 모드'),
          actions: <Widget>[
            ShadButton.ghost(
              child: const Text('닫기'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('재생 모드 선택', style: theme.textTheme.h4),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    localPlayMode == PlayMode.normal
                        ? ShadButton(
                          onPressed: () {
                            setDialogState(() {
                              localPlayMode = PlayMode.normal;
                            });
                            onPlayModeChanged(PlayMode.normal);
                          },
                          child: const Text('일반 재생'),
                        )
                        : ShadButton.outline(
                          onPressed: () {
                            setDialogState(() {
                              localPlayMode = PlayMode.normal;
                            });
                            onPlayModeChanged(PlayMode.normal);
                          },
                          child: const Text('일반 재생'),
                        ),
                    localPlayMode == PlayMode.repeat
                        ? ShadButton(
                          onPressed: () {
                            setDialogState(() {
                              localPlayMode = PlayMode.repeat;
                            });
                            onPlayModeChanged(PlayMode.repeat);
                          },
                          child: const Text('한 곡 반복'),
                        )
                        : ShadButton.outline(
                          onPressed: () {
                            setDialogState(() {
                              localPlayMode = PlayMode.repeat;
                            });
                            onPlayModeChanged(PlayMode.repeat);
                          },
                          child: const Text('한 곡 반복'),
                        ),
                    localPlayMode == PlayMode.allSongs
                        ? ShadButton(
                          onPressed: () {
                            setDialogState(() {
                              localPlayMode = PlayMode.allSongs;
                            });
                            onPlayModeChanged(PlayMode.allSongs);
                          },
                          child: const Text('전체 재생'),
                        )
                        : ShadButton.outline(
                          onPressed: () {
                            setDialogState(() {
                              localPlayMode = PlayMode.allSongs;
                            });
                            onPlayModeChanged(PlayMode.allSongs);
                          },
                          child: const Text('전체 재생'),
                        ),
                    localPlayMode == PlayMode.shuffle
                        ? ShadButton(
                          onPressed: () {
                            setDialogState(() {
                              localPlayMode = PlayMode.shuffle;
                            });
                            onPlayModeChanged(PlayMode.shuffle);
                          },
                          child: const Text('랜덤 재생'),
                        )
                        : ShadButton.outline(
                          onPressed: () {
                            setDialogState(() {
                              localPlayMode = PlayMode.shuffle;
                            });
                            onPlayModeChanged(PlayMode.shuffle);
                          },
                          child: const Text('랜덤 재생'),
                        ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('노동요 목록', style: theme.textTheme.h4),
                const SizedBox(height: 8),
                Material(
                  type: MaterialType.transparency,
                  child: SizedBox(
                    height: 300,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: songList.length,
                      itemBuilder: (context, index) {
                        final song = songList[index];
                        final isCurrentSong =
                            song.filePath == selectedSong.filePath;
                        return ListTile(
                          title: Text(
                            song.title,
                            style: theme.textTheme.p.copyWith(
                              fontWeight:
                                  isCurrentSong
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                              color:
                                  isCurrentSong
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.foreground,
                            ),
                          ),
                          subtitle: Text(
                            '${song.bpm} BPM',
                            style: theme.textTheme.small,
                          ),
                          onTap: () {
                            Navigator.of(context).pop();
                            onSongSelected(song);
                          },
                          selected: isCurrentSong,
                          selectedTileColor: theme.colorScheme.primary
                              .withOpacity(0.1),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
