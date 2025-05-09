import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '리듬농부 메이트',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
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
  bool _isPlaying = false;
  final String _currentSongTitle = '논삶는소리 (강원 홍천군)';
  Duration? _audioDuration;

  Timer? _timer;
  Duration _remainingTime = const Duration(seconds: 0);
  String _timerText = '00:00';
  bool _isTimerRunning = false;
  double _progressPercent = 0.0;

  Timer? _bpmTimer;
  final int _currentBpm = 120; // 예시 BPM 값
  bool _beatHighlighter = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _initAudioPlayer();
    _updateTimerText();
  }

  Future<void> _initAudioPlayer() async {
    try {
      await _audioPlayer.setAsset('assets/audio/se0101.mp3');
      _audioPlayer.durationStream.listen((duration) {
        if (mounted) {
          setState(() {
            _audioDuration = duration;
            if (!_isTimerRunning && _audioDuration != null) {
              _remainingTime = _audioDuration!;
              _updateTimerText();
              _updateProgress();
            }
          });
        }
      });
    } catch (e) {
      print("Error loading audio source: $e");
    }

    _audioPlayer.playingStream.listen((playing) {
      if (mounted) {
        setState(() {
          _isPlaying = playing;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _timer?.cancel();
    _bpmTimer?.cancel(); // BPM 타이머 리소스 해제
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
    if (_audioDuration != null && _audioDuration!.inSeconds > 0) {
      final elapsedTime = _audioDuration!.inSeconds - _remainingTime.inSeconds;
      if (mounted) {
        setState(() {
          _progressPercent = elapsedTime / _audioDuration!.inSeconds;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _progressPercent = 0.0;
        });
      }
    }
  }

  void _startTimer() {
    if (_isTimerRunning) return;

    if (_audioDuration != null) {
      _remainingTime = _audioDuration!;
    } else {
      if (_audioDuration == null) {
        print("오디오 정보가 아직 로드되지 않았습니다.");
      }
    }
    _updateTimerText();
    _updateProgress();

    setState(() {
      _isTimerRunning = true;
      _beatHighlighter = false; // 시작 시 초기화
    });
    _audioPlayer.play();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime.inSeconds <= 0) {
        _stopTimer(completed: true);
      } else {
        if (mounted) {
          setState(() {
            _remainingTime = _remainingTime - const Duration(seconds: 1);
            _updateTimerText();
            _updateProgress();
          });
        }
      }
    });

    // BPM 타이머 시작
    final beatInterval = (60000 / _currentBpm).round(); // 밀리초 단위
    _bpmTimer = Timer.periodic(Duration(milliseconds: beatInterval), (timer) {
      if (mounted) {
        setState(() {
          _beatHighlighter = !_beatHighlighter;
        });
      }
    });
  }

  void _stopTimer({bool completed = false}) {
    _timer?.cancel();
    _bpmTimer?.cancel();
    if (mounted) {
      setState(() {
        _isTimerRunning = false;
        _beatHighlighter = false;
        if (completed) {
          _progressPercent = 1.0;
          _remainingTime = Duration.zero;
        } else if (_audioDuration != null) {
          _updateProgress();
        }
      });
    }
    _audioPlayer.pause();
    if (completed) {
      print('작업 완료!');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('챌린지 성공! 잘 하셨어요! 🎉'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
      if (_audioDuration != null) {
        // 작업 완료 후, 다음 시작을 위해 상태 초기화 (선택적)
        // setState(() {
        //   _remainingTime = _audioDuration!;
        //   _progressPercent = 0.0;
        //   _updateTimerText();
        // });
      }
    }
    _updateTimerText();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text(
          '리듬농부 메이트',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0), // 전체 패딩 증가
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 24.0,
                  horizontal: 16.0,
                ), // 타이머 영역 패딩 조정
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(12.0), // 모서리 둥글게
                ),
                child: Center(
                  child: Text(
                    _timerText,
                    style: const TextStyle(
                      fontSize: 60,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ), // 타이머 폰트 크기 및 색상 조정
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Container(
                height: 60, // BPM 표시기 높이 증가
                decoration: BoxDecoration(
                  color:
                      _beatHighlighter
                          ? Colors.amberAccent.shade100
                          : Colors.grey.shade200, // 색상 부드럽게
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Center(
                  child: Text(
                    'BPM: $_currentBpm',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ), // BPM 텍스트 스타일 조정
                  ),
                ),
              ),
              const SizedBox(height: 24),

              LinearProgressIndicator(
                value: _progressPercent,
                minHeight: 25, // 진행 바 높이 증가
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.green.shade600,
                ),
                borderRadius: BorderRadius.circular(12.5), // 진행 바 모서리 둥글게
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  '진행도: ${(_progressPercent * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ), // 진행도 텍스트 스타일 조정
                ),
              ),
              const SizedBox(height: 30),

              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Column(
                  children: [
                    Text(
                      '현재 재생 중: $_currentSongTitle',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18, // 곡 제목 폰트 크기 증가
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // 재생/일시정지 버튼은 타이머와 오디오 상태에 따라 아이콘이 변경되므로 항상 활성화된 것처럼 보임
                        IconButton(
                          icon: Icon(
                            _isPlaying
                                ? Icons.pause_circle_filled
                                : Icons.play_circle_filled,
                            color: Theme.of(context).primaryColor,
                          ),
                          iconSize: 60, // 아이콘 크기 증가
                          onPressed: () {
                            if (_audioDuration == null)
                              return; // 오디오 로드 전에는 동작 안함
                            if (_isPlaying) {
                              _audioPlayer.pause();
                            } else {
                              _audioPlayer.play();
                            }
                          },
                        ),
                        // 정지 버튼 역시 타이머와 오디오 상태와 직접 연동 (타이머 비실행 중에도 누를 수 있도록)
                        IconButton(
                          icon: Icon(
                            Icons.stop_circle_outlined,
                            color: Colors.red.shade700,
                          ),
                          iconSize: 60, // 아이콘 크기 증가
                          onPressed: () {
                            if (_audioDuration == null)
                              return; // 오디오 로드 전에는 동작 안함
                            _audioPlayer.stop();
                            _audioPlayer.seek(Duration.zero);
                            // 만약 타이머가 실행 중이었다면, 타이머도 함께 정지 (선택적, 현재는 타이머는 별도 제어)
                            // if (_isTimerRunning) {
                            //   _stopTimer();
                            // }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 20.0,
                  ), // 버튼 내부 패딩 증가
                  backgroundColor:
                      _isTimerRunning
                          ? Colors.red.shade400
                          : Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white, // 텍스트 색상 명시
                  textStyle: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ), // 버튼 텍스트 스타일 조정
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ), // 버튼 모서리 둥글게
                ),
                onPressed: () {
                  if (_isTimerRunning) {
                    _stopTimer();
                  } else {
                    if (_audioDuration != null &&
                        (_remainingTime.inSeconds == 0 ||
                            _remainingTime != _audioDuration)) {
                      setState(() {
                        _remainingTime = _audioDuration!;
                        _progressPercent = 0.0;
                        _updateTimerText();
                      });
                    }
                    _startTimer();
                  }
                },
                child: Text(
                  _isTimerRunning ? '작업 중지' : '작업 시작',
                  style: const TextStyle(fontSize: 20, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
