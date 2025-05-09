import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../models/song.dart';
import '../models/song_category.dart';

class SongSelectionWidget extends StatefulWidget {
  final List<Song> songList;
  final Song selectedSong;
  final bool isLoading;
  final bool isChallengeRunning;
  final Function(Song?) onSongChanged;
  final SongCategoryType? initialFilterCategory;

  const SongSelectionWidget({
    super.key,
    required this.songList,
    required this.selectedSong,
    required this.isLoading,
    required this.isChallengeRunning,
    required this.onSongChanged,
    this.initialFilterCategory,
  });

  @override
  State<SongSelectionWidget> createState() => _SongSelectionWidgetState();
}

class _SongSelectionWidgetState extends State<SongSelectionWidget> {
  SongCategoryType? _filterCategory;
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _filterCategory = widget.initialFilterCategory;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final canInteract = !widget.isChallengeRunning && !widget.isLoading;

    if (widget.isChallengeRunning) {
      // 챌린지 중에는 현재 선택된 곡 제목만 표시
      return Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: ShadCard(
          title: Text(
            '현재 작업중인 노동요',
            style: theme.textTheme.muted.copyWith(fontSize: 12),
          ),
          description: Text(
            widget.selectedSong.title,
            style: theme.textTheme.p,
          ),
        ),
      );
    }

    // 필터링 및 검색 적용
    final List<Song> filteredSongs =
        widget.songList.where((song) {
          final matchesCategory =
              _filterCategory == null || song.categoryType == _filterCategory;
          final matchesSearch =
              _searchText.isEmpty ||
              song.title.toLowerCase().contains(_searchText.toLowerCase());
          return matchesCategory && matchesSearch;
        }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 제목과 필터 컨트롤
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '노동요 목록',
              style: theme.textTheme.h4.copyWith(fontWeight: FontWeight.bold),
            ),
            buildCategoryFilter(theme),
          ],
        ),

        // 검색창 추가
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: TextFormField(
            decoration: InputDecoration(
              hintText: '노래 검색...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 12.0,
                horizontal: 16.0,
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchText = value;
              });
            },
          ),
        ),

        // 로딩 중일 때 표시
        if (widget.isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32.0),
              child: CircularProgressIndicator(),
            ),
          )
        // 필터링된 결과가 없을 때 표시
        else if (filteredSongs.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32.0),
            child: Center(
              child: Text(
                '검색 결과가 없습니다',
                style: theme.textTheme.muted.copyWith(fontSize: 16),
              ),
            ),
          )
        // 노래 목록 표시
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredSongs.length,
            itemBuilder: (context, index) {
              final song = filteredSongs[index];
              final isSelected = song.title == widget.selectedSong.title;

              return Card(
                margin: const EdgeInsets.only(bottom: 8.0),
                elevation: isSelected ? 4 : 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color:
                        isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.border,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                color:
                    isSelected
                        ? theme.colorScheme.primary.withOpacity(0.1)
                        : theme.colorScheme.card,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 16.0,
                  ),
                  title: Text(
                    song.title,
                    style: theme.textTheme.p.copyWith(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color:
                          isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.foreground,
                    ),
                  ),
                  subtitle: Text(
                    'BPM: ${song.bpm}',
                    style: theme.textTheme.small,
                  ),
                  trailing: Icon(
                    isSelected
                        ? Icons.play_circle_filled
                        : Icons.play_circle_outline,
                    color: theme.colorScheme.primary,
                    size: 28,
                  ),
                  onTap: canInteract ? () => widget.onSongChanged(song) : null,
                ),
              );
            },
          ),
      ],
    );
  }

  // 카테고리 필터 선택 UI
  Widget buildCategoryFilter(ShadThemeData theme) {
    return DropdownButton<SongCategoryType?>(
      hint: const Text('모든 분류'),
      value: _filterCategory,
      onChanged: (value) {
        setState(() {
          _filterCategory = value;
        });
      },
      underline: Container(height: 1, color: theme.colorScheme.border),
      items: [
        DropdownMenuItem<SongCategoryType?>(
          value: null,
          child: const Text('모든 분류'),
        ),
        DropdownMenuItem<SongCategoryType?>(
          value: SongCategoryType.traditionalNongyo1,
          child: const Text('전통 노동요 1'),
        ),
        DropdownMenuItem<SongCategoryType?>(
          value: SongCategoryType.traditionalNongyo2,
          child: const Text('전통 노동요 2'),
        ),
        DropdownMenuItem<SongCategoryType?>(
          value: SongCategoryType.traditionalNongyo3,
          child: const Text('전통 노동요 3'),
        ),
        DropdownMenuItem<SongCategoryType?>(
          value: SongCategoryType.traditionalNongyo4,
          child: const Text('전통 노동요 4'),
        ),
        DropdownMenuItem<SongCategoryType?>(
          value: SongCategoryType.modernLaborSong,
          child: const Text('현대 노동요'),
        ),
        DropdownMenuItem<SongCategoryType?>(
          value: SongCategoryType.userRegistered,
          child: const Text('내 노동요'),
        ),
      ],
    );
  }
}
