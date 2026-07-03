import 'package:drift/drift.dart';

class GchDurationConv extends TypeConverter<Duration, int> {
  const GchDurationConv();

  @override
  Duration fromSql(int fromDb) => Duration(seconds: fromDb);

  @override
  int toSql(Duration value) => value.inSeconds;
}
