import 'package:flutter_test/flutter_test.dart';
import 'package:iron_clock/src/features/workout/badges.dart';

void main() {
  test('badge catalog has exactly 100 badges with unique ids', () {
    expect(BadgeCatalog.all.length, 100);
    final ids = BadgeCatalog.all.map((b) => b.id).toSet();
    expect(ids.length, 100);
  });
}
