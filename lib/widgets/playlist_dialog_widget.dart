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
    // 화면 크기에 맞게 높이 조정
    final screenHeight = MediaQuery.of(context).size.height;
    final dialogHeight = screenHeight * 0.6; // 화면의 60% 높이로 제한

    return Material(
      type: MaterialType.transparency,
      child: ShadDialog(
        title: const Text('현재 재생 목록'),
        description: Text('총 ${songList.length}곡'),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: dialogHeight - 150, // 타이틀과 버튼 공간 고려
            maxWidth: double.maxFinite,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  '목록 전체 재생 모드:',
                  style: theme.textTheme.p.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Material 위젯으로 감싸서 DropdownButton 사용
              Material(
                color: Colors.transparent,
                child: DropdownButton<PlayMode>(
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
              ),
              const Divider(height: 20),
              Expanded(
                child:
                    songList.isEmpty
                        ? const Center(child: Text('재생 목록이 비어있습니다.'))
                        : ListView.builder(
                          shrinkWrap: true, // 목록 크기를 내용에 맞게 조정
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
      ),
    );
  }
}
