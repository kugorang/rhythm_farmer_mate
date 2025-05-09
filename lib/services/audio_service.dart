import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
// import 'package:shadcn_ui/shadcn_ui.dart'; // ShadToaster 사용 안 함
import '../models/song.dart';

// 오디오 서비스 상태 이벤트 콜백을 위한 타입 정의
typedef AudioPlayerStateCallback = void Function(bool isPlaying);
typedef AudioDurationCallback = void Function(Duration? duration);
typedef AudioErrorCallback = void Function(String errorMessage);
// typedef MetronomeTickCallback = void Function(bool beatOn); // 삭제
typedef AudioCompletionCallback = void Function(); // 추가된 완료 콜백 타입

/// 오디오 재생 관련 기능을 제공하는 서비스 클래스
class AudioService {
  late AudioPlayer _audioPlayer;
  // late AudioPlayer _metronomePlayer; // 삭제
  bool _isDisposed = false; // 서비스 해제 여부 플래그

  // 상태 콜백
  AudioPlayerStateCallback? onPlayingStateChanged;
  AudioDurationCallback? onDurationChanged;
  AudioErrorCallback? onError;
  // MetronomeTickCallback? onMetronomeTick; // 삭제
  AudioCompletionCallback? onCompletion; // 추가된 완료 콜백

  // BPM 및 메트로놈 관련 상태
  // Timer? _bpmTimer; // 삭제
  // bool _isMetronomeSoundEnabled = true; // 삭제
  double _currentPlaybackSpeed = 1.0; // 현재 재생 속도 저장 변수

  // 생성자
  AudioService() {
    _initPlayers();
  }

  // 초기화
  void _initPlayers() {
    _audioPlayer = AudioPlayer();
    // _metronomePlayer = AudioPlayer(); // 삭제
    _isDisposed = false; // 초기화 시 false로 설정

    // _metronomePlayer.setLoopMode(LoopMode.one); // 삭제
    // _metronomePlayer.setAsset('assets/audio/tick.mp3').catchError((e) { ... }); // 삭제

    // 재생 상태 리스너 설정
    _audioPlayer.playingStream.listen((isPlaying) {
      onPlayingStateChanged?.call(isPlaying);
    });

    // 길이 변경 리스너 설정
    _audioPlayer.durationStream.listen((duration) {
      onDurationChanged?.call(duration);
    });

    // 재생 상태 이벤트 리스너 설정
    _audioPlayer.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        // 완료 이벤트 콜백 호출
        onCompletion?.call();
      }
    });

    // 오류 이벤트 리스너 설정
    _audioPlayer.playerStateStream.listen((playerState) {
      // just_audio에서 명시적인 error 상태는 playbackEventStream.onError로 처리됨
      // 여기서는 playerState.processingState가 예상치 못한 상태일 때를 감지하거나 로깅할 수 있음
      if (playerState.processingState == ProcessingState.idle &&
          _audioPlayer.duration == null &&
          !_audioPlayer.playing) {
        // 로드 실패 또는 초기화 실패로 간주할 수 있는 상태 (더 정교한 조건 필요할 수 있음)
        // onError?.call('오디오 플레이어 상태 오류 또는 로드 실패');
        // debugPrint("AudioService: Player in idle with no duration and not playing.");
      }
    });

    _audioPlayer.playbackEventStream.listen(
      (event) {
        // event 파라미터 명시
        // 필요한 경우 event.processingState 등을 여기서도 확인 가능
      },
      onError: (Object e, StackTrace st) {
        onError?.call('오디오 플레이어 오류: ${e.toString()}');
        debugPrint('오디오 플레이어 오류 발생: $e\n$st'); // 스택 트레이스도 출력
      },
    );
  }

  // BPM에 맞춰 메트로놈 시작
  // void startBpmTicker(int bpm, {bool forceRestart = false}) { ... } // 삭제

  // BPM 타이커 중지
  // void stopBpmTicker() { ... } // 삭제

  // 현재 재생 중인지 확인
  bool get isPlaying => _audioPlayer.playing;

  // 현재 재생 위치 확인
  Duration? get position => _audioPlayer.position;

  // 현재 곡 길이 확인
  Duration? get duration => _audioPlayer.duration;

  // 해제
  void dispose() {
    _isDisposed = true; // 해제됨으로 표시
    // _bpmTimer?.cancel(); // 삭제
    _audioPlayer.dispose();
    // _metronomePlayer.dispose(); // 삭제

    onPlayingStateChanged = null;
    onDurationChanged = null;
    onError = null;
    // onMetronomeTick = null; // 삭제
    onCompletion = null; // 추가된 완료 콜백 해제
  }

  // 공개 API

  // 곡 로드
  Future<void> loadSong(Song song) async {
    try {
      final songAsset = song.filePath;
      if (songAsset?.isEmpty ?? true) {
        onError?.call('음악 파일 경로가 없습니다.');
        return;
      }
      await _audioPlayer.setAsset(songAsset!);
      debugPrint('오디오 로드 성공: ${song.title}');
    } catch (e) {
      debugPrint('오디오 로드 오류: $e');
      onError?.call('음악 파일 로드 실패: ${e.toString()}');
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
    try {
      _currentPlaybackSpeed = speed; // 현재 재생 속도 업데이트
      await _audioPlayer.setSpeed(speed > 0 ? speed : 1.0);
      // BPM 티커가 실행 중이라면, 속도 변경에 맞춰 재시작
      // if (_bpmTimer != null && _bpmTimer!.isActive) {
      //   startBpmTicker(60); // 기본 BPM 60으로 재시작
      // }
    } catch (e) {
      onError?.call('재생 속도 설정 오류: ${e.toString()}');
    }
  }

  // 메트로놈 설정
  // void setMetronomeSoundEnabled(bool enabled) { ... } // 삭제
}
