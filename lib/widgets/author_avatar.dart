import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;

import 'svg_classes.dart';

class AuthorAvatar extends StatelessWidget {
  const AuthorAvatar({required this.url, this.size = defaultSize, super.key});

  final String? url;
  final double size;

  static const defaultSize = 40.0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: _picture(scheme),
      ),
    );
  }

  Widget _picture(ColorScheme scheme) {
    final url = this.url;
    if (url == null || url.isEmpty) return avatarFallback(scheme);
    if (_isSvg(url)) return _SvgAvatar(url: url, size: size);
    return CachedNetworkImage(
      imageUrl: url,
      width: size,
      height: size,
      fit: BoxFit.cover,
      placeholder: (_, _) => avatarFallback(scheme),
      errorWidget: (_, _, _) => avatarFallback(scheme),
    );
  }

  bool _isSvg(String url) {
    final path = Uri.tryParse(url)?.path.toLowerCase() ?? url.toLowerCase();
    return path.endsWith('.svg');
  }
}

class _SvgAvatar extends StatefulWidget {
  const _SvgAvatar({required this.url, required this.size});

  final String url;
  final double size;

  @override
  State<_SvgAvatar> createState() => _SvgAvatarState();
}

class _SvgAvatarState extends State<_SvgAvatar> {
  late Future<String?> _svg;

  @override
  void initState() {
    super.initState();
    _svg = _load(widget.url);
  }

  @override
  void didUpdateWidget(_SvgAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _svg = _load(widget.url);
    }
  }

  Future<String?> _load(String url) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return null;
      return inlineSvgClasses(utf8.decode(response.bodyBytes, allowMalformed: true));
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FutureBuilder<String?>(
      future: _svg,
      builder: (context, snapshot) {
        final svg = snapshot.data;
        if (svg == null || svg.isEmpty) return avatarFallback(scheme);
        return SvgPicture.string(
          svg,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
          placeholderBuilder: (_) => avatarFallback(scheme),
          errorBuilder: (_, _, _) => avatarFallback(scheme),
        );
      },
    );
  }
}

Widget avatarFallback(ColorScheme scheme) {
  return ColoredBox(
    color: scheme.surfaceContainerHighest,
    child: Center(
      child: Icon(Icons.person, size: 22, color: scheme.onSurfaceVariant),
    ),
  );
}
