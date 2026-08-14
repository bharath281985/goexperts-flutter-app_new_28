import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_sizes.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/custom_cached_image.dart';
import '../../../../core/widgets/icon_widget.dart';
import '../../../../core/widgets/share_sheet.dart';

/// A reusable document viewer shell with type-aware preview.
///
/// For images, renders the actual image from the URL.
/// For PDFs and other document types, provides an option to open externally.
class DocumentViewerPage extends StatelessWidget {
  const DocumentViewerPage({
    super.key,
    required this.type,
    this.name,
    this.url,
  });

  final String type;
  final String? name;
  final String? url;

  @override
  Widget build(BuildContext context) {
    final meta = _metaFor(type, url);
    return AppScaffold(
      appBar: AppBar(
        leading: IconTapWidget(onTap: () => Navigator.of(context).maybePop()),
        title: Text(name ?? '$type Viewer'),
        actions: [
          IconButton(
            onPressed: () => _share(context),
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share',
          ),
          IconButton(
            onPressed: () => _openExternal(context),
            icon: const Icon(Icons.download_rounded),
            tooltip: 'Download',
          ),
          IconButton(
            onPressed: () => _openExternal(context),
            icon: const Icon(Icons.open_in_browser_rounded),
            tooltip: 'Open in browser',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _preview(context, meta)),
          _toolbar(context, meta),
        ],
      ),
    );
  }

  Future<void> _openExternal(BuildContext context) async {
    if (url == null || url!.isEmpty) {
      context.showSnack('No document URL available', isError: true);
      return;
    }
    final uri = Uri.tryParse(url!);
    if (uri == null) {
      context.showSnack('Invalid document URL', isError: true);
      return;
    }
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        context.showSnack('Could not open document', isError: true);
      }
    } catch (e) {
      if (context.mounted) {
        context.showSnack('Could not open document: $e', isError: true);
      }
    }
  }

  void _share(BuildContext context) {
    if (url == null || url!.isEmpty) {
      context.showSnack('No document URL to share', isError: true);
      return;
    }
    ShareSheet.show(
      context,
      title: name ?? 'Document',
      subtitle: '$type document',
      link: url!,
    );
  }

  Widget _preview(BuildContext context, _DocMeta meta) {
    // If we have a URL and it's an image, show the actual image
    if (meta.kind == _DocKind.image && url != null && url!.isNotEmpty) {
      return InteractiveViewer(
        minScale: 0.5,
        maxScale: 4.0,
        child: Container(
          color: Colors.black,
          alignment: Alignment.center,
          child: CustomCachedImage(imageUrl: url!, fit: BoxFit.contain),
        ),
      );
    }

    // For documents with a URL, show an action-oriented preview
    if (url != null && url!.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: meta.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(meta.icon, size: 64, color: meta.color),
              ),
              AppSizes.vGapXl,
              Text(
                name ?? '$type Document',
                style: context.text.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              AppSizes.vGapSm,
              Text(
                type.toUpperCase(),
                style: context.text.labelMedium?.copyWith(
                  color: meta.color,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              AppSizes.vGapXl,
              AppSizes.vGapLg,
              FilledButton.icon(
                onPressed: () => _openExternal(context),
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Open Document'),
                style: FilledButton.styleFrom(
                  backgroundColor: meta.color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              AppSizes.vGapMd,
              Text(
                'Tap to open in your device\'s default viewer',
                style: context.text.bodySmall?.copyWith(
                  color: AppColors.subtleText,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Fallback: no URL provided
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.mutedText.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.insert_drive_file_outlined,
                size: 64,
                color: AppColors.mutedText,
              ),
            ),
            AppSizes.vGapXl,
            Text(
              'No document URL available',
              style: context.text.titleMedium?.copyWith(
                color: AppColors.subtleText,
              ),
            ),
            AppSizes.vGapSm,
            Text(
              'This document may not have been uploaded yet.',
              style: context.text.bodySmall?.copyWith(
                color: AppColors.mutedText,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _toolbar(BuildContext context, _DocMeta meta) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.lg,
          vertical: AppSizes.md,
        ),
        decoration: BoxDecoration(
          color: context.theme.cardColor,
          border: Border(top: BorderSide(color: context.theme.dividerColor)),
        ),
        child: Row(
          children: [
            Icon(meta.icon, color: meta.color),
            AppSizes.hGapMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name ?? '$type document',
                    style: context.text.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    url != null && url!.isNotEmpty
                        ? type.toUpperCase()
                        : '$type · no URL',
                    style: context.text.labelSmall,
                  ),
                ],
              ),
            ),
            if (url != null && url!.isNotEmpty) ...[
              IconButton(
                onPressed: () => _openExternal(context),
                icon: const Icon(Icons.open_in_new_rounded),
                tooltip: 'Open externally',
              ),
            ],
          ],
        ),
      ),
    );
  }

  _DocMeta _metaFor(String type, String? url) {
    // First check the explicit type parameter
    final lower = type.toLowerCase();

    // If type is generic or 'pdf', also check the URL for file extension hints
    final urlLower = (url ?? '').toLowerCase();

    String effectiveType = lower;
    if (lower == 'pdf' || lower == 'document') {
      // Keep as-is
    } else if (urlLower.contains('.png') ||
        urlLower.contains('.jpg') ||
        urlLower.contains('.jpeg') ||
        urlLower.contains('.gif') ||
        urlLower.contains('.webp')) {
      effectiveType = 'image';
    } else if (urlLower.contains('.mp4') ||
        urlLower.contains('.mov') ||
        urlLower.contains('.avi')) {
      effectiveType = 'video';
    } else if (urlLower.contains('.mp3') ||
        urlLower.contains('.wav') ||
        urlLower.contains('.aac')) {
      effectiveType = 'audio';
    }

    switch (effectiveType) {
      case 'pdf':
        return const _DocMeta(
          _DocKind.pages,
          Icons.picture_as_pdf_outlined,
          AppColors.danger,
        );
      case 'docx':
      case 'doc':
        return const _DocMeta(
          _DocKind.pages,
          Icons.description_outlined,
          AppColors.info,
        );
      case 'excel':
      case 'xlsx':
        return const _DocMeta(
          _DocKind.pages,
          Icons.table_chart_outlined,
          AppColors.success,
        );
      case 'powerpoint':
      case 'ppt':
      case 'pptx':
        return const _DocMeta(
          _DocKind.pages,
          Icons.slideshow_outlined,
          AppColors.warning,
        );
      case 'image':
      case 'png':
      case 'jpg':
        return const _DocMeta(
          _DocKind.image,
          Icons.image_outlined,
          AppColors.info,
        );
      case 'video':
      case 'mp4':
        return const _DocMeta(
          _DocKind.video,
          Icons.movie_outlined,
          AppColors.primary,
        );
      case 'audio':
      case 'mp3':
        return const _DocMeta(
          _DocKind.audio,
          Icons.audiotrack_outlined,
          AppColors.primary,
        );
      case 'zip':
      case 'archive':
        return const _DocMeta(
          _DocKind.archive,
          Icons.folder_zip_outlined,
          AppColors.mutedText,
        );
      default:
        return const _DocMeta(
          _DocKind.pages,
          Icons.insert_drive_file_outlined,
          AppColors.mutedText,
        );
    }
  }
}

enum _DocKind { pages, image, video, audio, archive }

class _DocMeta {
  const _DocMeta(this.kind, this.icon, this.color);
  final _DocKind kind;
  final IconData icon;
  final Color color;
}
