import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../../widgets/common/watermarked_image.dart';

class ImageOptimizer {
  /// Load optimized image with caching, placeholders and watermark „bcagencja.eu”.
  static Widget optimizedImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    return WatermarkedImage(
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) =>
            placeholder ??
            Container(
              color: AppColors.grey200,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        errorWidget: (context, url, error) =>
            errorWidget ??
            Container(
              color: AppColors.grey200,
              child: const Center(
                child: Icon(
                  AppIcons.image,
                  size: 48,
                  color: AppColors.grey400,
                ),
              ),
            ),
        memCacheWidth: width?.toInt(),
        memCacheHeight: height?.toInt(),
        maxWidthDiskCache: 1200,
        maxHeightDiskCache: 1200,
      ),
    );
  }
  
  /// Get optimized image URL with size parameters
  static String getOptimizedUrl(String originalUrl, {int? width, int? height}) {
    // This would integrate with your CDN/image service
    // For now, return original URL
    // In production, append size parameters like:
    // return '$originalUrl?w=$width&h=$height&format=webp';
    return originalUrl;
  }
  
  /// Clear image cache
  static Future<void> clearCache() async {
    await CachedNetworkImage.evictFromCache('');
  }
}
