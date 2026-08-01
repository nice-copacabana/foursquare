import 'package:flutter_test/flutter_test.dart';
import 'package:foursquare/ui/layouts/adaptive_breakpoints.dart';

void main() {
  test('widths are classified at the published responsive boundaries', () {
    expect(AdaptiveBreakpoints.classify(599), AdaptiveWindowClass.compact);
    expect(AdaptiveBreakpoints.classify(600), AdaptiveWindowClass.medium);
    expect(AdaptiveBreakpoints.classify(839), AdaptiveWindowClass.medium);
    expect(AdaptiveBreakpoints.classify(840), AdaptiveWindowClass.expanded);
  });

  test('layout policy derives columns and content width from the width class',
      () {
    expect(AdaptiveBreakpoints.homeColumnCount(360), 1);
    expect(AdaptiveBreakpoints.homeColumnCount(600), 2);
    expect(AdaptiveBreakpoints.contentMaxWidth(360), 480);
    expect(AdaptiveBreakpoints.contentMaxWidth(700), 840);
    expect(AdaptiveBreakpoints.contentMaxWidth(1000), 1200);
    expect(AdaptiveBreakpoints.useTwoPaneGameLayout(839), isFalse);
    expect(AdaptiveBreakpoints.useTwoPaneGameLayout(840), isTrue);
  });

  test('invalid layout widths are rejected', () {
    expect(() => AdaptiveBreakpoints.classify(-1), throwsArgumentError);
    expect(() => AdaptiveBreakpoints.classify(double.nan), throwsArgumentError);
  });
}
