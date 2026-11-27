import 'dart:io';

import 'package:flutter/material.dart';

ImageProvider? resolveImageProvider(String? path) {
  if (path == null || path.isEmpty) return null;
  if (path.startsWith('asset:')) {
    return AssetImage(path.substring(6));
  }
  if (path.startsWith('http://') || path.startsWith('https://')) {
    return NetworkImage(path);
  }
  final f = File(path);
  if (f.existsSync()) return FileImage(f);
  return null;
}

class AvatarWidget extends StatelessWidget {
  const AvatarWidget({
    super.key,
    required this.emoji,
    this.imagePath,
    this.radius = 20,
    this.onTap,
  });

  final String emoji;
  final String? imagePath;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final provider = resolveImageProvider(imagePath);

    Widget avatar;
    if (provider != null) {
      avatar = Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: accent.withValues(alpha: 0.12),
          image: DecorationImage(image: provider, fit: BoxFit.cover),
        ),
      );
    } else {
      avatar = CircleAvatar(
        radius: radius,
        backgroundColor: accent.withValues(alpha: 0.14),
        child: Text(
          emoji.isEmpty ? '♡' : emoji,
          style: TextStyle(color: accent, fontSize: radius * 0.85),
        ),
      );
    }

    if (onTap == null) return avatar;
    return GestureDetector(onTap: onTap, child: avatar);
  }
}

class VerifiedBadge extends StatelessWidget {
  const VerifiedBadge({super.key, this.size = 16});

  final double size;

  @override
  Widget build(BuildContext context) => Icon(
        Icons.verified_rounded,
        size: size,
        color: Theme.of(context).colorScheme.primary,
      );
}

class AppMediaImage extends StatelessWidget {
  const AppMediaImage({
    super.key,
    required this.path,
    this.height,
    this.fit = BoxFit.cover,
  });

  final String path;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (path.startsWith('asset:')) {
      return Image.asset(
        path.substring(6),
        height: height,
        width: double.infinity,
        fit: fit,
        errorBuilder: (_, __, ___) => _placeholder(context),
      );
    }
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        height: height,
        width: double.infinity,
        fit: fit,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            height: height ?? 200,
            color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
            alignment: Alignment.center,
            child: const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        errorBuilder: (_, __, ___) => _placeholder(context),
      );
    }
    final file = File(path);
    if (!file.existsSync()) return _placeholder(context);
    return Image.file(
      file,
      height: height,
      width: double.infinity,
      fit: fit,
      errorBuilder: (_, __, ___) => _placeholder(context),
    );
  }

  Widget _placeholder(BuildContext context) => Container(
        height: height ?? 160,
        color: Theme.of(context).dividerColor.withValues(alpha: 0.18),
        alignment: Alignment.center,
        child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
      );
}
