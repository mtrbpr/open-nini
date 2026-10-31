import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/parsers/html_utils.dart';
import '../router.dart';

class PostBody extends StatelessWidget {
  const PostBody({required this.html, super.key});

  final String html;

  @override
  Widget build(BuildContext context) {
    if (html.trim().isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final font = Theme.of(context).textTheme.bodyLarge?.fontFamily;
    final imageWidth = MediaQuery.sizeOf(context).width - 56;
    return Html(
      data: html,
      style: {
        'body': Style(
          margin: Margins.zero,
          padding: HtmlPaddings.zero,
          fontSize: FontSize(16),
          lineHeight: const LineHeight(1.7),
          fontFamily: font,
          color: scheme.onSurface,
          direction: TextDirection.rtl,
          textAlign: TextAlign.right,
        ),
        'p': Style(margin: Margins.only(bottom: 8)),
        'a': Style(
          color: scheme.primary,
          textDecoration: TextDecoration.none,
        ),
      },
      onLinkTap: (url, attributes, element) => _openLink(context, url),
      extensions: [
        ImageExtension(
          builder: (extensionContext) {
            final src = extensionContext.attributes['src'];
            if (src == null || src.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: src,
                  width: imageWidth,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const SizedBox(
                    height: 160,
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  errorWidget: (context, url, error) => Icon(
                    Icons.broken_image_outlined,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _openLink(BuildContext context, String? url) {
    if (url == null || url.isEmpty) return;
    final topic = parseTopicLink(url);
    if (topic != null) {
      openTopic(context, id: topic.id, path: topic.path);
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) return;
    launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class QuoteBlock extends StatelessWidget {
  const QuoteBlock({required this.html, super.key});

  final String html;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border(right: BorderSide(color: scheme.primary, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'نقل‌قول',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: scheme.primary),
          ),
          PostBody(html: html),
        ],
      ),
    );
  }
}
