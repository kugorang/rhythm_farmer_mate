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
                          : currentMode == ThemeMode.dark
                          ? ThemeMode.system
                          : ThemeMode.light;
                },
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: theme.colorScheme.card,
            child: ListTile(
              title: Text(category.title, style: theme.textTheme.large),
              subtitle: Text(category.description, style: theme.textTheme.p),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                if (category.type == SongCategoryType.userRegistered) {
                  _showAddSongDialog();
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => MyHomePage(
                            selectedCategoryType: category.type,
                            userSongs: [],
                          ),
                    ),
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }
}
