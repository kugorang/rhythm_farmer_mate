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
  bool _isDisposed = false; // 서비스 해제 여부 플래그

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
    _isDisposed = false; // 초기화 시 false로 설정

    // 메트로놈 플레이어 루프 모드 설정
    _metronomePlayer.setLoopMode(LoopMode.one);

    // 메트로놈 음원 로드 (앱 시작 시 한 번만)
    _metronomePlayer.setAsset('assets/audio/tick.mp3').catchError((e) {
      if (!_isDisposed) debugPrint('초기 메트로놈 음원 로드 실패: $e');
      // 여기서 사용자에게 오류를 알릴 필요는 없을 수 있음. 재생 시점에 다시 시도.
    });

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
    _bpmTimer?.cancel();

    if (_isDisposed || bpm <= 0) {
      if (onMetronomeTick != null && !_isDisposed) {
        onMetronomeTick!(false);
      }
      return;
    }

    final beatIntervalMs = (60000 / bpm).round();
    if (beatIntervalMs <= 0) {
      if (onMetronomeTick != null && !_isDisposed) {
        onMetronomeTick!(false);
      }
      return;
    }
    final beatInterval = Duration(milliseconds: beatIntervalMs);

    bool visualBeatState = false;

    void handleBeat() {
      if (_isDisposed) return;

      visualBeatState = !visualBeatState;
      if (onMetronomeTick != null) {
        onMetronomeTick!(visualBeatState);
      }

      if (_isMetronomeSoundEnabled) {
        if (_metronomePlayer.processingState == ProcessingState.ready ||
            _metronomePlayer.processingState == ProcessingState.completed) {
          // LoopMode.one을 사용하므로 seek(0)은 필요 없고, play만 호출
          _metronomePlayer.play().catchError((e) {
            if (!_isDisposed) debugPrint('메트로놈 소리 재생 오류: $e');
          });
        } else if (_metronomePlayer.processingState == ProcessingState.idle) {
          // 로드 안된 경우 대비
          _metronomePlayer
              .setAsset('assets/audio/tick.mp3')
              .then((_) {
                if (!_isDisposed) _metronomePlayer.play();
              })
              .catchError((e) {
                if (!_isDisposed) debugPrint('메트로놈 재생 중 음원 로드 실패: $e');
              });
        }
      }
    }

    // 첫 비트 즉시 실행
    handleBeat();

    _bpmTimer = Timer.periodic(beatInterval, (timer) {
      if (_isDisposed) {
        timer.cancel();
        return;
      }
      handleBeat();
    });
  }

  // BPM 타이커 중지
  void stopBpmTicker() {
    _bpmTimer?.cancel();
    if (!_isDisposed) {
      _metronomePlayer.pause(); // 루프 모드이므로 pause 후 seek(0)
      _metronomePlayer.seek(Duration.zero);
      if (onMetronomeTick != null) {
        onMetronomeTick!(false);
      }
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
    _isDisposed = true; // 해제됨으로 표시
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
      if (songAsset?.isEmpty ?? true) {
        if (onError != null) {
          onError!('음악 파일 경로가 없습니다.');
        }
        return;
      }

      await _audioPlayer.setAsset(songAsset!);
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
