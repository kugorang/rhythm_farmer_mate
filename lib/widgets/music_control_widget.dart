import 'package:flutter/material.dart';
// AudioPlayer 상태 접근 위해 필요할 수 있음
import 'package:shadcn_ui/shadcn_ui.dart';
import '../models/song.dart'; // Song 모델
import '../screens/my_home_page.dart'
    show PomodoroState; // PomodoroState 접근을 위해

class MusicControlWidget extends StatelessWidget {
  final bool isLoadingSong;
  final PomodoroState currentPomodoroState; // 포모도로 상태를 직접 받음
  final bool isPlaying;
  final Song selectedSong;
  final Duration? audioDuration;
  final double currentPlaybackSpeed;
  final int currentManualBpm;
  final BorderRadiusGeometry defaultBorderRadius;

  final VoidCallback onPlayPause;
  final VoidCallback onStop;

  const MusicControlWidget({
    super.key,
    required this.isLoadingSong,
    required this.currentPomodoroState, // 추가
    required this.isPlaying,
    required this.selectedSong,
    this.audioDuration,
    required this.currentPlaybackSpeed,
    required this.currentManualBpm,
    required this.defaultBorderRadius,
    required this.onPlayPause,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    // 음악 컨트롤은 포모도로가 '중단' 상태일 때만 활성화, 또는 로딩 중이 아닐 때
    final bool canControlMusicIndependently =
        currentPomodoroState == PomodoroState.stopped &&
        !isLoadingSong &&
        (audioDuration != null || selectedSong.youtubeVideoId != null);

    return Visibility(
      visible: canControlMusicIndependently,
      maintainSize: false,
      maintainAnimation: false,
      maintainState: false,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.card,
          borderRadius: defaultBorderRadius,
          border: Border.all(color: theme.colorScheme.border),
        ),
        child: Column(
          children: [
            Text(
              '현재 재생 중: ${selectedSong.title}',
              textAlign: TextAlign.center,
              style: theme.textTheme.p.copyWith(fontWeight: FontWeight.bold),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                currentPlaybackSpeed == 1.0
                    ? "(원곡 빠르기, BPM: ${selectedSong.bpm > 0 ? selectedSong.bpm : 'N/A'})"
                    : '재생 빠르기: ${currentPlaybackSpeed.toStringAsFixed(1)}배 (원곡 BPM: ${selectedSong.bpm > 0 ? selectedSong.bpm : 'N/A'} -> 현재 BPM: $currentManualBpm)',
                style: theme.textTheme.small.copyWith(
                  color: theme.colorScheme.mutedForeground,
                ),
                textAlign: TextAlign.center, // 중앙 정렬 추가
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ShadButton.ghost(
                  icon: Padding(
                    padding: const EdgeInsets.only(right: 4.0),
                    child: Icon(
                      isPlaying
                          ? Icons.pause_circle_outline
                          : Icons.play_circle_outline,
                      size: 28, // 아이콘 크기 약간 증가
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  onPressed: onPlayPause,
                  child: Text(
                    isPlaying ? '일시정지' : '재생',
                    style: theme.textTheme.p.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                ShadButton.ghost(
                  icon: Padding(
                    padding: const EdgeInsets.only(right: 4.0),
                    child: Icon(
                      Icons.stop_circle,
                      size: 28, // 아이콘 크기 약간 증가
                      color: theme.colorScheme.destructive,
                    ),
                  ),
                  onPressed: onStop,
                  child: Text(
                    '정지',
                    style: theme.textTheme.p.copyWith(
                      color: theme.colorScheme.destructive,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
