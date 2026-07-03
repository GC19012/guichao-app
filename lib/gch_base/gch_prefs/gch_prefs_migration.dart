import 'package:guichao/gch_base/gch_prefs/gch_store.dart';
import 'package:guichao/gch_gen/gch_text.dart';

/// One-time migration: rename legacy preference storage keys to gch-prefixed
/// isolated keys to prevent string-scan similarity with third-party apps.
///
/// Safe to call on every startup — skips keys already migrated.
class GchPrefsMigration {
  static const _doneMarker = 'gch.prefs-migration-v1-done';

  static Map<String, String> get _migrations => <String, String>{
    // Core tunnel/proxy settings
    'service-mode':                GchText.prefsTunnelModeType,
    'region':                      GchText.prefsGeoZoneLabel,
    'use-xray-core-when-possible': GchText.prefsPreferXrayEngine,
    'block-ads':                   GchText.prefsFilterAdverts,
    'log-level':                   GchText.prefsVerbosityTier,
    'resolve-destination':         GchText.prefsLookupFinalHost,
    'ipv6-mode':                   GchText.prefsInet6PolicyMode,
    // DNS
    'remote-dns-address':          GchText.prefsUpstreamResolver,
    'remote-dns-domain-strategy':  GchText.prefsRemoteResolvePolicy,
    'direct-dns-address':          GchText.prefsLocalResolverAddr,
    'direct-dns-domain-strategy':  GchText.prefsDirectResolvePolicy,
    'enable-dns-routing':          GchText.prefsActivateDnsRoute,
    'enable-fake-dns':             GchText.prefsSyntheticDnsMode,
    'independent-dns-cache':       GchText.prefsIsolatedDnsCache,
    // Ports / routing
    'mixed-port':                  GchText.prefsBlendPortNum,
    'tproxy-port':                 GchText.prefsTransparentProxyPort,
    'tun-implementation':          GchText.prefsTunStackVariant,
    'mtu':                         GchText.prefsFrameSizeLimit,
    'strict-route':                GchText.prefsEnforceRouting,
    'bypass-lan':                  GchText.prefsSkipLocalnet,
    'allow-connection-from-lan':   GchText.prefsPermitLinkFromLan,
    // Test
    'connection-test-url':         GchText.prefsProbeEndpointUrl,
    'url-test-interval':           GchText.prefsProbeFrequency,
    // TLS tricks
    'enable-tls-fragment':         GchText.prefsFragmentTlsToggle,
    'tls-fragment-size':           GchText.prefsTlsChunkSize,
    'tls-fragment-sleep':          GchText.prefsTlsChunkPause,
    'enable-tls-mixed-sni-case':   GchText.prefsMixedSniSwitch,
    'enable-tls-padding':          GchText.prefsTlsPadToggle,
    'tls-padding-size':            GchText.prefsTlsPadLength,
    // Mux
    'enable-mux':                  GchText.prefsMultiplexingOn,
    'mux-padding':                 GchText.prefsMultiplexPad,
    'mux-max-streams':             GchText.prefsMaxMultiplexCh,
    'mux-protocol':                GchText.prefsMultiplexProto,
    // Warp
    'enable-warp':                 GchText.prefsWarpShieldActive,
    'warp-detour-mode':            GchText.prefsShieldBypassMode,
    'warp-license-key':            GchText.prefsShieldPermitKey,
    'warp2s-license-key':          GchText.prefsShield2PermitKey,
    'warp-account-id':             GchText.prefsShieldAcctId,
    'warp2-account-id':            GchText.prefsShield2AcctId,
    'warp-access-token':           GchText.prefsShieldAuthToken,
    'warp2-access-token':          GchText.prefsShield2AuthToken,
    'warp-clean-ip':               GchText.prefsShieldRelayAddr,
    'warp-port':                   GchText.prefsShieldGatewayPort,
    'warp-noise-delay':            GchText.prefsShieldNoiseWait,
    'warp-noise-mode':             GchText.prefsShieldNoiseType,
    'warp-noise-size':             GchText.prefsShieldNoiseLen,
    'warp-noise':                  GchText.prefsShieldNoiseSpan,
    'warp-wireguard-config':       GchText.prefsShieldWgConf,
    'warp2-wireguard-config':      GchText.prefsShield2WgConf,
  };

  static Future<void> run(GchStore store) async {
    if (await store.has(_doneMarker)) return;

    for (final entry in _migrations.entries) {
      final oldKey = entry.key;
      final newKey = entry.value;

      if (!await store.has(oldKey)) continue;
      if (await store.has(newKey)) {
        await store.delete(oldKey);
        continue;
      }

      final value = await store.get<dynamic>(oldKey);
      if (value != null) {
        await store.put<dynamic>(newKey, value);
      }
      await store.delete(oldKey);
    }

    await store.put<bool>(_doneMarker, true);
  }
}
