import 'package:hive/hive.dart';
import '../models/song.dart';

class UserSongService {
  static const String _boxName = 'userSongsBox';
  static const String _playlistBoxName = 'playlistSongsBox'; // 플레이리스트용 박스 이름

  // Box<Song> get _userSongsBox => Hive.box<Song>(_boxName);
  // Box가 열려있음을 보장하기 위해 Future<Box<Song>> 형태로 변경
  Future<Box<Song>> get _userSongsBox async {
    if (!Hive.isBoxOpen(_boxName)) {
      return await Hive.openBox<Song>(_boxName);
    }
    return Hive.box<Song>(_boxName);
  }

  // 플레이리스트 박스 getter
  Future<Box<Song>> get _playlistSongsBox async {
    if (!Hive.isBoxOpen(_playlistBoxName)) {
      return await Hive.openBox<Song>(_playlistBoxName);
    }
    return Hive.box<Song>(_playlistBoxName);
  }

  // Song 객체 복사본 생성 (동일한 Song 객체를 여러 Box에 저장하는 오류 방지)
  Song _copySong(Song original) {
    return Song(
      filePath: original.filePath,
      youtubeVideoId: original.youtubeVideoId,
      title: original.title,
      bpm: original.bpm,
      categoryType: original.categoryType,
      subCategory: original.subCategory,
    );
  }

  Future<void> addUserSong(Song song) async {
    try {
      final box = await _userSongsBox;
      // Hive에 객체를 추가할 때는 add() 또는 put()을 사용합니다.
      // add()는 자동 증가하는 정수 키를 사용하고, put()은 지정된 키를 사용합니다.
      print('UserSongService: 노래 추가 시도 - ${song.title}');
      await box.add(song);
      print('UserSongService: 노래 추가 성공 - ${song.title}');
    } catch (e) {
      print('UserSongService 오류: 노래 추가 실패 - ${e.toString()}');
      // 오류 발생 시에도 앱이 계속 작동하도록 처리
    }
  }

  Future<List<Song>> getUserSongs() async {
    try {
      final box = await _userSongsBox;
      final songs = box.values.toList();
      print('UserSongService: ${songs.length}개 노래 로드됨');
      return songs;
    } catch (e) {
      print('UserSongService 오류: 노래 목록 로드 실패 - ${e.toString()}');
      return []; // 오류 시 빈 목록 반환
    }
  }

  Future<void> deleteUserSong(Song songToDelete) async {
    final box = await _userSongsBox;
    // HiveObject를 직접 삭제하려면 해당 객체의 key를 알아야 합니다.
    // Song 객체가 HiveObject를 상속했으므로, songToDelete.key를 사용할 수 있습니다.
    if (songToDelete.isInBox) {
      // 객체가 Box에 있는지 확인 (key가 할당되었는지)
      await box.delete(songToDelete.key);
    }

    // 재생 목록에서도 해당 노래 제거 (filePath 또는 youtubeId 기준으로 일치하는 곡 검색)
    await _removeFromPlaylist(songToDelete);
  }

  Future<void> updateUserSong(Song oldSong, Song newSong) async {
    final box = await _userSongsBox;
    if (oldSong.isInBox) {
      await box.put(oldSong.key, newSong);
    }

    // 플레이리스트에 있는 노래도 업데이트
    await _updateSongInPlaylist(oldSong, newSong);
  }

  // 모든 사용자 노래 삭제 (테스트 또는 초기화용)
  Future<void> deleteAllUserSongs() async {
    final box = await _userSongsBox;
    await box.clear();
  }

  // 플레이리스트 관련 메서드

  // 플레이리스트에 저장된 노래 목록 가져오기
  Future<List<Song>> getPlaylistSongs() async {
    final box = await _playlistSongsBox;
    return box.values.toList();
  }

  // 플레이리스트 저장하기 (기존 내용을 삭제하고 새로 저장)
  Future<void> savePlaylistSongs(List<Song> songs) async {
    final box = await _playlistSongsBox;
    // 박스 초기화 후 새 목록 저장
    await box.clear();
    for (final song in songs) {
      // 반드시 Song 객체 복사본을 생성하여 저장 (Hive 중복 객체 저장 오류 방지)
      await box.add(_copySong(song));
    }
  }

  // 플레이리스트에 노래 추가
  Future<void> addToPlaylist(Song song) async {
    try {
      final box = await _playlistSongsBox;
      // 중복 체크
      final existingSongs =
          box.values
              .where(
                (s) =>
                    (s.filePath != null && s.filePath == song.filePath) ||
                    (s.youtubeVideoId != null &&
                        s.youtubeVideoId == song.youtubeVideoId),
              )
              .toList();

      if (existingSongs.isNotEmpty) {
        print('UserSongService: 이미 재생목록에 존재하는 노래 - ${song.title}');
        return; // 이미 존재하면 추가하지 않음
      }

      // 반드시 Song 객체 복사본을 생성하여 저장 (Hive 중복 객체 저장 오류 방지)
      print('UserSongService: 재생목록에 노래 추가 시도 - ${song.title}');
      await box.add(_copySong(song));
      print('UserSongService: 재생목록에 노래 추가 성공 - ${song.title}');
    } catch (e) {
      print('UserSongService 오류: 재생목록에 노래 추가 실패 - ${e.toString()}');
    }
  }

  // 플레이리스트에서 특정 노래 제거
  Future<void> removeFromPlaylist(Song song) async {
    await _removeFromPlaylist(song);
  }

  // 플레이리스트에서 특정 노래 제거 (필터 기능 헬퍼)
  Future<void> _removeFromPlaylist(Song songToRemove) async {
    final playlistBox = await _playlistSongsBox;
    final List<int> keysToDelete = [];

    // 플레이리스트 내에서 같은 곡 찾기 (filePath 또는 youtubeVideoId 기준)
    for (final entry in playlistBox.toMap().entries) {
      final Song playlistSong = entry.value;
      if ((songToRemove.filePath != null &&
              playlistSong.filePath == songToRemove.filePath) ||
          (songToRemove.youtubeVideoId != null &&
              playlistSong.youtubeVideoId == songToRemove.youtubeVideoId)) {
        keysToDelete.add(entry.key);
      }
    }

    // 찾은 키에 해당하는 항목 삭제
    for (final key in keysToDelete) {
      await playlistBox.delete(key);
    }
  }

  // 플레이리스트 내 곡 업데이트 (필터 기능 헬퍼)
  Future<void> _updateSongInPlaylist(Song oldSong, Song newSong) async {
    final playlistBox = await _playlistSongsBox;
    final Map<int, Song> updatesMap = {};

    // 플레이리스트 내에서 같은 곡 찾기 (filePath 또는 youtubeVideoId 기준)
    for (final entry in playlistBox.toMap().entries) {
      final Song playlistSong = entry.value;
      if ((oldSong.filePath != null &&
              playlistSong.filePath == oldSong.filePath) ||
          (oldSong.youtubeVideoId != null &&
              playlistSong.youtubeVideoId == oldSong.youtubeVideoId)) {
        // 복사본 생성하여 업데이트 맵에 추가
        updatesMap[entry.key] = _copySong(newSong);
      }
    }

    // 찾은 키에 해당하는 항목 업데이트
    for (final entry in updatesMap.entries) {
      await playlistBox.put(entry.key, entry.value);
    }
  }

  // 인덱스로 플레이리스트 항목 제거
  Future<void> removeFromPlaylistAtIndex(int index) async {
    final box = await _playlistSongsBox;
    final songs = box.values.toList();
    if (index >= 0 && index < songs.length) {
      final songKey = box.keyAt(index);
      await box.delete(songKey);
    }
  }

  // 플레이리스트 비우기
  Future<void> clearPlaylist() async {
    final box = await _playlistSongsBox;
    await box.clear();
  }
}
