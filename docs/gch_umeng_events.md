# 友盟自定义埋点事件清单

所有事件均通过 `GchUmengSvc` 统一上报，仅在 iOS 平台生效。

---

## 一、核心转化漏斗（高优先级）

| 事件 ID | 触发时机 | 参数 | 埋点位置 |
|---|---|---|---|
| `gch_login_tap` | 点击「登录」按钮 | `event_time` | `login_page.dart` |
| `gch_login` | 登录成功 | `provider`(password/apple), `event_time` | `login_page.dart` |
| `gch_register_tap` | 点击「注册」按钮 | `event_time` | `register_page.dart` |
| `gch_register_success` | 注册成功并跳转主页 | `auth_type`, `event_time` | `register_page.dart` |
| `gch_iap_tap` | 点击底部「立即开通」胶囊按钮 | `event_time` | `purchase_style_widgets.dart` |
| `gch_payment_confirm` | 通过前置校验，实际发起支付前 | `product_id`, `provider`, `event_time` | `checkout_notifier_v2.dart` |
| `gch_purchase` | 支付凭证服务端验证成功 | `product_id`, `event_time` | `in_app_purchase_base.dart` |
| `gch_subscription_cancel` | StoreKit 返回取消或用户主动取消 | `product_id`, `event_time` | `checkout_notifier_v2.dart` |
| `gch_restore_purchase_tap` | 点击「恢复购买」按钮 | `event_time` | `checkout_page_components.dart` |
| `gch_product_select` | 选择套餐卡片 | `product_id`, `price`, `currency`, `event_time` | `checkout_notifier_v2.dart` |
| `gch_connect_tap` | 点击主页连接按钮 | `event_time` | `gch_conn_btn.dart` |
| `gch_vpn_connect` | VPN 连接成功建立 | `node`(可选), `protocol`(可选) | `gch_conn_ctrl.dart` |
| `gch_vpn_disconnect` | VPN 断开 | `duration_sec`(可选) | `gch_conn_ctrl.dart` |
| `gch_conn_fail` | VPN 连接前置检查失败或执行失败 | `reason`, `event_time` | `gch_conn_ctrl.dart` |

---

## 二、用户行为分析（中优先级）

| 事件 ID | 触发时机 | 参数 | 埋点位置 |
|---|---|---|---|
| `gch_node_select` | 用户点击某个代理节点 | `node_name`, `group_tag`, `event_time` | `proxy_node_page.dart` |
| `gch_node_switch` | 节点切换成功（from → to） | `from`, `to` | `proxy_node_page.dart` |
| `gch_speed_test` | 点击分组测速按钮 | `group_tag`, `event_time` | `proxy_node_page.dart` |
| `gch_smart_line_toggle` | 切换智能选线开关 | `enabled`(1/0), `event_time` | `proxy_node_page.dart` |
| `gch_tab_tap` | 底部 TabBar 点击 | `tab`(purchase/acceleration/more), `event_time` | `user_bottom_navigation.dart` |
| `gch_profile_module_tap` | 个人中心功能模块点击 | `module`(orders/support/privacy/about/delete_account/checkout/password_change), `event_time` | `setting_menu_list.dart` |
| `gch_service_tap` | 客服按钮点击 | `event_time` | `gch_top_bar.dart` |
| `gch_logout_tap` | 用户登出成功 | `event_time` | `user_setting_notifier.dart` |
| `gch_logout` | 用户登出（友盟 Profile 注销） | — | 随 `gch_logout_tap` 一起触发 |

---

## 三、低优先级（辅助漏斗分析）

| 事件 ID | 触发时机 | 参数 | 埋点位置 |
|---|---|---|---|
| `gch_checkout_open` | 结账页面初始化（进入购买漏斗） | `event_time` | `checkout_notifier_v2.dart` |
| `gch_search_open` | 打开代理节点搜索栏 | `event_time` | `proxy_node_page.dart` |
| `gch_page_view` | 每次路由导航 | `page`(路由路径) | `gch_umeng_observer.dart` / `gch_nav_engine.dart` |

---

## 四、页面统计（自动上报）

通过 `GchUmengObserver` + `GoRouter` 路由钩子自动上报，无需手动调用。

| 方法 | 说明 |
|---|---|
| `onPageStart(pageName)` | 进入页面（手动模式） |
| `onPageEnd(pageName)` | 离开页面（手动模式） |

---

## 五、已定义但暂未使用的方法

| 方法 | 备注 |
|---|---|
| `onVpnConnect(node, protocol)` | 可传节点和协议，当前调用不传参 |
| `onVpnDisconnect(durationSec)` | 可传时长，当前调用不传参 |
| `onNodeSwitch(from, to)` | 已在节点切换成功时调用 |
| `onProxyPageOpen()` | 预留，目前页面统计由路由钩子覆盖 |

---

## 六、接入说明

- 所有事件通过 `GchUmengSvc.onXxx()` 静态方法调用
- 若 SDK 未初始化（非 iOS 平台、初始化失败），方法调用自动跳过
- `event_time` 字段为 ISO8601 格式时间戳，便于服务端时序分析
- 友盟要求事件参数值必须为字符串，`GchUmengSvc` 内部已统一转换
- Debug 版本所有事件均有 `debugPrint` 输出，在 Android Studio Console 可见
- 友盟 Native SDK 日志（`UMConfigure.setLogEnabled`）仅在 Xcode Console 可见
