/// Width classes used by the phone-first, tablet-adaptive interface.
enum AdaptiveWindowClass {
  compact,
  medium,
  expanded,
}

/// Responsive thresholds shared by every first-party screen.
abstract final class AdaptiveBreakpoints {
  static const double medium = 600;
  static const double expanded = 840;

  static AdaptiveWindowClass classify(double width) {
    if (width.isNaN || width < 0) {
      throw ArgumentError.value(width, 'width', 'Must be zero or greater.');
    }
    if (width < medium) {
      return AdaptiveWindowClass.compact;
    }
    if (width < expanded) {
      return AdaptiveWindowClass.medium;
    }
    return AdaptiveWindowClass.expanded;
  }

  static int homeColumnCount(double width) {
    return classify(width) == AdaptiveWindowClass.compact ? 1 : 2;
  }

  static double contentMaxWidth(double width) {
    return switch (classify(width)) {
      AdaptiveWindowClass.compact => 480,
      AdaptiveWindowClass.medium => 840,
      AdaptiveWindowClass.expanded => 1200,
    };
  }

  static bool useTwoPaneGameLayout(double width) {
    return classify(width) == AdaptiveWindowClass.expanded;
  }
}
