import '../../../models/track.dart';

/// 搜索响应模型
class SearchResponse {
  /// 搜索结果列表
  final List<Track> tracks;
  
  /// 总数
  final int total;
  
  /// 是否有更多结果
  final bool hasMore;

  const SearchResponse({
    required this.tracks,
    required this.total,
    this.hasMore = false,
  });

  factory SearchResponse.empty() {
    return const SearchResponse(
      tracks: [],
      total: 0,
      hasMore: false,
    );
  }
}
