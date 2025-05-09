import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:file_picker/file_picker.dart';
// import 'dart:io'; // 웹에서는 dart:io 사용 불가, 웹에서는 path만 사용
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../models/song_category.dart';
import '../models/song.dart';
import './my_home_page.dart'; // show PlayMode 제거 또는 MyHomePage 추가
import '../my_app.dart'; // themeModeNotifier 접근
import '../services/user_song_service.dart'; // UserSongService import
// import '../widgets/song_selection_widget.dart'; // 이 화면에서 직접 ListView 사용

class CategorySelectionScreen extends StatefulWidget {
  const CategorySelectionScreen({super.key});

  @override
  State<CategorySelectionScreen> createState() =>
      _CategorySelectionScreenState();
}

class _CategorySelectionScreenState extends State<CategorySelectionScreen> {
  final UserSongService _userSongService = UserSongService();
  List<Song> _userRegisteredSongs = [];
  List<Song> _fullSongList = []; // 기본 제공 곡 목록 + 사용자 등록 곡
  SongCategoryType? _selectedCategoryType;
  final _youtubeUrlController = TextEditingController();
  final _bpmController = TextEditingController(); // BPM 입력용 컨트롤러
  // PlayMode _defaultPlayMode = PlayMode.normal; // 삭제 (재생 화면에서 선택)
  // Map<String, PlayMode> _songPlayModes = {}; // 삭제 (재생 화면에서 선택)

  // 기본 제공 곡 목록 (실제 앱에서는 별도 데이터 소스에서 관리하는 것이 좋음)
  final List<Song> _baseSongList = [
    Song(
      filePath: 'assets/audio/emart_original.mp3',
      title: '이마트 로고송',
      bpm: 100,
      categoryType: SongCategoryType.modernLaborSong,
    ),
    Song(
      filePath: 'assets/audio/se0101.mp3',
      title: '논삶는소리 (강원 홍천군)',
      bpm: 69,
      categoryType: SongCategoryType.traditionalNongyo1,
      subCategory: '논고르기',
    ),
    Song(
      filePath: 'assets/audio/se0102.mp3',
      title: '논고르는소리 (제주 서귀포시)',
      bpm: 93,
      categoryType: SongCategoryType.traditionalNongyo1,
      subCategory: '논고르기',
    ),
    Song(
      filePath: 'assets/audio/se0103.mp3',
      title: '모찌는소리-"얼른 하더니 한 춤" (강원 양양군)',
      bpm: 70,
      categoryType: SongCategoryType.traditionalNongyo1,
      subCategory: '모찌기',
    ),
    Song(
      filePath: 'assets/audio/se0104.mp3',
      title: '모찌는소리-"뭉치세 제치세" (충북 진천군)',
      bpm: 76,
      categoryType: SongCategoryType.traditionalNongyo1,
      subCategory: '모찌기',
    ),
    Song(
      filePath: 'assets/audio/se0201.mp3',
      title: '논매는소리-"헤헤 곯었네" (경기 안성군)',
      bpm: 52,
      categoryType: SongCategoryType.traditionalNongyo2,
      subCategory: '논매기(1)',
    ),
    Song(
      filePath: 'assets/audio/se0202.mp3',
      title: '논매는소리-대허리 (경기 이천군)',
      bpm: 115,
      categoryType: SongCategoryType.traditionalNongyo2,
      subCategory: '논매기(1)',
    ),
    Song(
      filePath: 'assets/audio/se0203.mp3',
      title: '논매는소리-오독떼기 (강원 양양군)',
      bpm: 107,
      categoryType: SongCategoryType.traditionalNongyo2,
      subCategory: '논매기(1)',
    ),
    Song(
      filePath: 'assets/audio/se0204.mp3',
      title: '논매는소리-"얼카 덩어리" (충남 홍성군)',
      bpm: 62,
      categoryType: SongCategoryType.traditionalNongyo2,
      subCategory: '논매기(1)',
    ),
    Song(
      filePath: 'assets/audio/se0301.mp3',
      title: '논매는소리-긴소리/들래기소리 (전남 무안군)',
      bpm: 66,
      categoryType: SongCategoryType.traditionalNongyo3,
      subCategory: '논매기(2)',
    ),
    Song(
      filePath: 'assets/audio/se0302.mp3',
      title: '논매는소리-소오니소리 (경북 구미시)',
      bpm: 55,
      categoryType: SongCategoryType.traditionalNongyo3,
      subCategory: '논매기(2)',
    ),
    Song(
      filePath: 'assets/audio/se0303.mp3',
      title: '논매는소리 (경북 예천군)',
      bpm: 78,
      categoryType: SongCategoryType.traditionalNongyo3,
      subCategory: '논매기(2)',
    ),
    Song(
      filePath: 'assets/audio/se0304.mp3',
      title: '농사장원례소리-애롱대롱 (전남 나주군)',
      bpm: 91,
      categoryType: SongCategoryType.traditionalNongyo3,
      subCategory: '기타',
    ),
    Song(
      filePath: 'assets/audio/se0401.mp3',
      title: '밭가는소리 (강원 홍천군)',
      bpm: 132,
      categoryType: SongCategoryType.traditionalNongyo4,
      subCategory: '밭갈이',
    ),
    Song(
      filePath: 'assets/audio/se0402.mp3',
      title: '밭일구는소리(따비질) (제주 북제주군)',
      bpm: 72,
      categoryType: SongCategoryType.traditionalNongyo4,
      subCategory: '밭갈이',
    ),
    Song(
      filePath: 'assets/audio/se0403.mp3',
      title: '밭고르는소리(곰방메질) (제주 북제주군)',
      bpm: 64,
      categoryType: SongCategoryType.traditionalNongyo4,
      subCategory: '밭갈이',
    ),
    Song(
      filePath: 'assets/audio/se0404.mp3',
      title: '밭밟는소리 (제주 북제주군)',
      bpm: 69,
      categoryType: SongCategoryType.traditionalNongyo4,
      subCategory: '밭갈이',
    ),
    // Song(filePath: 'assets/audio/tick.mp3', title: '메트로놈 틱', bpm: 0, categoryType: SongCategoryType.modernLaborSong), // 메트로놈 삭제로 제거
  ];

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    final userSongs = await _userSongService.getUserSongs();
    if (mounted) {
      setState(() {
        _userRegisteredSongs = userSongs;
        _fullSongList = [..._baseSongList, ..._userRegisteredSongs];
        // _songPlayModes 초기화 로직 삭제
      });
    }
  }

  Future<void> _showAddSongDialog() async {
    return showShadDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return ShadDialog(
          title: const Text('내 노래 추가 방식 선택'),
          actions: <Widget>[
            ShadButton.ghost(
              child: const Text('취소'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ShadButton(
                width: double.infinity,
                child: const Text('로컬 오디오 파일 선택 (웹은 경로만 저장)'),
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
              onPressed: () => Navigator.of(context).pop(),
            ),
            ShadButton(
              child: const Text('추가'),
              onPressed: () async {
                final url = _youtubeUrlController.text;
                if (url.isNotEmpty) {
                  try {
                    final videoId = YoutubePlayerController.convertUrlToId(url);
                    if (videoId != null) {
                      Navigator.of(context).pop();
                      await _addYoutubeSong(videoId, url);
                    } else {
                      if (mounted)
                        ShadToaster.of(context).show(
                          const ShadToast(
                            description: Text('잘못된 YouTube URL입니다.'),
                          ),
                        );
                    }
                  } catch (e) {
                    if (mounted)
                      ShadToaster.of(context).show(
                        const ShadToast(description: Text('URL 분석 중 오류 발생')),
                      );
                  }
                } else {
                  if (mounted)
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

  Future<void> _addYoutubeSong(String videoId, String originalUrl) async {
    final int userBpm =
        await _showBpmInputDialog() ?? 120; // BPM 입력 받기 (기본값 120)
    final title = await _fetchYoutubeTitle(videoId) ?? 'YouTube - $videoId';
    final newSong = Song(
      youtubeVideoId: videoId,
      title: title,
      bpm: userBpm,
      categoryType: SongCategoryType.userRegistered,
    );
    await _userSongService.addUserSong(newSong);
    await _loadSongs();
    if (mounted)
      ShadToaster.of(
        context,
      ).show(ShadToast(description: Text('${newSong.title} 추가됨')));
  }

  // 간단한 YouTube 제목 가져오기 예시 (실제로는 http 패키지 등 사용 및 오류 처리 필요)
  Future<String?> _fetchYoutubeTitle(String videoId) async {
    // 웹에서는 CORS 문제로 직접 API 호출이 어려울 수 있으므로, 이는 예시입니다.
    // 실제 구현 시에는 서버 프록시 또는 다른 방법을 고려해야 할 수 있습니다.
    if (kIsWeb) return 'YouTube Video'; // 웹에서는 단순 반환
    try {
      // final response = await http.get(Uri.parse('https://www.youtube.com/oembed?url=http://www.youtube.com/watch?v=$videoId&format=json'));
      // if (response.statusCode == 200) {
      //   final data = jsonDecode(response.body);
      //   return data['title'];
      // }
      return 'YouTube - $videoId'; // 임시
    } catch (e) {
      return null;
    }
  }

  Future<void> _pickAndAddUserSongFromFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
      );

      if (result != null) {
        final fileName = result.files.single.name;
        // 웹에서는 result.files.single.path가 null일 수 있으므로, 이름만 사용하거나 다른 방식 고려
        final filePath = kIsWeb ? fileName : result.files.single.path;

        if (filePath != null) {
          final int userBpm = await _showBpmInputDialog() ?? 120; // BPM 입력 받기
          final newSong = Song(
            filePath: filePath,
            title: fileName.split('.').first,
            bpm: userBpm,
            categoryType: SongCategoryType.userRegistered,
          );
          await _userSongService.addUserSong(newSong);
          await _loadSongs();
          if (mounted)
            ShadToaster.of(
              context,
            ).show(ShadToast(description: Text('${newSong.title} 추가됨')));
        } else {
          if (mounted)
            ShadToaster.of(
              context,
            ).show(const ShadToast(description: Text('파일 경로를 가져올 수 없습니다.')));
        }
      } else {
        if (mounted)
          ShadToaster.of(
            context,
          ).show(const ShadToast(description: Text('파일이 선택되지 않았습니다.')));
      }
    } catch (e) {
      if (mounted)
        ShadToaster.of(
          context,
        ).show(const ShadToast(description: Text('파일을 불러오는 중 오류가 발생했습니다.')));
    }
  }

  // BPM 입력 다이얼로그 메소드 추가
  Future<int?> _showBpmInputDialog() async {
    _bpmController.clear();
    return showShadDialog<int>(
      context: context,
      builder: (context) {
        return ShadDialog(
          title: const Text('노래 BPM 입력 (숫자만)'),
          child: ShadInput(
            controller: _bpmController,
            keyboardType: TextInputType.number,
            placeholder: const Text('예: 120'),
          ),
          actions: [
            ShadButton.ghost(
              child: const Text('취소'),
              onPressed: () => Navigator.of(context).pop(null),
            ),
            ShadButton(
              child: const Text('확인'),
              onPressed: () {
                final bpm = int.tryParse(_bpmController.text);
                Navigator.of(context).pop(bpm);
              },
            ),
          ],
        );
      },
    );
  }

  // 사용자 등록 곡 관리 다이얼로그
  Future<void> _showUserSongManagementDialog() async {
    // _loadSongs를 호출하여 최신 사용자 곡 목록을 가져올 수 있지만, 현재 _userRegisteredSongs 사용
    // await _loadSongs(); // 필요시 호출
    return showShadDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          // 다이얼로그 내부에서 setState를 사용하기 위해
          builder: (context, setDialogState) {
            return ShadDialog(
              title: const Text('내가 등록한 노동요 관리'),
              description: Text('총 ${_userRegisteredSongs.length}곡'),
              child: SizedBox(
                width: double.maxFinite,
                height: MediaQuery.of(context).size.height * 0.5, // 높이 조절
                child:
                    _userRegisteredSongs.isEmpty
                        ? const Center(child: Text('등록된 노래가 없습니다.'))
                        : ListView.builder(
                          itemCount: _userRegisteredSongs.length,
                          itemBuilder: (ctx, index) {
                            final song = _userRegisteredSongs[index];
                            return ListTile(
                              title: Text(song.title),
                              subtitle: Text(
                                song.filePath ?? song.youtubeVideoId ?? '정보 없음',
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.redAccent,
                                ),
                                tooltip: '삭제',
                                onPressed: () async {
                                  bool? confirmed = await showShadDialog<bool>(
                                    context: context,
                                    builder:
                                        (context) => ShadDialog(
                                          title: const Text('삭제 확인'),
                                          description: Text(
                                            '\'${song.title}\' 노래를 삭제하시겠습니까?',
                                          ),
                                          actions: [
                                            ShadButton.ghost(
                                              child: const Text('취소'),
                                              onPressed:
                                                  () => Navigator.of(
                                                    context,
                                                  ).pop(false),
                                            ),
                                            ShadButton.destructive(
                                              child: const Text('삭제'),
                                              onPressed:
                                                  () => Navigator.of(
                                                    context,
                                                  ).pop(true),
                                            ),
                                          ],
                                        ),
                                  );
                                  if (confirmed == true) {
                                    await _userSongService.deleteUserSong(song);
                                    await _loadSongs(); // 전체 목록 및 현재 화면 다시 로드
                                    setDialogState(() {}); // 다이얼로그 내부 UI 갱신
                                    if (mounted)
                                      ShadToaster.of(context).show(
                                        ShadToast(
                                          description: Text(
                                            '${song.title} 삭제됨',
                                          ),
                                        ),
                                      );
                                  }
                                },
                              ),
                            );
                          },
                        ),
              ),
              actions: [
                ShadButton(
                  child: const Text('닫기'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _youtubeUrlController.dispose();
    _bpmController.dispose(); // 컨트롤러 해제 추가
    super.dispose();
  }

  // Widget _buildPlayModeToggle(Song song) { ... } // 이 메소드는 재생 화면으로 이동

  @override
  Widget build(BuildContext context) {
    final categories = SongCategory.getCategories();
    final theme = ShadTheme.of(context);

    List<Song> displayedSongs =
        _selectedCategoryType == null
            ? _fullSongList
            : _fullSongList
                .where((song) => song.categoryType == _selectedCategoryType)
                .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '노동요 선택하기',
          style: theme.textTheme.h4.copyWith(
            color: theme.colorScheme.primaryForeground,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: theme.colorScheme.primary,
        actions: [
          Tooltip(
            message: '내가 등록한 노동요 관리',
            child: ShadButton.ghost(
              icon: const Icon(
                Icons.playlist_play_rounded,
                color: Colors.white,
              ),
              onPressed: _showUserSongManagementDialog,
            ),
          ),
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Wrap(
              spacing: 12.0,
              runSpacing: 12.0,
              alignment: WrapAlignment.center,
              children: [
                ShadButton(
                  size: ShadButtonSize.sm,
                  variant:
                      _selectedCategoryType == null
                          ? ShadButtonVariant.primary
                          : ShadButtonVariant.outline,
                  onPressed: () {
                    setState(() {
                      _selectedCategoryType = null;
                    });
                  },
                  child: const Text('전체', style: TextStyle(fontSize: 14)),
                ),
                ...categories.map((category) {
                  final isSelected = _selectedCategoryType == category.type;
                  return ShadButton(
                    size: ShadButtonSize.sm,
                    variant:
                        isSelected
                            ? ShadButtonVariant.primary
                            : ShadButtonVariant.outline,
                    onPressed: () {
                      setState(() {
                        _selectedCategoryType = category.type;
                      });
                    },
                    child: Text(
                      category.title,
                      style: const TextStyle(fontSize: 14),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child:
                displayedSongs.isEmpty
                    ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          _selectedCategoryType == null && _fullSongList.isEmpty
                              ? '등록된 노동요가 없습니다. \n하단의 \'내 노동요 추가\' 버튼으로 노래를 등록해주세요.'
                              : (_selectedCategoryType == null
                                  ? (_fullSongList.isEmpty
                                      ? '노래가 없습니다. 먼저 추가해주세요.'
                                      : '모든 노동요 목록입니다.')
                                  : '이 카테고리에는 곡이 없습니다.'),
                          style: theme.textTheme.p.copyWith(height: 1.5),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
                      itemCount: displayedSongs.length,
                      itemBuilder: (context, index) {
                        final song = displayedSongs[index];
                        // PlayMode currentSongPlayMode = _songPlayModes[song.title] ?? _defaultPlayMode; // 재생 모드 선택 UI 제거
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            leading: Icon(
                              song.youtubeVideoId != null
                                  ? Icons.smart_display_rounded
                                  : Icons.music_note_rounded,
                              color: theme.colorScheme.primary,
                              size: 36,
                            ),
                            title: Text(
                              song.title,
                              style: theme.textTheme.p.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 17,
                              ),
                            ),
                            // subtitle: Text('BPM: ${song.bpm}', style: theme.textTheme.small), // BPM 표시 제거
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.play_circle_fill_rounded,
                                size: 32,
                              ),
                              color: theme.colorScheme.primary,
                              tooltip: '이 노래 재생하기',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => MyHomePage(
                                          selectedSong: song,
                                          // initialPlayMode는 MyHomePage에서 기본값(normal) 사용 또는 재생 화면에서 선택
                                        ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton: ShadButton(
        size: ShadButtonSize.lg,
        onPressed: _showAddSongDialog,
        icon: const Padding(
          padding: EdgeInsets.only(right: 8.0),
          child: Icon(Icons.add_rounded, size: 24),
        ),
        child: const Text(
          '내 노동요 추가',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
