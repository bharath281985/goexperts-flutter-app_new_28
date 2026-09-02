import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../../app/config/app_config.dart';
import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_sizes.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/icon_widget.dart';

class PublicContentPage extends StatefulWidget {
  const PublicContentPage({
    super.key,
    required this.title,
    required this.path,
    this.showAppBar = true,
  });

  final String title;
  final String path;
  final bool showAppBar;

  @override
  State<PublicContentPage> createState() => _PublicContentPageState();
}

class _PublicContentPageState extends State<PublicContentPage> {
  bool _loading = true;
  String? _error;
  String _content = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await Dio().get<Map<String, dynamic>>(
        '${AppConfig.authBaseUrl}/public/${widget.path}',
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      final body = response.data ?? const <String, dynamic>{};
      final data = body['data'];
      final content = _extractContent(data);
      if (!mounted) return;
      setState(() {
        _content = content?.trim() ?? '';
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Unable to load ${widget.title}.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
        ? AppErrorState(message: _error, onRetry: _load)
        : ListView(
            padding: const EdgeInsets.all(AppSizes.screenPadding),
            children: _renderContent(context, _content),
          );

    if (!widget.showAppBar) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Center(
          child: IconTapWidget(
            onTap: () {
              Navigator.of(context).maybePop();
            },
          ),
        ),
        title: Text(widget.title),
      ),
      body: body,
    );
  }

  List<Widget> _renderContent(BuildContext context, String raw) {
    final clean = raw.replaceAll(RegExp(r'<[^>]*>'), '');
    final lines = clean.split('\n');
    final widgets = <Widget>[];

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) {
        widgets.add(const SizedBox(height: 8));
        continue;
      }

      if (line.startsWith('### ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 6),
          child: Text(
            line.substring(4),
            style: context.text.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ));
      } else if (line.startsWith('## ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 8),
          child: Text(
            line.substring(3),
            style: context.text.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ));
      } else if (line.startsWith('# ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 12),
          child: Text(
            line.substring(2),
            style: context.text.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ));
      } else if (line.startsWith('- ') || line.startsWith('* ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('•  ', style: TextStyle(fontWeight: FontWeight.bold)),
              Expanded(
                child: Text(
                  line.substring(2),
                  style: context.text.bodyMedium?.copyWith(height: 1.5),
                ),
              ),
            ],
          ),
        ));
      } else {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            line,
            style: context.text.bodyMedium?.copyWith(height: 1.6),
          ),
        ));
      }
    }

    return widgets;
  }

  String? _extractContent(dynamic data) {
    if (data is String) return data;
    if (data is! Map) return null;
    final map = Map<String, dynamic>.from(data);
    final content = map['content'];
    final contentValue = _contentFromValue(content);
    if (contentValue != null && contentValue.trim().isNotEmpty) {
      return contentValue;
    }

    for (final key in const ['publishedJson', 'draftJson']) {
      final raw = map[key];
      if (raw is! String || raw.trim().isEmpty) continue;
      try {
        final decoded = jsonDecode(raw);
        final value = _contentFromValue(decoded);
        if (value != null && value.trim().isNotEmpty) return value;
      } catch (_) {}
    }
    return null;
  }

  String? _contentFromValue(dynamic value) {
    if (value is String) return value;
    if (value is! Map) return null;
    final map = Map<String, dynamic>.from(value);
    final sections = map['sections'];
    if (sections is List) {
      final buffer = StringBuffer();
      final title = map['title']?.toString();
      final subtitle = map['subtitle']?.toString();
      if (title != null && title.trim().isNotEmpty) {
        buffer.writeln('# $title\n');
      }
      if (subtitle != null && subtitle.trim().isNotEmpty) {
        buffer.writeln('$subtitle\n');
      }
      for (final section in sections.whereType<Map>()) {
        final heading = section['title']?.toString();
        final body = section['content']?.toString();
        if (heading != null && heading.trim().isNotEmpty) {
          buffer.writeln('## $heading\n');
        }
        if (body != null && body.trim().isNotEmpty) {
          buffer.writeln('$body\n');
        }
      }
      return buffer.toString();
    }
    return map['content']?.toString();
  }
}
