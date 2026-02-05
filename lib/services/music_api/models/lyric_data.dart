/// 歌词数据模型
class LyricData {
  /// 原文歌词
  final String lyric;
  
  /// 翻译歌词
  final String tlyric;
  
  /// 罗马音歌词
  final String romalrc;

  const LyricData({
    required this.lyric,
    this.tlyric = '',
    this.romalrc = '',
  });

  factory LyricData.empty() {
    return const LyricData(lyric: '');
  }

  bool get hasLyric => lyric.isNotEmpty;
  bool get hasTranslation => tlyric.isNotEmpty;
}
