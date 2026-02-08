import 'dart:convert';
import '../../base_platform.dart';
import '../../crypto/netease_crypto.dart';
import '../../models/search_response.dart';
import '../../models/lyric_data.dart';
import '../../utils/api_logger.dart';
import '../../../../models/track.dart';
import '../../../../models/song_detail.dart';
import '../../../../models/toplist.dart';
import '../../../audio_quality_service.dart';

/// 网易云音乐平台适配器
class NeteasePlatform extends BasePlatform {
  @override
  String get name => 'netease';

  static const String baseUrl = 'https://music.163.com';
  static const String apiUrl = 'https://music.163.com/weapi';

  @override
  Future<SearchResponse> search(String keyword, {int limit = 20}) async {
    final startTime = DateTime.now();

    try {
      ApiLogger.logInfo(
        platform: name,
        message: '开始搜索',
        data: {'keyword': keyword, 'limit': limit},
      );

      final params = {
        'keywords': keyword,
        'limit': limit.toString(),
        'type': '1', // 1-单曲
        'offset': '0',
      };

      // 使用 Weapi 加密
      final encrypted = NeteaseCrypto.weapi(params);

      final response = await httpClient.post(
        '$apiUrl/search/get',
        body: encrypted,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['code'] == 200) {
          final songs = data['result']['songs'] as List<dynamic>? ?? [];
          final tracks = songs.map((item) => _parseTrack(item)).toList();

          final duration = DateTime.now().difference(startTime);
          ApiLogger.logPerformance(
            platform: name,
            operation: 'search',
            duration: duration,
            metrics: {
              'keyword': keyword,
              'results': tracks.length,
              'total': data['result']['songCount'] ?? 0,
            },
          );

          return SearchResponse(tracks: tracks, total: tracks.length);
        }
      }

      throw Exception('搜索失败: ${response.statusCode}');
    } catch (e, stackTrace) {
      ApiLogger.logError(
        platform: name,
        operation: 'search',
        error: e,
        stackTrace: stackTrace,
      );
      return SearchResponse.empty();
    }
  }

  @override
  Future<SongDetail?> getSongDetail(
    dynamic songId,
    AudioQuality quality,
  ) async {
    try {
      print('🎵 [Netease] 获取歌曲详情: $songId');

      // 1. 获取歌曲基本信息
      final infoParams = {
        'ids': '[$songId]',
        'c': '[{"id":$songId}]',
      };

      final infoEncrypted = NeteaseCrypto.weapi(infoParams);
      final infoResponse = await httpClient.post(
        '$apiUrl/v3/song/detail',
        body: infoEncrypted,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      );

      if (infoResponse.statusCode != 200) {
        throw Exception('获取歌曲信息失败');
      }

      final infoData = json.decode(infoResponse.body);
      final songs = infoData['songs'] as List<dynamic>?;
      if (songs == null || songs.isEmpty) {
        throw Exception('歌曲不存在');
      }
      
      final song = songs[0];

      // 2. 获取播放URL
      final url = await getSongUrl(songId, quality);

      // 3. 获取歌词
      final lyric = await getLyric(songId);

      // 4. 组装返回数据
      return SongDetail(
        id: songId,
        name: song['name'] ?? '',
        pic: song['al']?['picUrl'] ?? '',
        arName: (song['ar'] as List<dynamic>)
            .map((a) => a['name'] as String)
            .join(', '),
        alName: song['al']?['name'] ?? '',
        level: _qualityToLevel(quality),
        size: '0',
        url: url ?? '',
        lyric: lyric?.lyric ?? '',
        tlyric: lyric?.tlyric ?? '',
        source: MusicSource.netease,
      );
    } catch (e) {
      print('❌ [Netease] 获取歌曲详情失败: $e');
      return null;
    }
  }

  @override
  Future<String?> getSongUrl(
    dynamic songId,
    AudioQuality quality,
  ) async {
    try {
      final level = _qualityToLevel(quality);
      
      final params = {
        'ids': '[$songId]',
        'level': level,
        'encodeType': 'flac',
      };

      final encrypted = NeteaseCrypto.weapi(params);
      final response = await httpClient.post(
        '$apiUrl/song/enhance/player/url/v1',
        body: encrypted,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 200 && data['data'] != null) {
          final urls = data['data'] as List<dynamic>;
          if (urls.isNotEmpty) {
            return urls[0]['url'] as String?;
          }
        }
      }

      return null;
    } catch (e) {
      print('❌ [Netease] 获取URL失败: $e');
      return null;
    }
  }

  @override
  Future<LyricData?> getLyric(dynamic songId) async {
    try {
      final params = {'id': songId.toString()};
      final encrypted = NeteaseCrypto.weapi(params);
      
      final response = await httpClient.post(
        '$apiUrl/song/lyric',
        body: encrypted,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return LyricData(
          lyric: data['lrc']?['lyric'] ?? '',
          tlyric: data['tlyric']?['lyric'] ?? '',
        );
      }

      return null;
    } catch (e) {
      print('❌ [Netease] 获取歌词失败: $e');
      return null;
    }
  }

  @override
  Future<List<Toplist>> getToplists() async {
    try {
      final response = await httpClient.post(
        '$apiUrl/toplist',
        body: NeteaseCrypto.weapi({}),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final list = data['list'] as List<dynamic>;
        
        return list.map((item) => _parseToplist(item)).toList();
      }

      return [];
    } catch (e) {
      print('❌ [Netease] 获取榜单失败: $e');
      return [];
    }
  }

  @override
  Future<List<Track>> getPlaylistTracks(String playlistId) async {
    try {
      final params = {
        'id': playlistId,
        'n': '100000',
      };

      final encrypted = NeteaseCrypto.weapi(params);
      final response = await httpClient.post(
        '$apiUrl/v3/playlist/detail',
        body: encrypted,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final tracks = data['playlist']['tracks'] as List<dynamic>;

        return tracks.map((item) => _parseTrack(item)).toList();
      }

      return [];
    } catch (e) {
      print('❌ [Netease] 获取歌单失败: $e');
      return [];
    }
  }

  @override
  Future<List<Track>> getRecommendSongs({int limit = 30}) async {
    final startTime = DateTime.now();

    try {
      ApiLogger.logInfo(
        platform: name,
        message: '获取每日推荐歌曲',
        data: {'limit': limit},
      );

      final params = {
        'limit': limit.toString(),
      };

      // 使用 Eapi 加密
      final encrypted = NeteaseCrypto.eapi(
        '/api/v1/discovery/recommend/songs',
        params,
      );

      final response = await httpClient.post(
        'https://music.163.com/eapi/v1/discovery/recommend/songs',
        body: encrypted,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 200) {
          final songs = data['data']?['dailySongs'] as List<dynamic>? ?? [];
          final tracks = songs.map((item) => _parseTrack(item)).toList();

          final duration = DateTime.now().difference(startTime);
          ApiLogger.logPerformance(
            platform: name,
            operation: 'getRecommendSongs',
            duration: duration,
            metrics: {
              'results': tracks.length,
              'requested': limit,
            },
          );

          return tracks;
        }
      }

      return [];
    } catch (e, stackTrace) {
      ApiLogger.logError(
        platform: name,
        operation: 'getRecommendSongs',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getRecommendPlaylists({int limit = 30}) async {
    final startTime = DateTime.now();

    try {
      ApiLogger.logInfo(
        platform: name,
        message: '获取推荐歌单',
        data: {'limit': limit},
      );

      final params = {
        'limit': limit.toString(),
        'total': 'true',
        'n': '1000',
      };

      final encrypted = NeteaseCrypto.weapi(params);
      final response = await httpClient.post(
        '$apiUrl/personalized/playlist',
        body: encrypted,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 200) {
          final result = data['result'] as List<dynamic>? ?? [];
          final playlists = result.map((item) => {
            'id': item['id'].toString(),
            'name': item['name'] as String,
            'picUrl': item['picUrl'] as String,
            'playCount': item['playCount'] as int? ?? 0,
          }).toList();

          final duration = DateTime.now().difference(startTime);
          ApiLogger.logPerformance(
            platform: name,
            operation: 'getRecommendPlaylists',
            duration: duration,
            metrics: {
              'results': playlists.length,
              'requested': limit,
            },
          );

          return playlists;
        }
      }

      return [];
    } catch (e, stackTrace) {
      ApiLogger.logError(
        platform: name,
        operation: 'getRecommendPlaylists',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  @override
  Future<List<Track>> getPersonalFM() async {
    final startTime = DateTime.now();

    try {
      ApiLogger.logInfo(
        platform: name,
        message: '获取私人FM',
      );

      final encrypted = NeteaseCrypto.weapi({});
      final response = await httpClient.post(
        '$apiUrl/v1/radio/get',
        body: encrypted,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 200) {
          final songs = data['data'] as List<dynamic>? ?? [];
          final tracks = songs.map((item) => _parseTrack(item)).toList();

          final duration = DateTime.now().difference(startTime);
          ApiLogger.logPerformance(
            platform: name,
            operation: 'getPersonalFM',
            duration: duration,
            metrics: {
              'results': tracks.length,
            },
          );

          return tracks;
        }
      }

      return [];
    } catch (e, stackTrace) {
      ApiLogger.logError(
        platform: name,
        operation: 'getPersonalFM',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  // 工具方法

  Track _parseTrack(Map<String, dynamic> item) {
    return Track(
      id: item['id'],
      name: item['name'] ?? '',
      artists: (item['ar'] as List<dynamic>)
          .map((a) => a['name'] as String)
          .join(', '),
      album: item['al']?['name'] ?? '',
      picUrl: item['al']?['picUrl'] ?? '',
      source: MusicSource.netease,
    );
  }

  Toplist _parseToplist(Map<String, dynamic> item) {
    final tracks = (item['tracks'] as List<dynamic>? ?? [])
        .take(100)
        .map((t) => _parseTrack(t))
        .toList();

    return Toplist(
      id: item['id'],
      name: item['name'] ?? '',
      nameEn: item['name'] ?? '',
      coverImgUrl: item['coverImgUrl'] ?? '',
      creator: '',
      trackCount: 0,
      description: '',
      // Remove updateFrequency as it is not in Toplist
      tracks: tracks,
      source: MusicSource.netease,
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
