import 'package:flutter/material.dart'
    hide BorderStyle; // BoxDecoration, Border, BorderRadius는 사용
import 'package:hive_flutter/hive_flutter.dart'; // hive_flutter import
import 'package:path_provider/path_provider.dart'; // path_provider import
import 'package:flutter/foundation.dart' show kIsWeb; // kIsWeb import
import 'package:rhythm_farmer_mate/my_app.dart'; // MyApp import
import './models/song.dart'; // SongAdapter를 위해 import
import './models/song_category.dart'; // SongCategoryTypeAdapter를 위해 import

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Flutter 엔진 바인딩 초기화

  try {
    print("Hive 초기화 시작");
    // Hive 초기화
    if (!kIsWeb) {
      // 웹이 아닐 경우에만 path_provider 사용
      final appDocumentDir = await getApplicationDocumentsDirectory();
      await Hive.initFlutter(appDocumentDir.path);
    } else {
      await Hive.initFlutter(); // 웹에서는 경로 지정 없이 초기화
    }

    // Adapter 등록
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(SongAdapter());
    }

    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(SongCategoryTypeAdapter());
    }

    print("Hive 어댑터 등록 완료");

    // 필요한 Box들 열기 (예: 사용자 노래 목록을 위한 Box)
    final userSongsBox = await Hive.openBox<Song>('userSongsBox');
    print("userSongsBox 열림: ${userSongsBox.isOpen}");

    final playlistSongsBox = await Hive.openBox<Song>('playlistSongsBox');
    print("playlistSongsBox 열림: ${playlistSongsBox.isOpen}");

    print("Hive 초기화 완료");
  } catch (e) {
    print("Hive 초기화 오류: ${e.toString()}");
    // 오류가 발생해도 앱은 계속 실행되게 함
  }

  runApp(const MyApp());
}
