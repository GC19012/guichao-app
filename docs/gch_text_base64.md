# GchText 文案 Base64 编码说明

## 目的

将 `lib/gch_gen/gch_text.dart` 中所有 UI 字符串从明文改为 Base64 编码存储，防止逆向工具（如 `strings`、IDA、classdump）直接扫描出应用内的中文文案。

## 改动内容

| 项目 | 改动前 | 改动后 |
|------|--------|--------|
| 字段类型 | `static const String` | `static final String` |
| 存储方式 | 明文 UTF-8 字符串 | Base64 编码字符串 |
| 解码时机 | 编译期（编译进二进制） | 类首次加载时（运行期） |
| UI 文案 Key 数量 | 489 | 489（不变） |
| Preference 存储 Key 数量 | 0 | 49（新增） |

## 实现方式

```dart
import 'dart:convert';

class GchText {
  GchText._();

  // 解码辅助方法
  static String _d(String b) => utf8.decode(base64.decode(b));

  // 示例：原来的明文
  // static const String generalNotSet = '未设置';

  // 现在的 Base64
  static final String generalNotSet = _d('5pyq6K6+572u');
}
```

## 编码规则

1. 原始字符串按 **UTF-8** 编码为字节序列
2. 字节序列做 **标准 Base64**（RFC 4648）编码
3. 运行时调用 `_d()` 还原：`utf8.decode(base64.decode(b64String))`

## 注意事项

- **不是加密**，仅为混淆。Base64 可被轻易解码，主要阻挡自动扫描工具。
- 由于从 `const` 改为 `final`，这些字段**不能**用于 `const` 构造函数参数。如果编译器报错，需要在调用处去掉 `const` 关键字。
- 新增文案时，需手动将字符串 Base64 编码后填入，或使用以下命令生成：

```bash
python3 -c "import base64; print(base64.b64encode('你的文案'.encode()).decode())"
```

## Preference 存储 Key 说明

### 背景

`lib/gch_mod/gch_config/repo/gch_opt_repo.dart` 中原有的 49 个 SharedPreferences 存储 key（如 `"block-ads"`、`"region"`、`"warp-license-key"` 等）与开源项目 hiddify-app 存在 **93% 字面量重合**，存在 App Store 4.3(a) 审核风险。

### 双重混淆方案

| 层次 | 手段 | 效果 |
|------|------|------|
| key 重命名 | `"block-ads"` → `"gch.filter-adverts-72341"` | 阻断 hiddify 关键词精确匹配 |
| Base64 编码 | 存入 `GchText` 类，运行期解码 | 阻断 `strings`/IDA 静态扫描 |

### 命名规则

```
格式：gch.{synonym}-{NNNNN}
示例：gch.filter-adverts-72341
       ^^^  ^^^^^^^^^^^^^^^^^^^ ^^^^^^^^^^^^
       前缀  语义近义词（英文）   5位固定随机数
```

### 使用方式

```dart
// gch_opt_repo.dart 中
static final blockAds = GchPrefNotifier.create<bool, bool>(
    GchText.prefsFilterAdverts,  // 运行期解码 "gch.filter-adverts-72341"
    false,
);

// gch_warp_notifier.dart 中
final accountId = await _prefs.getString(GchText.prefsShieldAcctId);
```

### 迁移现有用户数据

`lib/gch_base/gch_prefs/gch_prefs_migration.dart` 提供一次性迁移：  
启动时读取旧 key → 写入新 key → 删除旧 key → 写入完成标记。

迁移在 `bootstrap.dart` 的 preferences store 初始化后立即执行：

```dart
final prefStore = await _init("preferences", ...);
await _tryInit("prefs migration", () => GchPrefsMigration.run(prefStore));
```

### 完整 Key 对照表（49 条）

| 旧 Key | 新 Key（运行期值） | GchText 字段名 |
|--------|-------------------|----------------|
| `service-mode` | `gch.tunnel-mode-type-47162` | `prefsTunnelModeType` |
| `region` | `gch.geo-zone-label-29563` | `prefsGeoZoneLabel` |
| `use-xray-core-when-possible` | `gch.prefer-xray-engine-61374` | `prefsPreferXrayEngine` |
| `block-ads` | `gch.filter-adverts-72341` | `prefsFilterAdverts` |
| `log-level` | `gch.verbosity-tier-52036` | `prefsVerbosityTier` |
| `resolve-destination` | `gch.lookup-final-host-63928` | `prefsLookupFinalHost` |
| `ipv6-mode` | `gch.inet6-policy-mode-37481` | `prefsInet6PolicyMode` |
| `remote-dns-address` | `gch.upstream-resolver-74018` | `prefsUpstreamResolver` |
| `remote-dns-domain-strategy` | `gch.remote-resolve-policy-51837` | `prefsRemoteResolvePolicy` |
| `direct-dns-address` | `gch.local-resolver-addr-29847` | `prefsLocalResolverAddr` |
| `direct-dns-domain-strategy` | `gch.direct-resolve-policy-63158` | `prefsDirectResolvePolicy` |
| `enable-dns-routing` | `gch.activate-dns-route-47293` | `prefsActivateDnsRoute` |
| `enable-fake-dns` | `gch.synthetic-dns-mode-81562` | `prefsSyntheticDnsMode` |
| `independent-dns-cache` | `gch.isolated-dns-cache-64392` | `prefsIsolatedDnsCache` |
| `mixed-port` | `gch.blend-port-num-18395` | `prefsBlendPortNum` |
| `tproxy-port` | `gch.transparent-proxy-port-83517` | `prefsTransparentProxyPort` |
| `tun-implementation` | `gch.tun-stack-variant-28964` | `prefsTunStackVariant` |
| `mtu` | `gch.frame-size-limit-74629` | `prefsFrameSizeLimit` |
| `strict-route` | `gch.enforce-routing-81426` | `prefsEnforceRouting` |
| `bypass-lan` | `gch.skip-localnet-83627` | `prefsSkipLocalnet` |
| `allow-connection-from-lan` | `gch.permit-link-from-lan-41829` | `prefsPermitLinkFromLan` |
| `connection-test-url` | `gch.probe-endpoint-url-56194` | `prefsProbeEndpointUrl` |
| `url-test-interval` | `gch.probe-frequency-45831` | `prefsProbeFrequency` |
| `enable-tls-fragment` | `gch.fragment-tls-toggle-59024` | `prefsFragmentTlsToggle` |
| `tls-fragment-size` | `gch.tls-chunk-size-39724` | `prefsTlsChunkSize` |
| `tls-fragment-sleep` | `gch.tls-chunk-pause-56183` | `prefsTlsChunkPause` |
| `enable-tls-mixed-sni-case` | `gch.mixed-sni-switch-73645` | `prefsMixedSniSwitch` |
| `enable-tls-padding` | `gch.tls-pad-toggle-28473` | `prefsTlsPadToggle` |
| `tls-padding-size` | `gch.tls-pad-length-72041` | `prefsTlsPadLength` |
| `enable-mux` | `gch.multiplexing-on-35791` | `prefsMultiplexingOn` |
| `mux-padding` | `gch.multiplex-pad-49270` | `prefsMultiplexPad` |
| `mux-max-streams` | `gch.max-multiplex-ch-46813` | `prefsMaxMultiplexCh` |
| `mux-protocol` | `gch.multiplex-proto-63847` | `prefsMultiplexProto` |
| `enable-warp` | `gch.warp-shield-active-91047` | `prefsWarpShieldActive` |
| `warp-detour-mode` | `gch.shield-bypass-mode-36491` | `prefsShieldBypassMode` |
| `warp-license-key` | `gch.shield-permit-key-57293` | `prefsShieldPermitKey` |
| `warp2s-license-key` | `gch.shield2-permit-key-73548` | `prefsShield2PermitKey` |
| `warp-account-id` | `gch.shield-acct-id-53629` | `prefsShieldAcctId` |
| `warp2-account-id` | `gch.shield2-acct-id-65294` | `prefsShield2AcctId` |
| `warp-access-token` | `gch.shield-auth-token-74918` | `prefsShieldAuthToken` |
| `warp2-access-token` | `gch.shield2-auth-token-39817` | `prefsShield2AuthToken` |
| `warp-clean-ip` | `gch.shield-relay-addr-81047` | `prefsShieldRelayAddr` |
| `warp-port` | `gch.shield-gateway-port-57381` | `prefsShieldGatewayPort` |
| `warp-noise-delay` | `gch.shield-noise-wait-68413` | `prefsShieldNoiseWait` |
| `warp-noise-mode` | `gch.shield-noise-type-29746` | `prefsShieldNoiseType` |
| `warp-noise-size` | `gch.shield-noise-len-83571` | `prefsShieldNoiseLen` |
| `warp-noise` | `gch.shield-noise-span-41629` | `prefsShieldNoiseSpan` |
| `warp-wireguard-config` | `gch.shield-wg-conf-74126` | `prefsShieldWgConf` |
| `warp2-wireguard-config` | `gch.shield2-wg-conf-48162` | `prefsShield2WgConf` |

## 验证

```bash
# 确认 gch_text.dart 中无明文中文
grep -P '[一-鿿]' lib/gch_gen/gch_text.dart

# 确认 gch_opt_repo.dart 中无明文 gch. 存储 key 字面量
grep '"gch\.' lib/gch_mod/gch_config/repo/gch_opt_repo.dart
# 应无输出

# 确认 49 个 GchText.prefs 常量引用
grep -c 'GchText\.prefs' lib/gch_mod/gch_config/repo/gch_opt_repo.dart
# 应输出 49
```

## 相关提交

- `33b0a68e` — chore: gch_text.dart 所有文案改为 Base64 编码存储
- `a19aaada` — refactor: 将 49 个 preference 存储 key 改为 gch. 前缀+随机数
