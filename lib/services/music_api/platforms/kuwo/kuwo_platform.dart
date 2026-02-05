import 'dart:convert';
import 'dart:math';
import '../../base_platform.dart';
import '../../models/search_response.dart';
import '../../models/lyric_data.dart';
import '../../../../models/track.dart';
import '../../../../models/song_detail.dart';
import '../../../../models/toplist.dart';
import '../../../audio_quality_service.dart';

/// 酷我音乐平台适配器
class KuwoPlatform extends BasePlatform {
  @override
  String get name => 'kuwo';

  @override
  Future<SearchResponse> search(String keyword, {int limit = 20}) async {
    try {
      print('🔍 [Kuwo] 搜索: $keyword');

      // 使用旧版 API，相对稳定且不需要复杂签名
      final url = 'http://search.kuwo.cn/r.s?all=${Uri.encodeComponent(keyword)}'
          '&ft=music&itemset=web_2013&client=kt&pn=0&rn=$limit&rformat=json&encoding=utf8';

      final response = await httpClient.get(
        url,
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Referer': 'http://www.kuwo.cn/',
        },
      );

      if (response.statusCode == 200) {
        // 酷我旧版 API 返回的数据可能包含单引号，需要处理
        String body = response.body.replaceAll("'", '"');
        // 有时候返回的数据不是标准 JSON，可能需要额外处理
        try {
          final data = json.decode(body);
          final abslist = data['abslist'] as List<dynamic>? ?? [];
          
          final tracks = abslist.map((item) => _parseTrack(item)).toList();

          print('✅ [Kuwo] 搜索成功: ${tracks.length} 首');
          return SearchResponse(tracks: tracks, total: data['TOTAL'] != null ? int.tryParse(data['TOTAL'].toString()) ?? 0 : tracks.length);
        } catch (e) {
           print('⚠️ [Kuwo] JSON解析失败，尝试修复: $e');
           // 简单的修复尝试，如果失败则返回空
           return SearchResponse.empty();
        }
      }

      throw Exception('搜索失败: ${response.statusCode}');
    } catch (e) {
      print('❌ [Kuwo] 搜索失败: $e');
      return SearchResponse.empty();
    }
  }

  @override
  Future<SongDetail?> getSongDetail(dynamic songId, AudioQuality quality) async {
    try {
      print('🎵 [Kuwo] 获取歌曲详情: $songId');

      // 1. 获取播放URL
      final url = await getSongUrl(songId, quality);
      if (url == null) {
        throw Exception('无法获取播放URL');
      }

      // 2. 获取歌词
      final lyric = await getLyric(songId);

      // 3. 由于旧版搜索API返回的信息有限，这里可能需要再次获取详情
      // 但为了简单，我们假设 search 已经提供了足够的信息，或者我们只填充已知信息
      // 如果需要更详细信息，可以调用 http://www.kuwo.cn/api/www/music/musicInfo?mid=$songId
      
      // 尝试从 API 获取详情 (可选)
      String name = '';
      String artist = '';
      String album = '';
      String pic = '';

      try {
         final infoUrl = 'http://www.kuwo.cn/api/www/music/musicInfo?mid=$songId&httpsStatus=1';
         final infoResp = await httpClient.get(infoUrl, headers: _getHeaders());
         if (infoResp.statusCode == 200) {
           final data = json.decode(infoResp.body);
           if (data['code'] == 200) {
             final musicInfo = data['data'];
             name = musicInfo['name'] ?? '';
             artist = musicInfo['artist'] ?? '';
             album = musicInfo['album'] ?? '';
             pic = musicInfo['pic'] ?? '';
           }
         }
      } catch (_) {}

      return SongDetail(
        id: songId,
        name: name.isNotEmpty ? name : 'Unknown',
        pic: pic,
        arName: artist,
        alName: album,
        level: _qualityToLevel(quality),
        size: '0',
        url: url,
        lyric: lyric?.lyric ?? '',
        tlyric: lyric?.tlyric ?? '',
        source: MusicSource.kuwo,
      );
    } catch (e) {
      print('❌ [Kuwo] 获取歌曲详情失败: $e');
      return null;
    }
  }

  @override
  Future<String?> getSongUrl(dynamic songId, AudioQuality quality) async {
    try {
      final br = _qualityToBr(quality);
      final url = 'http://www.kuwo.cn/api/v1/www/music/playUrl?mid=$songId&type=music&httpsStatus=1&br=$br';

      final response = await httpClient.get(
        url,
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 200) {
          final playUrl = data['data']['url'];
          if (playUrl != null && playUrl.isNotEmpty) {
            return playUrl;
          }
        }
      }

      return null;
    } catch (e) {
      print('❌ [Kuwo] 获取URL失败: $e');
      return null;
    }
  }

  @override
  Future<LyricData?> getLyric(dynamic songId) async {
    try {
      final url = 'http://m.kuwo.cn/newh5/singles/songinfoandlrc?musicId=$songId';

      final response = await httpClient.get(
        url,
        headers: {
          'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 200) {
          final lrclist = data['data']['lrclist'] as List<dynamic>?;
          if (lrclist != null && lrclist.isNotEmpty) {
            final buffer = StringBuffer();
            for (final line in lrclist) {
              final time = double.tryParse(line['time'].toString()) ?? 0;
              final text = line['lineLyric'] as String? ?? '';
              
              // 格式化时间 [mm:ss.xx]
              final m = (time ~/ 60).toString().padLeft(2, '0');
              final s = (time % 60).toStringAsFixed(2).padLeft(5, '0');
              buffer.writeln('[$m:$s]$text');
            }
            return LyricData(lyric: buffer.toString(), tlyric: '');
          }
        }
      }

      return null;
    } catch (e) {
      print('❌ [Kuwo] 获取歌词失败: $e');
      return null;
    }
  }

  @override
  Future<List<Toplist>> getToplists() async {
    try {
      // 酷我榜单 API
      final url = 'http://www.kuwo.cn/api/www/bang/bang/bangMenu?httpsStatus=1';
      
      final response = await httpClient.get(
        url,
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 200) {
          final list = data['data'] as List<dynamic>? ?? [];
          final toplists = <Toplist>[];
          
          for (final group in list) {
            final groupList = group['list'] as List<dynamic>? ?? [];
            for (final item in groupList) {
              toplists.add(_parseToplist(item));
            }
          }
          return toplists;
        }
      }

      return [];
    } catch (e) {
      print('❌ [Kuwo] 获取榜单失败: $e');
      return [];
    }
  }

  @override
  Future<List<Track>> getPlaylistTracks(String playlistId) async {
    try {
      final url = 'http://www.kuwo.cn/api/www/bang/bang/musicList?bangId=$playlistId&pn=1&rn=100&httpsStatus=1';

      final response = await httpClient.get(
        url,
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 200) {
          final musicList = data['data']['musicList'] as List<dynamic>? ?? [];
          return musicList.map((item) => _parseTrackFromDetail(item)).toList();
        }
      }

      return [];
    } catch (e) {
      print('❌ [Kuwo] 获取歌单失败: $e');
      return [];
    }
  }

  // 工具方法

  Map<String, String> _getHeaders() {
    return {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36',
      'Referer': 'http://www.kuwo.cn/',
      'Cookie': 'kw_token=H7N4X0X0X0X', // 这是一个示例 token，实际可能需要动态获取或固定一个有效的
      'csrf': 'H7N4X0X0X0X',
    };
  }

  Track _parseTrack(Map<String, dynamic> item) {
    // 处理旧版搜索 API 的返回格式
    // ITEM格式: {MUSICRID: "MUSIC_123", SONGNAME: "...", ARTIST: "...", ALBUM: "...", ...}
    
    final idStr = item['MUSICRID'] as String? ?? '';
    final id = idStr.replaceFirst('MUSIC_', ''); // 去掉前缀
    
    return Track(
      id: id,
      name: item['SONGNAME'] ?? '',
      artists: item['ARTIST'] ?? '',
      album: item['ALBUM'] ?? '',
      picUrl: '', // 旧版搜索不返回图片，需详情接口
      source: MusicSource.kuwo,
    );
  }

  Track _parseTrackFromDetail(Map<String, dynamic> item) {
    // 处理新版 API (如榜单) 返回的格式
    return Track(
      id: item['rid']?.toString() ?? '',
      name: item['name'] ?? '',
      artists: item['artist'] ?? '',
      album: item['album'] ?? '',
      picUrl: item['pic'] ?? '',
      source: MusicSource.kuwo,
    );
  }

  Toplist _parseToplist(Map<String, dynamic> item) {
    return Toplist(
      id: int.tryParse(item['sourceid']?.toString() ?? '0') ?? 0,
      name: item['name'] ?? '',
      nameEn: item['name'] ?? '', // 酷我不提供英文名
      coverUrl: item['pic'] ?? '',
      updateFrequency: item['intro'] ?? '每日更新',
      tracks: [],
      source: MusicSource.kuwo,
    );
  }

  String _qualityToLevel(AudioQuality quality) {
    // 仅作显示用
    return quality.displayName;
  }
  
  String _qualityToBr(AudioQuality quality) {
    switch (quality) {
      case AudioQuality.standard:
        return '128kmp3';
      case AudioQuality.higher:
        return '192kmp3';
      case AudioQuality.exhigh:
        return '320kmp3';
      case AudioQuality.lossless:
        return 'flac';
      case AudioQuality.hires:
        return 'flac24bit'; // 假设支持
      default:
        return '320kmp3';
    }
  }
}
