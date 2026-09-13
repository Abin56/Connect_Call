import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Circular avatar with an online/offline presence dot. Falls back to the
/// user's initial when there's no profile image.
class UserAvatar extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final double radius;
  final bool? isOnline;

  const UserAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.radius = 24,
    this.isOnline,
  });

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final surfaceColor = Theme.of(context).scaffoldBackgroundColor;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: AppColors.nearBlack,
          backgroundImage: (imageUrl != null && imageUrl!.isNotEmpty)
              ? CachedNetworkImageProvider(imageUrl!)
              : null,
          child: (imageUrl == null || imageUrl!.isEmpty)
              ? Text(
                  initial,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: radius * 0.7,
                  ),
                )
              : null,
        ),
        if (isOnline != null)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: radius * 0.4,
              height: radius * 0.4,
              decoration: BoxDecoration(
                color: isOnline!
                    ? context.onlineColor
                    : Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.3),
                shape: BoxShape.circle,
                border: Border.all(color: surfaceColor, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}
