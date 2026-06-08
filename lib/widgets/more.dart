import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MoreSectionWidget extends StatefulWidget {
  final String title;
  final List<QueryDocumentSnapshot> items;
  final VoidCallback onSeeMore;
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
  late final AnimationController _btnAnimController;
  late final Animation<double> _btnOpacity;
  late final Animation<double> _btnSlide;

  bool _atEnd = false;

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController()..addListener(_onScroll);

    _btnAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _btnOpacity = CurvedAnimation(
      parent: _btnAnimController,
      curve: Curves.easeOut,
    );

    _btnSlide = Tween<double>(begin: 20, end: 0).animate(
      CurvedAnimation(parent: _btnAnimController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _btnAnimController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    final reachedEnd = pos.pixels >= pos.maxScrollExtent - 4;

    if (reachedEnd && !_atEnd) {
      _atEnd = true;
      _btnAnimController.forward();
    } else if (!reachedEnd && _atEnd) {
      _atEnd = false;
      _btnAnimController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    const int maxVisible = 6;
    final displayItems = widget.items.take(maxVisible).toList();
    final bool canScroll = widget.items.length > 2;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            widget.title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              letterSpacing: -0.3,
            ),
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
                  onNotification: (_) => false,
                  child: ListView.builder(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(
                      left: 12,
                      right: 8,
                      bottom: 8,
                      top: 4,
                    ),
                    itemCount: displayItems.length,
                    itemBuilder: (context, index) {
                      final doc = displayItems[index];
                      final ikan = doc.data() as Map<String, dynamic>;
                      return _FishCard(
                        doc: doc,
                        ikan: ikan,
                        detailBuilder: widget.detailBuilder,
                      );
                    },
                  ),
                ),

                if (canScroll)
                  AnimatedBuilder(
                    animation: _btnAnimController,
                    builder: (context, child) => Positioned(
                      right: 8,
                      top: 75,
                      child: Opacity(
                        opacity: _btnOpacity.value,
                        child: Transform.translate(
                          offset: Offset(_btnSlide.value, 0),
                          child: child,
                        ),
                      ),
                    ),
                    child: GestureDetector(
                      onTap: widget.onSeeMore,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C8EF5),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6C8EF5).withOpacity(0.40),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),
      ],
    );
  }
}

class _FishCard extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final Map<String, dynamic> ikan;
  final Widget Function(String ikanId) detailBuilder;

  const _FishCard({
    required this.doc,
    required this.ikan,
    required this.detailBuilder,
  });

  String _formatRupiah(dynamic harga) {
    final number = int.tryParse(harga.toString()) ?? 0;
    final format = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return format.format(number);
  }

  Widget _placeholder(bool isDark) => Container(
    color: isDark ? const Color(0xFF2A2A3E) : const Color(0xFFEEF3FF),
    child: Center(
      child: Icon(
        Icons.set_meal_rounded,
        size: 38,
        color: isDark ? const Color(0xFF9BAFFF) : const Color(0xFF6C8EF5),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
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
                        errorBuilder: (_, __, ___) => _placeholder(isDark),
                      )
                    : _placeholder(isDark),
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
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1A1A2E),
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
                    _formatRupiah(harga),
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
