import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../models/song.dart';

// 오디오 서비스 상태 이벤트 콜백을 위한 타입 정의
typedef AudioPlayerStateCallback = void Function(bool isPlaying);
typedef AudioDurationCallback = void Function(Duration? duration);
typedef AudioErrorCallback = void Function(String errorMessage);
typedef MetronomeTickCallback = void Function(bool beatOn);
typedef AudioCompletionCallback = void Function(); // 추가된 완료 콜백 타입

/// 오디오 재생 관련 기능을 제공하는 서비스 클래스
class AudioService {
  late AudioPlayer _audioPlayer;
  late AudioPlayer _metronomePlayer;

  // 상태 콜백
  AudioPlayerStateCallback? onPlayingStateChanged;
  AudioDurationCallback? onDurationChanged;
  AudioErrorCallback? onError;
  MetronomeTickCallback? onMetronomeTick;
  AudioCompletionCallback? onCompletion; // 추가된 완료 콜백

  // BPM 및 메트로놈 관련 상태
  Timer? _bpmTimer;
  bool _isMetronomeSoundEnabled = true;

  // 생성자
  AudioService() {
    _initPlayers();
  }

  // 초기화
  void _initPlayers() {
    _audioPlayer = AudioPlayer();
    _metronomePlayer = AudioPlayer();

    // 재생 상태 리스너 설정
    _audioPlayer.playingStream.listen((isPlaying) {
      if (onPlayingStateChanged != null) {
        onPlayingStateChanged!(isPlaying);
      }
    });

    // 길이 변경 리스너 설정
    _audioPlayer.durationStream.listen((duration) {
      if (onDurationChanged != null) {
        onDurationChanged!(duration);
      }
    });

    // 재생 상태 이벤트 리스너 설정
    _audioPlayer.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        // 완료 이벤트 콜백 호출
        if (onCompletion != null) {
          onCompletion!();
        }
      }
    });

    // 오류 이벤트 리스너 설정
    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState != ProcessingState.completed &&
          state.processingState != ProcessingState.idle &&
          state.processingState != ProcessingState.loading &&
          state.processingState != ProcessingState.buffering &&
          state.processingState != ProcessingState.ready) {
        // 알려진 상태가 아닌 경우 오류로 처리
        if (onError != null) {
          onError!('오디오 처리 중 오류 발생');
        }
      }
    });

    // 직접적인 에러 리스너 추가
    _audioPlayer.playbackEventStream.listen(
      (_) {},
      onError: (Object e, StackTrace st) {
        if (onError != null) {
          onError!('오디오 플레이어 오류: ${e.toString()}');
        }
        debugPrint('오디오 플레이어 오류 발생: $e');
      },
    );
  }

  // BPM에 맞춰 메트로놈 시작
  void startBpmTicker(int bpm, {bool forceRestart = false}) {
    // 기존 타이머 중지
    _bpmTimer?.cancel();

    if (bpm <= 0) {
      if (onMetronomeTick != null) {
        onMetronomeTick!(false);
      }
      return;
    }

    // BPM에 맞는 밀리초 간격 계산
    final beatInterval = (60000 / bpm).round();

    bool beatOn = false;
    _bpmTimer = Timer.periodic(Duration(milliseconds: beatInterval), (timer) {
      beatOn = !beatOn;
      if (onMetronomeTick != null) {
        onMetronomeTick!(beatOn);
      }

      // 소리 활성화된 경우 메트로놈 소리 재생
      if (_isMetronomeSoundEnabled &&
          _metronomePlayer.processingState == ProcessingState.ready) {
        _metronomePlayer.seek(Duration.zero);
        _metronomePlayer.play();
      }
    });
  }

  // BPM 타이커 중지
  void stopBpmTicker() {
    _bpmTimer?.cancel();
    if (onMetronomeTick != null) {
      onMetronomeTick!(false);
    }
  }

  // 현재 재생 중인지 확인
  bool get isPlaying => _audioPlayer.playing;

  // 현재 재생 위치 확인
  Duration? get position => _audioPlayer.position;

  // 현재 곡 길이 확인
  Duration? get duration => _audioPlayer.duration;

  // 해제
  void dispose() {
    _bpmTimer?.cancel();
    _audioPlayer.dispose();
    _metronomePlayer.dispose();

    onPlayingStateChanged = null;
    onDurationChanged = null;
    onError = null;
    onMetronomeTick = null;
    onCompletion = null; // 추가된 완료 콜백 해제
  }

  // 공개 API

  // 곡 로드
  Future<void> loadSong(Song song, BuildContext? context) async {
    try {
      final songAsset = song.filePath;
      if (songAsset.isEmpty) {
        if (onError != null) {
          onError!('음악 파일 경로가 없습니다.');
        }
        return;
      }

      await _audioPlayer.setAsset(songAsset);
      debugPrint('오디오 로드 성공: ${song.title}');

      if (_metronomePlayer.processingState == ProcessingState.idle) {
        try {
          await _metronomePlayer.setAsset('assets/audio/tick.mp3');
        } catch (e) {
          debugPrint('메트로놈 로드 실패: $e');
          if (context != null && context.mounted) {
            ShadToaster.of(context).show(
              ShadToast(
                title: const Text('오류'),
                description: const Text('메트로놈 효과음 로드 실패!'),
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('오디오 로드 오류: $e');
      if (onError != null) {
        onError!('음악 파일 로드 실패: ${e.toString()}');
      }
      if (context != null && context.mounted) {
        ShadToaster.of(context).show(
          ShadToast(
            title: const Text('오류'),
            description: Text('음악 로드 실패: ${song.title}'),
          ),
        );
      }
    }
  }

  // 재생
  Future<void> play() async {
    await _audioPlayer.play();
  }

  // 일시 정지
  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  // 정지 (처음으로 이동)
  Future<void> stop() async {
    await _audioPlayer.stop();
    await _audioPlayer.seek(Duration.zero);
  }

  // 특정 위치로 이동
  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  // 재생 속도 설정
  Future<void> setSpeed(double speed) async {
    await _audioPlayer.setSpeed(speed > 0 ? speed : 1.0);
  }

  // 메트로놈 설정
  void setMetronomeSoundEnabled(bool enabled) {
    _isMetronomeSoundEnabled = enabled;
  }
}
