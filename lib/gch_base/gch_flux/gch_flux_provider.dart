import 'package:guichao/gch_base/gch_app_xinxi/gch_yingyong_xinxi.dart';
import 'package:guichao/gch_base/gch_core/gch_nucleus.dart';
import 'package:guichao/gch_base/gch_flux/gch_flux_engine.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'gch_flux_provider.g.dart';

@Riverpod(keepAlive: true)
GchFluxEngine gchFlux(GchFluxRef ref) {
  final appInfoAsync = ref.watch(gchYingyongXinxiProvider);
  final userAgent = appInfoAsync.when(
    data: (appInfo) => appInfo.agentTag,
    loading: () => "guichao/0.0.0 (Unknown)",
    error: (_, __) => "guichao/0.0.0 (Unknown)",
  );
  
  final client = GchFluxEngine(
    config: GchFluxConfig(
      timeout:const Duration(seconds: 15),  // 下载需要更长时间
      userAgent: userAgent,
      debug: GchNucleus.isDevMode,
    ),
  );

  return client;
}
