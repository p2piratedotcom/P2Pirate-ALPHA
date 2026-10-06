import 'package:rational/rational.dart';
import 'package:test/test.dart';
import 'package:web_dex/views/dex/dex_helpers.dart';
import 'package:web_dex/views/dex/simple/form/exchange_info/dex_compared_to_cex.dart';

void testCompareToCex() {
  test('compare different prices', () {
    expect(compareToCex(1, 2, Rational.one), 100);
  });
  test(
    'equal rates have neutral direction and unavailable comparisons stay unknown',
    () {
      final equal = compareToCex(10, 2, Rational.fromInt(5));
      expect(dexReferenceComparisonLabel(equal), 'Equal to reference');
      expect(dexReferenceComparisonLabel(-0.0), 'Equal to reference');
      expect(dexReferenceComparisonLabel(25), contains('above reference'));
      expect(dexReferenceComparisonLabel(-25), contains('below reference'));
      expect(dexReferenceComparisonLabel(null), 'Reference unavailable');
      expect(dexReferenceComparisonLabel(double.nan), 'Reference unavailable');
    },
  );
}
