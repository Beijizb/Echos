import 'dart:convert';
import '../../base_platform.dart';
import '../../models/search_response.dart';
import '../../models/lyric_data.dart';
import '../../../../models/track.dart';
import '../../../../models/song_detail.dart';
import '../../../../models/toplist.dart';
import '../../../audio_quality_service.dart';

/// QQ音乐平台适配器
class QQPlatform extends BasePlatform {
  @override
  String get name => 'qq';

  static const String apiUrl = 'https://u.y.qq.com/cgi-bin/musicu.fcg';

  @override
  Future<SearchResponse> search(String keyword, {int limit = 20}) async {
    try {
      print('🔍 [QQ] 搜索: $keyword');

      // 限制最大值为30，避免返回空结果
      final actualLimit = limit > 30 ? 30 : limit;

      final requestData = {
        'comm': {
          'ct': '19',
          'cv': '1859',
          'uin': '0',
        },
        'req_1': {
          'method': 'DoSearchForQQMusicDesktop',
          'module': 'music.search.SearchCgiService',
          'param': {
            'grp': 1,
            'num_per_page': actualLimit,
            'page_num': 1,
            'query': keyword,
            'search_type': 0, // 0=单曲
          },
        },
      };

      final response = await httpClient.post(
        apiUrl,
        body: json.encode(requestData),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['code'] == 0 && data['req_1']?['code'] == 0) {
          final searchResult = data['req_1']['data']['body'];
          final songList = searchResult['song']?['list'] as List<dynamic>? ?? [];
          final tracks = songList.map((item) => _parseTrack(item)).toList();

          print('✅ [QQ] 搜索成功: ${tracks.length} 首');
          return SearchResponse(tracks: tracks, total: tracks.length);
        }
      }

      throw Exception('搜索失败: ${response.statusCode}');
    } catch (e) {
      print('❌ [QQ] 搜索失败: $e');
      return SearchResponse.empty();
    }
  }

  @override
  Future<SongDetail?> getSongDetail(dynamic songId, AudioQuality quality) async {
    try {
      print('🎵 [QQ] 获取歌曲详情: $songId');

      // 1. 获取播放URL
      final url = await getSongUrl(songId, quality);
      if (url == null) {
        throw Exception('无法获取播放URL');
      }

      // 2. 获取歌词
      final lyric = await getLyric(songId);

      // 3. 获取歌曲基本信息（从songId中提取mid）
      final mid = songId is Map ? songId['mid'] : songId.toString();

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
        source: MusicSource.qq,
      );
    } catch (e) {
      print('❌ [QQ] 获取歌曲详情失败: $e');
      return null;
    }
  }

  @override
  Future<String?> getSongUrl(dynamic songId, AudioQuality quality) async {
    try {
      // QQ音乐需要 mid 而不是 id
      final mid = songId is Map ? songId['mid'] : songId.toString();

      final requestData = {
        'comm': {
          'cv': 4747474,
          'ct': 24,
          'format': 'json',
          'inCharset': 'utf-8',
          'outCharset': 'utf-8',
          'notice': 0,
          'platform': 'yqq.json',
          'needNewCode': 1,
          'uin': 0,
          'g_tk_new_20200303': 5381,
          'g_tk': 5381,
        },
        'req_1': {
          'module': 'vkey.GetVkeyServer',
          'method': 'CgiGetVkey',
          'param': {
            'guid': '10000',
            'songmid': [mid],
            'songtype': [0],
            'uin': '0',
            'loginflag': 1,
            'platform': '20',
          },
        },
      };

      final response = await httpClient.post(
        apiUrl,
        body: json.encode(requestData),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 0 && data['req_1']?['code'] == 0) {
          final midurlinfo = data['req_1']['data']['midurlinfo'];
          if (midurlinfo != null && midurlinfo.isNotEmpty) {
            final purl = midurlinfo[0]['purl'];
            if (purl != null && purl.isNotEmpty) {
              return 'https://dl.stream.qqmusic.qq.com/$purl';
            }
          }
        }
      }

      return null;
    } catch (e) {
      print('❌ [QQ] 获取URL失败: $e');
      return null;
    }
  }

  @override
  Future<LyricData?> getLyric(dynamic songId) async {
    try {
      final mid = songId is Map ? songId['mid'] : songId.toString();

      final requestData = {
        'comm': {
          'cv': 4747474,
          'ct': 24,
          'format': 'json',
          'uin': 0,
        },
        'req_1': {
          'module': 'music.musichallSong.PlayLyricInfo',
          'method': 'GetPlayLyricInfo',
          'param': {
            'songMID': mid,
            'songID': 0,
          },
        },
      };

      final response = await httpClient.post(
        apiUrl,
        body: json.encode(requestData),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 0 && data['req_1']?['code'] == 0) {
          final lyricData = data['req_1']['data'];
          return LyricData(
            lyric: lyricData['lyric'] ?? '',
            tlyric: lyricData['trans'] ?? '',
          );
        }
      }

      return null;
    } catch (e) {
      print('❌ [QQ] 获取歌词失败: $e');
      return null;
    }
  }

  @override
  Future<List<Toplist>> getToplists() async {
    try {
      final requestData = {
        'comm': {
          'cv': 4747474,
          'ct': 24,
          'format': 'json',
          'uin': 0,
        },
        'req_1': {
          'module': 'musicToplist.ToplistInfoServer',
          'method': 'GetAll',
          'param': {},
        },
      };

      final response = await httpClient.post(
        apiUrl,
        body: json.encode(requestData),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 0 && data['req_1']?['code'] == 0) {
          final list = data['req_1']['data']['group'] as List<dynamic>;
          final toplists = <Toplist>[];

          for (final group in list) {
            final groupLists = group['toplist'] as List<dynamic>? ?? [];
            for (final item in groupLists) {
              toplists.add(_parseToplist(item));
            }
          }

          return toplists;
        }
      }

      return [];
    } catch (e) {
      print('❌ [QQ] 获取榜单失败: $e');
      return [];
    }
  }

  @override
  Future<List<Track>> getPlaylistTracks(String playlistId) async {
    try {
      final requestData = {
        'comm': {
          'cv': 4747474,
          'ct': 24,
          'format': 'json',
          'uin': 0,
        },
        'req_1': {
          'module': 'music.srfDissInfo.aiDissInfo',
          'method': 'uniform_get_Dissinfo',
          'param': {
            'disstid': int.tryParse(playlistId) ?? 0,
            'userinfo': 1,
            'tag': 1,
          },
        },
      };

      final response = await httpClient.post(
        apiUrl,
        body: json.encode(requestData),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 0 && data['req_1']?['code'] == 0) {
          final songlist = data['req_1']['data']['songlist'] as List<dynamic>? ?? [];
          return songlist.map((item) => _parseTrack(item)).toList();
        }
      }

      return [];
    } catch (e) {
      print('❌ [QQ] 获取歌单失败: $e');
      return [];
    }
  }

  // 工具方法

  Track _parseTrack(Map<String, dynamic> item) {
    final singers = item['singer'] as List<dynamic>? ?? [];
    final artistNames = singers.map((s) => s['name'] as String).join(', ');

    final album = item['album'];
    final albumMid = album?['mid'] ?? '';
    final picUrl = albumMid.isNotEmpty
        ? 'https://y.gtimg.cn/music/photo_new/T002R300x300M000$albumMid.jpg'
        : '';

    return Track(
      id: {
        'id': item['id'],
        'mid': item['mid'],
        'name': item['name'],
        'artists': artistNames,
        'album': album?['name'] ?? '',
        'pic': picUrl,
      },
      name: item['name'] ?? '',
      artists: artistNames,
      album: album?['name'] ?? '',
      picUrl: picUrl,
      source: MusicSource.qq,
    );
  }

  Toplist _parseToplist(Map<String, dynamic> item) {
    return Toplist(
      id: item['topId'],
      name: item['title'] ?? '',
      nameEn: item['titleEn'] ?? '',
      coverUrl: item['headPicUrl'] ?? item['frontPicUrl'] ?? '',
      updateFrequency: item['updateType'] ?? '每日更新',
      tracks: [],
      source: MusicSource.qq,
    );
  }

  String _qualityToLevel(AudioQuality quality) {
    switch (quality) {
      case AudioQuality.standard:
        return 'standard';
      case AudioQuality.higher:
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
