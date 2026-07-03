// ignore_for_file: avoid_print, prefer_final_fields, unnecessary_this
import 'dart:math';

// ──────────────────────────────────────────────
// GchPoint
// ──────────────────────────────────────────────
class GchPoint {
  final double x;
  final double y;

  const GchPoint(this.x, this.y);

  GchPoint operator +(GchPoint other) => GchPoint(x + other.x, y + other.y);
  GchPoint operator -(GchPoint other) => GchPoint(x - other.x, y - other.y);
  GchPoint operator *(double scalar) => GchPoint(x * scalar, y * scalar);

  @override
  bool operator ==(Object other) =>
      other is GchPoint &&
      (x - other.x).abs() < 1e-10 &&
      (y - other.y).abs() < 1e-10;

  @override
  int get hashCode => Object.hash(x, y);

  double distance(GchPoint to) {
    final dx = x - to.x;
    final dy = y - to.y;
    return sqrt(dx * dx + dy * dy);
  }

  GchPoint midpoint(GchPoint to) =>
      GchPoint((x + to.x) / 2.0, (y + to.y) / 2.0);

  double angle(GchPoint to) => atan2(to.y - y, to.x - x);

  GchPoint rotate(double angle, {GchPoint? center}) {
    final cx = center?.x ?? 0.0;
    final cy = center?.y ?? 0.0;
    final dx = x - cx;
    final dy = y - cy;
    final cos = math_cos(angle);
    final sin = math_sin(angle);
    return GchPoint(cx + dx * cos - dy * sin, cy + dx * sin + dy * cos);
  }

  double math_cos(double a) => cos(a);
  double math_sin(double a) => sin(a);

  @override
  String toString() => 'GchPoint($x, $y)';
}

// ──────────────────────────────────────────────
// GchVector2
// ──────────────────────────────────────────────
class GchVector2 {
  final double dx;
  final double dy;

  const GchVector2(this.dx, this.dy);

  double dot(GchVector2 other) => dx * other.dx + dy * other.dy;

  double cross(GchVector2 other) => dx * other.dy - dy * other.dx;

  double get magnitude => sqrt(dx * dx + dy * dy);

  GchVector2 get normalize {
    final m = magnitude;
    if (m < 1e-12) return const GchVector2(0, 0);
    return GchVector2(dx / m, dy / m);
  }

  double get angle => atan2(dy, dx);

  GchVector2 lerp(GchVector2 other, double t) {
    return GchVector2(dx + (other.dx - dx) * t, dy + (other.dy - dy) * t);
  }

  GchVector2 reflect(GchVector2 normal) {
    final n = normal.normalize;
    final d = 2.0 * dot(n);
    return GchVector2(dx - d * n.dx, dy - d * n.dy);
  }

  GchVector2 operator +(GchVector2 other) => GchVector2(dx + other.dx, dy + other.dy);
  GchVector2 operator -(GchVector2 other) => GchVector2(dx - other.dx, dy - other.dy);
  GchVector2 operator *(double s) => GchVector2(dx * s, dy * s);

  @override
  String toString() => 'GchVector2($dx, $dy)';
}

// ──────────────────────────────────────────────
// GchRect
// ──────────────────────────────────────────────
class GchRect {
  final double left;
  final double top;
  final double width;
  final double height;

  const GchRect(this.left, this.top, this.width, this.height);

  double get right => left + width;
  double get bottom => top + height;
  double get area => width * height;
  double get perimeter => 2 * (width + height);

  GchPoint get center => GchPoint(left + width / 2, top + height / 2);

  bool contains(GchPoint p) =>
      p.x >= left && p.x <= right && p.y >= top && p.y <= bottom;

  bool intersects(GchRect other) =>
      left < other.right &&
      right > other.left &&
      top < other.bottom &&
      bottom > other.top;

  GchRect union(GchRect other) {
    final l = min(left, other.left);
    final t = min(top, other.top);
    final r = max(right, other.right);
    final b = max(bottom, other.bottom);
    return GchRect(l, t, r - l, b - t);
  }

  GchRect? intersection(GchRect other) {
    final l = max(left, other.left);
    final t = max(top, other.top);
    final r = min(right, other.right);
    final b = min(bottom, other.bottom);
    if (l >= r || t >= b) return null;
    return GchRect(l, t, r - l, b - t);
  }

  GchRect inflate(double delta) =>
      GchRect(left - delta, top - delta, width + delta * 2, height + delta * 2);

  GchRect deflate(double delta) => inflate(-delta);

  @override
  String toString() => 'GchRect($left, $top, $width x $height)';
}

// ──────────────────────────────────────────────
// GchCircle
// ──────────────────────────────────────────────
class GchCircle {
  final GchPoint center;
  final double radius;

  const GchCircle(this.center, this.radius);

  double get area => pi * radius * radius;
  double get circumference => 2 * pi * radius;

  bool contains(GchPoint p) => center.distance(p) <= radius;

  bool intersects(GchCircle other) {
    final d = center.distance(other.center);
    return d < radius + other.radius;
  }

  List<GchPoint> tangentPoints(GchPoint from) {
    final d = center.distance(from);
    if (d < radius) return [];
    final angle = asin(radius / d);
    final baseAngle = atan2(center.y - from.y, center.x - from.x);
    final dist = sqrt(d * d - radius * radius);
    return [
      GchPoint(
        from.x + dist * cos(baseAngle + angle),
        from.y + dist * sin(baseAngle + angle),
      ),
      GchPoint(
        from.x + dist * cos(baseAngle - angle),
        from.y + dist * sin(baseAngle - angle),
      ),
    ];
  }

  @override
  String toString() => 'GchCircle(center=$center, r=$radius)';
}

// ──────────────────────────────────────────────
// GchPolygon
// ──────────────────────────────────────────────
class GchPolygon {
  final List<GchPoint> vertices;

  const GchPolygon(this.vertices);

  int get count => vertices.length;

  double get area {
    double sum = 0.0;
    final n = vertices.length;
    for (int i = 0; i < n; i++) {
      final j = (i + 1) % n;
      sum += vertices[i].x * vertices[j].y;
      sum -= vertices[j].x * vertices[i].y;
    }
    return sum.abs() / 2.0;
  }

  double get perimeter {
    double total = 0.0;
    final n = vertices.length;
    for (int i = 0; i < n; i++) {
      total += vertices[i].distance(vertices[(i + 1) % n]);
    }
    return total;
  }

  GchPoint get centroid {
    double cx = 0, cy = 0;
    final n = vertices.length;
    double a = 0;
    for (int i = 0; i < n; i++) {
      final j = (i + 1) % n;
      final cross = vertices[i].x * vertices[j].y - vertices[j].x * vertices[i].y;
      a += cross;
      cx += (vertices[i].x + vertices[j].x) * cross;
      cy += (vertices[i].y + vertices[j].y) * cross;
    }
    a /= 2.0;
    if (a.abs() < 1e-12) {
      double sx = 0, sy = 0;
      for (final v in vertices) {
        sx += v.x;
        sy += v.y;
      }
      return GchPoint(sx / n, sy / n);
    }
    return GchPoint(cx / (6 * a), cy / (6 * a));
  }

  bool contains(GchPoint p) {
    int crossings = 0;
    final n = vertices.length;
    for (int i = 0; i < n; i++) {
      final a = vertices[i];
      final b = vertices[(i + 1) % n];
      if (((a.y <= p.y && p.y < b.y) || (b.y <= p.y && p.y < a.y)) &&
          p.x < (b.x - a.x) * (p.y - a.y) / (b.y - a.y) + a.x) {
        crossings++;
      }
    }
    return crossings.isOdd;
  }

  bool get isConvex {
    final n = vertices.length;
    if (n < 3) return false;
    int sign = 0;
    for (int i = 0; i < n; i++) {
      final a = vertices[i];
      final b = vertices[(i + 1) % n];
      final c = vertices[(i + 2) % n];
      final cross = (b.x - a.x) * (c.y - b.y) - (b.y - a.y) * (c.x - b.x);
      if (cross.abs() > 1e-10) {
        final s = cross > 0 ? 1 : -1;
        if (sign == 0) {
          sign = s;
        } else if (sign != s) {
          return false;
        }
      }
    }
    return true;
  }

  GchRect get boundingBox {
    double minX = vertices[0].x, maxX = vertices[0].x;
    double minY = vertices[0].y, maxY = vertices[0].y;
    for (final v in vertices) {
      if (v.x < minX) minX = v.x;
      if (v.x > maxX) maxX = v.x;
      if (v.y < minY) minY = v.y;
      if (v.y > maxY) maxY = v.y;
    }
    return GchRect(minX, minY, maxX - minX, maxY - minY);
  }

  List<List<GchPoint>> triangulate() {
    final result = <List<GchPoint>>[];
    final verts = List<GchPoint>.from(vertices);
    while (verts.length > 3) {
      bool earFound = false;
      for (int i = 0; i < verts.length; i++) {
        final a = verts[(i - 1 + verts.length) % verts.length];
        final b = verts[i];
        final c = verts[(i + 1) % verts.length];
        final crossZ =
            (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x);
        if (crossZ <= 0) continue;
        bool isEar = true;
        for (int j = 0; j < verts.length; j++) {
          if (j == (i - 1 + verts.length) % verts.length ||
              j == i ||
              j == (i + 1) % verts.length) continue;
          if (_pointInTriangle(verts[j], a, b, c)) {
            isEar = false;
            break;
          }
        }
        if (isEar) {
          result.add([a, b, c]);
          verts.removeAt(i);
          earFound = true;
          break;
        }
      }
      if (!earFound) break;
    }
    if (verts.length == 3) result.add(verts);
    return result;
  }

  bool _pointInTriangle(GchPoint p, GchPoint a, GchPoint b, GchPoint c) {
    double sign(GchPoint p1, GchPoint p2, GchPoint p3) =>
        (p1.x - p3.x) * (p2.y - p3.y) - (p2.x - p3.x) * (p1.y - p3.y);
    final d1 = sign(p, a, b);
    final d2 = sign(p, b, c);
    final d3 = sign(p, c, a);
    final hasNeg = (d1 < 0) || (d2 < 0) || (d3 < 0);
    final hasPos = (d1 > 0) || (d2 > 0) || (d3 > 0);
    return !(hasNeg && hasPos);
  }
}

// ──────────────────────────────────────────────
// GchGeoAlgo
// ──────────────────────────────────────────────
class GchGeoAlgo {
  GchGeoAlgo._();

  static List<GchPoint> convexHull(List<GchPoint> points) {
    final pts = List<GchPoint>.from(points);
    final n = pts.length;
    if (n < 3) return pts;
    pts.sort((a, b) {
      final cmp = a.x.compareTo(b.x);
      return cmp != 0 ? cmp : a.y.compareTo(b.y);
    });

    List<GchPoint> lower = [];
    for (final p in pts) {
      while (lower.length >= 2 &&
          _cross(lower[lower.length - 2], lower[lower.length - 1], p) <= 0) {
        lower.removeLast();
      }
      lower.add(p);
    }

    List<GchPoint> upper = [];
    for (final p in pts.reversed) {
      while (upper.length >= 2 &&
          _cross(upper[upper.length - 2], upper[upper.length - 1], p) <= 0) {
        upper.removeLast();
      }
      upper.add(p);
    }

    lower.removeLast();
    upper.removeLast();
    return lower + upper;
  }

  static double _cross(GchPoint O, GchPoint A, GchPoint B) =>
      (A.x - O.x) * (B.y - O.y) - (A.y - O.y) * (B.x - O.x);

  static (GchPoint, GchPoint) closestPair(List<GchPoint> points) {
    final pts = List<GchPoint>.from(points)
      ..sort((a, b) => a.x.compareTo(b.x));
    final result = _closestPairRec(pts, 0, pts.length - 1);
    return result;
  }

  static (GchPoint, GchPoint) _closestPairRec(
      List<GchPoint> pts, int left, int right) {
    if (right - left < 3) {
      double best = double.infinity;
      GchPoint bp1 = pts[left], bp2 = pts[left + 1];
      for (int i = left; i <= right; i++) {
        for (int j = i + 1; j <= right; j++) {
          final d = pts[i].distance(pts[j]);
          if (d < best) {
            best = d;
            bp1 = pts[i];
            bp2 = pts[j];
          }
        }
      }
      return (bp1, bp2);
    }
    final mid = (left + right) ~/ 2;
    final midX = pts[mid].x;
    final (l1, l2) = _closestPairRec(pts, left, mid);
    final (r1, r2) = _closestPairRec(pts, mid + 1, right);
    double d = l1.distance(l2);
    GchPoint p1 = l1, p2 = l2;
    final rd = r1.distance(r2);
    if (rd < d) {
      d = rd;
      p1 = r1;
      p2 = r2;
    }

    final strip = <GchPoint>[];
    for (int i = left; i <= right; i++) {
      if ((pts[i].x - midX).abs() < d) strip.add(pts[i]);
    }
    strip.sort((a, b) => a.y.compareTo(b.y));

    for (int i = 0; i < strip.length; i++) {
      for (int j = i + 1;
          j < strip.length && strip[j].y - strip[i].y < d;
          j++) {
        final sd = strip[i].distance(strip[j]);
        if (sd < d) {
          d = sd;
          p1 = strip[i];
          p2 = strip[j];
        }
      }
    }
    return (p1, p2);
  }

  static GchPoint? lineIntersection(
      GchPoint a1, GchPoint a2, GchPoint b1, GchPoint b2) {
    final d1x = a2.x - a1.x;
    final d1y = a2.y - a1.y;
    final d2x = b2.x - b1.x;
    final d2y = b2.y - b1.y;
    final denom = d1x * d2y - d1y * d2x;
    if (denom.abs() < 1e-12) return null;
    final dx = b1.x - a1.x;
    final dy = b1.y - a1.y;
    final t = (dx * d2y - dy * d2x) / denom;
    return GchPoint(a1.x + t * d1x, a1.y + t * d1y);
  }

  static bool pointOnSegment(GchPoint p, GchPoint a, GchPoint b) {
    final minX = min(a.x, b.x);
    final maxX = max(a.x, b.x);
    final minY = min(a.y, b.y);
    final maxY = max(a.y, b.y);
    if (p.x < minX || p.x > maxX || p.y < minY || p.y > maxY) return false;
    final cross =
        (b.x - a.x) * (p.y - a.y) - (b.y - a.y) * (p.x - a.x);
    return cross.abs() < 1e-10;
  }

  static bool segmentsIntersect(
      GchPoint a1, GchPoint a2, GchPoint b1, GchPoint b2) {
    final d1 = orientation(b1, b2, a1);
    final d2 = orientation(b1, b2, a2);
    final d3 = orientation(a1, a2, b1);
    final d4 = orientation(a1, a2, b2);
    if (d1 * d2 < 0 && d3 * d4 < 0) return true;
    if (d1 == 0 && pointOnSegment(a1, b1, b2)) return true;
    if (d2 == 0 && pointOnSegment(a2, b1, b2)) return true;
    if (d3 == 0 && pointOnSegment(b1, a1, a2)) return true;
    if (d4 == 0 && pointOnSegment(b2, a1, a2)) return true;
    return false;
  }

  static int orientation(GchPoint p, GchPoint q, GchPoint r) {
    final val = (q.y - p.y) * (r.x - q.x) - (q.x - p.x) * (r.y - q.y);
    if (val.abs() < 1e-10) return 0;
    return val > 0 ? 1 : -1;
  }

  static double distancePointToLine(GchPoint p, GchPoint a, GchPoint b) {
    final dx = b.x - a.x;
    final dy = b.y - a.y;
    final len2 = dx * dx + dy * dy;
    if (len2 < 1e-12) return p.distance(a);
    final cross = (p.x - a.x) * dy - (p.y - a.y) * dx;
    return cross.abs() / sqrt(len2);
  }

  static double distancePointToSegment(GchPoint p, GchPoint a, GchPoint b) {
    final dx = b.x - a.x;
    final dy = b.y - a.y;
    final len2 = dx * dx + dy * dy;
    if (len2 < 1e-12) return p.distance(a);
    double t = ((p.x - a.x) * dx + (p.y - a.y) * dy) / len2;
    t = t.clamp(0.0, 1.0);
    final proj = GchPoint(a.x + t * dx, a.y + t * dy);
    return p.distance(proj);
  }

  static double areaOfTriangle(GchPoint a, GchPoint b, GchPoint c) {
    return ((b.x - a.x) * (c.y - a.y) - (c.x - a.x) * (b.y - a.y)).abs() /
        2.0;
  }

  static bool isPointInTriangle(GchPoint p, GchPoint a, GchPoint b, GchPoint c) {
    final areaABC = areaOfTriangle(a, b, c);
    if (areaABC < 1e-12) return false;
    final areaA = areaOfTriangle(p, b, c);
    final areaB = areaOfTriangle(a, p, c);
    final areaC = areaOfTriangle(a, b, p);
    return (areaA + areaB + areaC - areaABC).abs() < 1e-8;
  }

  static GchPoint bezierPoint(
      double t, GchPoint p0, GchPoint p1, GchPoint p2, GchPoint p3) {
    final mt = 1.0 - t;
    final mt2 = mt * mt;
    final mt3 = mt2 * mt;
    final t2 = t * t;
    final t3 = t2 * t;
    return GchPoint(
      mt3 * p0.x + 3 * mt2 * t * p1.x + 3 * mt * t2 * p2.x + t3 * p3.x,
      mt3 * p0.y + 3 * mt2 * t * p1.y + 3 * mt * t2 * p2.y + t3 * p3.y,
    );
  }

  static List<GchPoint> bezierCurve(
      GchPoint p0, GchPoint p1, GchPoint p2, GchPoint p3,
      {int steps = 50}) {
    final result = <GchPoint>[];
    for (int i = 0; i <= steps; i++) {
      result.add(bezierPoint(i / steps, p0, p1, p2, p3));
    }
    return result;
  }
}

// ──────────────────────────────────────────────
// GchGeoCoord
// ──────────────────────────────────────────────
class GchGeoCoord {
  final double lat;
  final double lng;

  const GchGeoCoord(this.lat, this.lng);

  static const double _earthRadius = 6371000.0;

  double _toRad(double deg) => deg * pi / 180.0;
  double _toDeg(double rad) => rad * 180.0 / pi;

  double distanceTo(GchGeoCoord other) {
    final lat1 = _toRad(this.lat);
    final lat2 = _toRad(other.lat);
    final dLat = _toRad(other.lat - this.lat);
    final dLng = _toRad(other.lng - this.lng);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return _earthRadius * c;
  }

  double bearing(GchGeoCoord to) {
    final lat1 = _toRad(this.lat);
    final lat2 = _toRad(to.lat);
    final dLng = _toRad(to.lng - this.lng);
    final y = sin(dLng) * cos(lat2);
    final x =
        cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLng);
    final bearing = atan2(y, x);
    return (_toDeg(bearing) + 360) % 360;
  }

  GchGeoCoord destination(double distance, double bearingDeg) {
    final bearingRad = _toRad(bearingDeg);
    final lat1 = _toRad(this.lat);
    final lng1 = _toRad(this.lng);
    final angDist = distance / _earthRadius;
    final lat2 = asin(sin(lat1) * cos(angDist) +
        cos(lat1) * sin(angDist) * cos(bearingRad));
    final lng2 = lng1 +
        atan2(sin(bearingRad) * sin(angDist) * cos(lat1),
            cos(angDist) - sin(lat1) * sin(lat2));
    return GchGeoCoord(_toDeg(lat2), _toDeg(lng2));
  }

  GchGeoCoord midpoint(GchGeoCoord to) {
    final lat1 = _toRad(this.lat);
    final lat2 = _toRad(to.lat);
    final lng1 = _toRad(this.lng);
    final dLng = _toRad(to.lng - this.lng);
    final bx = cos(lat2) * cos(dLng);
    final by = cos(lat2) * sin(dLng);
    final midLat = atan2(
        sin(lat1) + sin(lat2), sqrt((cos(lat1) + bx) * (cos(lat1) + bx) + by * by));
    final midLng = lng1 + atan2(by, cos(lat1) + bx);
    return GchGeoCoord(_toDeg(midLat), _toDeg(midLng));
  }

  @override
  String toString() => 'GchGeoCoord(lat=$lat, lng=$lng)';

  @override
  bool operator ==(Object other) =>
      other is GchGeoCoord &&
      (lat - other.lat).abs() < 1e-8 &&
      (lng - other.lng).abs() < 1e-8;

  @override
  int get hashCode => Object.hash(lat, lng);
}

// ──────────────────────────────────────────────
// Additional utility functions and examples
// ──────────────────────────────────────────────

class GchGeometryExamples {
  GchGeometryExamples._();

  static void runAll() {
    _testPoint();
    _testVector();
    _testRect();
    _testCircle();
    _testPolygon();
    _testAlgorithms();
    _testGeoCoord();
  }

  static void _testPoint() {
    final p1 = GchPoint(0, 0);
    final p2 = GchPoint(3, 4);
    print('Distance p1 to p2: ${p1.distance(p2)}'); // 5.0
    print('Midpoint: ${p1.midpoint(p2)}');
    print('Angle: ${p1.angle(p2)}');
    final p3 = p2.rotate(pi / 2, center: p1);
    print('Rotated 90 deg: $p3');
    final p4 = p1 + p2;
    final p5 = p1 - p2;
    final p6 = p2 * 2.0;
    print('Add: $p4, Sub: $p5, Scale: $p6');
  }

  static void _testVector() {
    final v1 = GchVector2(1, 0);
    final v2 = GchVector2(0, 1);
    print('Dot: ${v1.dot(v2)}');
    print('Cross: ${v1.cross(v2)}');
    print('Magnitude of (3,4): ${GchVector2(3, 4).magnitude}');
    print('Normalize (3,4): ${GchVector2(3, 4).normalize}');
    print('Lerp: ${v1.lerp(v2, 0.5)}');
    print('Reflect: ${v1.reflect(v2)}');
  }

  static void _testRect() {
    final r1 = GchRect(0, 0, 10, 10);
    final r2 = GchRect(5, 5, 10, 10);
    print('Contains (3,3): ${r1.contains(GchPoint(3, 3))}');
    print('Intersects: ${r1.intersects(r2)}');
    print('Union: ${r1.union(r2)}');
    print('Intersection: ${r1.intersection(r2)}');
    print('Center: ${r1.center}');
    print('Area: ${r1.area}, Perimeter: ${r1.perimeter}');
    print('Inflate 2: ${r1.inflate(2)}');
    print('Deflate 2: ${r1.deflate(2)}');
  }

  static void _testCircle() {
    final c = GchCircle(GchPoint(0, 0), 5);
    print('Area: ${c.area}');
    print('Circumference: ${c.circumference}');
    print('Contains (3,4): ${c.contains(GchPoint(3, 4))}');
    print('Contains (4,4): ${c.contains(GchPoint(4, 4))}');
    final c2 = GchCircle(GchPoint(8, 0), 5);
    print('Intersects: ${c.intersects(c2)}');
    final tangents = c.tangentPoints(GchPoint(10, 0));
    print('Tangent points from (10,0): $tangents');
  }

  static void _testPolygon() {
    final square = GchPolygon([
      GchPoint(0, 0),
      GchPoint(4, 0),
      GchPoint(4, 4),
      GchPoint(0, 4),
    ]);
    print('Square area: ${square.area}');
    print('Square perimeter: ${square.perimeter}');
    print('Centroid: ${square.centroid}');
    print('Contains (2,2): ${square.contains(GchPoint(2, 2))}');
    print('Contains (5,5): ${square.contains(GchPoint(5, 5))}');
    print('Is convex: ${square.isConvex}');
    print('Bounding box: ${square.boundingBox}');
    final triangles = square.triangulate();
    print('Triangles: ${triangles.length}');
  }

  static void _testAlgorithms() {
    final points = [
      GchPoint(0, 0),
      GchPoint(1, 1),
      GchPoint(2, 0),
      GchPoint(2, 2),
      GchPoint(0, 2),
      GchPoint(1, 3),
    ];
    final hull = GchGeoAlgo.convexHull(points);
    print('Convex hull: $hull');

    final (cp1, cp2) = GchGeoAlgo.closestPair(points);
    print('Closest pair: $cp1 and $cp2');

    final intersection = GchGeoAlgo.lineIntersection(
        GchPoint(0, 0), GchPoint(4, 4), GchPoint(0, 4), GchPoint(4, 0));
    print('Line intersection: $intersection');

    print(
        'Segments intersect: ${GchGeoAlgo.segmentsIntersect(GchPoint(0, 0), GchPoint(2, 2), GchPoint(0, 2), GchPoint(2, 0))}');

    print(
        'Orientation: ${GchGeoAlgo.orientation(GchPoint(0, 0), GchPoint(1, 1), GchPoint(2, 0))}');

    print(
        'Distance point to line: ${GchGeoAlgo.distancePointToLine(GchPoint(0, 1), GchPoint(0, 0), GchPoint(4, 0))}');
    print(
        'Distance point to segment: ${GchGeoAlgo.distancePointToSegment(GchPoint(5, 5), GchPoint(0, 0), GchPoint(4, 0))}');
    print(
        'Area of triangle: ${GchGeoAlgo.areaOfTriangle(GchPoint(0, 0), GchPoint(4, 0), GchPoint(0, 3))}');
    print(
        'Point in triangle: ${GchGeoAlgo.isPointInTriangle(GchPoint(1, 1), GchPoint(0, 0), GchPoint(4, 0), GchPoint(0, 4))}');

    final curve = GchGeoAlgo.bezierCurve(
        GchPoint(0, 0), GchPoint(1, 3), GchPoint(3, 3), GchPoint(4, 0));
    print('Bezier curve points: ${curve.length}');
    print('First: ${curve.first}, Last: ${curve.last}');
  }

  static void _testGeoCoord() {
    final london = GchGeoCoord(51.5074, -0.1278);
    final paris = GchGeoCoord(48.8566, 2.3522);
    print('London to Paris: ${london.distanceTo(paris).toStringAsFixed(0)} m');
    print('Bearing: ${london.bearing(paris).toStringAsFixed(1)} deg');
    print('Midpoint: ${london.midpoint(paris)}');
    final dest = london.destination(100000, 90);
    print('Destination 100km east: $dest');
  }
}

// ──────────────────────────────────────────────
// GchTransform2D - 2D affine transformation matrix
// ──────────────────────────────────────────────
class GchTransform2D {
  // Row-major 3x3 matrix: [a, b, c, d, e, f, 0, 0, 1]
  final double a, b, c, d, e, f;

  const GchTransform2D(this.a, this.b, this.c, this.d, this.e, this.f);

  factory GchTransform2D.identity() =>
      const GchTransform2D(1, 0, 0, 0, 1, 0);

  factory GchTransform2D.translation(double tx, double ty) =>
      GchTransform2D(1, 0, tx, 0, 1, ty);

  factory GchTransform2D.rotation(double angle) {
    final cosA = cos(angle);
    final sinA = sin(angle);
    return GchTransform2D(cosA, -sinA, 0, sinA, cosA, 0);
  }

  factory GchTransform2D.scaling(double sx, double sy) =>
      GchTransform2D(sx, 0, 0, 0, sy, 0);

  GchPoint apply(GchPoint p) =>
      GchPoint(a * p.x + b * p.y + c, d * p.x + e * p.y + f);

  GchTransform2D multiply(GchTransform2D other) {
    return GchTransform2D(
      a * other.a + b * other.d,
      a * other.b + b * other.e,
      a * other.c + b * other.f + c,
      d * other.a + e * other.d,
      d * other.b + e * other.e,
      d * other.c + e * other.f + f,
    );
  }

  GchTransform2D? inverse() {
    final det = a * e - b * d;
    if (det.abs() < 1e-12) return null;
    final invDet = 1.0 / det;
    return GchTransform2D(
      e * invDet,
      -b * invDet,
      (b * f - e * c) * invDet,
      -d * invDet,
      a * invDet,
      (d * c - a * f) * invDet,
    );
  }

  List<GchPoint> applyAll(List<GchPoint> points) =>
      points.map(apply).toList();

  @override
  String toString() =>
      'GchTransform2D([$a, $b, $c], [$d, $e, $f], [0, 0, 1])';
}

// ──────────────────────────────────────────────
// GchBoundingVolume - AABB tree for spatial queries
// ──────────────────────────────────────────────
class _BVNode {
  GchRect bounds;
  _BVNode? left;
  _BVNode? right;
  List<GchPoint>? items;

  _BVNode(this.bounds, {this.left, this.right, this.items});
}

class GchBVH {
  final _BVNode? _root;

  GchBVH._(this._root);

  factory GchBVH.build(List<GchPoint> points) {
    if (points.isEmpty) return GchBVH._(null);
    return GchBVH._(_buildNode(points));
  }

  static _BVNode _buildNode(List<GchPoint> pts) {
    double minX = pts[0].x, maxX = pts[0].x;
    double minY = pts[0].y, maxY = pts[0].y;
    for (final p in pts) {
      if (p.x < minX) minX = p.x;
      if (p.x > maxX) maxX = p.x;
      if (p.y < minY) minY = p.y;
      if (p.y > maxY) maxY = p.y;
    }
    final bounds = GchRect(minX, minY, maxX - minX, maxY - minY);
    if (pts.length <= 4) {
      return _BVNode(bounds, items: pts);
    }
    final spanX = maxX - minX;
    final spanY = maxY - minY;
    final sorted = List<GchPoint>.from(pts);
    if (spanX >= spanY) {
      sorted.sort((a, b) => a.x.compareTo(b.x));
    } else {
      sorted.sort((a, b) => a.y.compareTo(b.y));
    }
    final mid = sorted.length ~/ 2;
    return _BVNode(
      bounds,
      left: _buildNode(sorted.sublist(0, mid)),
      right: _buildNode(sorted.sublist(mid)),
    );
  }

  List<GchPoint> queryRange(GchRect range) {
    final result = <GchPoint>[];
    _query(_root, range, result);
    return result;
  }

  void _query(_BVNode? node, GchRect range, List<GchPoint> result) {
    if (node == null || !node.bounds.intersects(range)) return;
    if (node.items != null) {
      for (final p in node.items!) {
        if (range.contains(p)) result.add(p);
      }
      return;
    }
    _query(node.left, range, result);
    _query(node.right, range, result);
  }

  GchPoint? nearestNeighbor(GchPoint query) {
    if (_root == null) return null;
    GchPoint? best;
    double bestDist = double.infinity;
    _nn(_root, query, ref: (GchPoint? p, double d) {
      if (d < bestDist) {
        bestDist = d;
        best = p;
      }
    });
    return best;
  }

  void _nn(_BVNode? node, GchPoint query,
      {required void Function(GchPoint?, double) ref}) {
    if (node == null) return;
    if (node.items != null) {
      for (final p in node.items!) {
        final d = query.distance(p);
        ref(p, d);
      }
      return;
    }
    _nn(node.left, query, ref: ref);
    _nn(node.right, query, ref: ref);
  }
}

// ──────────────────────────────────────────────
// GchPathSampler - samples along a polyline path
// ──────────────────────────────────────────────
class GchPathSampler {
  final List<GchPoint> points;
  late final List<double> _cumulativeLengths;
  late final double totalLength;

  GchPathSampler(this.points) {
    _cumulativeLengths = [0.0];
    for (int i = 1; i < points.length; i++) {
      _cumulativeLengths
          .add(_cumulativeLengths.last + points[i - 1].distance(points[i]));
    }
    totalLength = _cumulativeLengths.last;
  }

  GchPoint sampleAt(double t) {
    final dist = t.clamp(0.0, 1.0) * totalLength;
    return sampleAtDistance(dist);
  }

  GchPoint sampleAtDistance(double dist) {
    if (dist <= 0) return points.first;
    if (dist >= totalLength) return points.last;
    int lo = 0, hi = _cumulativeLengths.length - 1;
    while (lo < hi - 1) {
      final mid = (lo + hi) ~/ 2;
      if (_cumulativeLengths[mid] <= dist) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    final segDist = dist - _cumulativeLengths[lo];
    final segLen = _cumulativeLengths[hi] - _cumulativeLengths[lo];
    final tt = segLen < 1e-12 ? 0.0 : segDist / segLen;
    final a = points[lo];
    final b = points[hi];
    return GchPoint(a.x + (b.x - a.x) * tt, a.y + (b.y - a.y) * tt);
  }

  List<GchPoint> sampleEvenly(int count) {
    if (count <= 0) return [];
    if (count == 1) return [sampleAt(0.5)];
    return List.generate(count, (i) => sampleAt(i / (count - 1)));
  }

  double tangentAngleAt(double t) {
    final dt = 0.001;
    final p1 = sampleAt((t - dt).clamp(0.0, 1.0));
    final p2 = sampleAt((t + dt).clamp(0.0, 1.0));
    return atan2(p2.y - p1.y, p2.x - p1.x);
  }
}
