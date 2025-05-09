import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../models/song_category.dart';
import '../models/song.dart';
import './my_home_page.dart';
import '../my_app.dart';

class CategorySelectionScreen extends StatefulWidget {
  const CategorySelectionScreen({super.key});

  @override
  State<CategorySelectionScreen> createState() =>
      _CategorySelectionScreenState();
}

class _CategorySelectionScreenState extends State<CategorySelectionScreen> {
  final List<Song> _userRegisteredSongs = [];
  final _youtubeUrlController = TextEditingController();

  Future<void> _showAddSongDialog() async {
    return showShadDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return ShadDialog(
          title: const Text('내 노래 추가 방식 선택'),
          actions: <Widget>[
            ShadButton.ghost(
              child: const Text('취소'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ShadButton(
                width: double.infinity,
                child: const Text('로컬 오디오 파일 선택'),
                onPressed: () {
                  Navigator.of(context).pop();
                  _pickAndAddUserSongFromFile();
                },
              ),
              const SizedBox(height: 10),
              ShadButton(
                width: double.infinity,
                child: const Text('YouTube URL 입력'),
                onPressed: () {
                  Navigator.of(context).pop();
                  _showYoutubeUrlInputDialog();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showYoutubeUrlInputDialog() async {
    _youtubeUrlController.clear();
    return showShadDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return ShadDialog(
          title: const Text('YouTube URL 입력'),
          actions: <Widget>[
            ShadButton.ghost(
              child: const Text('취소'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ShadButton(
              child: const Text('추가'),
              onPressed: () {
                final url = _youtubeUrlController.text;
                if (url.isNotEmpty) {
                  try {
                    final videoId = YoutubePlayerController.convertUrlToId(url);
                    if (videoId != null) {
                      Navigator.of(context).pop();
                      _addYoutubeSong(videoId, url);
                    } else {
                      ShadToaster.of(context).show(
                        const ShadToast(
                          description: Text('잘못된 YouTube URL입니다.'),
                        ),
                      );
                    }
                  } catch (e) {
                    ShadToaster.of(context).show(
                      const ShadToast(description: Text('URL 분석 중 오류 발생')),
                    );
                    print("YouTube URL parsing error: $e");
                  }
                } else {
                  ShadToaster.of(
                    context,
                  ).show(const ShadToast(description: Text('URL을 입력해주세요.')));
                }
              },
            ),
          ],
          child: ShadInput(
            controller: _youtubeUrlController,
            placeholder: const Text(
              '예: https://www.youtube.com/watch?v=VIDEO_ID',
            ),
          ),
        );
      },
    );
  }

  void _addYoutubeSong(String videoId, String originalUrl) {
    final newSong = Song(
      youtubeVideoId: videoId,
      title: 'YouTube Video - $videoId',
      bpm: 0,
      categoryType: SongCategoryType.userRegistered,
      filePath: null,
    );
    _addSongToListAndNavigate(newSong);
  }

  Future<void> _pickAndAddUserSongFromFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final fileName = result.files.single.name;
        final newSong = Song(
          filePath: filePath,
          title: fileName.split('.').first,
          bpm: 0,
          categoryType: SongCategoryType.userRegistered,
        );
        _addSongToListAndNavigate(newSong);
      } else {
        if (mounted) {
          ShadToaster.of(context).show(
            const ShadToast(
              title: Text('알림'),
              description: Text('파일이 선택되지 않았습니다.'),
            ),
          );
        }
      }
    } catch (e) {
      print('파일 선택 오류: $e');
      if (mounted) {
        ShadToaster.of(context).show(
          const ShadToast(
            title: Text('오류'),
            description: Text('파일을 불러오는 중 오류가 발생했습니다.'),
          ),
        );
      }
    }
  }

  void _addSongToListAndNavigate(Song newSong) {
    if (mounted) {
      setState(() {
        _userRegisteredSongs.add(newSong);
      });
      ShadToaster.of(context).show(
        ShadToast(
          title: const Text('노래 추가됨'),
          description: Text('${newSong.title} 이(가) 목록에 추가되었습니다.'),
        ),
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => MyHomePage(
                selectedCategoryType: SongCategoryType.userRegistered,
                userSongs: List.from(_userRegisteredSongs),
              ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _youtubeUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = SongCategory.getCategories();
    final theme = ShadTheme.of(context);

    // "내 노동요 등록" 카테고리를 찾아서 분리하거나, FAB에서만 처리하도록 결정
    // 여기서는 categories 리스트에서 제거하고 FAB으로만 기능을 제공하는 것으로 가정
    final mainCategories =
        categories
            .where((cat) => cat.type != SongCategoryType.userRegistered)
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '음악 카테고리 선택',
          style: theme.textTheme.h4.copyWith(
            color: theme.colorScheme.primaryForeground,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: theme.colorScheme.primary,
        actions: [
          ValueListenableBuilder<ThemeMode>(
            valueListenable: themeModeNotifier,
            builder: (context, currentMode, child) {
              return ShadButton.ghost(
                icon: Icon(
                  currentMode == ThemeMode.dark
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                  color: theme.colorScheme.primaryForeground,
                ),
                onPressed: () {
                  themeModeNotifier.value =
                      currentMode == ThemeMode.light
                          ? ThemeMode.dark
                          : ThemeMode.light;
                },
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: mainCategories.length, // userRegistered 제외한 카테고리 수
        itemBuilder: (context, index) {
          final category = mainCategories[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: theme.colorScheme.card,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ), // 패딩 증가
              title: Text(
                category.title,
                style: theme.textTheme.h4.copyWith(fontWeight: FontWeight.bold),
              ), // 폰트 스타일 조정
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  category.description,
                  style: theme.textTheme.p,
                ), // 폰트 스타일 조정
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 20,
                color: theme.colorScheme.primary,
              ), // 아이콘 크기 및 색상
              onTap: () {
                // userRegistered 카테고리 탭 로직은 FAB으로 이동
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => MyHomePage(
                          selectedCategoryType: category.type,
                          userSongs: [], // 사용자 곡은 여기서 전달 안 함
                        ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: ShadButton(
        size: ShadButtonSize.lg,
        onPressed: _showAddSongDialog,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_rounded, size: 24), // 아이콘 크기 약간 조정
            const SizedBox(width: 8),
            const Text(
              '내 노동요 추가',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        // backgroundColor: theme.colorScheme.primary,
        // foregroundColor: theme.colorScheme.primaryForeground,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
