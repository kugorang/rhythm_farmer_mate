import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../models/song_category.dart';
import './my_home_page.dart'; // MyHomePage로 이동하기 위함

class CategorySelectionScreen extends StatelessWidget {
  const CategorySelectionScreen({super.key});

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
                  // TODO: "내가 등록한 노래" 기능 구현 (예: 로컬 파일 선택)
                  ShadToaster.of(context).show(
                    ShadToast(
                      title: const Text('알림'),
                      description: const Text('이 기능은 곧 준비될 예정입니다!'),
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              MyHomePage(selectedCategoryType: category.type),
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
