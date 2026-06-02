import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget yang membungkus konten dan mendeteksi swipe up
/// di area bawah layar untuk membuka komentar.
class CommentTrigger extends StatefulWidget {
  final Widget child;
  final VoidCallback onSwipeUp;

  /// Tinggi zona sensitif swipe di bagian bawah (default 80px)
  final double triggerZoneHeight;

  const CommentTrigger({
    super.key,
    required this.child,
    required this.onSwipeUp,
    this.triggerZoneHeight = 80,
  });

  @override
  State<CommentTrigger> createState() => _CommentTriggerState();
}

class _CommentTriggerState extends State<CommentTrigger>
    with SingleTickerProviderStateMixin {
  double? _dragStartY;
  bool _isInTriggerZone = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    final screenHeight = MediaQuery.of(context).size.height;
    final triggerTop = screenHeight - widget.triggerZoneHeight;
    if (event.position.dy >= triggerTop) {
      _dragStartY = event.position.dy;
      setState(() => _isInTriggerZone = true);
    } else {
      _dragStartY = null;
      setState(() => _isInTriggerZone = false);
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_dragStartY == null) return;
    final delta = _dragStartY! - event.position.dy;
    if (delta > 30) {
      _dragStartY = null;
      setState(() => _isInTriggerZone = false);
      HapticFeedback.mediumImpact();
      widget.onSwipeUp();
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    _dragStartY = null;
    setState(() => _isInTriggerZone = false);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      child: Stack(
        children: [
          widget.child,
          // Zona indikator swipe di bawah
          Positioned(
            left: 0,
            right: 0,
            bottom: 56,
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: _isInTriggerZone ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  height: widget.triggerZoneHeight,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        const Color(0xff6C8EF5).withOpacity(0.18),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _pulseAnim,
                      builder: (_, __) => Opacity(
                        opacity: _pulseAnim.value,
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.keyboard_arrow_up_rounded,
                              color: Color(0xff6C8EF5),
                              size: 28,
                            ),
                            Text(
                              "Geser untuk komentar",
                              style: TextStyle(
                                color: Color(0xff6C8EF5),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Hint permanen (tidak aktif swipe)
          Positioned(
            left: 0,
            right: 0,
            bottom: 62,
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: _isInTriggerZone ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (_, __) => Opacity(
                    opacity: _pulseAnim.value * 0.5,
                    child: const Center(
                      child: Icon(
                        Icons.keyboard_arrow_up_rounded,
                        color: Color(0xff6C8EF5),
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
