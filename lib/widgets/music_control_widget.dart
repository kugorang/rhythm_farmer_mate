import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart'; // AudioPlayer 상태 접근 위해 필요할 수 있음
import 'package:shadcn_ui/shadcn_ui.dart';
import '../models/song.dart'; // Song 모델

class MusicControlWidget extends StatelessWidget {
  final bool isLoadingSong;
  final bool isChallengeRunning; // 챌린지 중에는 독립적 음악 제어 제한 위함
  final bool isPlaying; // 현재 음악 재생 상태
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
    required this.isChallengeRunning,
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
    final canControlMusicIndependently =
        !isChallengeRunning && !isLoadingSong && audioDuration != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            (isLoadingSong ||
                    (isChallengeRunning &&
                        !isPlaying)) // 챌린지 중 음악이 꺼져있을 때도 muted
                ? theme.colorScheme.muted.withOpacity(0.5)
                : theme.colorScheme.card,
        borderRadius: defaultBorderRadius,
        border: Border.all(color: theme.colorScheme.border),
      ),
      child: Column(
        children: [
          Text(
            isLoadingSong ? '로딩 중...' : '현재 재생 중: ${selectedSong.title}',
            textAlign: TextAlign.center,
            style: theme.textTheme.p.copyWith(fontWeight: FontWeight.bold),
          ),
          if (!isLoadingSong && audioDuration != null)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                currentPlaybackSpeed == 1.0
                    ? "(원곡 빠르기, 현재 박자: ${selectedSong.bpm > 0 ? selectedSong.bpm : 'N/A'})"
                    : '재생 빠르기: ${currentPlaybackSpeed.toStringAsFixed(1)}배 (원곡 박자: ${selectedSong.bpm > 0 ? selectedSong.bpm : 'N/A'} -> 현재 박자: $currentManualBpm)',
                style: theme.textTheme.small.copyWith(
                  color: theme.colorScheme.mutedForeground,
                ),
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
                    size: 24,
                    color:
                        canControlMusicIndependently
                            ? theme.colorScheme.primary
                            : theme.colorScheme.mutedForeground,
                  ),
                ),
                onPressed: canControlMusicIndependently ? onPlayPause : null,
                child: Text(
                  isPlaying ? '일시정지' : '재생',
                  style: theme.textTheme.p.copyWith(
                    color:
                        canControlMusicIndependently
                            ? theme.colorScheme.primary
                            : theme.colorScheme.mutedForeground,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              ShadButton.ghost(
                icon: Padding(
                  padding: const EdgeInsets.only(right: 4.0),
                  child: Icon(
                    Icons.stop_circle,
                    size: 24,
                    color:
                        canControlMusicIndependently
                            ? theme.colorScheme.destructive
                            : theme.colorScheme.mutedForeground,
                  ),
                ),
                onPressed: canControlMusicIndependently ? onStop : null,
                child: Text(
                  '정지',
                  style: theme.textTheme.p.copyWith(
                    color:
                        canControlMusicIndependently
                            ? theme.colorScheme.destructive
                            : theme.colorScheme.mutedForeground,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
