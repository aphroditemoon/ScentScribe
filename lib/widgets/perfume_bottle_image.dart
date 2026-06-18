
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../services/perfume_image_service.dart';
import '../theme/app_theme.dart';


class PerfumeBottleImage extends StatefulWidget {
  final String perfumeName;
  final String? brand;
  final String? imageUrl;
  final String? imagePath;
  final Color? backgroundColor;
  final BoxFit fit;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final bool showLoadingState;

  const PerfumeBottleImage({
    super.key,
    required this.perfumeName,
    this.brand,
    this.imageUrl,
    this.imagePath,
    this.backgroundColor,
    this.fit = BoxFit.contain,
    this.borderRadius = 14,
    this.padding = const EdgeInsets.all(8),
    this.showLoadingState = true,
  });

  @override
  State<PerfumeBottleImage> createState() => _PerfumeBottleImageState();
}

class _PerfumeBottleImageState extends State<PerfumeBottleImage> {
  late Future<String?> _imageFuture;

  @override
  void initState() {
    super.initState();
    _imageFuture = _resolveImageUrl();
  }

  @override
  void didUpdateWidget(covariant PerfumeBottleImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.perfumeName != widget.perfumeName ||
        oldWidget.brand != widget.brand ||
        oldWidget.imageUrl != widget.imageUrl ||
        oldWidget.imagePath != widget.imagePath) {
      _imageFuture = _resolveImageUrl();
    }
  }

  Future<String?> _resolveImageUrl() async {
    final savedUrl = widget.imageUrl?.trim();
    if (savedUrl != null && savedUrl.isNotEmpty) return savedUrl;

    return PerfumeImageService.instance.findImageUrl(
      perfumeName: widget.perfumeName,
      brand: widget.brand,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: Container(
        color: widget.backgroundColor ?? AppColors.charcoal.withOpacity(0.12),
        padding: widget.padding,
        child: _buildImageContent(),
      ),
    );
  }

  Widget _buildImageContent() {
    final localPath = widget.imagePath?.trim();
    if (localPath != null && localPath.isNotEmpty) {
      return Image.file(
        File(localPath),
        fit: widget.fit,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }

    final query = '${widget.brand ?? ''} ${widget.perfumeName}'.trim();
    if (query.isEmpty) return _placeholder();

    return FutureBuilder<String?>(
      future: _imageFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            widget.showLoadingState) {
          return _loading();
        }

        final url = snapshot.data;
        if (url == null || url.isEmpty) return _placeholder();

        return CachedNetworkImage(
          imageUrl: url,
          fit: widget.fit,
          fadeInDuration: const Duration(milliseconds: 180),
          fadeOutDuration: const Duration(milliseconds: 120),
          placeholder: (_, __) => _loading(),
          errorWidget: (_, __, ___) => _placeholder(),
        );
      },
    );
  }

  Widget _loading() {
    return const Center(
      child: SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.gold,
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Image.asset(
      PerfumeImageService.placeholderAsset,
      fit: widget.fit,
      errorBuilder: (_, __, ___) => const Center(
        child: Icon(
          Icons.spa_rounded,
          color: AppColors.gold,
          size: 28,
        ),
      ),
    );
  }
}
