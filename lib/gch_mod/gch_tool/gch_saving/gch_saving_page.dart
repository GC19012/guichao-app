import 'package:flutter/material.dart';
import 'package:guichao/gch_aux/gch_responsive.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _bg = Color(0xFFF1EFF9);
const _accent = Color(0xFF5969FF);
const _vipGold = Color(0xFFFFAA00);
const _card = Colors.white;
const _textPrimary = Color(0xFF1A1A2E);
const _textSecondary = Color(0xFF666680);
const _textMuted = Color(0xFF9999B3);

// ─── 数据模型 ──────────────────────────────────────────────────────────────────

class _Tip {
  final String id;
  final String title;
  final String desc;
  final List<String> countries;
  final bool isVip;
  const _Tip(this.id, this.title, this.desc,
      {this.countries = const [], this.isVip = false});
}

class _Category {
  final String name;
  final IconData icon;
  final Color color;
  final List<_Tip> tips;
  const _Category(this.name, this.icon, this.color, this.tips);
}

// ─── 国家列表 ──────────────────────────────────────────────────────────────────

const _allCountries = ['全部', '美国', '英国', '澳洲', '加拿大', '日本', '新加坡', '韩国'];

// ─── 攻略数据 ──────────────────────────────────────────────────────────────────

const _categories = [
  _Category('教育优惠', Icons.school_rounded, Color(0xFF5969FF), [
    _Tip('edu1', 'Apple 教育优惠',
        '凭学生邮箱在教育商店购买 Mac、iPad、AirPods 最高立减 ¥1500（美区约 \$200），每学年限购一次，返校季可叠加礼品卡活动'),
    _Tip('edu2', 'Microsoft 365 免费',
        '大多数高校通过 Azure for Education 提供免费 Office 全套，用学校邮箱登录 office.com 选教育版激活，无需付任何费用'),
    _Tip('edu3', 'GitHub Student Pack',
        '免费获得 100+ 工具：Namecheap 免费域名、DigitalOcean \$200 云服务器额度、JetBrains 全家桶 IDE，合计价值超 \$2000'),
    _Tip('edu4', 'Adobe Creative Cloud 学生版',
        '首年约 ¥1888/年，打折超 60%，含 Photoshop、Premiere Pro、After Effects 全套。注意：毕业后价格将跳回原价，提前续期更划算'),
    _Tip('edu5', 'JetBrains 全家桶免费',
        '凭学校邮箱申请 Educational License，IntelliJ IDEA、PyCharm、WebStorm、GoLand 等全部免费，每年重新验证续期'),
    _Tip('edu6', 'Notion 学生 Plus',
        '用 .edu 邮箱或上传在读证明，免费升级 Plus 计划（含 AI 功能折扣），不申请则每月需 \$10'),
    _Tip('edu7', 'Spotify / YouTube Premium 学生版',
        'Spotify 美区学生版 \$5.99/月（正常 \$11.99），YouTube Premium \$6.99/月，每年通过 SheerID 验证一次在读状态即可续享',
        countries: ['美国', '英国', '澳洲', '加拿大']),
    _Tip('edu8', 'Canva for Education',
        '通过学校邮箱申请，完全免费使用 Canva Pro 全功能，含海量模板和素材库，制作 PPT、海报、简历首选'),
  ]),
  _Category('生活必备', Icons.local_offer_rounded, Color(0xFF2ECC9A), [
    _Tip('life1', 'Amazon Prime Student',
        '免费试用 6 个月，后续享正常价格 50% 折扣（约 \$7.49/月）。含 2 天免费快递、Prime Video、Prime Music，年度综合性价比最高',
        countries: ['美国', '英国', '日本']),
    _Tip('life2', 'UNiDAYS / Student Beans',
        '注册即可访问 800+ 品牌折扣：Nike 10%、ASOS 10–15%、Gymshark 10%、Dell 5%……购物前先在这里搜一下，经常有惊喜'),
    _Tip('life3', 'Costco 批量采购',
        '年费 \$65（美/加），日用品批量采购可省 30–40%。多人合住分摊年费，厨纸、洗洁精、零食的性价比远超普通超市',
        countries: ['美国', '加拿大']),
    _Tip('life4', 'Aldi / Lidl 超市',
        '德系平价超市，同类商品比 Tesco/Woolworths/Kroger 便宜约 25%，日常蔬果、肉类、乳制品首选，品质不输主流超市',
        countries: ['英国', '澳洲', '美国']),
    _Tip('life5', 'Facebook Marketplace 二手',
        '搬家季（5–9月）大量留学生低价出售家具家电，沙发、床架、微波炉常见 1–3 折。搬入前一周蹲守，可淘到几乎全新物品'),
    _Tip('life6', '本地图书馆卡',
        '免费申请，可借实体书、电子书（Libby / OverDrive App）、有声书，还能免费打印。善用图书馆可每年省去数百元教材费用'),
    _Tip('life7', 'Honey / Capital One Shopping',
        '安装浏览器插件后，结账时自动搜索并应用最优优惠码，Amazon 购物可自动比价，调研显示每年平均省 \$126',
        countries: ['美国']),
    _Tip('life8', '超市积分返现 App',
        'Ibotta（美）/ Checkout 51（加）/ Shopmium（英）等 App，上传超市购物小票可返现，坚持使用每月可省 \$20–50',
        countries: ['美国', '加拿大', '英国']),
  ]),
  _Category('出行交通', Icons.directions_transit_rounded, Color(0xFFFF7043), [
    _Tip('travel1', '16-25 Railcard（英国）',
        '年费 £30（3年卡 £70），全英火车票享三分之一折扣。London→Manchester 原价 £150，折后约 £100，月均出行 2 次即可回本',
        countries: ['英国']),
    _Tip('travel2', 'Concession 交通卡（澳洲）',
        'Myki / Opal / Go Card 学生优惠卡，持有效在读证明申请，全程约半价。悉尼、墨尔本、布里斯班、珀斯均适用',
        countries: ['澳洲']),
    _Tip('travel3', 'MTA / MBTA 学生月票（美国）',
        '纽约 MTA 和波士顿 MBTA 均有学生优惠月票，部分大学通过校园一卡通直接提供补贴，入学时务必询问',
        countries: ['美国']),
    _Tip('travel4', 'Google Flights 订票技巧',
        '日期选"灵活±3天"对比，周二/三出发通常最便宜；开启价格追踪，降价自动通知；避开学校假期前后各 1 周出行高峰'),
    _Tip('travel5', '廉价航空要诀',
        '英国 Ryanair / EasyJet、澳洲 Jetstar、美国 Spirit / Frontier，提前 6–8 周购买可省 50–70%。注意行李额外计费，只带随身行李最省'),
    _Tip('travel6', 'Amtrak 长途火车（美国）',
        '持学生证享约 10% 折扣，提前 45 天购 Saver 票可省 60%；西海岸 Coast Starlight 线（洛杉矶↔西雅图）沿途风景极佳且超值',
        countries: ['美国']),
    _Tip('travel7', '青春18切符（日本）',
        '每年特定时期发售，5次分割票约 ¥12050，可乘坐全国 JR 普通/快速列车，适合多城市游学，是低价长途出行神器',
        countries: ['日本']),
    _Tip('travel8', 'Zipcar / GoGet 共享汽车',
        '凭学生证注册享优惠费率，按小时/天计费，车险保险全含。适合周末出行，月均使用超过 2 次比 Uber/Lyft 更省',
        countries: ['美国', '英国', '澳洲'], isVip: true),
  ]),
  _Category('手机网络', Icons.phone_android_rounded, Color(0xFF9B6FFF), [
    _Tip('phone1', 'T-Mobile 学生套餐（美国）',
        'Magenta 学生版 \$25/月起，含无限通话/短信/数据。凭 .edu 邮箱或 SheerID 验证；和朋友拼家庭套餐每人可进一步降至 \$20 以下',
        countries: ['美国']),
    _Tip('phone2', 'giffgaff（英国）',
        '月付无合约，从 £6/月（1GB）到 £25/月（无限流量），随时更改套餐无违约金。无需信用记录，SIM 卡免费邮寄，留英首选',
        countries: ['英国']),
    _Tip('phone3', '楽天 Mobile + IIJmio（日本）',
        '楽天 Mobile 1GB 以下完全免费，超出 ¥1078/月封顶；IIJmio 最低 ¥880/月含 2GB，两卡组合使用可实现最低成本',
        countries: ['日本']),
    _Tip('phone4', 'Google Fi（美国）',
        '按量计费 \$10/GB（每月最多 \$50 封顶），200+ 国家漫游免费，适合经常回国或多国旅行的留学生，避免高额漫游费',
        countries: ['美国']),
    _Tip('phone5', 'Koodo / Public Mobile（加拿大）',
        '加拿大手机费普遍偏贵，Koodo 和 Public Mobile 经常有 \$29–34/月 的促销套餐（15–20GB），明显优于三大运营商',
        countries: ['加拿大']),
    _Tip('phone6', 'SMARTY / VOXI（英国）',
        'SMARTY 超出流量可转入下月额度；VOXI 社交媒体流量（Instagram、TikTok、YouTube 等）不计入套餐额度，重度用户推荐',
        countries: ['英国']),
    _Tip('phone7', '国内保号最省方案',
        '移动神州行保号套餐 5 元/月可接收短信，支持开通国际漫游；联通/电信均有类似低资费保号，出国前开通避免号码被回收'),
    _Tip('phone8', 'Wi-Fi Calling 省国际漫游',
        'iPhone 开启 Wi-Fi 通话功能，Wi-Fi 环境下通过套餐分钟数拨打国内电话完全免费。配合 iMessage 和微信，几乎无需支付漫游费'),
  ]),
  _Category('退税攻略', Icons.receipt_long_rounded, Color(0xFFFFB300), [
    _Tip('tax1', '英国 VAT 退税（20%）',
        '购物总额 ≥ £30 可申请，向商户索取 Tax Refund / Tax Free 表格，离境时在机场海关盖章，凭护照和收据在退税柜台取现或退卡',
        countries: ['英国']),
    _Tip('tax2', '澳洲 TRS 退税（10%）',
        '离境前 60 天内在同一商户购物满 A\$300，保留发票，在机场 TRS（Tourist Refund Scheme）柜台办理，可退还 10% GST',
        countries: ['澳洲']),
    _Tip('tax3', '日本免税购物（8–10%）',
        '在贴有 Tax Free 标志的商店，持护照购物满 5000 日元（含税）可免消费税（一般商品 10%，食品 8%）。出示护照现场抵扣',
        countries: ['日本']),
    _Tip('tax4', '美国免税州购物',
        '俄勒冈（OR）、蒙大拿（MT）、新罕布什尔（NH）、特拉华（DE）、阿拉斯加（AK）五州无消费税，购买电子产品建议专程前往',
        countries: ['美国']),
    _Tip('tax5', '韩国 Tax Refund（7–11%）',
        '持护照在贴有 Tax Free 标志的商店购物单笔满 3 万韩元即可申请，机场有自助退税机，操作约 5 分钟，当场退现金或刷卡退回',
        countries: ['韩国']),
    _Tip('tax6', '美国年度报税（F1 必做）',
        'F1 学生每年须提交 Form 8843（无收入也需提交），有奖学金/打工收入需提交 1040NR，可能退回部分代扣税。Sprintax 软件可协助',
        countries: ['美国'], isVip: true),
    _Tip('tax7', '英国年度退税（P800）',
        '英国打工学生年终可能因税码问题多缴税，收到 HMRC 的 P800 表格后可申请退款，或主动登录 Government Gateway 账户查询',
        countries: ['英国'], isVip: true),
  ]),
  _Category('银行卡选择', Icons.credit_card_rounded, Color(0xFF26C6DA), [
    _Tip('bank1', 'Wise 多币种卡（强烈推荐）',
        '持有 40+ 币种本地账户，汇率使用真实中间市场价（非银行牌价），费率约 0.4–1.0%，无月费。留学换汇和汇款综合成本最低，首选'),
    _Tip('bank2', 'Revolut（英 / 欧 / 澳）',
        '欧洲、英国、澳洲通用，汇率透明，标准版免月费含每月 £1000 免手续费换汇额度，超出后 0.5% 手续费。旅行换汇必备',
        countries: ['英国', '澳洲']),
    _Tip('bank3', '招商银行全币卡',
        '境外刷卡手续费约 1.5%，国内以人民币还款方便，国内家长也可协助还款。适合需要中外账户频繁操作的留学生'),
    _Tip('bank4', '避免 DCC 动态货币兑换',
        '海外刷卡时若收银机提示"以人民币结算"，必须选择【以当地货币结算】，拒绝 DCC，否则商家汇率可额外多扣 2–4%'),
    _Tip('bank5', '新加坡 DBS / OCBC 账户',
        'DBS 多付宝开户无最低存款，支持多国转账；OCBC Frank 学生账户零月费，绑定 PayNow 实时收款，东南亚留学首选',
        countries: ['新加坡']),
    _Tip('bank6', 'Discover Student Card（美国）',
        '无需信用记录即可申请，无年费，是在美建立信用分的首选工具。每月全额还清无利息，消费返现 1–5%，用来建分性价比最高',
        countries: ['美国'], isVip: true),
    _Tip('bank7', '汇丰 One 国际转账（英国）',
        '在英国或香港开立汇丰账户，与国内汇丰账户互转手续费极低甚至免费，适合有大额（>5万）资金往来需求的留学生',
        countries: ['英国'], isVip: true),
  ]),
];

// ─── Page ─────────────────────────────────────────────────────────────────────

class GchSavingPage extends StatefulWidget {
  const GchSavingPage({super.key});

  @override
  State<GchSavingPage> createState() => _PageState();
}

class _PageState extends State<GchSavingPage> {
  String _country = '全部';
  Set<String> _favs = {};

  @override
  void initState() {
    super.initState();
    _loadFavs();
  }

  Future<void> _loadFavs() async {
    final p = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _favs = Set.from(p.getStringList('gch_saving_favs') ?? []));
    }
  }

  Future<void> _toggleFav(String id) async {
    final p = await SharedPreferences.getInstance();
    setState(() => _favs.contains(id) ? _favs.remove(id) : _favs.add(id));
    await p.setStringList('gch_saving_favs', _favs.toList());
  }

  List<_Tip> _filter(List<_Tip> tips) {
    if (_country == '全部') return tips;
    return tips.where((t) => t.countries.isEmpty || t.countries.contains(_country)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        title: Text(
          '留学省钱手册',
          style: TextStyle(color: _textPrimary, fontSize: 17.rf, fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: _textPrimary),
        centerTitle: true,
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 16.rw),
        children: [
          SizedBox(height: 8.rh),
          _CountryRow(
            selected: _country,
            onChanged: (v) => setState(() => _country = v),
          ),
          SizedBox(height: 4.rh),
          // 收藏分类（有收藏时显示）
          if (_favs.isNotEmpty) ...[
            SizedBox(height: 8.rh),
            _FavoritesCard(
              allCategories: _categories,
              favIds: _favs,
              onFav: _toggleFav,
            ),
            SizedBox(height: 12.rh),
          ] else
            SizedBox(height: 12.rh),
          // 各分类
          for (final cat in _categories) ...[
            Builder(builder: (_) {
              final visible = _filter(cat.tips);
              if (visible.isEmpty) return const SizedBox.shrink();
              return _CategoryCard(
                category: cat,
                tips: visible,
                favIds: _favs,
                onFav: _toggleFav,
              );
            }),
            SizedBox(height: 12.rh),
          ],
          _VipBanner(),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
        ],
      ),
    );
  }
}

// ─── CountryRow ───────────────────────────────────────────────────────────────

class _CountryRow extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  const _CountryRow({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36.rh,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _allCountries.length,
        separatorBuilder: (_, __) => SizedBox(width: 8.rw),
        itemBuilder: (_, i) {
          final c = _allCountries[i];
          final active = c == selected;
          return GestureDetector(
            onTap: () => onChanged(c),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: REdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: active ? _accent : _card,
                borderRadius: BorderRadius.circular(20.rr),
                boxShadow: active
                    ? [BoxShadow(color: _accent.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))]
                    : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)],
              ),
              child: Text(
                c,
                style: TextStyle(
                  color: active ? Colors.white : _textSecondary,
                  fontSize: 13.rf,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── FavoritesCard ────────────────────────────────────────────────────────────

class _FavoritesCard extends StatelessWidget {
  final List<_Category> allCategories;
  final Set<String> favIds;
  final ValueChanged<String> onFav;
  const _FavoritesCard({
    required this.allCategories,
    required this.favIds,
    required this.onFav,
  });

  @override
  Widget build(BuildContext context) {
    final favTips = allCategories
        .expand((c) => c.tips)
        .where((t) => favIds.contains(t.id))
        .toList();
    if (favTips.isEmpty) return const SizedBox.shrink();

    return _CardShell(
      header: Row(
        children: [
          Container(
            width: 32.ri,
            height: 32.ri,
            decoration: BoxDecoration(
              color: _vipGold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8.rr),
            ),
            child: Icon(Icons.star_rounded, size: 16.ri, color: _vipGold),
          ),
          SizedBox(width: 10.rw),
          Text('我的收藏',
              style: TextStyle(color: _textPrimary, fontSize: 15.rf, fontWeight: FontWeight.w600)),
          const Spacer(),
          Text('${favTips.length} 条',
              style: TextStyle(color: _textMuted, fontSize: 12.rf)),
        ],
      ),
      children: favTips.asMap().entries.map((e) {
        return _TipRow(
          tip: e.value,
          dotColor: _vipGold,
          isFav: true,
          isLast: e.key == favTips.length - 1,
          onFav: onFav,
        );
      }).toList(),
    );
  }
}

// ─── CategoryCard ─────────────────────────────────────────────────────────────

class _CategoryCard extends StatelessWidget {
  final _Category category;
  final List<_Tip> tips;
  final Set<String> favIds;
  final ValueChanged<String> onFav;
  const _CategoryCard({
    required this.category,
    required this.tips,
    required this.favIds,
    required this.onFav,
  });

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      header: Row(
        children: [
          Container(
            width: 32.ri,
            height: 32.ri,
            decoration: BoxDecoration(
              color: category.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8.rr),
            ),
            child: Icon(category.icon, size: 16.ri, color: category.color),
          ),
          SizedBox(width: 10.rw),
          Text(category.name,
              style: TextStyle(color: _textPrimary, fontSize: 15.rf, fontWeight: FontWeight.w600)),
          const Spacer(),
          Container(
            padding: REdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: category.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10.rr),
            ),
            child: Text('${tips.length} 条',
                style: TextStyle(color: category.color, fontSize: 11.rf, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
      children: tips.asMap().entries.map((e) {
        return _TipRow(
          tip: e.value,
          dotColor: category.color,
          isFav: favIds.contains(e.value.id),
          isLast: e.key == tips.length - 1,
          onFav: onFav,
        );
      }).toList(),
    );
  }
}

// ─── TipRow ───────────────────────────────────────────────────────────────────

class _TipRow extends StatelessWidget {
  final _Tip tip;
  final Color dotColor;
  final bool isFav;
  final bool isLast;
  final ValueChanged<String> onFav;
  const _TipRow({
    required this.tip,
    required this.dotColor,
    required this.isFav,
    required this.isLast,
    required this.onFav,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: REdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: 5.rh),
                child: Container(
                  width: 6.ri,
                  height: 6.ri,
                  decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                ),
              ),
              SizedBox(width: 10.rw),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            tip.title,
                            style: TextStyle(
                              color: tip.isVip ? _textMuted : _textPrimary,
                              fontSize: 13.rf,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (tip.isVip)
                          Container(
                            margin: EdgeInsets.only(left: 6.rw),
                            padding: REdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: _vipGold.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4.rr),
                            ),
                            child: Text('VIP',
                                style: TextStyle(
                                  color: _vipGold,
                                  fontSize: 10.rf,
                                  fontWeight: FontWeight.w700,
                                )),
                          ),
                      ],
                    ),
                    SizedBox(height: 3.rh),
                    tip.isVip
                        ? Text('开通 VIP 解锁完整内容',
                            style: TextStyle(
                              color: _vipGold.withValues(alpha: 0.7),
                              fontSize: 12.rf,
                              fontStyle: FontStyle.italic,
                            ))
                        : Text(
                            tip.desc,
                            style: TextStyle(
                              color: _textSecondary,
                              fontSize: 12.rf,
                              height: 1.5,
                            ),
                          ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: tip.isVip ? null : () => onFav(tip.id),
                child: Padding(
                  padding: REdgeInsets.all(8),
                  child: Icon(
                    isFav ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 18.ri,
                    color: isFav ? _vipGold : _textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            thickness: 1,
            indent: 32.rw,
            endIndent: 16.rw,
            color: const Color(0xFFF0F0F8),
          ),
      ],
    );
  }
}

// ─── VipBanner ────────────────────────────────────────────────────────────────

class _VipBanner extends StatelessWidget {
  const _VipBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: REdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2D1B69), Color(0xFF5969FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.rr),
      ),
      child: Row(
        children: [
          Icon(Icons.workspace_premium_rounded, color: _vipGold, size: 32.ri),
          SizedBox(width: 12.rw),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('VIP 专属攻略',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15.rf,
                      fontWeight: FontWeight.w700,
                    )),
                SizedBox(height: 3.rh),
                Text('税务申报、汇丰通道、学生信用卡建分等 7 条深度内容',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 12.rf,
                      height: 1.4,
                    )),
              ],
            ),
          ),
          SizedBox(width: 8.rw),
          Container(
            padding: REdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _vipGold,
              borderRadius: BorderRadius.circular(20.rr),
            ),
            child: Text('解锁',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13.rf,
                  fontWeight: FontWeight.w700,
                )),
          ),
        ],
      ),
    );
  }
}

// ─── CardShell ────────────────────────────────────────────────────────────────

class _CardShell extends StatelessWidget {
  final Widget header;
  final List<Widget> children;
  const _CardShell({required this.header, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16.rr),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: REdgeInsets.fromLTRB(16, 14, 16, 10),
            child: header,
          ),
          Divider(height: 1, thickness: 1, color: const Color(0xFFF0F0F8)),
          ...children,
          SizedBox(height: 4.rh),
        ],
      ),
    );
  }
}
