import 'package:flutter/material.dart';

/// A complete, immutable visual identity consumed by the application shell.
@immutable
class ThemePack {
  const ThemePack({
    required this.id,
    required this.schemaVersion,
    required this.displayName,
    required this.themeData,
    required this.colors,
    required this.typography,
    required this.spacing,
    required this.shapes,
    required this.board,
    required this.pieces,
    required this.motion,
    required this.audio,
  });

  final String id;
  final int schemaVersion;
  final String displayName;
  final ThemeData themeData;
  final AppColorTokens colors;
  final TypographyThemeTokens typography;
  final SpacingThemeTokens spacing;
  final ShapeThemeTokens shapes;
  final BoardThemeTokens board;
  final PieceThemeTokens pieces;
  final MotionThemeTokens motion;
  final AudioThemeTokens audio;
}

/// Semantic application colors. Callers should not introduce theme-specific
/// colors outside this module.
@immutable
class AppColorTokens {
  const AppColorTokens({
    required this.paperBase,
    required this.paperRaised,
    required this.paperPressed,
    required this.inkPrimary,
    required this.inkMuted,
    required this.jade,
    required this.jadePressed,
    required this.cinnabar,
    required this.bronze,
    required this.divider,
    required this.danger,
  });

  final Color paperBase;
  final Color paperRaised;
  final Color paperPressed;
  final Color inkPrimary;
  final Color inkMuted;
  final Color jade;
  final Color jadePressed;
  final Color cinnabar;
  final Color bronze;
  final Color divider;
  final Color danger;
}

@immutable
class TypographyThemeTokens {
  const TypographyThemeTokens({
    required this.displayFontFamily,
    required this.bodyFontFamily,
    required this.fontFamilyFallback,
  });

  final String displayFontFamily;
  final String bodyFontFamily;
  final List<String> fontFamilyFallback;
}

@immutable
class SpacingThemeTokens {
  const SpacingThemeTokens({
    required this.extraSmall,
    required this.small,
    required this.medium,
    required this.large,
    required this.extraLarge,
    required this.minimumTapTarget,
  });

  final double extraSmall;
  final double small;
  final double medium;
  final double large;
  final double extraLarge;
  final double minimumTapTarget;
}

@immutable
class ShapeThemeTokens {
  const ShapeThemeTokens({
    required this.controlRadius,
    required this.panelRadius,
    required this.dialogRadius,
    required this.borderWidth,
  });

  final double controlRadius;
  final double panelRadius;
  final double dialogRadius;
  final double borderWidth;
}

enum BoardMarkerShape {
  doubleCorners,
  dotAndTick,
  endpointBrackets,
}

/// Visual values needed to render a board without knowing a concrete pack ID.
@immutable
class BoardThemeTokens {
  const BoardThemeTokens({
    required this.surfaceColor,
    required this.gridColor,
    required this.frameColor,
    required this.selectionColor,
    required this.validMoveColor,
    required this.lastMoveColor,
    required this.gridLineWidth,
    required this.frameLineWidth,
    required this.cornerRadius,
    required this.selectionMarker,
    required this.validMoveMarker,
    required this.lastMoveMarker,
    this.textureAsset,
  });

  final Color surfaceColor;
  final Color gridColor;
  final Color frameColor;
  final Color selectionColor;
  final Color validMoveColor;
  final Color lastMoveColor;
  final double gridLineWidth;
  final double frameLineWidth;
  final double cornerRadius;
  final BoardMarkerShape selectionMarker;
  final BoardMarkerShape validMoveMarker;
  final BoardMarkerShape lastMoveMarker;
  final String? textureAsset;
}

enum PieceMarkerShape {
  fourPointSeal,
  concentricRing,
}

@immutable
class PieceVisualTokens {
  const PieceVisualTokens({
    required this.surfaceColor,
    required this.highlightColor,
    required this.borderColor,
    required this.markerColor,
    required this.marker,
  });

  final Color surfaceColor;
  final Color highlightColor;
  final Color borderColor;
  final Color markerColor;
  final PieceMarkerShape marker;
}

/// Piece appearance uses both tone and geometry, so it remains legible in
/// grayscale and for players with color-vision deficiencies.
@immutable
class PieceThemeTokens {
  const PieceThemeTokens({
    required this.inkSide,
    required this.jadeSide,
    required this.radiusRatio,
    required this.shadowColor,
    required this.shadowOffset,
    required this.shadowBlurRadius,
  });

  final PieceVisualTokens inkSide;
  final PieceVisualTokens jadeSide;
  final double radiusRatio;
  final Color shadowColor;
  final Offset shadowOffset;
  final double shadowBlurRadius;
}

@immutable
class MotionThemeTokens {
  const MotionThemeTokens({
    required this.pageTransitionDuration,
    required this.moveDuration,
    required this.captureDuration,
    required this.stateChangeDuration,
    required this.firstPlayerDuration,
    required this.pageCurve,
    required this.moveCurve,
    required this.captureCurve,
    required this.selectionPulseEnabled,
    required this.particlesEnabled,
  });

  final Duration pageTransitionDuration;
  final Duration moveDuration;
  final Duration captureDuration;
  final Duration stateChangeDuration;
  final Duration firstPlayerDuration;
  final Curve pageCurve;
  final Curve moveCurve;
  final Curve captureCurve;
  final bool selectionPulseEnabled;
  final bool particlesEnabled;

  /// Resolves the effective animation policy. System and user preferences are
  /// combined by the caller before crossing this interface.
  MotionThemeTokens resolve({required bool reduceMotion}) {
    if (!reduceMotion) {
      return this;
    }
    return const MotionThemeTokens(
      pageTransitionDuration: Duration.zero,
      moveDuration: Duration.zero,
      captureDuration: Duration.zero,
      stateChangeDuration: Duration.zero,
      firstPlayerDuration: Duration.zero,
      pageCurve: Curves.linear,
      moveCurve: Curves.linear,
      captureCurve: Curves.linear,
      selectionPulseEnabled: false,
      particlesEnabled: false,
    );
  }
}

@immutable
class AudioThemeTokens {
  const AudioThemeTokens({
    required this.select,
    required this.move,
    required this.capture,
    required this.win,
    required this.lose,
    required this.click,
    required this.mainMusic,
    required this.gameplayMusic,
  });

  final String select;
  final String move;
  final String capture;
  final String win;
  final String lose;
  final String click;
  final String mainMusic;
  final String gameplayMusic;

  List<String> get all => List.unmodifiable([
        select,
        move,
        capture,
        win,
        lose,
        click,
        mainMusic,
        gameplayMusic,
      ]);
}
