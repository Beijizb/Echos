import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../services/player_service.dart';
import '../../services/lyric_font_service.dart';
import '../../services/lyric_style_service.dart';
import '../../models/lyric_line.dart';

/// 核心：弹性间距动画 + 波浪式延迟 (1:1 复刻 HTML)
class PlayerFluidCloudLyricsPanel extends StatefulWidget {
  final List<LyricLine> lyrics;
  final int currentLyricIndex;
  final bool showTranslation;
  final int visibleLineCount;

  const PlayerFluidCloudLyricsPanel({
    super.key,
    required this.lyrics,
    required this.currentLyricIndex,
    required this.showTranslation,
    this.visibleLineCount = 7,
  });

  @override
  State<PlayerFluidCloudLyricsPanel> createState() => _PlayerFluidCloudLyricsPanelState();
}

class _PlayerFluidCloudLyricsPanelState extends State<PlayerFluidCloudLyricsPanel>
    with TickerProviderStateMixin {
  
  // 核心变量 - 对应 CSS var(--line-height)
  // HTML 中是 80px，这里我们也用 80 逻辑像素
  final double _lineHeight = 80.0; 
  
  // 滚动/拖拽相关
  double _dragOffset = 0.0;
  bool _isDragging = false;
  Timer? _dragResetTimer;
  
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _dragResetTimer?.cancel();
    super.dispose();
  }

  // 简单的拖拽手势处理，允许用户微调查看
  void _onDragStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
      _dragResetTimer?.cancel();
    });
  }

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta.dy;
    });
  }

  void _onDragEnd(DragEndDetails details) {
     // 拖拽结束后，延时回弹归位
     _dragResetTimer = Timer(const Duration(milliseconds: 600), () {
       if (mounted) {
         setState(() {
           _isDragging = false;
           _dragOffset = 0.0; 
         });
       }
     });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.lyrics.isEmpty) {
      return _buildNoLyric();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportHeight = constraints.maxHeight;
        final viewportWidth = constraints.maxWidth;
        final centerY = viewportHeight / 2;
        
        // 可视区域计算
        final visibleBuffer = 6; 
        final visibleLines = (viewportHeight / _lineHeight).ceil(); // 估算
        final minIndex = max(0, widget.currentLyricIndex - visibleBuffer - (visibleLines ~/ 2));
        final maxIndex = min(widget.lyrics.length - 1, widget.currentLyricIndex + visibleBuffer + (visibleLines ~/ 2));

        // [New] 动态高度计算
        // 1. 计算每个可见 Item 的高度
        final Map<int, double> heights = {};
        // 考虑到回弹动画，我们需要稍微多计算一些范围的 Item 高度，或者至少计算 active 附近的
        // 为了布局准确，我们计算 minIndex 到 maxIndex 的高度
        final textMaxWidth = viewportWidth - 80; // horizontal padding 40 * 2
        
        for (int i = minIndex; i <= maxIndex; i++) {
          heights[i] = _measureLyricItemHeight(i, textMaxWidth);
        }

        // 2. 计算偏移量 (相对于 activeIndex 中心)
        // activeIndex 的 offset 为 0
        final Map<int, double> offsets = {};
        offsets[widget.currentLyricIndex] = 0;

        // 向下累加 (active + 1, active + 2 ...)
        double currentOffset = 0;
        // active 本身的一半高度
        double prevHalfHeight = (heights[widget.currentLyricIndex] ?? _lineHeight) / 2;
        
        for (int i = widget.currentLyricIndex + 1; i <= maxIndex; i++) {
          final h = heights[i] ?? _lineHeight;
          // 距离 = 上一个的一半 + 当前的一半 + 间距(可选)
          currentOffset += prevHalfHeight + (h / 2); 
          offsets[i] = currentOffset;
          prevHalfHeight = h / 2;
        }

        // 向上累加 (active - 1, active - 2 ...)
        currentOffset = 0;
        double nextHalfHeight = (heights[widget.currentLyricIndex] ?? _lineHeight) / 2;
        
        for (int i = widget.currentLyricIndex - 1; i >= minIndex; i--) {
          final h = heights[i] ?? _lineHeight;
          currentOffset -= (nextHalfHeight + h / 2);
          offsets[i] = currentOffset;
          nextHalfHeight = h / 2;
        }

        List<Widget> children = [];
        for (int i = minIndex; i <= maxIndex; i++) {
          // 传递计算好的相对偏移 offsets[i] 以及自身高度 heights[i]
          children.add(_buildLyricItem(i, centerY, offsets[i] ?? 0.0, heights[i] ?? _lineHeight));
        }

        return GestureDetector(
          onVerticalDragStart: _onDragStart,
          onVerticalDragUpdate: _onDragUpdate,
          onVerticalDragEnd: _onDragEnd,
          behavior: HitTestBehavior.translucent, 
          child: Stack(
            fit: StackFit.expand,
            children: children,
          ),
        );
      },
    );
  }

  /// 估算歌词项高度
  double _measureLyricItemHeight(int index, double maxWidth) {
    if (index < 0 || index >= widget.lyrics.length) return _lineHeight;
    final lyric = widget.lyrics[index];
    final fontFamily = LyricFontService().currentFontFamily ?? 'Microsoft YaHei';
    final fontSize = 32.0; // 与 _buildInnerContent 保持一致

    // 测量原文高度 (maxLines: 2)
    final textPainter = TextPainter(
      text: TextSpan(
        text: lyric.text,
        style: TextStyle(
          fontFamily: fontFamily,
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          height: 1.1,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 2,
    );
    textPainter.layout(maxWidth: maxWidth);
    double h = textPainter.height;

    // 测量翻译高度
    if (widget.showTranslation && lyric.translation != null && lyric.translation!.isNotEmpty) {
      final transPainter = TextPainter(
        text: TextSpan(
          text: lyric.translation,
          style: TextStyle(
            fontFamily: fontFamily,
            fontSize: 18, // 与 _buildInnerContent 保持一致
            fontWeight: FontWeight.w600,
            height: 1.0, // 假设默认
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      );
      transPainter.layout(maxWidth: maxWidth);
      h += 2.0; // Padding top
      h += transPainter.height;
    }
    
    // 增加一点基础 Padding 上下余量，避免太拥挤
    h += 24.0; 
    
    // 保证最小高度，避免空行太窄
    return max(h, _lineHeight);
  }

  Widget _buildLyricItem(int index, double centerYOffset, double relativeOffset, double itemHeight) {
    final activeIndex = widget.currentLyricIndex;
    final diff = index - activeIndex;
    
    // 1. 基础位移 (改为使用预计算的相对 Dynamic Offset)
    final double baseTranslation = relativeOffset;
    
    // 2. 正弦偏移：保持原有的“果冻”弹性算法
    // Math.sin(diff * 0.8) * 20
    final double sineOffset = sin(diff * 0.8) * 20.0;
    
    // 3. 最终Y坐标
    // centerYOffset 是屏幕中心
    // baseTranslation 是该 Item 中心相对于屏幕中心的偏移
    // sineOffset 是动画偏移
    // 最后要减去 itemHeight / 2 因为 Positioned top 是左上角
    double targetY = centerYOffset + baseTranslation + sineOffset - (itemHeight / 2);

    // 叠加拖拽偏移
    if (_isDragging) {
       targetY += _dragOffset;
    }
    
    // 4. 缩放逻辑
    // const scale = i === index ? 1.15 : (Math.abs(diff) < 3 ? 1 - Math.abs(diff) * 0.1 : 0.7);
    double targetScale;
    if (diff == 0) {
      targetScale = 1.15;
    } else if (diff.abs() < 3) {
      targetScale = 1.0 - diff.abs() * 0.1;
    } else {
      targetScale = 0.7;
    }

    // 5. 透明度逻辑
    // const opacity = Math.abs(diff) > 4 ? 0 : 1 - Math.abs(diff) * 0.2;
    double targetOpacity;
    if (diff.abs() > 4) {
      targetOpacity = 0.0;
    } else {
      targetOpacity = 1.0 - diff.abs() * 0.2;
    }
    targetOpacity = targetOpacity.clamp(0.0, 1.0).toDouble();

    // 6. 延迟逻辑
    // transitionDelay = ${Math.abs(diff) * 0.05}s
    final int delayMs = (diff.abs() * 50).toInt();

    // 7. 模糊逻辑
    // active: 0, near (diff=1): 1px, others: 4px
    double targetBlur = 4.0;
    if (diff == 0) targetBlur = 0.0;
    else if (diff.abs() == 1) targetBlur = 1.0;

    final bool isActive = (diff == 0);

    return _ElasticLyricLine(
      key: ValueKey(index), // 保持 Key 稳定以复用 State
      text: widget.lyrics[index].text,
      translation: widget.lyrics[index].translation,
      lyric: widget.lyrics[index], 
      lyrics: widget.lyrics,     
      index: index,             
      lineHeight: _lineHeight,
      targetY: targetY,
      targetScale: targetScale,
      targetOpacity: targetOpacity,
      targetBlur: targetBlur,
      isActive: isActive,
      delay: Duration(milliseconds: delayMs),
      isDragging: _isDragging,
      showTranslation: widget.showTranslation,
    );
  }

  Widget _buildNoLyric() {
    return const Center(
      child: Text(
        '暂无歌词',
        style: TextStyle(color: Colors.white54, fontSize: 24),
      ),
    );
  }
}

/// 能够处理延迟和弹性动画的单行歌词组件
/// 对应 HTML .lyric-line 及其 CSS transition
class _ElasticLyricLine extends StatefulWidget {
  final String text;
  final String? translation;
  final LyricLine lyric;
  final List<LyricLine> lyrics;
  final int index;
  final double lineHeight;
  
  final double targetY;
  final double targetScale;
  final double targetOpacity;
  final double targetBlur;
  final bool isActive;
  final Duration delay;
  final bool isDragging;
  final bool showTranslation;

  const _ElasticLyricLine({
    Key? key,
    required this.text,
    this.translation,
    required this.lyric,
    required this.lyrics,
    required this.index,
    required this.lineHeight,
    required this.targetY,
    required this.targetScale,
    required this.targetOpacity,
    required this.targetBlur,
    required this.isActive,
    required this.delay,
    required this.isDragging,
    required this.showTranslation,
  }) : super(key: key);

  @override
  State<_ElasticLyricLine> createState() => _ElasticLyricLineState();
}

class _ElasticLyricLineState extends State<_ElasticLyricLine> with TickerProviderStateMixin {
  // 当前动画值
  late double _y;
  late double _scale;
  late double _opacity;
  late double _blur;
  
  AnimationController? _controller;
  Animation<double>? _yAnim;
  Animation<double>? _scaleAnim;
  Animation<double>? _opacityAnim;
  Animation<double>? _blurAnim;
  
  Timer? _delayTimer;

  // HTML CSS: transition: transform 0.8s cubic-bezier(0.34, 1.56, 0.64, 1)
  // 这是带回弹的曲线
  static const Curve elasticCurve = Cubic(0.34, 1.56, 0.64, 1.0);
  static const Duration animDuration = Duration(milliseconds: 800);
  
  @override
  void initState() {
    super.initState();
    _y = widget.targetY;
    _scale = widget.targetScale;
    _opacity = widget.targetOpacity;
    _blur = widget.targetBlur;
  }

  @override
  void didUpdateWidget(_ElasticLyricLine oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // 使用 Epsilon 阈值防止微小浮点误差/UI抖动导致的动画频繁重启
    const double epsilon = 0.05;
    
    // 只在变化显著时才触发动画
    bool positionChanged = (oldWidget.targetY - widget.targetY).abs() > epsilon;
    bool scaleChanged = (oldWidget.targetScale - widget.targetScale).abs() > 0.001;
    bool opacityChanged = (oldWidget.targetOpacity - widget.targetOpacity).abs() > 0.01;
    bool blurChanged = (oldWidget.targetBlur - widget.targetBlur).abs() > 0.1;
    
    if (positionChanged || scaleChanged || opacityChanged || blurChanged) {
      _startAnimation();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _delayTimer?.cancel();
    super.dispose();
  }

  void _startAnimation() {
    _delayTimer?.cancel();
    
    // 如果正在拖拽，或者目标一致，则不播放动画
    if (widget.isDragging) {
      _controller?.stop();
      setState(() {
        _y = widget.targetY;
        _scale = widget.targetScale;
        _opacity = widget.targetOpacity;
        _blur = widget.targetBlur;
      });
      return;
    }

    void play() {
      // 创建新的控制器
      _controller?.dispose();
      _controller = AnimationController(
        vsync: this,
        duration: animDuration,
      );

      _yAnim = Tween<double>(begin: _y, end: widget.targetY).animate(
        CurvedAnimation(parent: _controller!, curve: elasticCurve)
      );
      _scaleAnim = Tween<double>(begin: _scale, end: widget.targetScale).animate(
         CurvedAnimation(parent: _controller!, curve: elasticCurve)
      );
      // Opacity/Blur 使用 ease，避免回弹导致闪烁
      _opacityAnim = Tween<double>(begin: _opacity, end: widget.targetOpacity).animate(
        CurvedAnimation(parent: _controller!, curve: Curves.ease)
      );
      _blurAnim = Tween<double>(begin: _blur, end: widget.targetBlur).animate(
        CurvedAnimation(parent: _controller!, curve: Curves.ease)
      );

      _controller!.addListener(() {
        if (!mounted) return;
        setState(() {
          _y = _yAnim!.value;
          _scale = _scaleAnim!.value;
          _opacity = _opacityAnim!.value;
          _blur = _blurAnim!.value;
        });
      });

      _controller!.forward();
    }

    if (widget.delay == Duration.zero) {
      play();
    } else {
      _delayTimer = Timer(widget.delay, play);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 性能优化：如果透明度极低，不渲染
    if (_opacity < 0.01) return const SizedBox();

    return Positioned(
      top: _y,
      left: 0,
      right: 0,
      // height: widget.lineHeight, // Remove strict height constraint to allow natural wrapping without overflow
      child: Transform.scale(
        scale: _scale,
        alignment: Alignment.centerLeft, // HTML: transform-origin: left center
        child: Opacity(
          opacity: _opacity,
          child: _OptionalBlur(
            blur: _blur,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 40), // HTML: padding: 0 40px
              alignment: Alignment.centerLeft, // HTML: display: flex; align-items: center
              child: _buildInnerContent(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInnerContent() {
    final fontFamily = LyricFontService().currentFontFamily ?? 'Microsoft YaHei';
    
    // HTML font-size: 2.4rem.
    // 我们使用固定大小，或者根据需求调整。原 Flutter 代码是 32。
    final double textFontSize = 32.0;

    // 颜色:
    // HTML .lyric-line.active -> rgba(255, 255, 255, 1)
    // HTML .lyric-line -> rgba(255, 255, 255, 0.2)
    // 我们的 _opacity 已经模拟了整体容器的透明度。
    // 但是 HTML 同时改变了 color 和 opacity。
    // Active 行 color 是完全不透明白色。
    // 非 Active 行 color 是 0.2 白。
    // 加上容器 opacity，非 Active 行会非常暗 (0.2 * opacity)。
    // 为了匹配效果，我们需要同时调整 color 的 opacity。
    
    Color textColor;
    if (widget.isActive) {
      textColor = Colors.white;
    } else {
      // 匹配 HTML rgba(255, 255, 255, 0.2)
      textColor = Colors.white.withOpacity(0.3); 
    }
    
    // 构建文本 Widget
    Widget textWidget;
    // 只有当服务端提供了逐字歌词(hasWordByWord)时，才启用卡拉OK动画
    // 否则仅保留基础的变白+放大效果 (由 textColor 和 parent scale控制)
    if (widget.isActive && widget.lyric.hasWordByWord) {
      textWidget = _KaraokeText(
        text: widget.text,
        lyric: widget.lyric,
        lyrics: widget.lyrics,
        index: widget.index,
        originalTextStyle: TextStyle(
             fontFamily: fontFamily,
             fontSize: textFontSize, 
             fontWeight: FontWeight.w800,
             color: Colors.white,
             height: 1.1, 
        ),
      );
    } else {
      textWidget = Text(
        widget.text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: fontFamily,
          fontSize: textFontSize, 
          fontWeight: FontWeight.w800,
          color: textColor,
          height: 1.1,
        ),
      );
    }
    
    // 如果有翻译
    if (widget.showTranslation && widget.translation != null && widget.translation!.isNotEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          textWidget,
          Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Text(
              widget.translation!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.3), // 译文始终保持未播放行的样式
              ),
            ),
          )
        ],
      );
    }
    
    // 如果是第一行，且活跃，显示倒计时点 (Features)
    if (widget.index == 0 && !widget.isDragging) {
       return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
           _CountdownDots(lyrics: widget.lyrics, countdownThreshold: 5.0),
           textWidget, 
        ]
       );
    }

    return textWidget;
  }
}

/// 性能优化：模糊组件
class _OptionalBlur extends StatelessWidget {
  final double blur;
  final Widget child;

  const _OptionalBlur({required this.blur, required this.child});

  @override
  Widget build(BuildContext context) {
    if (blur < 0.1) return child;
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
      child: child,
    );
  }
}

/// 卡拉OK文本组件 - 实现逐字填充效果
/// (保留原有逻辑)
class _KaraokeText extends StatefulWidget {
  final String text;
  final LyricLine lyric;
  final List<LyricLine> lyrics;
  final int index;
  final TextStyle originalTextStyle; // 新增：允许外部传入样式

  const _KaraokeText({
    required this.text,
    required this.lyric,
    required this.lyrics,
    required this.index,
    required this.originalTextStyle,
  });

  @override
  State<_KaraokeText> createState() => _KaraokeTextState();
}

class _KaraokeTextState extends State<_KaraokeText> with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  double _lineProgress = 0.0;

  // 缓存
  double _cachedMaxWidth = 0.0;
  TextStyle? _cachedStyle;
  int _cachedLineCount = 1;
  double _line1Width = 0.0;
  double _line2Width = 0.0;
  double _line1Height = 0.0;
  double _line2Height = 0.0;
  double _line1Ratio = 0.5;

  late Duration _duration;

  @override
  void initState() {
    super.initState();
    _calculateDuration();
    _ticker = createTicker(_onTick);
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _calculateDuration() {
    if (widget.index < widget.lyrics.length - 1) {
      _duration = widget.lyrics[widget.index + 1].startTime - widget.lyric.startTime;
    } else {
      _duration = const Duration(seconds: 5);
    }
    if (_duration.inMilliseconds == 0) _duration = const Duration(seconds: 3);
  }

  void _onTick(Duration elapsed) {
    if (!mounted) return;

    // 只处理非逐字歌词的行级进度
    if (!widget.lyric.hasWordByWord || widget.lyric.words == null) {
      final currentPos = PlayerService().position;
      final elapsedFromStart = currentPos - widget.lyric.startTime;
      final newProgress = (elapsedFromStart.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0);

      if ((newProgress - _lineProgress).abs() > 0.005) {
        setState(() {
          _lineProgress = newProgress;
        });
      }
    }
  }
  
  // 简化版布局缓存，因为现在是单行/Wrap 为主
  void _updateLayoutCache(BoxConstraints constraints, TextStyle style) {
    if (_cachedMaxWidth == constraints.maxWidth && _cachedStyle == style) return;
    _cachedMaxWidth = constraints.maxWidth;
    _cachedStyle = style;
    
    final textSpan = TextSpan(text: widget.text, style: style);
    final textPainter = TextPainter(
      text: textSpan,
      maxLines: 2,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: constraints.maxWidth);
    
    final metrics = textPainter.computeLineMetrics();
    _cachedLineCount = metrics.length.clamp(1, 2);
    if (metrics.isNotEmpty) {
       _line1Width = metrics[0].width;
       _line1Height = metrics[0].height;
       if (metrics.length > 1) {
           _line2Width = metrics[1].width;
           _line2Height = metrics[1].height;
       }
    }
    
    final totalWidth = _line1Width + _line2Width;
    _line1Ratio = totalWidth > 0 ? _line1Width / totalWidth : 0.5;
    textPainter.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 使用传入的样式
    final style = widget.originalTextStyle;

    if (widget.lyric.hasWordByWord && widget.lyric.words != null && widget.lyric.words!.isNotEmpty) {
      return _buildWordByWordEffect(style);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        _updateLayoutCache(constraints, style);
        return _buildLineGradientEffect(style);
      },
    );
  }
  
  Widget _buildWordByWordEffect(TextStyle style) {
    final words = widget.lyric.words!;
    return Wrap(
      alignment: WrapAlignment.start,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: List.generate(words.length, (index) {
        final word = words[index];
        return _WordFillWidget(
          key: ValueKey('${widget.index}_$index'), // 稳定的 key
          text: word.text,
          word: word, // 传递整个 word 对象
          style: style,
        );
      }),
    );
  }
  
  Widget _buildLineGradientEffect(TextStyle style) {
    if (_cachedLineCount == 1) {
      return RepaintBoundary(
        child: ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft, end: Alignment.centerRight,
              colors: const [Colors.white, Color(0x99FFFFFF)],
              stops: [_lineProgress, _lineProgress],
              tileMode: TileMode.clamp,
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcIn,
          child: Text(widget.text, maxLines: 2, overflow: TextOverflow.ellipsis, style: style),
        ),
      );
    }
    
    // 多行逻辑：计算每行进度
    double line1Progress = 0.0; 
    double line2Progress = 0.0;
    
    if (_lineProgress <= _line1Ratio) {
      // 正在播放第一行
      if (_line1Ratio > 0) {
        line1Progress = _lineProgress / _line1Ratio;
      }
      line2Progress = 0.0;
    } else {
      // 第一行已播完，正在播放第二行
      line1Progress = 1.0;
      if (_line1Ratio < 1.0) {
        line2Progress = (_lineProgress - _line1Ratio) / (1.0 - _line1Ratio);
      }
    }
    
    final dimText = Text(
      widget.text,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: style.copyWith(color: const Color(0x99FFFFFF)),
    );
    
    final brightText = Text(
      widget.text,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: style.copyWith(color: Colors.white),
    );
    
    return RepaintBoundary(
      child: Stack(
        children: [
          dimText,
          // 第一行裁剪
          ClipRect(
            clipper: _LineClipper(
              lineIndex: 0,
              progress: line1Progress,
              lineHeight: _line1Height,
              lineWidth: _line1Width,
            ),
            child: brightText,
          ),
          // 第二行裁剪
          if (_cachedLineCount > 1)
            ClipRect(
              clipper: _LineClipper(
                lineIndex: 1,
                progress: line2Progress,
                lineHeight: _line2Height + 10,
                lineWidth: _line2Width,
                yOffset: _line1Height,
              ),
              child: brightText,
            ),
        ],
      ),
    );
  }
}

class _WordFillWidget extends StatefulWidget {
  final String text;
  final LyricWord word; // 单词的时间信息
  final TextStyle style;

  const _WordFillWidget({
    Key? key,
    required this.text,
    required this.word,
    required this.style,
  }) : super(key: key);

  @override
  State<_WordFillWidget> createState() => _WordFillWidgetState();
}

class _WordFillWidgetState extends State<_WordFillWidget> with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  double _progress = 0.0;

  static const double fadeRatio = 0.3;
  static const double floatDistanceRatio = 0.10;
  static const double ascendPhaseRatio = 0.65;
  static const double settlePhaseRatio = 0.35;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    if (!mounted) return;

    final currentPos = PlayerService().position;
    double newProgress;

    if (currentPos < widget.word.startTime) {
      newProgress = 0.0;
    } else if (currentPos >= widget.word.endTime) {
      newProgress = 1.0;
    } else {
      final wordElapsed = currentPos - widget.word.startTime;
      newProgress = (wordElapsed.inMilliseconds / widget.word.duration.inMilliseconds).clamp(0.0, 1.0);
    }

    // 只在变化显著时更新，减少重绘
    // 降低阈值以确保更平滑的视觉过渡，避免跳跃
    if ((newProgress - _progress).abs() > 0.003) {
      setState(() {
        _progress = newProgress;
      });
    }

    // 优化：如果已经完成，停止 ticker
    if (_progress >= 1.0 && _ticker.isActive) {
      _ticker.stop();
    }
  }

  bool _isAsciiText() {
    if (widget.text.isEmpty) return false;
    int asciiCount = 0;
    for (final char in widget.text.runes) {
      if ((char >= 65 && char <= 90) || (char >= 97 && char <= 122)) asciiCount++;
    }
    return asciiCount > widget.text.length / 2;
  }

  double _ascendCurve(double t) {
    if (t <= 0) return 0; if (t >= 1) return 1;
    final t2 = t * t; final t3 = t2 * t;
    return 3 * (1 - t) * (1 - t) * t * 0.05 + 3 * (1 - t) * t2 * 0.25 + t3;
  }

  double _settleCurve(double t) {
    if (t <= 0) return 0; if (t >= 1) return 1;
    final t2 = t * t; final t3 = t2 * t;
    return 3 * (1 - t) * (1 - t) * t * 0.6 + 3 * (1 - t) * t2 * 1.0 + t3;
  }

  double _calculateVerticalOffset(double progressValue, double fontSize) {
    final maxFloatDistance = fontSize * floatDistanceRatio;
    if (progressValue <= 0) return 0;

    // 当进度完成时，返回固定的最终偏移值，确保稳定
    if (progressValue >= 1.0) {
      return _getFinalVerticalOffset(fontSize);
    }

    if (progressValue < ascendPhaseRatio) {
      return -maxFloatDistance * _ascendCurve(progressValue / ascendPhaseRatio);
    }
    final settleProgress = (progressValue - ascendPhaseRatio) / settlePhaseRatio;
    return -maxFloatDistance + (0.1 * _settleCurve(settleProgress.clamp(0.0, 1.0)));
  }

  /// 返回字母完成填充后的固定垂直偏移（静止位置）
  double _getFinalVerticalOffset(double fontSize) {
    final maxFloatDistance = fontSize * floatDistanceRatio;
    // 最终位置：上升后略微回落，固定值避免抖动
    return -maxFloatDistance + 0.1;
  }

  @override
  Widget build(BuildContext context) {
    // 恢复 RepaintBoundary，防止 Layer 重绘导致的闪烁，配合内部逻辑优化防止抖动
    return RepaintBoundary(
      child: _buildInner(),
    );
  }

  Widget _buildInner() {
    if (_isAsciiText() && widget.text.length > 1) return _buildLetterByLetterEffect();
    return _buildWholeWordEffect();
  }
  
  Widget _buildWholeWordEffect() {
    final fontSize = widget.style.fontSize ?? 32.0;
    final verticalOffset = _calculateVerticalOffset(_progress, fontSize);

    // 统一使用 4-stops 结构的 LinearGradient，避免 GPU 重新编译着色器导致闪烁
    // 通过调整 stops 值来模拟不同状态
    double fillStop;
    double fadeStop;
    
    if (_progress <= 0.0) {
      // 完全未填充：全灰色
      fillStop = 0.0;
      fadeStop = 0.001;
    } else if (_progress >= 1.0) {
      // 完全填充：全白色
      fillStop = 1.0;
      fadeStop = 1.0;
    } else {
      // 正在填充：正常渐变
      fillStop = _progress.clamp(0.0, 1.0);
      fadeStop = (_progress + fadeRatio).clamp(fillStop + 0.001, 1.0);
    }

    return Transform.translate(
      offset: Offset(0, verticalOffset),
      child: ShaderMask(
        shaderCallback: (bounds) => LinearGradient(
          colors: const [Colors.white, Colors.white, Color(0x99FFFFFF), Color(0x99FFFFFF)],
          stops: [0.0, fillStop, fadeStop, 1.0],
        ).createShader(bounds),
        blendMode: BlendMode.srcIn,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Text(widget.text, style: widget.style.copyWith(color: Colors.white, height: 1.1)),
        ),
      ),
    );
  }

  Widget _buildLetterByLetterEffect() {
    final letters = widget.text.split('');
    final letterCount = letters.length;
    final fontSize = widget.style.fontSize ?? 32.0;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(letterCount, (index) {
        final letter = letters[index];
        final baseWidth = 1.0 / letterCount;
        
        // 计算填充进度
        final fillStart = index * baseWidth;
        final fillEnd = (index + 1) * baseWidth;
        final fillProgress = ((_progress - fillStart) / (fillEnd - fillStart)).clamp(0.0, 1.0);

        // 关键修复：已完成字母使用固定偏移，避免抖动
        double verticalOffset;
        if (fillProgress >= 1.0) {
          // 已完成的字母：使用固定的最终偏移，确保稳定
          verticalOffset = _getFinalVerticalOffset(fontSize);
        } else if (fillProgress <= 0.0) {
          // 未开始的字母：无偏移
          verticalOffset = 0.0;
        } else {
          // 正在填充的字母：使用波浪偏移
          final waveExpandedWidth = baseWidth * 4.0;
          final waveStart = (index * baseWidth) - (baseWidth * 1.5);
          final waveEnd = waveStart + waveExpandedWidth;
          final rawWaveProgress = ((_progress - waveStart) / (waveEnd - waveStart)).clamp(0.0, 1.0);
          verticalOffset = _calculateVerticalOffset(rawWaveProgress, fontSize);
        }

        // 统一使用 4-stops 结构的 LinearGradient，避免 GPU 重新编译着色器
        double gradientFill;
        double gradientFade;
        
        if (fillProgress <= 0.0) {
          // 完全未填充
          gradientFill = 0.0;
          gradientFade = 0.001;
        } else if (fillProgress >= 1.0) {
          // 完全填充
          gradientFill = 1.0;
          gradientFade = 1.0;
        } else {
          // 正在填充
          gradientFill = fillProgress;
          gradientFade = (fillProgress + fadeRatio).clamp(gradientFill + 0.001, 1.0);
        }

        final letterWidget = ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: const [Colors.white, Colors.white, Color(0x99FFFFFF), Color(0x99FFFFFF)],
            stops: [0.0, gradientFill, gradientFade, 1.0],
          ).createShader(bounds),
          blendMode: BlendMode.srcIn,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Text(letter, style: widget.style.copyWith(color: Colors.white, height: 1.1)),
          ),
        );

        return Transform.translate(
          offset: Offset(0, verticalOffset),
          child: letterWidget,
        );
      }),
    );
  }
}

/// 裁剪器 (保留但可能未被直接使用，防止报错)
class _LineClipper extends CustomClipper<Rect> {
  final int lineIndex;
  final double progress;
  final double lineHeight;
  final double lineWidth;
  final double yOffset;
  _LineClipper({required this.lineIndex, required this.progress, required this.lineHeight, required this.lineWidth, this.yOffset = 0.0});
  @override Rect getClip(Size size) => Rect.fromLTWH(0, yOffset, lineWidth * progress, lineHeight);
  @override bool shouldReclip(_LineClipper oldClipper) => oldClipper.progress != progress;
}

/// 倒计时点组件 - Apple Music 风格 (保留)
class _CountdownDots extends StatefulWidget {
  final List<LyricLine> lyrics;
  final double countdownThreshold;
  const _CountdownDots({required this.lyrics, required this.countdownThreshold});
  @override State<_CountdownDots> createState() => _CountdownDotsState();
}

class _CountdownDotsState extends State<_CountdownDots> with TickerProviderStateMixin {
  late Ticker _ticker;
  double _progress = 0.0;
  bool _isVisible = false;
  bool _wasVisible = false;
  late AnimationController _appearController;
  late Animation<double> _appearAnimation;
  
  static const int _dotCount = 3;

  @override
  void initState() {
    super.initState();
    _appearController = AnimationController(duration: const Duration(milliseconds: 400), vsync: this);
    _appearAnimation = CurvedAnimation(parent: _appearController, curve: Curves.easeOutBack, reverseCurve: Curves.easeInBack);
    _ticker = createTicker(_onTick);
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _appearController.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    if (widget.lyrics.isEmpty) return;
    final firstLyricTime = widget.lyrics.first.startTime;
    final currentPos = PlayerService().position;
    final timeUntilFirstLyric = (firstLyricTime - currentPos).inMilliseconds / 1000.0;
    final isPlaying = PlayerService().isPlaying;
    final shouldShow = isPlaying && currentPos.inMilliseconds > 0 && timeUntilFirstLyric > 0 && timeUntilFirstLyric <= widget.countdownThreshold;

    if (shouldShow) {
      final newProgress = 1.0 - (timeUntilFirstLyric / widget.countdownThreshold);
      if (!_wasVisible) {
        _wasVisible = true;
        _appearController.forward();
      }
      if (!_isVisible || (newProgress - _progress).abs() > 0.01) {
        setState(() {
          _isVisible = true;
          _progress = newProgress.clamp(0.0, 1.0);
        });
      }
    } else if (_isVisible || _wasVisible) {
      if (_wasVisible) {
        _wasVisible = false;
        _appearController.reverse();
      }
      setState(() {
        _isVisible = false;
        _progress = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _appearAnimation,
      builder: (context, child) {
        if (_appearAnimation.value <= 0.01 && !_isVisible) return const SizedBox.shrink();
        
        return RepaintBoundary(
          child: SizedBox(
            height: 20,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(_dotCount, (index) {
                final dotStartProgress = index / _dotCount;
                final dotEndProgress = (index + 1) / _dotCount;
                double dotProgress = 0.0;
                if (_progress > dotStartProgress) {
                   dotProgress = (_progress - dotStartProgress) / (dotEndProgress - dotStartProgress);
                   if (_progress >= dotEndProgress) dotProgress = 1.0;
                }
                
                final staggerDelay = index * 0.15;
                double appearScale = 0.0;
                if (_appearAnimation.value >= staggerDelay) {
                  appearScale = ((_appearAnimation.value - staggerDelay) / (1.0 - staggerDelay)).clamp(0.0, 1.0);
                }
                
                return Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Transform.scale(
                    scale: _easeOutBack(appearScale),
                    child: _CountdownDot(
                      size: 12.0,
                      fillProgress: dotProgress,
                      appearProgress: appearScale,
                    ),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }
  double _easeOutBack(double t) {
    if (t <= 0) return 0; if (t >= 1) return 1;
    const c1 = 1.70158; const c3 = c1 + 1;
    return 1 + c3 * (t - 1) * (t - 1) * (t - 1) + c1 * (t - 1) * (t - 1);
  }
}

class _CountdownDot extends StatelessWidget {
  final double size;
  final double fillProgress;
  final double appearProgress;
  const _CountdownDot({required this.size, required this.fillProgress, required this.appearProgress});
  
  @override
  Widget build(BuildContext context) {
    final innerSize = (size - 4) * (1 - (1 - fillProgress) * (1 - fillProgress) * (1 - fillProgress) * (1 - fillProgress));
    final borderOpacity = 0.4 + (0.2 * appearProgress);
    final glowIntensity = fillProgress > 0.3 ? (fillProgress - 0.3) / 0.7 : 0.0;
    
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(borderOpacity), width: 1.5),
      ),
      child: Center(
        child: Container(
          width: innerSize, height: innerSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.9),
            boxShadow: glowIntensity > 0 ? [BoxShadow(color: Colors.white.withOpacity(0.4 * glowIntensity), blurRadius: 8 * glowIntensity)] : null,
          ),
        ),
      ),
    );
  }
}