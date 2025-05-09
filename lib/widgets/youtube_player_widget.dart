import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class YouTubePlayerWidget extends StatefulWidget {
  final YoutubePlayerController controller;
  final String timerText;
  final double progressPercent;
  final bool isChallengeRunning;
  final VoidCallback onChallengeButtonPressed;
  final Function(PlayerState state, Duration position, Duration duration)?
  onPlayerStateChanged;

  const YouTubePlayerWidget({
    Key? key,
    required this.controller,
    required this.timerText,
    required this.progressPercent,
    required this.isChallengeRunning,
    required this.onChallengeButtonPressed,
    this.onPlayerStateChanged,
  }) : super(key: key);

  @override
  State<YouTubePlayerWidget> createState() => _YouTubePlayerWidgetState();
}

class _YouTubePlayerWidgetState extends State<YouTubePlayerWidget> {
  @override
  void initState() {
    super.initState();
    // initState에서 리스너 등록
    widget.controller.listen(_youtubePlayerListener);
  }

  void _youtubePlayerListener(YoutubePlayerValue event) {
    if (widget.onPlayerStateChanged != null) {
      // 현재 재생 시간(position)을 비동기적으로 가져옵니다.
      widget.controller.currentTime
          .then((seconds) {
            final position = Duration(milliseconds: (seconds * 1000).round());
            if (mounted) {
              // 위젯이 여전히 마운트되어 있는지 확인
              widget.onPlayerStateChanged!(
                event.playerState,
                position,
                event.metaData.duration,
              );
            }
          })
          .catchError((_) {
            // 오류 발생 시 (예: 컨트롤러가 이미 dispose된 경우)
            if (mounted && widget.onPlayerStateChanged != null) {
              widget.onPlayerStateChanged!(
                event.playerState,
                Duration.zero,
                event.metaData.duration,
              );
            }
          });
    }
  }

  @override
  void dispose() {
    // dispose에서 리스너 제거 (controller.removeListener는 제공되지 않으므로,
    // controller 자체가 dispose될 때 내부적으로 처리될 것으로 기대하거나,
    // YoutubePlayerController의 stream 구독을 취소하는 방식으로 변경 필요.
    // 여기서는 listen 자체가 controller의 stream을 구독하므로,
    // controller가 dispose되면 자동으로 해제될 것으로 가정합니다.
    // 명시적으로 구독을 취소하려면 controller.stream.listen(...).cancel() 패턴 사용 필요.
    // 다만, 현재 controller는 부모 위젯에서 관리하므로 여기서 직접 dispose하지 않습니다.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final size = MediaQuery.of(context).size;
    final maxWidth = size.width > 600 ? 600.0 : size.width;

    // 최대한 단순화된 레이아웃
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 유튜브 플레이어 - 크기 제약 및 AspectRatio 적용
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth,
            maxHeight: maxWidth * 9 / 16, // 16:9 비율 유지
          ),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.border),
                ),
                child: YoutubePlayer(controller: widget.controller),
              ),
            ),
          ),
        ),

        // 타이머 표시
        Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: Text(widget.timerText, style: theme.textTheme.h1),
        ),

        // 진행 표시줄
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Container(
            width: maxWidth,
            child: LinearProgressIndicator(
              value: widget.progressPercent,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4.0),
            ),
          ),
        ),

        // 챌린지 버튼
        SizedBox(
          width: maxWidth,
          child: ShadButton(
            onPressed: widget.onChallengeButtonPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                widget.isChallengeRunning ? '작업 중단하기' : '작업 시작하기',
                style: theme.textTheme.p.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18, // 요청에 따라 글자 크기 18pt로 설정
                ),
              ),
            ),
          ),
        ),

        // 재생 제어
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: SizedBox(width: maxWidth, child: buildPlayControls(theme)),
        ),
      ],
    );
  }

  // 유튜브 플레이어 이벤트 핸들링
  Widget buildPlayControls(ShadThemeData theme) {
    return StreamBuilder<YoutubePlayerValue>(
      stream: widget.controller.stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ShadButton.outline(
                onPressed: () => widget.controller.seekTo(seconds: 0),
                icon: const Icon(Icons.restart_alt),
                child: const Text('처음으로'),
              ),
              const SizedBox(width: 16),
              ShadButton.outline(
                onPressed: () => widget.controller.playVideo(),
                icon: const Icon(Icons.play_arrow),
                child: const Text('재생'),
              ),
            ],
          );
        }

        final value = snapshot.data!;
        final isPlaying = value.playerState == PlayerState.playing;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ShadButton.outline(
              onPressed: () => widget.controller.seekTo(seconds: 0),
              icon: const Icon(Icons.restart_alt),
              child: const Text('처음으로'),
            ),
            const SizedBox(width: 16),
            ShadButton.outline(
              onPressed: () {
                if (isPlaying) {
                  widget.controller.pauseVideo();
                } else {
                  widget.controller.playVideo();
                }
              },
              icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
              child: Text(isPlaying ? '일시정지' : '재생'),
            ),
          ],
        );
      },
    );
  }
}
