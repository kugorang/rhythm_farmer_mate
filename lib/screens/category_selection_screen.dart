import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

import '../models/song_category.dart';
import '../models/song.dart';
import './my_home_page.dart';

class CategorySelectionScreen extends StatefulWidget {
  const CategorySelectionScreen({super.key});

  @override
  State<CategorySelectionScreen> createState() =>
      _CategorySelectionScreenState();
}

class _CategorySelectionScreenState extends State<CategorySelectionScreen> {
  List<Song> _userRegisteredSongs = [];

  Future<void> _pickAndAddUserSong() async {
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
      } else {
        if (mounted) {
          ShadToaster.of(context).show(
            ShadToast(
              title: const Text('알림'),
              description: const Text('파일이 선택되지 않았습니다.'),
            ),
          );
        }
      }
    } catch (e) {
      print('파일 선택 오류: $e');
      if (mounted) {
        ShadToaster.of(context).show(
          ShadToast(
            title: const Text('오류'),
            description: const Text('파일을 불러오는 중 오류가 발생했습니다.'),
          ),
        );
      }
    }
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
                  _pickAndAddUserSong();
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => MyHomePage(
                            selectedCategoryType: category.type,
                            userSongs:
                                category.type == SongCategoryType.userRegistered
                                    ? List.from(_userRegisteredSongs)
                                    : [],
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
