import 'dart:async';
import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../models/song.dart';
import '../services/audio_service.dart';

class ChallengeService {
  // 챌린지 시작
  static Future<Map<String, dynamic>> startChallenge({
    required Song selectedSong,
    required bool isYoutubeMode,
    required YoutubePlayerController? youtubeController,
    required AudioService audioService,
    required double currentPlaybackSpeed,
    required Duration youtubeDuration,
    required BuildContext context,
  }) async {
    Duration challengeTotalDuration;

    if (isYoutubeMode) {
      if (youtubeController == null || youtubeDuration.inSeconds == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('YouTube 영상 정보를 가져오는 중입니다.')),
        );
        return {'success': false};
      }
      challengeTotalDuration = youtubeDuration;
      await youtubeController.setPlaybackRate(
        currentPlaybackSpeed,
      ); // 챌린지 시작 시 현재 설정된 속도 적용
      await youtubeController.playVideo();

      return {'success': true, 'duration': challengeTotalDuration};
    } else {
      if (audioService.duration == null ||
          audioService.duration!.inSeconds == 0) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('음악 정보를 가져오는 중입니다.')));
        return {'success': false};
      }

      audioService.setSpeed(currentPlaybackSpeed);
      challengeTotalDuration = Duration(
        seconds:
            (audioService.duration!.inSeconds / currentPlaybackSpeed).round(),
      );
      audioService.play();

      return {'success': true, 'duration': challengeTotalDuration};
    }
  }

  // 챌린지 종료
  static Future<void> stopChallenge({
    required Song selectedSong,
    required bool completed,
    required bool stopAudioManually,
    required YoutubePlayerController? youtubeController,
    required AudioService audioService,
    required BuildContext? context,
  }) async {
    if (stopAudioManually) {
      if (selectedSong.youtubeVideoId != null && youtubeController != null) {
        await youtubeController.pauseVideo();
      } else {
        audioService.pause();
      }
    }

    if (selectedSong.filePath != null) {
      audioService.stopBpmTicker();
    }

    if (completed && context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('작업 완료! 오늘도 수고 많으셨습니다! 🎉'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // 진행도 계산
  static Future<double> calculateProgress({
    required bool isChallengeRunning,
    required bool isYoutubeMode,
    required Duration remainingTime,
    required Duration youtubeDuration,
    required YoutubePlayerController? youtubeController,
    required AudioService audioService,
    required double currentPlaybackSpeed,
  }) async {
    double newProgress = 0.0;

    if (isChallengeRunning) {
      Duration totalDuration;
      Duration elapsedTime;

      if (isYoutubeMode) {
        totalDuration = youtubeDuration;
      } else {
        if (audioService.duration != null &&
            audioService.duration!.inSeconds > 0 &&
            currentPlaybackSpeed > 0) {
          totalDuration = Duration(
            seconds:
                (audioService.duration!.inSeconds / currentPlaybackSpeed)
                    .round(),
          );
        } else {
          totalDuration = remainingTime; // fallback
        }
      }

      if (totalDuration.inSeconds > 0) {
        elapsedTime = totalDuration - remainingTime;
        newProgress = elapsedTime.inSeconds / totalDuration.inSeconds;
      } else if (remainingTime.inSeconds == 0) {
        newProgress = 1.0; // 전체 시간이 0이고 남은 시간도 0이면 완료로 간주
      }
    } else {
      // 챌린지 실행 중이 아닐 때 (일반 재생 시)
      Duration? currentDuration;
      Duration currentPosition = Duration.zero;

      if (isYoutubeMode) {
        currentDuration = youtubeDuration;
        if (youtubeController != null && currentDuration.inSeconds > 0) {
          try {
            final currentPositionSeconds = await youtubeController.currentTime;
            currentPosition = Duration(
              milliseconds: (currentPositionSeconds * 1000).round(),
            );
          } catch (e) {
            currentPosition = Duration.zero;
          }
        }
      } else {
        currentDuration = audioService.duration;
        if (audioService.position != null) {
          currentPosition = audioService.position!;
        }
      }

      if (currentDuration != null && currentDuration.inSeconds > 0) {
        newProgress = currentPosition.inSeconds / currentDuration.inSeconds;
      }
    }

    newProgress = newProgress.clamp(0.0, 1.0);
    if (newProgress.isNaN) newProgress = 0.0;

    return newProgress;
  }
}
