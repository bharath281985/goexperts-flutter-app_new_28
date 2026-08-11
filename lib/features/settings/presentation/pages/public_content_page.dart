import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

import '../../../../app/config/app_config.dart';
import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_sizes.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_error_state.dart';

class PublicContentPage extends StatefulWidget {
  const PublicContentPage({super.key, required this.title, required this.path});

  final String title;
  final String path;

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
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? AppErrorState(message: _error, onRetry: _load)
          : ListView(
              padding: const EdgeInsets.all(AppSizes.screenPadding),
              children: [
                Html(
                  data: _markdownToHtml(_content),
                  style: {
                    'body': Style(
                      fontSize: FontSize(16),
                      lineHeight: const LineHeight(1.6),
                      color: context.colors.onSurface,
                    ),
                    'h1': Style(
                      fontSize: FontSize(24),
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      margin: Margins.only(bottom: 16),
                    ),
                    'h2': Style(
                      fontSize: FontSize(20),
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                      margin: Margins.only(top: 24, bottom: 12),
                    ),
                    'h3': Style(
                      fontSize: FontSize(18),
                      fontWeight: FontWeight.w600,
                      color: context.colors.onSurface,
                      margin: Margins.only(top: 20, bottom: 10),
                    ),
                    'p': Style(
                      fontSize: FontSize(16),
                      margin: Margins.only(bottom: 12),
                      lineHeight: const LineHeight(1.6),
                      color: context.colors.onSurface,
                    ),
                    'ul': Style(margin: Margins.only(bottom: 16, left: 16)),
                    'li': Style(
                      fontSize: FontSize(16),
                      margin: Margins.only(bottom: 8),
                      lineHeight: const LineHeight(1.6),
                      color: context.colors.onSurface,
                    ),
                    'strong': Style(
                      fontWeight: FontWeight.w600,
                      color: context.colors.onSurface,
                    ),
                    'a': Style(
                      color: AppColors.primary,
                      textDecoration: TextDecoration.underline,
                    ),
                  },
                ),
              ],
            ),
    );
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
        buffer.write('<h1>${_escape(title)}</h1>');
      }
      if (subtitle != null && subtitle.trim().isNotEmpty) {
        buffer.write('<p>${_escape(subtitle)}</p>');
      }
      for (final section in sections.whereType<Map>()) {
        final heading = section['title']?.toString();
        final body = section['content']?.toString();
        if (heading != null && heading.trim().isNotEmpty) {
          buffer.write('<h2>${_escape(heading)}</h2>');
        }
        if (body != null && body.trim().isNotEmpty) {
          buffer.write(body);
        }
      }
      return buffer.toString();
    }
    return map['content']?.toString();
  }

  String _markdownToHtml(String source) {
    if (source.trimLeft().startsWith('<')) return source;
    final lines = source.split('\n');
    final buffer = StringBuffer();
    var inList = false;
    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) {
        if (inList) {
          buffer.write('</ul>');
          inList = false;
        }
        continue;
      }
      if (line.startsWith('### ')) {
        if (inList) {
          buffer.write('</ul>');
          inList = false;
        }
        buffer.write('<h3>${_inline(line.substring(4))}</h3>');
      } else if (line.startsWith('## ')) {
        if (inList) {
          buffer.write('</ul>');
          inList = false;
        }
        buffer.write('<h2>${_inline(line.substring(3))}</h2>');
      } else if (line.startsWith('# ')) {
        if (inList) {
          buffer.write('</ul>');
          inList = false;
        }
        buffer.write('<h1>${_inline(line.substring(2))}</h1>');
      } else if (line.startsWith('- ') || line.startsWith('* ')) {
        if (!inList) {
          buffer.write('<ul>');
          inList = true;
        }
        buffer.write('<li>${_inline(line.substring(2))}</li>');
      } else {
        if (inList) {
          buffer.write('</ul>');
          inList = false;
        }
        buffer.write('<p>${_inline(line)}</p>');
      }
    }
    if (inList) buffer.write('</ul>');
    return buffer.toString();
  }

  String _inline(String text) {
    return _escape(text).replaceAllMapped(
      RegExp(r'\*\*(.+?)\*\*'),
      (match) => '<strong>${match.group(1)}</strong>',
    );
  }

  String _escape(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');
  }
}
