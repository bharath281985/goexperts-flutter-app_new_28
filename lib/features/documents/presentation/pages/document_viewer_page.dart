import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_sizes.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/custom_cached_image.dart';
import '../../../../core/widgets/icon_widget.dart';
import '../../../../core/widgets/share_sheet.dart';

/// A reusable document viewer shell with in-app interactive PDF & image preview.
class DocumentViewerPage extends StatefulWidget {
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
  State<DocumentViewerPage> createState() => _DocumentViewerPageState();
}

class _DocumentViewerPageState extends State<DocumentViewerPage> {
  bool _pdfLoadError = false;
  String? _pdfErrorMessage;

  @override
  Widget build(BuildContext context) {
    final meta = _metaFor(widget.type, widget.url);
    return AppScaffold(
      appBar: AppBar(
        leading: IconTapWidget(onTap: () => Navigator.of(context).maybePop()),
        title: Text(widget.name ?? '${widget.type} Viewer'),
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
    if (widget.url == null || widget.url!.isEmpty) {
      context.showSnack('No document URL available', isError: true);
      return;
    }
    final uri = Uri.tryParse(widget.url!);
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
    if (widget.url == null || widget.url!.isEmpty) {
      context.showSnack('No document URL to share', isError: true);
      return;
    }
    ShareSheet.show(
      context,
      title: widget.name ?? 'Document',
      subtitle: '${widget.type} document',
      link: widget.url!,
    );
  }

  Widget _preview(BuildContext context, _DocMeta meta) {
    final cleanUrl = widget.url?.trim();
    final hasUrl = cleanUrl != null && cleanUrl.isNotEmpty && cleanUrl != 'null';

    // 1. Image Preview
    if (meta.kind == _DocKind.image && hasUrl) {
      return InteractiveViewer(
        minScale: 0.5,
        maxScale: 4.0,
        child: Container(
          color: Colors.black,
          alignment: Alignment.center,
          child: CustomCachedImage(imageUrl: cleanUrl, fit: BoxFit.contain),
        ),
      );
    }

    // 2. In-App Interactive PDF Viewer
    final isPdf = widget.type.toLowerCase() == 'pdf' ||
        cleanUrl?.toLowerCase().contains('.pdf') == true;

    if (isPdf && hasUrl && !_pdfLoadError) {
      return SfPdfViewer.network(
        cleanUrl!,
        canShowScrollHead: true,
        canShowScrollStatus: true,
        enableDoubleTapZooming: true,
        pageSpacing: 4,
        onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
          if (mounted) {
            setState(() {
              _pdfLoadError = true;
              _pdfErrorMessage = details.description;
            });
          }
        },
      );
    }

    // 3. For non-PDF docs or if in-app render failed, show action card
    if (hasUrl) {
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
                widget.name ?? '${widget.type} Document',
                style: context.text.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              AppSizes.vGapSm,
              Text(
                widget.type.toUpperCase(),
                style: context.text.labelMedium?.copyWith(
                  color: meta.color,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              if (_pdfErrorMessage != null) ...[
                AppSizes.vGapMd,
                Text(
                  _pdfErrorMessage!,
                  style: context.text.bodySmall?.copyWith(
                    color: AppColors.danger,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              AppSizes.vGapXl,
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
                'Tap to open in your device\'s default viewer or browser',
                style: context.text.bodySmall?.copyWith(
                  color: AppColors.subtleText,
                ),
                textAlign: TextAlign.center,
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
    final cleanUrl = widget.url?.trim();
    final hasUrl = cleanUrl != null && cleanUrl.isNotEmpty && cleanUrl != 'null';

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
                    widget.name ?? '${widget.type} document',
                    style: context.text.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    hasUrl
                        ? widget.type.toUpperCase()
                        : '${widget.type} · no URL',
                    style: context.text.labelSmall,
                  ),
                ],
              ),
            ),
            if (hasUrl) ...[
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
    final lower = type.toLowerCase();
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
