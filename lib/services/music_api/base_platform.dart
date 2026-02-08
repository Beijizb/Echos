import '../../models/track.dart';
import '../../models/song_detail.dart';
import '../../models/toplist.dart';
import '../../services/audio_source_service.dart'; // For MusicSource
import '../../services/audio_quality_service.dart'; // For AudioQuality
import 'models/search_response.dart';
import 'models/lyric_data.dart';
import 'http_client.dart';
import '../audio_quality_service.dart';

/// 基础平台适配器抽象类
/// 定义所有音乐平台必须实现的接口
abstract class BasePlatform {
  /// 平台名称
  String get name;

  /// HTTP 客户端
  final MusicApiHttpClient httpClient = MusicApiHttpClient();

  /// 搜索歌曲
  /// 
  /// [keyword] 搜索关键词
  /// [limit] 返回结果数量限制，默认20
  /// 
  /// 返回搜索结果列表
  Future<SearchResponse> search(
    String keyword, {
    int limit = 20,
  });

  /// 获取歌曲详情
  /// 
  /// [songId] 歌曲ID（不同平台类型可能不同）
  /// [quality] 音质要求
  /// 
  /// 返回歌曲详细信息，包括播放URL
  Future<SongDetail?> getSongDetail(
    dynamic songId,
    AudioQuality quality,
  );

  /// 获取歌曲播放URL
  /// 
  /// [songId] 歌曲ID
  /// [quality] 音质要求
  /// 
  /// 返回可播放的URL，失败返回null
  Future<String?> getSongUrl(
    dynamic songId,
    AudioQuality quality,
  );

  /// 获取歌词
  /// 
  /// [songId] 歌曲ID
  /// 
  /// 返回歌词数据（原文和翻译）
  Future<LyricData?> getLyric(dynamic songId);

  /// 获取榜单列表
  /// 
  /// 返回该平台所有榜单
  Future<List<Toplist>> getToplists();

  /// 获取歌单详情
  ///
  /// [playlistId] 歌单ID
  ///
  /// 返回歌单中的所有歌曲
  Future<List<Track>> getPlaylistTracks(String playlistId);

  /// 获取每日推荐歌曲
  ///
  /// 返回每日推荐的歌曲列表
  Future<List<Track>> getRecommendSongs({int limit = 30}) async {
    print('⚠️ [$name] 该平台不支持每日推荐歌曲');
    return [];
  }

  /// 获取推荐歌单
  ///
  /// 返回推荐的歌单列表
  Future<List<Map<String, dynamic>>> getRecommendPlaylists({int limit = 30}) async {
    print('⚠️ [$name] 该平台不支持推荐歌单');
    return [];
  }

  /// 获取私人FM
  ///
  /// 返回私人FM歌曲列表
  Future<List<Track>> getPersonalFM() async {
    print('⚠️ [$name] 该平台不支持私人FM');
    return [];
  }

  /// 平台初始化
  ///
  /// 在首次使用前调用，用于设置cookies、headers等
  Future<void> initialize() async {
    print('🎵 [$name] 平台初始化完成');
  }

  /// 释放资源
  void dispose() {
    httpClient.dispose();
  }
}
