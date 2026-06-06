import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Widget horizontal-scrollable untuk section "Disarankan", "Langganan", "Terdekat".
///
/// Cara kerja overscroll:
/// - Maksimal 6 card ditampilkan secara horizontal
/// - Saat user scroll sampai card terakhir dan MASIH paksa scroll ke kanan,
///   muncul overlay hint "Lihat Semua " di kanan
/// - Jika user lepas (overscroll cukup), otomatis navigate ke screen penuh
/// - Tombol "Lihat Semua" di header juga selalu bisa ditekan
class MoreSectionWidget extends StatefulWidget {
  final String title;
  final List<QueryDocumentSnapshot> items;
  final VoidCallback onSeeMore;

  /// Builder untuk membuka halaman detail.
  /// Contoh: detailBuilder: (id) => DetailScreen(ikanId: id)
  final Widget Function(String ikanId) detailBuilder;

  const MoreSectionWidget({
    super.key,
    required this.title,
    required this.items,
    required this.onSeeMore,
    required this.detailBuilder,
  });

  @override
  State<MoreSectionWidget> createState() => _MoreSectionWidgetState();
}

class _MoreSectionWidgetState extends State<MoreSectionWidget>
    with SingleTickerProviderStateMixin {
  late final ScrollController _scrollController;
  late final AnimationController _hintAnimController;
  late final Animation<double> _hintOpacity;
  late final Animation<double> _hintSlide;

  // Seberapa jauh overscroll sebelum trigger navigate (dalam pixel)
  static const double _triggerThreshold = 60.0;

  double _overscrollAmount = 0.0;
  bool _navigating = false;

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController();

    _hintAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _hintOpacity = CurvedAnimation(
      parent: _hintAnimController,
      curve: Curves.easeOut,
    );

    _hintSlide = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(parent: _hintAnimController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _hintAnimController.dispose();
    super.dispose();
  }

  bool _onNotification(ScrollNotification notification) {
    // OverscrollNotification terjadi saat user paksa scroll melewati batas
    if (notification is OverscrollNotification) {
      // Hanya peduli overscroll ke KANAN (nilai positif)
      if (notification.overscroll > 0) {
        setState(() {
          _overscrollAmount += notification.overscroll;
        });

        // Tampilkan hint saat mulai overscroll
        if (_overscrollAmount > 5 && !_hintAnimController.isCompleted) {
          _hintAnimController.forward();
        }

        // Trigger navigate jika overscroll cukup jauh
        if (_overscrollAmount >= _triggerThreshold && !_navigating) {
          _navigating = true;
          // Sedikit delay agar user sempat lihat hint
          Future.delayed(const Duration(milliseconds: 150), () {
            if (mounted) {
              setState(() => _overscrollAmount = 0);
              _hintAnimController.reverse();
              _navigating = false;
              widget.onSeeMore();
            }
          });
        }
      }
    }

    // Reset saat scroll kembali normal
    if (notification is ScrollUpdateNotification) {
      if (_overscrollAmount > 0 &&
          notification.scrollDelta != null &&
          notification.scrollDelta! < 0) {
        setState(() => _overscrollAmount = 0);
        _hintAnimController.reverse();
      }
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    const int maxVisible = 6;
    final displayItems = widget.items.take(maxVisible).toList();

    final double overscrollProgress = (_overscrollAmount / _triggerThreshold)
        .clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                  letterSpacing: -0.3,
                ),
              ),
              GestureDetector(
                onTap: widget.onSeeMore,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C8EF5).withOpacity(0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Lihat Semua',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6C8EF5),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Transform.translate(
          offset: const Offset(-12, 0),
          child: SizedBox(
            width: MediaQuery.of(context).size.width - 16 + 12,
            height: 213,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                NotificationListener<ScrollNotification>(
                  onNotification: _onNotification,
                  child: ListView.builder(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.only(
                      left: 12,
                      right: 4,
                      bottom: 8,
                      top: 4,
                    ),
                    itemCount: displayItems.length,
                    itemBuilder: (context, index) {
                      final doc = displayItems[index];
                      final ikan = doc.data() as Map<String, dynamic>;
                      final bool isLast = index == displayItems.length - 1;

                      return _FishCard(
                        doc: doc,
                        ikan: ikan,
                        detailBuilder: widget.detailBuilder,
                        isLast: isLast,
                      );
                    },
                  ),
                ),

                AnimatedBuilder(
                  animation: _hintAnimController,
                  builder: (context, child) {
                    return Positioned(
                      right: 0,
                      top: 0,
                      bottom: 6,
                      child: Opacity(
                        opacity: _hintOpacity.value,
                        child: Transform.translate(
                          offset: Offset(_hintSlide.value, 0),
                          child: child,
                        ),
                      ),
                    );
                  },
                  child: GestureDetector(
                    onTap: widget.onSeeMore,
                    child: Container(
                      width: 90,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            const Color(
                              0xFFF4F6FF,
                            ).withOpacity(0.7 + (overscrollProgress * 0.3)),
                            const Color(0xFFF4F6FF),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Lingkaran progress
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 42,
                                    height: 42,
                                    child: CircularProgressIndicator(
                                      value: overscrollProgress,
                                      strokeWidth: 2.5,
                                      backgroundColor: const Color(
                                        0xFF6C8EF5,
                                      ).withOpacity(0.15),
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                            Color(0xFF6C8EF5),
                                          ),
                                    ),
                                  ),
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF6C8EF5),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF6C8EF5,
                                          ).withOpacity(0.35),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.arrow_forward_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Lihat\nSemua',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF6C8EF5),
                                  fontWeight: FontWeight.w700,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ), // tutup Transform.translate > SizedBox

        const SizedBox(height: 20),
      ],
    );
  }
}

class _FishCard extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final Map<String, dynamic> ikan;
  final Widget Function(String ikanId) detailBuilder;
  final bool isLast;

  const _FishCard({
    required this.doc,
    required this.ikan,
    required this.detailBuilder,
    this.isLast = false,
  });

  Widget _placeholder() => Container(
    color: const Color(0xFFEEF3FF),
    child: const Center(
      child: Icon(Icons.set_meal_rounded, size: 38, color: Color(0xFF6C8EF5)),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final lokasiText = ikan['lokasi']?.toString() ?? '-';
    final harga = ikan['harga']?.toString() ?? '0';
    final nama = ikan['nama']?.toString() ?? '-';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => detailBuilder(doc.id)),
      ),
      child: Container(
        width: 148,
        margin: EdgeInsets.only(right: isLast ? 70 : 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C8EF5).withOpacity(0.10),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 112,
                child:
                    ikan['gambar'] != null &&
                        ikan['gambar'].toString().isNotEmpty
                    ? Image.memory(
                        base64Decode(ikan['gambar']),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nama,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E),
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        size: 11,
                        color: Color(0xFF9E9E9E),
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          lokasiText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF9E9E9E),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Rp $harga',
                    style: const TextStyle(
                      color: Color(0xFF6C8EF5),
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
