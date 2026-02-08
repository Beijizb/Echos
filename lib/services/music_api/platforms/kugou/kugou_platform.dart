import 'dart:convert';
import '../../base_platform.dart';
import '../../models/search_response.dart';
import '../../models/lyric_data.dart';
import '../../../../models/track.dart';
import '../../../../models/song_detail.dart';
import '../../../../models/toplist.dart';
import '../../../audio_quality_service.dart';

/// 酷狗音乐平台适配器
class KugouPlatform extends BasePlatform {
  @override
  String get name => 'kugou';

  static const String searchUrl = 'https://songsearch.kugou.com/song_search_v2';

  @override
  Future<SearchResponse> search(String keyword, {int limit = 20}) async {
    try {
      print('🔍 [Kugou] 搜索: $keyword');

      final url = '$searchUrl?keyword=${Uri.encodeComponent(keyword)}'
          '&page=1&pagesize=$limit&userid=0&clientver=&platform=WebFilter'
          '&filter=2&iscorrection=1&privilege_filter=0&area_code=1';

      final response = await httpClient.get(
        url,
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['error_code'] == 0) {
          final lists = data['data']['lists'] as List<dynamic>? ?? [];
          final tracks = lists.map((item) => _parseTrack(item)).toList();

          print('✅ [Kugou] 搜索成功: ${tracks.length} 首');
          return SearchResponse(tracks: tracks, total: tracks.length);
        }
      }

      throw Exception('搜索失败: ${response.statusCode}');
    } catch (e) {
      print('❌ [Kugou] 搜索失败: $e');
      return SearchResponse.empty();
    }
  }

  @override
  Future<SongDetail?> getSongDetail(dynamic songId, AudioQuality quality) async {
    try {
      print('🎵 [Kugou] 获取歌曲详情: $songId');

      // 1. 获取播放URL
      final url = await getSongUrl(songId, quality);
      if (url == null) {
        throw Exception('无法获取播放URL');
      }

      // 2. 获取歌词
      final lyric = await getLyric(songId);

      // 3. 从songId中提取信息
      final hash = songId is Map ? songId['hash'] : songId.toString();

      return SongDetail(
        id: songId,
        name: songId is Map ? songId['name'] ?? '' : '',
        pic: songId is Map ? songId['pic'] ?? '' : '',
        arName: songId is Map ? songId['artists'] ?? '' : '',
        alName: songId is Map ? songId['album'] ?? '' : '',
        level: _qualityToLevel(quality),
        size: '0',
        url: url,
        lyric: lyric?.lyric ?? '',
        tlyric: lyric?.tlyric ?? '',
        source: MusicSource.kugou,
      );
    } catch (e) {
      print('❌ [Kugou] 获取歌曲详情失败: $e');
      return null;
    }
  }

  @override
  Future<String?> getSongUrl(dynamic songId, AudioQuality quality) async {
    try {
      final hash = songId is Map ? songId['hash'] : songId.toString();
      final albumId = songId is Map ? songId['albumId'] ?? '' : '';

      final url = 'https://wwwapi.kugou.com/yy/index.php?r=play/getdata'
          '&hash=$hash&album_id=$albumId&dfid=-&mid=&platid=4&_=${DateTime.now().millisecondsSinceEpoch}';

      final response = await httpClient.get(
        url,
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['err_code'] == 0 && data['data'] != null) {
          final playUrl = data['data']['play_url'];
          if (playUrl != null && playUrl.isNotEmpty) {
            return playUrl;
          }
        }
      }

      return null;
    } catch (e) {
      print('❌ [Kugou] 获取URL失败: $e');
      return null;
    }
  }

  @override
  Future<LyricData?> getLyric(dynamic songId) async {
    try {
      final hash = songId is Map ? songId['hash'] : songId.toString();

      final url = 'https://wwwapi.kugou.com/yy/index.php?r=play/getdata'
          '&hash=$hash&dfid=-&mid=&platid=4&_=${DateTime.now().millisecondsSinceEpoch}';

      final response = await httpClient.get(
        url,
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['err_code'] == 0 && data['data'] != null) {
          return LyricData(
            lyric: data['data']['lyrics'] ?? '',
            tlyric: '',
          );
        }
      }

      return null;
    } catch (e) {
      print('❌ [Kugou] 获取歌词失败: $e');
      return null;
    }
  }

  @override
  Future<List<Toplist>> getToplists() async {
    try {
      final url = 'https://mobilecdnbj.kugou.com/api/v3/rank/list?version=9108&plat=0&showtype=1';

      final response = await httpClient.get(
        url,
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 1) {
          final list = data['data']['info'] as List<dynamic>? ?? [];
          return list.map((item) => _parseToplist(item)).toList();
        }
      }

      return [];
    } catch (e) {
      print('❌ [Kugou] 获取榜单失败: $e');
      return [];
    }
  }

  @override
  Future<List<Track>> getPlaylistTracks(String playlistId) async {
    try {
      final url = 'https://mobilecdnbj.kugou.com/api/v3/special/song'
          '?specialid=$playlistId&page=1&pagesize=100&version=9108&plat=0';

      final response = await httpClient.get(
        url,
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 1) {
          final list = data['data']['info'] as List<dynamic>? ?? [];
          return list.map((item) => _parseTrack(item)).toList();
        }
      }

      return [];
    } catch (e) {
      print('❌ [Kugou] 获取歌单失败: $e');
      return [];
    }
  }

  @override
  Future<List<Track>> getRecommendSongs({int limit = 30}) async {
    try {
      print('🎵 [Kugou] 获取每日推荐歌曲');

      final url = 'https://mobilecdnbj.kugou.com/api/v3/recommend/song'
          '?pagesize=$limit&version=9108&plat=0';

      final response = await httpClient.get(
        url,
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 1) {
          final songs = data['data']?['info'] as List<dynamic>? ?? [];
          final tracks = songs.map((item) => _parseRecommendTrack(item)).toList();

          print('✅ [Kugou] 每日推荐获取成功: ${tracks.length} 首');
          return tracks;
        }
      }

      return [];
    } catch (e) {
      print('❌ [Kugou] 获取每日推荐失败: $e');
      return [];
    }
  }

  Track _parseRecommendTrack(Map<String, dynamic> item) {
    final artistName = item['singername'] ?? '';
    final albumName = item['album_name'] ?? '';

    return Track(
      id: {
        'hash': item['hash'],
        'albumId': item['album_id'] ?? '',
        'name': item['songname'],
        'artists': artistName,
        'album': albumName,
        'pic': '',
      },
      name: item['songname'] ?? '',
      artists: artistName,
      album: albumName,
      picUrl: '',
      source: MusicSource.kugou,
    );
  }

  // 工具方法

  Track _parseTrack(Map<String, dynamic> item) {
    final singers = item['Singers'] as List<dynamic>? ?? [];
    final artistNames = singers.map((s) => s['name'] as String).join(', ');

    final albumName = item['AlbumName'] ?? '';
    final albumId = item['AlbumID'] ?? '';
    
    String picUrl = '';
    if (item['Image'] != null) {
      picUrl = (item['Image'] as String).replaceAll('{size}', '480');
    }

    return Track(
      id: {
        'hash': item['FileHash'],
        'albumId': albumId,
        'name': item['SongName'],
        'artists': artistNames,
        'album': albumName,
        'pic': picUrl,
      },
      name: item['SongName'] ?? '',
      artists: artistNames,
      album: albumName,
      picUrl: picUrl,
      source: MusicSource.kugou,
    );
  }

  Toplist _parseToplist(Map<String, dynamic> item) {
    return Toplist(
      id: item['rankid'],
      name: item['rankname'] ?? '',
      nameEn: item['rankname'] ?? '',
      coverImgUrl: item['imgurl'] ?? '',
      creator: '',
      trackCount: 0,
      description: item['intro'] ?? '',
      // updateFrequency: item['update_frequency'] ?? '',
      tracks: [],
      source: MusicSource.kugou,
    );
  }

  String _qualityToLevel(AudioQuality quality) {
    switch (quality) {
      case AudioQuality.standard:
        return 'standard';
      case AudioQuality.high:
        return 'higher';
      case AudioQuality.exhigh:
        return 'exhigh';
      case AudioQuality.lossless:
        return 'lossless';
      case AudioQuality.hires:
        return 'hires';
      default:
        return 'exhigh';
    }
  }
}
