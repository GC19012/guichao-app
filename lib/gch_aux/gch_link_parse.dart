import 'dart:convert';

import 'package:dartx/dartx.dart';
import 'package:guichao/gch_aux/gch_validate.dart';

typedef ProfileLink = ({String url, String name});

// TODO: test and improve
abstract class LinkParser {
  // protocols schemas
  static const protocols = {'guichao'};

  static ProfileLink? parse(String link) {
    return simple(link) ?? deep(link);
  }

  static ProfileLink? simple(String link) {
    if (!isUrl(link)) return null;
    final uri = Uri.parse(link.trim());
    return (
      url: uri.toString(),
      name: uri.queryParameters['name'] ?? '',
    );
  }

  static ({String content, String name})? protocol(String content) {
    return null;
  }

  static ProfileLink? deep(String link) {
    final uri = Uri.tryParse(link.trim());
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) return null;
    final queryParams = uri.queryParameters;
    switch (uri.scheme) {
      case 'clash' || 'clashmeta' when uri.authority == 'install-config':
        if (uri.authority != 'install-config' || !queryParams.containsKey('url')) return null;
        return (url: queryParams['url']!, name: queryParams['name'] ?? '');
      case 'guichao':
        if (uri.authority == "import") {
          return (url: uri.path.substring(1) + (uri.hasQuery ? "?${uri.query}" : ""), name: uri.fragment);
        }
        //for backward compatibility
        if ((uri.authority != 'install-config' && uri.authority != 'install-sub') || !queryParams.containsKey('url')) return null;
        return (url: queryParams['url']!, name: queryParams['name'] ?? '');
      default:
        return null;
    }
  }
}

String safeDecodeBase64(String str) {
  try {
    return utf8.decode(base64Decode(str));
  } catch (e) {
    return str;
  }
}
