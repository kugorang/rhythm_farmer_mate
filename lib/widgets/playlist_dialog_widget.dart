import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../models/song.dart';
import '../screens/my_home_page.dart' show PlayMode;

class PlaylistDialogWidget extends StatelessWidget {
  final List<Song> songList;
  final Song currentSelectedSong;
  final Function(Song) onSongSelected;
  final PlayMode playMode;
  final Function(PlayMode) onPlayModeChanged;

  const PlaylistDialogWidget({
    Key? key,
    required this.songList,
    required this.currentSelectedSong,
    required this.onSongSelected,
    required this.playMode,
    required this.onPlayModeChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('재생 목록'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButton<PlayMode>(
              value: playMode,
              onChanged: (value) {
                if (value != null) {
                  onPlayModeChanged(value);
                }
              },
              items: const [
                DropdownMenuItem(
                  value: PlayMode.normal,
                  child: Text('기본 재생 (한 곡 재생 후 정지)'),
                ),
                DropdownMenuItem(
                  value: PlayMode.repeat,
                  child: Text('한 곡 반복 재생'),
                ),
                DropdownMenuItem(
                  value: PlayMode.allSongs,
                  child: Text('전체 목록 순차 재생'),
                ),
                DropdownMenuItem(value: PlayMode.shuffle, child: Text('랜덤 재생')),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: songList.length,
                itemBuilder: (context, index) {
                  final song = songList[index];
                  return ListTile(
                    title: Text(song.title),
                    subtitle: Text(
                      song.youtubeVideoId != null ? 'YouTube' : 'Assets',
                    ),
                    selected: song.title == currentSelectedSong.title,
                    onTap: () => onSongSelected(song),
                  );
                },
              ),
            ),
          ],
        ),
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
