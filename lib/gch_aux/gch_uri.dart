import 'package:guichao/gch_aux/gch_log_mix.dart';
import 'package:loggy/loggy.dart';
import 'package:url_launcher/url_launcher.dart';

abstract class UriUtils {
  static final loggy = Loggy<GchInfraLogger>("UriUtils");

  static Future<bool> tryShareOrLaunchFile(Uri uri, {Uri? fileOrDir}) async {
    return tryLaunch(fileOrDir ?? uri);
  }

  static Future<bool> tryLaunch(Uri uri) async {
    try {
      loggy.debug("launching [$uri]");
      if (!await canLaunchUrl(uri)) {
        loggy.warning("can't launch [$uri]");
        return false;
      }
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e, stackTrace) {
      loggy.warning("error launching [$uri]", e, stackTrace);
      return false;
    }
  }
}
