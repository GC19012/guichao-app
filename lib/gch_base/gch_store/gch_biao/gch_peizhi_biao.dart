import 'package:drift/drift.dart';
import 'package:guichao/gch_base/gch_store/gch_conv/gch_dur_conv.dart';
import 'package:guichao/gch_base/gch_store/gch_crypt/gch_crypt_conv.dart';

@DataClassName('ProfileEntry')
class GchPeizhiBiao extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()();
  BoolColumn get active => boolean()();
  TextColumn get name => text().withLength(min: 1)();
  TextColumn get url => text().nullable().map(CryptoText.nullable)();
  DateTimeColumn get lastUpdate => dateTime()();
  IntColumn get updateInterval => integer().nullable().map(GchDurationConv())();
  IntColumn get upload => integer().nullable()();
  IntColumn get download => integer().nullable()();
  IntColumn get total => integer().nullable()();
  DateTimeColumn get expire => dateTime().nullable()();
  TextColumn get webPageUrl => text().nullable()();
  TextColumn get supportUrl => text().nullable()();
  TextColumn get testUrl => text().nullable()();

  /// 配置文件内容的MD5 hash，用于检测配置是否真正变化
  /// null 表示尚未计算或需要重新下载
  TextColumn get configHash => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

