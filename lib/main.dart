import 'package:flutter/material.dart'
    hide BorderStyle; // BoxDecoration, Border, BorderRadius는 사용
import 'package:just_audio/just_audio.dart';
import 'dart:async';
import 'package:shadcn_ui/shadcn_ui.dart'; // shadcn_ui import
import 'models/song.dart'; // Song 모델 import
import 'screens/splash_screen.dart'; // SplashScreen 위젯 import

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 폰트 크기 직접 지정
    final appTextTheme = ShadTextTheme(
      h1: const TextStyle(
        fontSize: 60 * 1.05,
        fontWeight: FontWeight.bold,
      ), // 타이머 크기
      h2: const TextStyle(fontSize: 30 * 1.1, fontWeight: FontWeight.bold),
      h4: const TextStyle(
        fontSize: 18 * 1.1,
        fontWeight: FontWeight.w600,
      ), // 카드 내 제목 등
      p: const TextStyle(fontSize: 15 * 1.15), // 본문/일반 텍스트 (기본 14 또는 15 가정)
      small: const TextStyle(fontSize: 12 * 1.1), // 작은 텍스트
      large: const TextStyle(fontSize: 18 * 1.1), // 큰 텍스트 (버튼 등)
      // ShadButton 내부 Text는 이 테마를 따르거나, child Text에 직접 스타일 적용 필요
    );

    return ShadApp.material(
      title: '리듬농부 메이트',
      theme: ShadThemeData(
        brightness: Brightness.light,
        colorScheme: const ShadZincColorScheme.light(),
        radius: BorderRadius.circular(6.0), // 고정값 사용 또는 ShadRadius.md 사용 가능시 변경
        textTheme: appTextTheme,
      ),
      darkTheme: ShadThemeData(
        brightness: Brightness.dark,
        colorScheme: const ShadZincColorScheme.dark(),
        radius: BorderRadius.circular(6.0),
        textTheme: appTextTheme,
      ),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      builder: (context, child) => ShadToaster(child: child!),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/home': (context) => const MyHomePage(),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late AudioPlayer _audioPlayer;
  late AudioPlayer _metronomePlayer;
  bool _isPlaying = false; // 현재 _audioPlayer가 재생 중인지 (음악 자체의 재생 상태)
  Duration? _audioDuration;
  bool _isLoadingSong = true;
  Timer? _timer; // 작업 타이머 (챌린지용)
  Duration _remainingTime = const Duration(seconds: 0);
  String _timerText = '00:00';
  bool _isChallengeRunning = false; // 작업(챌린지) 타이머가 실행 중인지
  double _progressPercent = 0.0;
  Timer? _bpmTimer; // 시각적 BPM 및 메트로놈용 타이머
  bool _beatHighlighter = false;

  static const int slowBpm = 60;
  static const int normalBpm = 90;
  static const int fastBpm = 120;

  List<DateTime> _tapTimestamps = [];
  Timer? _tapTempoResetTimer;
  static const int _minTapsForBpm = 2;
  static const Duration _tapTempoTimeout = Duration(seconds: 2);
  bool _bpmChangedByTap = false;

  late Song _selectedSong;
  late int _currentManualBpm;
  double _currentPlaybackSpeed = 1.0;

  Timer? _bpmAdjustTimer;

  // _songList는 이전 커밋에서 제공된 전체 목록으로 가정합니다.
  final List<Song> _songList = const [
    Song(
      filePath: 'assets/audio/emart_original.mp3',
      title: '이마트 로고송',
      bpm: 100,
    ),
    Song(
      filePath: 'assets/audio/CD01-01.mp3',
      title: '논삶는소리 (강원 홍천군)',
      bpm: 69,
    ),
    Song(
      filePath: 'assets/audio/CD01-02.mp3',
      title: '논고르는소리 (제주 서귀포시)',
      bpm: 93,
    ),
    Song(
      filePath: 'assets/audio/CD01-03.mp3',
      title: '모찌는소리-"얼른 하더니 한 춤" (강원 양양군)',
      bpm: 70,
    ),
    Song(
      filePath: 'assets/audio/CD01-04.mp3',
      title: '모찌는소리-"뭉치세 제치세" (충북 진천군)',
      bpm: 76,
    ),
    Song(
      filePath: 'assets/audio/CD02-01.mp3',
      title: '논매는소리-"헤헤 곯었네" (경기 안성군)',
      bpm: 52,
    ),
    Song(
      filePath: 'assets/audio/CD02-02.mp3',
      title: '논매는소리-대허리 (경기 이천군)',
      bpm: 115,
    ),
    Song(
      filePath: 'assets/audio/CD02-03.mp3',
      title: '논매는소리-오독떼기 (강원 양양군)',
      bpm: 107,
    ),
    Song(
      filePath: 'assets/audio/CD02-04.mp3',
      title: '논매는소리-"얼카 덩어리" (충남 홍성군)',
      bpm: 62,
    ),
    Song(
      filePath: 'assets/audio/CD03-01.mp3',
      title: '논매는소리-긴소리/들래기소리 (전남 무안군)',
      bpm: 66,
    ),
    Song(
      filePath: 'assets/audio/CD03-02.mp3',
      title: '논매는소리-소오니소리 (경북 구미시)',
      bpm: 55,
    ),
    Song(
      filePath: 'assets/audio/CD03-03.mp3',
      title: '논매는소리 (경북 예천군)',
      bpm: 78,
    ),
    Song(
      filePath: 'assets/audio/CD03-04.mp3',
      title: '농사장원례소리-애롱대롱 (전남 나주군)',
      bpm: 91,
    ),
    Song(
      filePath: 'assets/audio/CD04-01.mp3',
      title: '밭가는소리 (강원 홍천군)',
      bpm: 132,
    ),
    Song(
      filePath: 'assets/audio/CD04-02.mp3',
      title: '밭일구는소리(따비질) (제주 북제주군)',
      bpm: 72,
    ),
    Song(
      filePath: 'assets/audio/CD04-03.mp3',
      title: '밭고르는소리(곰방메질) (제주 북제주군)',
      bpm: 64,
    ),
    Song(
      filePath: 'assets/audio/CD04-04.mp3',
      title: '밭밟는소리 (제주 북제주군)',
      bpm: 69,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedSong =
        _songList.isNotEmpty
            ? _songList.first
            : const Song(filePath: '', title: '노래 없음', bpm: 0);
    _currentManualBpm = _selectedSong.bpm > 0 ? _selectedSong.bpm : 60;
    _audioPlayer = AudioPlayer();
    _metronomePlayer = AudioPlayer();
    if (_selectedSong.filePath.isNotEmpty) _initAudioPlayers();
    _updateTimerText(); // 초기 텍스트 설정
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _metronomePlayer.dispose();
    _timer?.cancel();
    _bpmTimer?.cancel();
    _tapTempoResetTimer?.cancel();
    _bpmAdjustTimer?.cancel(); // 추가된 타이머들도 dispose
    super.dispose();
  }

  Future<void> _initAudioPlayers() async {
    if (mounted)
      setState(() {
        _isLoadingSong = true;
      });
    try {
      await _audioPlayer.setAsset(_selectedSong.filePath);
      await _metronomePlayer.setAsset('assets/audio/tick.mp3');
      _audioPlayer.durationStream.listen((duration) {
        if (mounted)
          setState(() {
            _audioDuration = duration;
            // 챌린지 중이 아니고, 음악 로드 완료 시 타이머 시간 초기화 (재생 속도 반영)
            if (!_isChallengeRunning && _audioDuration != null) {
              _remainingTime = Duration(
                seconds:
                    (_audioDuration!.inSeconds /
                            (_currentPlaybackSpeed > 0
                                ? _currentPlaybackSpeed
                                : 1.0))
                        .round(),
              );
              _updateTimerText();
              _progressPercent = 0.0; // 곡 로드/변경 시 진행도는 0으로
              _updateProgress(); // 실제로 0으로 반영
            }
          });
      });
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted)
          setState(() {
            _isLoadingSong = false;
            if (_audioDuration == null && _audioPlayer.duration != null) {
              _audioDuration = _audioPlayer.duration;
              if (!_isChallengeRunning && _audioDuration != null) {
                _remainingTime = Duration(
                  seconds:
                      (_audioDuration!.inSeconds /
                              (_currentPlaybackSpeed > 0
                                  ? _currentPlaybackSpeed
                                  : 1.0))
                          .round(),
                );
                _updateTimerText();
                _updateProgress();
              }
            }
          });
      });
      _audioPlayer.playingStream.listen((playing) {
        if (mounted)
          setState(() {
            _isPlaying = playing;
          });
        // 음악 재생 상태 변경 시 BPM 타이머(시각화+메트로놈) 제어
        if (playing && !_isChallengeRunning) {
          // 음악만 재생 시작 (챌린지X)
          _restartBpmTimer();
        } else if (!playing && !_isChallengeRunning) {
          // 음악만 정지/일시정지 (챌린지X)
          _bpmTimer?.cancel();
          if (mounted) setState(() => _beatHighlighter = false);
        }
      });
      await _audioPlayer.setSpeed(
        _currentPlaybackSpeed > 0 ? _currentPlaybackSpeed : 1.0,
      );
    } catch (e) {
      print("Error loading audio source: $e");
      if (mounted && e.toString().contains('assets/audio/tick.mp3')) {
        ShadToaster.of(context).show(
          ShadToast(
            title: const Text('오류'),
            description: const Text('메트로놈 사운드(tick.mp3) 로드 실패!'),
          ),
        );
      }
    }
  }

  void _updateTimerText() {
    final minutes = _remainingTime.inMinutes
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    final seconds = _remainingTime.inSeconds
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    if (mounted)
      setState(() {
        _timerText = '$minutes:$seconds';
      });
  }

  void _updateProgress() {
    if (!mounted) return;
    if (_isChallengeRunning &&
        _audioDuration != null &&
        _audioDuration!.inSeconds > 0 &&
        _currentPlaybackSpeed > 0) {
      final totalDurationAdjusted =
          _audioDuration!.inSeconds / _currentPlaybackSpeed;
      if (totalDurationAdjusted > 0) {
        final elapsedTimeAdjusted =
            totalDurationAdjusted - _remainingTime.inSeconds;
        setState(() {
          _progressPercent = (elapsedTimeAdjusted / totalDurationAdjusted)
              .clamp(0.0, 1.0);
        });
      } else {
        setState(() {
          _progressPercent = _remainingTime.inSeconds > 0 ? 0.0 : 1.0;
        });
      }
    } else if (!_isChallengeRunning) {
      // 챌린지 중이 아니면 진행도 0으로 (곡 변경, BPM 변경 시 여기서 처리됨)
      setState(() {
        _progressPercent = 0.0;
      });
    }
  }

  // _startTimers -> _startChallenge
  void _startChallenge() {
    if (_isChallengeRunning) return;
    if (_audioDuration == null) {
      if (mounted)
        ShadToaster.of(context).show(
          ShadToast(
            title: const Text('알림'),
            description: const Text('음악을 불러오는 중입니다. 잠시만 기다려주세요.'),
          ),
        );
      return;
    }
    _remainingTime = Duration(
      seconds:
          (_audioDuration!.inSeconds /
                  (_currentPlaybackSpeed > 0 ? _currentPlaybackSpeed : 1.0))
              .round(),
    );
    _updateTimerText();
    if (mounted)
      setState(() {
        _progressPercent = 0.0;
      });

    setState(() {
      _isChallengeRunning = true; // 챌린지 시작
      _beatHighlighter = false; // BPM 시각화 초기화
    });
    _audioPlayer.setSpeed(
      _currentPlaybackSpeed > 0 ? _currentPlaybackSpeed : 1.0,
    );
    _audioPlayer.play(); // 음악 자동 시작
    // _isPlaying은 _audioPlayer.playingStream에 의해 자동으로 true가 될 것임

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime.inSeconds <= 0) {
        _stopChallenge(completed: true);
      } else {
        if (mounted) {
          _remainingTime = _remainingTime - const Duration(seconds: 1);
          _updateTimerText();
          _updateProgress();
        }
      }
    });
    _restartBpmTimer(); // 챌린지 시작 시 BPM 타이머(시각화+메트로놈) 활성화
  }

  // _stopTimers -> _stopChallenge
  void _stopChallenge({bool completed = false}) {
    _timer?.cancel();
    // _bpmTimer?.cancel(); // 챌린지 중지 시 BPM 시각화/메트로놈은 음악이 계속 재생 중이면 유지될 수 있도록 _audioPlayer.pause() 이후에 결정

    if (mounted)
      setState(() {
        _isChallengeRunning = false; // 챌린지 종료
        // _beatHighlighter = false; // BPM 타이머가 취소될 때 false로 설정됨
        if (completed) {
          _progressPercent = 1.0;
          _remainingTime = Duration.zero;
        } else {
          _updateProgress();
        }
      });
    _audioPlayer.pause(); // 챌린지 중지 시 음악도 일시정지 (또는 stop())
    // _isPlaying은 _audioPlayer.playingStream에 의해 자동으로 false가 될 것임
    // 음악이 멈췄으므로 BPM 타이머도 중지
    _bpmTimer?.cancel();
    if (mounted) setState(() => _beatHighlighter = false);

    if (completed && mounted) {
      ShadToaster.of(context).show(
        ShadToast(
          title: const Text('작업 완료!'),
          description: const Text('오늘도 수고 많으셨습니다! 🎉'),
        ),
      );
    }
    _updateTimerText();
  }

  void _restartBpmTimer() {
    _bpmTimer?.cancel();
    if (!mounted) return;
    // 챌린지 중이거나, 또는 음악만 재생 중일 때 BPM 타이머(시각화 + 메트로놈 소리) 활성화
    if (_isChallengeRunning || _isPlaying) {
      final songBpm = _currentManualBpm > 0 ? _currentManualBpm : 60;
      final beatInterval = (60000 / songBpm).round();
      if (beatInterval <= 0) return;

      _bpmTimer = Timer.periodic(Duration(milliseconds: beatInterval), (timer) {
        if (mounted) {
          setState(() {
            _beatHighlighter = !_beatHighlighter;
          });
          // 메트로놈 오디오 재생 로직 (현재 주석 처리 상태 유지)
          /* if ((_isChallengeRunning || _isPlaying) && mounted) { ... } */
        }
      });
    } else {
      if (mounted) setState(() => _beatHighlighter = false); // 둘 다 아니면 비활성화
    }
  }

  void _updateBpmAndPlaybackSpeed(int newBpm) {
    if (!mounted) return;
    setState(() {
      _currentManualBpm = newBpm.clamp(30, 240);
      final songBpm = _selectedSong.bpm > 0 ? _selectedSong.bpm : 60;
      _currentPlaybackSpeed =
          (songBpm == 0) ? 1.0 : (_currentManualBpm / songBpm).clamp(0.5, 2.0);
      _audioPlayer.setSpeed(
        _currentPlaybackSpeed > 0 ? _currentPlaybackSpeed : 1.0,
      );

      // 음악이 재생 중이거나 BPM 타이머가 활성화되어야 할 조건이면 재시작
      if (_isPlaying || _isChallengeRunning) {
        _restartBpmTimer();
      }
      // 챌린지 중이 아닐 때만, 변경된 BPM과 재생속도에 맞춰 남은 시간과 진행도 업데이트
      if (!_isChallengeRunning && _audioDuration != null) {
        _remainingTime = Duration(
          seconds:
              (_audioDuration!.inSeconds /
                      (_currentPlaybackSpeed > 0 ? _currentPlaybackSpeed : 1.0))
                  .round(),
        );
        _progressPercent = 0.0; // BPM 변경 시 진행도는 0으로 초기화
        _updateTimerText();
        _updateProgress(); // 실제로 0으로 반영
      }
    });
  }

  void _changeBpmToPreset(int presetBpm) {
    if (_isChallengeRunning && mounted) {
      ShadToaster.of(
        context,
      ).show(ShadToast(description: const Text('지금은 작업 중이라 박자를 바꿀 수 없어요.')));
      return;
    }
    _updateBpmAndPlaybackSpeed(presetBpm);
  }

  void _changeBpm(int delta) {
    if (_isChallengeRunning && mounted) {
      ShadToaster.of(
        context,
      ).show(ShadToast(description: const Text('지금은 작업 중이라 박자를 바꿀 수 없어요.')));
      return;
    }
    _updateBpmAndPlaybackSpeed(_currentManualBpm + delta);
  }

  void _handleTapForBpm() {
    if (_isChallengeRunning && mounted) {
      ShadToaster.of(
        context,
      ).show(ShadToast(description: const Text('지금은 작업 중이라 박자를 바꿀 수 없어요.')));
      return;
    }
    final now = DateTime.now();
    if (mounted) {
      if (_tapTimestamps.length >= _minTapsForBpm) _tapTimestamps.removeAt(0);
      setState(() {
        _tapTimestamps.add(now);
      });
    }
    _tapTempoResetTimer?.cancel();
    if (_tapTimestamps.length >= _minTapsForBpm) {
      final intervalMs =
          _tapTimestamps[1].difference(_tapTimestamps[0]).inMilliseconds;
      if (intervalMs > 250 && intervalMs < 2000) {
        final newBpm = (60000 / intervalMs).round();
        _updateBpmAndPlaybackSpeed(newBpm);
        if (mounted)
          ShadToaster.of(context).show(
            ShadToast(
              description: Text('현재 박자가 $_currentManualBpm (으)로 설정되었어요.'),
            ),
          );
        Timer(const Duration(milliseconds: 500), () {
          if (mounted)
            setState(() {
              _bpmChangedByTap = false;
            });
        });
      } else {
        if (mounted)
          ShadToaster.of(context).show(
            ShadToast(
              description: const Text('엇, 박자가 너무 빠르거나 느리네요. 다시 탭해주세요.'),
            ),
          );
      }
    } else {
      _tapTempoResetTimer = Timer(_tapTempoTimeout, () {
        if (_tapTimestamps.isNotEmpty &&
            _tapTimestamps.length < _minTapsForBpm &&
            mounted) {
          ShadToaster.of(context).show(
            ShadToast(
              description: Text(
                '박자 계산에 필요한 탭 횟수가 부족해요. (최소 ${_minTapsForBpm}번)',
              ),
            ),
          );
        }
        if (mounted)
          setState(() {
            _tapTimestamps.clear();
          });
      });
    }
    if (mounted) setState(() {});
  }

  Future<void> _onSongChanged(Song newSong) async {
    if (_isChallengeRunning && mounted) {
      ShadToaster.of(
        context,
      ).show(ShadToast(description: const Text('지금은 작업 중이라 노래를 바꿀 수 없어요.')));
      return;
    }
    if (mounted)
      setState(() {
        _isLoadingSong = true;
        _isChallengeRunning = false;
        _progressPercent = 0.0;
      }); // 곡 변경 시 챌린지 상태도 리셋
    // ... (나머지 상태 초기화)
    await _audioPlayer.stop();
    _bpmTimer?.cancel();
    if (mounted) setState(() => _beatHighlighter = false);
    await _initAudioPlayers();
  }

  // ... (dispose, _bpmAdjustTimer 관련 함수는 이전과 동일)
  void _startBpmAdjustTimer(int delta) {
    _bpmAdjustTimer?.cancel();
    _changeBpm(delta);
    _bpmAdjustTimer = Timer.periodic(const Duration(milliseconds: 150), (
      timer,
    ) {
      _changeBpm(delta);
    });
  }

  void _stopBpmAdjustTimer() {
    _bpmAdjustTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final defaultBorderRadius = theme.radius;
    final bpmIndicatorScale = _beatHighlighter ? 1.1 : 1.0;
    final bpmDisplayCardColor =
        _bpmChangedByTap
            ? theme.colorScheme.primary.withOpacity(0.1)
            : (_isLoadingSong
                ? theme.colorScheme.muted
                : theme.colorScheme.card);
    final bpmIndicatorColor =
        _isLoadingSong
            ? theme.colorScheme.muted
            : (_beatHighlighter
                ? theme.colorScheme.primary.withOpacity(0.35)
                : bpmDisplayCardColor);
    final bpmTextColor =
        _isLoadingSong
            ? theme.colorScheme.mutedForeground
            : (_bpmChangedByTap
                ? theme.colorScheme.primary
                : (_beatHighlighter
                    ? theme.colorScheme.primary
                    : theme.colorScheme.foreground));

    Widget buildBpmPresetButton(String label, int presetBpm) {
      final isSelected = _currentManualBpm == presetBpm;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: ShadButton.outline(
          size: ShadButtonSize.sm,
          child: Text(
            label,
            style: theme.textTheme.p.copyWith(
              color:
                  isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.foreground.withOpacity(0.7),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          onPressed:
              _isChallengeRunning || _isLoadingSong
                  ? null
                  : () => _changeBpmToPreset(presetBpm),
        ),
      );
    }

    // UI 요소 활성화 조건 변수화
    final canChangeSettings = !_isChallengeRunning && !_isLoadingSong;
    final canControlMusicIndependent =
        !_isChallengeRunning &&
        !_isLoadingSong &&
        _audioDuration != null; // 챌린지 아닐 때 음악만 제어
    // final canControlMusicInChallenge = _isChallengeRunning && !_isLoadingSong && _audioDuration != null; // 챌린지 중 음악 제어 (현재는 작업 시작/중지로 통합)

    return Scaffold(
      appBar: AppBar(/* ... */),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // horizontalPadding 변수 정의 복원
              final screenWidth = MediaQuery.of(context).size.width;
              final horizontalPadding = screenWidth < 600 ? 16.0 : 24.0;
              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 24.0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    if (_isLoadingSong)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    // 곡 선택 UI: 활성화 조건 변경
                    if (!_isChallengeRunning &&
                        !_isLoadingSong) // _isChallengeRunning으로 변경
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24.0),
                        child: ShadSelect<Song>(
                          placeholder: Text(
                            '노동요를 선택하세요',
                            style: theme.textTheme.p.copyWith(
                              color: theme.colorScheme.mutedForeground,
                            ),
                          ),
                          options:
                              _songList
                                  .map(
                                    (song) => ShadOption(
                                      value: song,
                                      child: Text(
                                        song.title,
                                        style: theme.textTheme.p,
                                      ),
                                    ),
                                  )
                                  .toList(),
                          selectedOptionBuilder:
                              (context, value) =>
                                  Text(value.title, style: theme.textTheme.p),
                          onChanged:
                              canChangeSettings
                                  ? (Song? value) {
                                    if (value != null) _onSongChanged(value);
                                  }
                                  : null,
                          initialValue: _selectedSong,
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color:
                            _isLoadingSong
                                ? theme.colorScheme.muted
                                : theme.colorScheme.card,
                        borderRadius: defaultBorderRadius,
                        border: Border.all(color: theme.colorScheme.border),
                      ),
                      child: Center(
                        child:
                            _isLoadingSong
                                ? Text(
                                  "노래 로딩 중...",
                                  style: theme.textTheme.h4.copyWith(
                                    color: theme.colorScheme.mutedForeground,
                                  ),
                                )
                                : Text(
                                  _timerText,
                                  style: theme.textTheme.h1.copyWith(
                                    fontFamily: 'monospace',
                                    color: theme.colorScheme.foreground,
                                  ),
                                ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // BPM 프리셋 버튼: 활성화 조건 변경
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        buildBpmPresetButton(
                          '느리게',
                          slowBpm,
                        ), // 내부 onPressed에서 canChangeSettings 사용하도록 수정 필요
                        buildBpmPresetButton('보통', normalBpm),
                        buildBpmPresetButton('빠르게', fastBpm),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // BPM +/- 버튼: 활성화 조건 변경
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap:
                              canChangeSettings && _currentManualBpm > 30
                                  ? () => _changeBpm(-5)
                                  : null,
                          onLongPressStart:
                              canChangeSettings && _currentManualBpm > 30
                                  ? (details) => _startBpmAdjustTimer(-1)
                                  : null,
                          onLongPressEnd:
                              canChangeSettings
                                  ? (details) => _stopBpmAdjustTimer()
                                  : null,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Icon(
                              Icons.remove_circle_outline,
                              size: 30,
                              color:
                                  !(canChangeSettings && _currentManualBpm > 30)
                                      ? theme.colorScheme.mutedForeground
                                      : theme.colorScheme.foreground,
                            ),
                          ),
                        ),
                        Expanded(
                          child: AnimatedContainer(
                            duration: Duration(
                              milliseconds:
                                  (60000 /
                                          (_currentManualBpm > 0
                                              ? _currentManualBpm
                                              : 60) /
                                          2)
                                      .round(),
                            ),
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            height: 52,
                            transform:
                                Matrix4.identity()..scale(bpmIndicatorScale),
                            transformAlignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: bpmIndicatorColor,
                              borderRadius: defaultBorderRadius,
                              border: Border.all(
                                color: theme.colorScheme.border,
                              ),
                            ),
                            child: Center(
                              child:
                                  _isLoadingSong
                                      ? Text(
                                        "--",
                                        style: theme.textTheme.p.copyWith(
                                          color:
                                              theme.colorScheme.mutedForeground,
                                        ),
                                      )
                                      : Text(
                                        '현재 박자: $_currentManualBpm',
                                        style: theme.textTheme.p.copyWith(
                                          color: bpmTextColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap:
                              canChangeSettings && _currentManualBpm < 240
                                  ? () => _changeBpm(5)
                                  : null,
                          onLongPressStart:
                              canChangeSettings && _currentManualBpm < 240
                                  ? (details) => _startBpmAdjustTimer(1)
                                  : null,
                          onLongPressEnd:
                              canChangeSettings
                                  ? (details) => _stopBpmAdjustTimer()
                                  : null,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Icon(
                              Icons.add_circle_outline,
                              size: 30,
                              color:
                                  !(canChangeSettings &&
                                          _currentManualBpm < 240)
                                      ? theme.colorScheme.mutedForeground
                                      : theme.colorScheme.foreground,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // 탭 템포 버튼: 활성화 조건 변경
                    SizedBox(
                      width: double.infinity,
                      child: ShadButton(
                        size: ShadButtonSize.lg,
                        child: Text(
                          '탭하여 박자 입력 (${_tapTimestamps.length}번 탭)',
                          style: theme.textTheme.p.copyWith(
                            color: theme.colorScheme.primaryForeground,
                          ),
                        ),
                        onPressed: canChangeSettings ? _handleTapForBpm : null,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ShadProgress(
                      value:
                          _isLoadingSong ? 0 : _progressPercent * 100 /* ... */,
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        _isLoadingSong
                            ? '로딩 중...'
                            : '진행도: ${(_progressPercent * 100).toStringAsFixed(0)}%' /* ... */,
                      ),
                    ),
                    const SizedBox(height: 30),
                    // 음악 제어 버튼 컨테이너: 활성화 조건 변경
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color:
                            (_isLoadingSong || _isChallengeRunning)
                                ? theme.colorScheme.muted.withOpacity(0.5)
                                : theme.colorScheme.card,
                        borderRadius: defaultBorderRadius,
                        border: Border.all(color: theme.colorScheme.border),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _isLoadingSong
                                ? '로딩 중...'
                                : '현재 재생 중: ${_selectedSong.title}',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.p.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (!_isLoadingSong && _audioDuration != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                _currentPlaybackSpeed == 1.0
                                    ? "(원곡 빠르기, 현재 박자: ${_selectedSong.bpm > 0 ? _selectedSong.bpm : 'N/A'})"
                                    : '재생 빠르기: ${_currentPlaybackSpeed.toStringAsFixed(1)}배 (원곡 박자: ${_selectedSong.bpm > 0 ? _selectedSong.bpm : 'N/A'} -> 현재 박자: $_currentManualBpm)',
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
                                    _isPlaying
                                        ? Icons.pause_circle_outline
                                        : Icons.play_circle_outline,
                                    size: 24,
                                    color:
                                        canControlMusicIndependent
                                            ? theme.colorScheme.primary
                                            : theme.colorScheme.mutedForeground,
                                  ),
                                ),
                                child: Text(
                                  _isPlaying ? '일시정지' : '재생',
                                  style: theme.textTheme.p.copyWith(
                                    color:
                                        canControlMusicIndependent
                                            ? theme.colorScheme.primary
                                            : theme.colorScheme.mutedForeground,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                onPressed:
                                    canControlMusicIndependent
                                        ? () {
                                          if (_isPlaying)
                                            _audioPlayer.pause();
                                          else {
                                            _audioPlayer.setSpeed(
                                              _currentPlaybackSpeed > 0
                                                  ? _currentPlaybackSpeed
                                                  : 1.0,
                                            );
                                            _audioPlayer.play();
                                            if (!_isChallengeRunning)
                                              _restartBpmTimer();
                                          }
                                        }
                                        : null,
                              ),
                              ShadButton.ghost(
                                icon: Padding(
                                  padding: const EdgeInsets.only(right: 4.0),
                                  child: Icon(
                                    Icons.stop_circle,
                                    size: 24,
                                    color:
                                        canControlMusicIndependent
                                            ? theme.colorScheme.destructive
                                            : theme.colorScheme.mutedForeground,
                                  ),
                                ),
                                child: Text(
                                  '정지',
                                  style: theme.textTheme.p.copyWith(
                                    color:
                                        canControlMusicIndependent
                                            ? theme.colorScheme.destructive
                                            : theme.colorScheme.mutedForeground,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                onPressed:
                                    canControlMusicIndependent
                                        ? () {
                                          _audioPlayer.stop();
                                          _audioPlayer.seek(Duration.zero);
                                          if (!_isChallengeRunning) {
                                            _bpmTimer?.cancel();
                                            if (mounted)
                                              setState(
                                                () => _beatHighlighter = false,
                                              );
                                          }
                                        }
                                        : null,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    // 작업 시작/중지 버튼
                    ShadButton(
                      size: ShadButtonSize.lg,
                      child: Text(
                        _isLoadingSong
                            ? '노래 로딩 중...'
                            : (_isChallengeRunning ? '작업 중지' : '작업 시작'),
                        style: theme.textTheme.large.copyWith(
                          color:
                              _isChallengeRunning
                                  ? theme.colorScheme.destructiveForeground
                                  : theme.colorScheme.primaryForeground,
                        ),
                      ),
                      onPressed:
                          _isLoadingSong
                              ? null
                              : () {
                                if (_isChallengeRunning) {
                                  _stopChallenge();
                                } else {
                                  // _startChallenge() 로직은 이전과 동일
                                  if (_audioDuration == null) {
                                    /* ... 알림 ... */
                                    return;
                                  }
                                  if (_remainingTime.inSeconds == 0 ||
                                      _remainingTime.inSeconds.toDouble() !=
                                          (_audioDuration!.inSeconds /
                                                  (_currentPlaybackSpeed > 0
                                                      ? _currentPlaybackSpeed
                                                      : 1.0))
                                              .round()) {
                                    if (mounted)
                                      setState(() {
                                        /* ... 시간/진행도 초기화 ... */
                                      });
                                  }
                                  _startChallenge();
                                }
                              },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // 생략된 함수 본문들 (예: initState, dispose, _initAudioPlayers, _updateTimerText 등)은 이전 커밋의 내용과 동일하게 유지합니다.
}
