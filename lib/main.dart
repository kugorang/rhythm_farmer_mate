import 'package:flutter/material.dart'
    hide BorderStyle; // BoxDecoration, Border, BorderRadius는 사용
import 'package:just_audio/just_audio.dart';
import 'dart:async';
import 'package:shadcn_ui/shadcn_ui.dart'; // shadcn_ui import

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
        colorScheme: const ShadSlateColorScheme.light(),
        radius: BorderRadius.circular(6.0), // 고정값 사용 또는 ShadRadius.md 사용 가능시 변경
        textTheme: appTextTheme,
      ),
      darkTheme: ShadThemeData(
        brightness: Brightness.dark,
        colorScheme: const ShadSlateColorScheme.dark(),
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

// Splash Screen 위젯 (Shadcn UI 스타일로 일부 변경)
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(
      const Duration(seconds: 2),
      () => Navigator.of(context).pushReplacementNamed('/home'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.background, // Shadcn 테마 배경색 사용
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/logo.png', width: 150, height: 150),
            const SizedBox(height: 20),
            Text(
              '리듬농부 메이트',
              style: theme.textTheme.h2.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 10),
            CircularProgressIndicator(
              color: theme.colorScheme.primary.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }
}

// Song 데이터 클래스
class Song {
  final String filePath;
  final String title;
  final int bpm;

  const Song({required this.filePath, required this.title, required this.bpm});
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late AudioPlayer _audioPlayer;
  late AudioPlayer _metronomePlayer; // 메트로놈용 오디오 플레이어
  bool _isPlaying = false;
  Duration? _audioDuration;
  bool _isLoadingSong = true; // 로딩 상태 변수 추가

  Timer? _timer;
  Duration _remainingTime = const Duration(seconds: 0);
  String _timerText = '00:00';
  bool _isTimerRunning = false;
  double _progressPercent = 0.0;

  Timer? _bpmTimer;
  bool _beatHighlighter = false;

  // bpm : https://tunebat.com/Analyzer
  final List<Song> _songList = const [
    // 현대 노동요
    Song(
      filePath: 'assets/audio/emart_original.mp3',
      title: '이마트 로고송',
      bpm: 100,
    ),
    // CD-01
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
    // CD-02
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
    // CD-03
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
    // CD-04
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
  late Song _selectedSong;
  late int _currentManualBpm; // 사용자가 조절하는 BPM
  double _currentPlaybackSpeed = 1.0; // 현재 재생 속도

  static const int slowBpm = 60;
  static const int normalBpm = 90;
  static const int fastBpm = 120;

  List<DateTime> _tapTimestamps = [];
  Timer? _tapTempoResetTimer;
  static const int _minTapsForBpm = 2;
  static const Duration _tapTempoTimeout = Duration(seconds: 2);
  bool _bpmChangedByTap = false;

  @override
  void initState() {
    super.initState();
    // _songList가 비어있지 않다고 가정하고 first를 사용
    _selectedSong =
        _songList.isNotEmpty
            ? _songList.first
            : const Song(filePath: '', title: '노래 없음', bpm: 0);
    _currentManualBpm = _selectedSong.bpm > 0 ? _selectedSong.bpm : 60;
    _audioPlayer = AudioPlayer();
    _metronomePlayer = AudioPlayer();
    if (_selectedSong.filePath.isNotEmpty) {
      // 선택된 곡이 있을 때만 초기화
      _initAudioPlayers();
    }
    _updateTimerText();
  }

  Future<void> _initAudioPlayers() async {
    if (mounted) {
      setState(() {
        _isLoadingSong = true;
      });
    }
    try {
      await _audioPlayer.setAsset(_selectedSong.filePath);
      await _metronomePlayer.setAsset('assets/audio/tick.mp3');

      _audioPlayer.durationStream.listen((duration) {
        if (mounted) {
          setState(() {
            _audioDuration = duration;
            if (!_isTimerRunning && _audioDuration != null) {
              _remainingTime = Duration(
                seconds:
                    (_audioDuration!.inSeconds / _currentPlaybackSpeed).round(),
              );
              _updateTimerText();
              _updateProgress();
            }
          });
        }
      });

      // durationStream이 안정적으로 첫 값을 받을 때까지 기다리거나, 최초 로드 완료 시점으로 이동
      // 또는 setAsset 완료 후 바로 로딩 완료로 간주 (duration은 나중에 업데이트)
      // 여기서는 setAsset 완료 후 로딩 완료로 처리하고, duration은 비동기 업데이트되도록 함.
      if (mounted) {
        // 약간의 딜레이를 주어 durationStream이 첫 값을 받을 기회를 줌 (이상적인 방법은 아님)
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {
              _isLoadingSong = false;
              // 만약 이때 _audioDuration이 아직 null이면, 기본값이나 초기화 필요
              if (_audioDuration == null && _audioPlayer.duration != null) {
                _audioDuration = _audioPlayer.duration; // 직접 가져오기 시도
                if (!_isTimerRunning && _audioDuration != null) {
                  _remainingTime = Duration(
                    seconds:
                        (_audioDuration!.inSeconds / _currentPlaybackSpeed)
                            .round(),
                  );
                  _updateTimerText();
                  _updateProgress();
                }
              }
            });
          }
        });
      }

      _audioPlayer.playingStream.listen((playing) {
        if (mounted) {
          setState(() {
            _isPlaying = playing;
          });
        }
      });
      // 재생 속도 초기화
      await _audioPlayer.setSpeed(_currentPlaybackSpeed);
    } catch (e) {
      print("Error loading audio source: $e");
      if (e.toString().contains('assets/audio/tick.mp3')) {
        ShadToaster.of(context).show(
          ShadToast(
            title: const Text('오류'),
            description: const Text(
              '메트로놈 사운드(tick.mp3) 로드 실패! assets/audio 폴더를 확인하세요.',
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _metronomePlayer.dispose(); // 메트로놈 플레이어 리소스 해제
    _timer?.cancel();
    _bpmTimer?.cancel();
    super.dispose();
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
    if (mounted) {
      setState(() {
        _timerText = '$minutes:$seconds';
      });
    }
  }

  void _updateProgress() {
    if (!mounted) return;
    if (_audioDuration != null &&
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
          _progressPercent = 0.0;
        });
      }
    } else {
      setState(() {
        _progressPercent = 0.0;
      });
    }
  }

  void _startTimers() {
    if (_isTimerRunning) return;
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
      seconds: (_audioDuration!.inSeconds / _currentPlaybackSpeed).round(),
    );
    _updateTimerText();
    // _updateProgress(); // 타이머 시작 시점에서 진행도는 0이 되어야 함
    if (mounted)
      setState(() {
        _progressPercent = 0.0;
      });

    setState(() {
      _isTimerRunning = true;
      _beatHighlighter = false;
    });
    _audioPlayer.setSpeed(_currentPlaybackSpeed);
    _audioPlayer.play();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime.inSeconds <= 0) {
        _stopTimers(completed: true);
      } else {
        if (mounted) {
          _remainingTime = _remainingTime - const Duration(seconds: 1);
          _updateTimerText();
          _updateProgress(); // 매초 진행도 업데이트
        }
      }
    });
    _restartBpmTimer();
  }

  void _stopTimers({bool completed = false}) {
    _timer?.cancel();
    _bpmTimer?.cancel();
    if (mounted)
      setState(() {
        _isTimerRunning = false;
        _beatHighlighter = false;
        if (completed) {
          _progressPercent = 1.0;
          _remainingTime = Duration.zero;
        } else {
          _updateProgress();
        }
      });
    _audioPlayer.pause();
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
    if (!_isTimerRunning && !_isPlaying) {}
    final beatInterval = (60000 / _currentManualBpm).round();
    if (beatInterval <= 0)
      return; // Prevent negative or zero duration for Timer
    _bpmTimer = Timer.periodic(Duration(milliseconds: beatInterval), (timer) {
      if (mounted)
        setState(() {
          _beatHighlighter = !_beatHighlighter;
        });
      if (_isTimerRunning || _isPlaying) {
        _metronomePlayer.seek(Duration.zero);
        _metronomePlayer.play();
      }
    });
  }

  void _changeBpmToPreset(int presetBpm) {
    if (_isTimerRunning && mounted) {
      ShadToaster.of(
        context,
      ).show(ShadToast(description: const Text('지금은 작업 중이라 박자를 바꿀 수 없어요.')));
      return;
    }
    setState(() {
      _currentManualBpm = presetBpm.clamp(30, 240);
      final songBpm = _selectedSong.bpm > 0 ? _selectedSong.bpm : 60;
      _currentPlaybackSpeed =
          (songBpm == 0) ? 1.0 : (_currentManualBpm / songBpm).clamp(0.5, 2.0);
      _audioPlayer.setSpeed(
        _currentPlaybackSpeed > 0 ? _currentPlaybackSpeed : 1.0,
      );

      if (_isTimerRunning || _isPlaying || (_bpmTimer?.isActive ?? false)) {
        _restartBpmTimer();
      }
      if (!_isTimerRunning && _audioDuration != null) {
        _remainingTime = Duration(
          seconds:
              (_audioDuration!.inSeconds /
                      (_currentPlaybackSpeed > 0 ? _currentPlaybackSpeed : 1.0))
                  .round(),
        );
        _updateTimerText();
        _updateProgress();
      }
    });
  }

  void _changeBpm(int delta) {
    if (_isTimerRunning && mounted) {
      ShadToaster.of(
        context,
      ).show(ShadToast(description: const Text('지금은 작업 중이라 박자를 바꿀 수 없어요.')));
      return;
    }
    setState(() {
      int newBpm = (_currentManualBpm + delta).clamp(30, 240);
      _currentManualBpm = newBpm;
      final songBpm = _selectedSong.bpm > 0 ? _selectedSong.bpm : 60;
      _currentPlaybackSpeed =
          (songBpm == 0) ? 1.0 : (_currentManualBpm / songBpm).clamp(0.5, 2.0);
      _audioPlayer.setSpeed(
        _currentPlaybackSpeed > 0 ? _currentPlaybackSpeed : 1.0,
      );
      if (_isTimerRunning || _isPlaying || (_bpmTimer?.isActive ?? false))
        _restartBpmTimer();
      if (!_isTimerRunning && _audioDuration != null) {
        _remainingTime = Duration(
          seconds:
              (_audioDuration!.inSeconds /
                      (_currentPlaybackSpeed > 0 ? _currentPlaybackSpeed : 1.0))
                  .round(),
        );
        _updateTimerText();
        _updateProgress();
      }
    });
  }

  Future<void> _onSongChanged(Song newSong) async {
    if (_isTimerRunning && mounted) {
      ShadToaster.of(
        context,
      ).show(ShadToast(description: const Text('지금은 작업 중이라 노래를 바꿀 수 없어요.')));
      return;
    }
    if (mounted)
      setState(() {
        _isLoadingSong = true;
      });
    setState(() {
      _selectedSong = newSong;
      _currentManualBpm =
          _selectedSong.bpm == 0 ? 60 : _selectedSong.bpm; // 기본 BPM 설정
      _currentPlaybackSpeed = 1.0;
      _isPlaying = false;
      _progressPercent = 0.0;
      _remainingTime = Duration.zero;
      _timerText = '00:00';
      _audioDuration = null;
      _beatHighlighter = false;
    });
    await _audioPlayer.stop();
    _bpmTimer?.cancel();
    await _initAudioPlayers();
  }

  void _handleTapForBpm() {
    if (_isTimerRunning && mounted) {
      ShadToaster.of(
        context,
      ).show(ShadToast(description: const Text('지금은 작업 중이라 박자를 바꿀 수 없어요.')));
      return;
    }

    final now = DateTime.now();
    if (mounted) {
      // 탭 기록이 이미 최대치(2)에 도달했으면, 가장 오래된 기록을 제거하고 새 기록 추가 (슬라이딩 윈도우 방식)
      if (_tapTimestamps.length >= _minTapsForBpm) {
        _tapTimestamps.removeAt(0);
      }
      setState(() {
        _tapTimestamps.add(now);
      });
    }

    _tapTempoResetTimer?.cancel();

    if (_tapTimestamps.length >= _minTapsForBpm) {
      // 이제 _tapTimestamps에는 항상 2개의 timestamp만 존재
      final intervalMs =
          _tapTimestamps[1].difference(_tapTimestamps[0]).inMilliseconds;

      if (intervalMs > 250 && intervalMs < 2000) {
        // BPM 30 ~ 240 범위에 해당하는 간격
        final newBpm = (60000 / intervalMs).round().clamp(30, 240);
        setState(() {
          _currentManualBpm = newBpm;
          final songBpm = _selectedSong.bpm > 0 ? _selectedSong.bpm : 60;
          _currentPlaybackSpeed =
              (songBpm == 0)
                  ? 1.0
                  : (_currentManualBpm / songBpm).clamp(0.5, 2.0);
          _audioPlayer.setSpeed(
            _currentPlaybackSpeed > 0 ? _currentPlaybackSpeed : 1.0,
          );

          if (_isPlaying || (_bpmTimer?.isActive ?? false)) _restartBpmTimer();
          if (!_isTimerRunning && _audioDuration != null) {
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
          _bpmChangedByTap = true;
        });
        if (mounted) {
          ShadToaster.of(context).show(
            ShadToast(
              description: Text('현재 박자가 $_currentManualBpm (으)로 설정되었어요.'),
            ),
          );
        }
        Timer(const Duration(milliseconds: 500), () {
          if (mounted)
            setState(() {
              _bpmChangedByTap = false;
            });
        });
        // _tapTimestamps.clear(); // 2번 탭마다 바로 계산하므로, 여기서는 초기화 안 함 (계속 2개 유지)
      } else {
        if (mounted)
          ShadToaster.of(context).show(
            ShadToast(
              description: const Text('엇, 박자가 너무 빠르거나 느리네요. 다시 탭해주세요.'),
            ),
          );
        // _tapTimestamps.clear(); // 잘못된 간격이라도, 다음 탭을 위해 이전 탭은 유지할 수 있음. 또는 초기화.
      }
    } else {
      // 1번 탭했을 때 (아직 2번 미만)
      _tapTempoResetTimer = Timer(_tapTempoTimeout, () {
        if (_tapTimestamps.isNotEmpty &&
            _tapTimestamps.length < _minTapsForBpm) {
          // 타임아웃 시 메시지 표시 안 함 (사용자가 다음 탭을 기다릴 수 있도록)
        }
        if (mounted)
          setState(() {
            _tapTimestamps.clear();
          }); // 타임아웃 시 초기화
      });
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final defaultBorderRadius = theme.radius;
    final bpmIndicatorScale = _beatHighlighter ? 1.08 : 1.0;
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
                ? theme.colorScheme.primary.withOpacity(0.35) // 비트 시 색상 더 진하게
                : bpmDisplayCardColor);
    final bpmTextColor =
        _isLoadingSong
            ? theme.colorScheme.mutedForeground
            : (_bpmChangedByTap
                ? theme.colorScheme.primary
                : (_beatHighlighter
                    ? theme.colorScheme.primary
                    : theme.colorScheme.foreground));

    final currentBeatIntervalMs =
        (60000 / (_currentManualBpm > 0 ? _currentManualBpm : 60)).round();
    final bpmAnimationDuration = Duration(
      milliseconds: (currentBeatIntervalMs / 3).round().clamp(50, 300),
    ); // 비트 간격의 1/3, 최소 50ms 최대 300ms

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
              _isTimerRunning || _isLoadingSong
                  ? null
                  : () => _changeBpmToPreset(presetBpm),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        title: Text(
          '리듬농부 메이트',
          style: theme.textTheme.h4.copyWith(
            color: theme.colorScheme.primaryForeground,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: LayoutBuilder(
            builder: (context, constraints) {
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
                    if (!_isTimerRunning && !_isLoadingSong)
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
                              _isLoadingSong
                                  ? null
                                  : (Song? value) {
                                    if (value != null) _onSongChanged(value);
                                  },
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        buildBpmPresetButton('느리게', slowBpm),
                        buildBpmPresetButton('보통', normalBpm),
                        buildBpmPresetButton('빠르게', fastBpm),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          iconSize: 30,
                          color: theme.colorScheme.foreground,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          splashRadius: 24,
                          onPressed:
                              _isTimerRunning ||
                                      _isLoadingSong ||
                                      _currentManualBpm <= 30
                                  ? null
                                  : () => _changeBpm(-5),
                        ),
                        Expanded(
                          child: AnimatedContainer(
                            duration: bpmAnimationDuration,
                            curve: Curves.elasticOut,
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
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          iconSize: 30,
                          color: theme.colorScheme.foreground,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          splashRadius: 24,
                          onPressed:
                              _isTimerRunning ||
                                      _isLoadingSong ||
                                      _currentManualBpm >= 240
                                  ? null
                                  : () => _changeBpm(5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
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
                        onPressed:
                            _isTimerRunning || _isLoadingSong
                                ? null
                                : _handleTapForBpm,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      tween: Tween<double>(
                        begin: _progressPercent * 100,
                        end: _isLoadingSong ? 0 : _progressPercent * 100,
                      ),
                      builder: (context, value, child) {
                        return ShadProgress(
                          value: value,
                          minHeight: 12,
                          color: theme.colorScheme.primary,
                          backgroundColor: theme.colorScheme.muted,
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        _isLoadingSong
                            ? '로딩 중...'
                            : '진행도: ${(_progressPercent * 100).toStringAsFixed(0)}%',
                        style: theme.textTheme.small.copyWith(
                          color: theme.colorScheme.mutedForeground,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color:
                            _isLoadingSong
                                ? theme.colorScheme.muted
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
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                child: Text(
                                  _isPlaying ? '일시정지' : '재생',
                                  style: theme.textTheme.p.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                onPressed:
                                    _isLoadingSong || _audioDuration == null
                                        ? null
                                        : () {
                                          if (_isPlaying)
                                            _audioPlayer.pause();
                                          else {
                                            _audioPlayer.setSpeed(
                                              _currentPlaybackSpeed > 0
                                                  ? _currentPlaybackSpeed
                                                  : 1.0,
                                            );
                                            _audioPlayer.play();
                                            if (!_isTimerRunning)
                                              _restartBpmTimer();
                                          }
                                        },
                              ),
                              ShadButton.ghost(
                                icon: Padding(
                                  padding: const EdgeInsets.only(right: 4.0),
                                  child: Icon(
                                    Icons.stop_circle,
                                    size: 24,
                                    color: theme.colorScheme.destructive,
                                  ),
                                ),
                                child: Text(
                                  '정지',
                                  style: theme.textTheme.p.copyWith(
                                    color: theme.colorScheme.destructive,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                onPressed:
                                    _isLoadingSong || _audioDuration == null
                                        ? null
                                        : () {
                                          _audioPlayer.stop();
                                          _audioPlayer.seek(Duration.zero);
                                        },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    ShadButton(
                      size: ShadButtonSize.lg,
                      child: Text(
                        _isLoadingSong
                            ? '노래 로딩 중...'
                            : (_isTimerRunning ? '작업 중지' : '작업 시작'),
                        style: theme.textTheme.large.copyWith(
                          color:
                              _isTimerRunning
                                  ? theme.colorScheme.destructiveForeground
                                  : theme.colorScheme.primaryForeground,
                        ),
                      ),
                      onPressed:
                          _isLoadingSong
                              ? null
                              : () {
                                if (_isTimerRunning) {
                                  _stopTimers();
                                } else {
                                  if (_audioDuration == null) {
                                    if (mounted)
                                      ShadToaster.of(context).show(
                                        ShadToast(
                                          title: const Text('오류'),
                                          description: const Text(
                                            '음악 정보를 로드 중입니다.',
                                          ),
                                        ),
                                      );
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
                                        _remainingTime = Duration(
                                          seconds:
                                              (_audioDuration!.inSeconds /
                                                      (_currentPlaybackSpeed > 0
                                                          ? _currentPlaybackSpeed
                                                          : 1.0))
                                                  .round(),
                                        );
                                        _progressPercent = 0.0;
                                        _updateTimerText();
                                      });
                                  }
                                  _startTimers();
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
}
