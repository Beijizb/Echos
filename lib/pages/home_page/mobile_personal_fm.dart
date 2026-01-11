import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import '../../models/track.dart';
import '../../services/player_service.dart';
import '../../services/playlist_queue_service.dart';
import '../../utils/theme_manager.dart';
import 'hero_section.dart'; // 复用 convertToTrack 函数

/// 私人FM（移动端）
class MobilePersonalFm extends StatelessWidget {
  final List<Map<String, dynamic>> list;
  const MobilePersonalFm({super.key, required this.list});
  
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final themeManager = ThemeManager();
    final isCupertino = (Platform.isIOS || Platform.isAndroid) && themeManager.isCupertinoFramework;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (list.isEmpty) return Text('暂无数据', style: Theme.of(context).textTheme.bodySmall);
    return AnimatedBuilder(
      animation: PlayerService(),
      builder: (context, _) {
        Map<String, dynamic> display = list.first;
        final current = PlayerService().currentTrack;
        if (current != null && current.source == MusicSource.netease) {
          for (final m in list) {
            final id = (m['id'] ?? (m['song'] != null ? (m['song'] as Map<String, dynamic>)['id'] : null)) as dynamic;
            if (id != null && id.toString() == current.id.toString()) {
              display = m;
              break;
            }
          }
        }

        final album = (display['album'] ?? display['al'] ?? {}) as Map<String, dynamic>;
        final artists = (display['artists'] ?? display['ar'] ?? []) as List<dynamic>;
        final artistsText = artists.map((e) => (e as Map<String, dynamic>)['name']?.toString() ?? '').where((e) => e.isNotEmpty).join('/');
        final pic = (album['picUrl'] ?? '').toString();

        final fmTracks = _convertListToTracks(list);
        final isFmCurrent = _currentTrackInList(fmTracks);
        final isFmQueue = _isSameQueueAs(fmTracks);
        final isFmPlaying = PlayerService().isPlaying && (isFmCurrent || isFmQueue);

        final cardContent = Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(pic, width: 120, height: 120, fit: BoxFit.cover),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(display['name']?.toString() ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Text(artistsText, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  isCupertino 
                      ? CupertinoButton(
                          padding: const EdgeInsets.all(8),
                          onPressed: () async {
                            final tracks = fmTracks;
                            if (tracks.isEmpty) return;
                            final ps = PlayerService();
                            if (isFmPlaying) {
                              await ps.pause();
                            } else if (ps.isPaused && (isFmQueue || isFmCurrent)) {
                              await ps.resume();
                            } else {
                              PlaylistQueueService().setQueue(tracks, 0, QueueSource.playlist);
                              await ps.playTrack(tracks.first);
                            }
                          },
                          child: Icon(
                            isFmPlaying ? CupertinoIcons.pause_fill : CupertinoIcons.play_fill, 
                            color: ThemeManager.iosBlue,
                            size: 28,
                          ),
                        )
                      : IconButton(
                          onPressed: () async {
                            final tracks = fmTracks;
                            if (tracks.isEmpty) return;
                            final ps = PlayerService();
                            if (isFmPlaying) {
                              await ps.pause();
                            } else if (ps.isPaused && (isFmQueue || isFmCurrent)) {
                              await ps.resume();
                            } else {
                              PlaylistQueueService().setQueue(tracks, 0, QueueSource.playlist);
                              await ps.playTrack(tracks.first);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('开始播放私人FM')),
                                );
                              }
                            }
                          },
                          style: IconButton.styleFrom(
                            hoverColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
                            focusColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.12),
                            overlayColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: Icon(isFmPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: cs.onSurface),
                          tooltip: isFmPlaying ? '暂停' : '播放',
                        ),
                  const SizedBox(width: 8),
                  isCupertino 
                      ? CupertinoButton(
                          padding: const EdgeInsets.all(8),
                          onPressed: () async {
                            final tracks = fmTracks;
                            if (tracks.isEmpty) return;
                            if (_isSameQueueAs(tracks)) {
                              await PlayerService().playNext();
                            } else {
                              final startIndex = tracks.length > 1 ? 1 : 0;
                              PlaylistQueueService().setQueue(tracks, startIndex, QueueSource.playlist);
                              await PlayerService().playTrack(tracks[startIndex]);
                            }
                          },
                          child: Icon(
                            CupertinoIcons.forward_fill, 
                            color: ThemeManager.iosBlue,
                            size: 28,
                          ),
                        )
                      : IconButton(
                          onPressed: () async {
                            final tracks = fmTracks;
                            if (tracks.isEmpty) return;
                            if (_isSameQueueAs(tracks)) {
                              await PlayerService().playNext();
                            } else {
                              final startIndex = tracks.length > 1 ? 1 : 0;
                              PlaylistQueueService().setQueue(tracks, startIndex, QueueSource.playlist);
                              await PlayerService().playTrack(tracks[startIndex]);
                            }
                          },
                          style: IconButton.styleFrom(
                            hoverColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
                            focusColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.12),
                            overlayColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: Icon(Icons.skip_next_rounded, color: cs.onSurface),
                          tooltip: '下一首',
                        ),
                ],
              ),
            ],
          ),
        );

        if (themeManager.isFluentFramework) {
          return fluent.Card(
            padding: EdgeInsets.zero,
            child: cardContent,
          );
        }

        if (isCupertino) {
          return Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: CupertinoColors.black.withOpacity(isDark ? 0.2 : 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: cardContent,
          );
        }

        return Card(
          color: cs.surfaceContainer,
          child: cardContent,
        );
      },
    );
  }

  List<Track> _convertListToTracks(List<Map<String, dynamic>> src) {
    return src.map((m) => convertToTrack(m)).toList();
  }

  bool _isSameQueueAs(List<Track> tracks) {
    final q = PlaylistQueueService().queue;
    if (q.length != tracks.length) return false;
    for (var i = 0; i < q.length; i++) {
      if (q[i].id.toString() != tracks[i].id.toString() || q[i].source != tracks[i].source) {
        return false;
      }
    }
    return true;
  }

  bool _currentTrackInList(List<Track> tracks) {
    final ct = PlayerService().currentTrack;
    if (ct == null) return false;
    return tracks.any((t) => t.id.toString() == ct.id.toString() && t.source == ct.source);
  }
}
