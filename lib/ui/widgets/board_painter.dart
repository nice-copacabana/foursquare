import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/board_state.dart';
import '../../models/board_theme.dart';
import '../../models/piece_type.dart';
import '../../models/position.dart';
import '../../theme/packs/modern_eastern_theme_pack.dart';
import '../../theme/theme_pack.dart';

/// Compatibility adapter for the legacy animated-board interface.
///
/// New code injects [ThemePack] directly. The adapter only exists while the
/// animation host still accepts the former [BoardTheme] model.
class ThemePackBoardThemeAdapter extends BoardTheme {
  ThemePackBoardThemeAdapter(this.themePack)
      : super(
          id: themePack.id,
          name: themePack.displayName,
          backgroundColor: themePack.board.surfaceColor,
          gridColor: themePack.board.gridColor,
          gridLineWidth: themePack.board.gridLineWidth,
          pieceStyle: PieceStyle.ink,
          selectionColor: themePack.board.selectionColor,
          moveHintColor: themePack.board.validMoveColor,
          lastMoveColor: themePack.board.lastMoveColor,
          backgroundTexture: themePack.board.textureAsset,
        );

  final ThemePack themePack;
}

/// Paints the complete themed board from a [ThemePack] without knowing its ID.
class BoardPainter extends CustomPainter {
  BoardPainter({
    required this.boardState,
    this.selectedPiece,
    this.validMoves = const [],
    this.lastMoveFrom,
    this.lastMoveTo,
    this.hidePiece,
    this.theme,
    this.themePack,
    this.selectionPulse,
  });

  final BoardState boardState;
  final Position? selectedPiece;
  final List<Position> validMoves;
  final Position? lastMoveFrom;
  final Position? lastMoveTo;
  final Position? hidePiece;

  /// Legacy input retained for [ThemePackBoardThemeAdapter].
  final BoardTheme? theme;
  final ThemePack? themePack;
  final double? selectionPulse;

  ThemePack get _pack {
    if (themePack != null) return themePack!;
    final legacyTheme = theme;
    if (legacyTheme is ThemePackBoardThemeAdapter) {
      return legacyTheme.themePack;
    }
    return modernEasternThemePack;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final pack = _pack;
    final cellSize = size.width / 4;
    final boardRect = Offset.zero & size;
    final boardRRect = RRect.fromRectAndRadius(
      boardRect,
      Radius.circular(pack.board.cornerRadius),
    );

    canvas.save();
    canvas.clipRRect(boardRRect);
    _drawSurface(canvas, size, pack);
    _drawGrid(canvas, size, cellSize, pack);

    if (lastMoveFrom != null) {
      _drawLastMoveMarker(
        canvas,
        cellSize,
        lastMoveFrom!,
        isDestination: false,
        pack: pack,
      );
    }
    if (lastMoveTo != null) {
      _drawLastMoveMarker(
        canvas,
        cellSize,
        lastMoveTo!,
        isDestination: true,
        pack: pack,
      );
    }

    for (final position in validMoves) {
      _drawValidMove(canvas, cellSize, position, pack);
    }

    for (var y = 0; y < 4; y++) {
      for (var x = 0; x < 4; x++) {
        final position = Position(x, y);
        if (position == hidePiece) continue;
        final piece = boardState.getPiece(position);
        if (piece != PieceType.empty) {
          _drawPiece(canvas, cellSize, position, piece, pack);
        }
      }
    }

    if (selectedPiece != null) {
      _drawSelection(canvas, cellSize, selectedPiece!, pack);
    }
    canvas.restore();

    final framePaint = Paint()
      ..color = pack.board.frameColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = pack.board.frameLineWidth;
    canvas.drawRRect(
      boardRRect.deflate(pack.board.frameLineWidth / 2),
      framePaint,
    );
  }

  void _drawSurface(Canvas canvas, Size size, ThemePack pack) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = pack.board.surfaceColor,
    );

    // A deterministic, low-contrast paper grain keeps the first-party theme
    // tactile without requiring an image asset or affecting legibility.
    final fiberPaint = Paint()
      ..color = pack.colors.inkMuted.withValues(alpha: 0.035)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;
    for (var y = 5.0; y < size.height; y += 11) {
      final wave = math.sin(y * 0.09) * 1.4;
      canvas.drawLine(
        Offset(0, y + wave),
        Offset(size.width, y - wave),
        fiberPaint,
      );
    }
  }

  void _drawGrid(
    Canvas canvas,
    Size size,
    double cellSize,
    ThemePack pack,
  ) {
    final gridPaint = Paint()
      ..color = pack.board.gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = pack.board.gridLineWidth;
    for (var index = 1; index < 4; index++) {
      final offset = index * cellSize;
      canvas
        ..drawLine(Offset(0, offset), Offset(size.width, offset), gridPaint)
        ..drawLine(Offset(offset, 0), Offset(offset, size.height), gridPaint);
    }
  }

  void _drawPiece(
    Canvas canvas,
    double cellSize,
    Position position,
    PieceType piece,
    ThemePack pack,
  ) {
    final center = _cellCenter(cellSize, position);
    final radius = cellSize * pack.pieces.radiusRatio;
    final tokens =
        piece == PieceType.black ? pack.pieces.inkSide : pack.pieces.jadeSide;

    final shadowPaint = Paint()
      ..color = pack.pieces.shadowColor
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        pack.pieces.shadowBlurRadius,
      );
    canvas.drawCircle(center + pack.pieces.shadowOffset, radius, shadowPaint);

    final facePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.35),
        radius: 1,
        colors: [tokens.highlightColor, tokens.surfaceColor],
        stops: const [0, 0.8],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, facePaint);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = tokens.borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.5, cellSize * 0.025),
    );

    switch (tokens.marker) {
      case PieceMarkerShape.fourPointSeal:
        _drawFourPointSeal(canvas, center, radius, tokens.markerColor);
      case PieceMarkerShape.concentricRing:
        _drawConcentricRing(canvas, center, radius, tokens.markerColor);
    }
  }

  void _drawFourPointSeal(
    Canvas canvas,
    Offset center,
    double radius,
    Color color,
  ) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square
      ..strokeWidth = math.max(1.4, radius * 0.08);
    for (var index = 0; index < 4; index++) {
      final angle = index * math.pi / 2;
      final inner = Offset(
        center.dx + math.cos(angle) * radius * 0.18,
        center.dy + math.sin(angle) * radius * 0.18,
      );
      final outer = Offset(
        center.dx + math.cos(angle) * radius * 0.48,
        center.dy + math.sin(angle) * radius * 0.48,
      );
      canvas.drawLine(inner, outer, paint);
    }
    final diamond = Path()
      ..moveTo(center.dx, center.dy - radius * 0.13)
      ..lineTo(center.dx + radius * 0.13, center.dy)
      ..lineTo(center.dx, center.dy + radius * 0.13)
      ..lineTo(center.dx - radius * 0.13, center.dy)
      ..close();
    canvas.drawPath(diamond, paint);
  }

  void _drawConcentricRing(
    Canvas canvas,
    Offset center,
    double radius,
    Color color,
  ) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.3, radius * 0.07);
    canvas
      ..drawCircle(center, radius * 0.43, paint)
      ..drawCircle(center, radius * 0.2, paint);
  }

  void _drawValidMove(
    Canvas canvas,
    double cellSize,
    Position position,
    ThemePack pack,
  ) {
    final center = _cellCenter(cellSize, position);
    final rect = Rect.fromLTWH(
      position.x * cellSize,
      position.y * cellSize,
      cellSize,
      cellSize,
    );
    switch (pack.board.validMoveMarker) {
      case BoardMarkerShape.dotAndTick:
        _drawDotAndTick(
          canvas,
          center,
          cellSize,
          pack.board.validMoveColor,
        );
      case BoardMarkerShape.doubleCorners:
        _drawDoubleCorners(
          canvas,
          rect,
          cellSize,
          pack.board.validMoveColor,
        );
      case BoardMarkerShape.endpointBrackets:
        _drawEndpointBrackets(
          canvas,
          rect,
          cellSize,
          pack.board.validMoveColor,
          isDestination: true,
        );
    }
  }

  void _drawDotAndTick(
    Canvas canvas,
    Offset center,
    double cellSize,
    Color color,
  ) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(2, cellSize * 0.035);
    canvas
      ..drawCircle(center, cellSize * 0.12, paint)
      ..drawCircle(
        center,
        cellSize * 0.035,
        Paint()..color = color,
      )
      ..drawLine(
        center + Offset(cellSize * 0.08, cellSize * 0.08),
        center + Offset(cellSize * 0.16, cellSize * 0.16),
        paint,
      );
  }

  void _drawSelection(
    Canvas canvas,
    double cellSize,
    Position position,
    ThemePack pack,
  ) {
    final pulse = (selectionPulse ?? 1).clamp(1.0, 1.15);
    final cellRect = Rect.fromLTWH(
      position.x * cellSize,
      position.y * cellSize,
      cellSize,
      cellSize,
    );
    switch (pack.board.selectionMarker) {
      case BoardMarkerShape.doubleCorners:
        _drawDoubleCorners(
          canvas,
          cellRect,
          cellSize,
          pack.board.selectionColor,
          pulse: pulse,
        );
      case BoardMarkerShape.dotAndTick:
        _drawDotAndTick(
          canvas,
          cellRect.center,
          cellSize,
          pack.board.selectionColor,
        );
      case BoardMarkerShape.endpointBrackets:
        _drawEndpointBrackets(
          canvas,
          cellRect,
          cellSize,
          pack.board.selectionColor,
          isDestination: true,
        );
    }
  }

  void _drawDoubleCorners(
    Canvas canvas,
    Rect cellRect,
    double cellSize,
    Color color, {
    double pulse = 1,
  }) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square
      ..strokeWidth = math.max(2, cellSize * 0.035);
    _drawCornerBrackets(
      canvas,
      cellRect.deflate(cellSize * (0.12 / pulse)),
      cellSize * 0.18,
      paint,
    );
    _drawCornerBrackets(
      canvas,
      cellRect.deflate(cellSize * (0.2 / pulse)),
      cellSize * 0.1,
      paint..strokeWidth = math.max(1.2, cellSize * 0.02),
    );
  }

  void _drawLastMoveMarker(
    Canvas canvas,
    double cellSize,
    Position position, {
    required bool isDestination,
    required ThemePack pack,
  }) {
    final rect = Rect.fromLTWH(
      position.x * cellSize,
      position.y * cellSize,
      cellSize,
      cellSize,
    );
    switch (pack.board.lastMoveMarker) {
      case BoardMarkerShape.endpointBrackets:
        _drawEndpointBrackets(
          canvas,
          rect,
          cellSize,
          pack.board.lastMoveColor,
          isDestination: isDestination,
        );
      case BoardMarkerShape.doubleCorners:
        _drawDoubleCorners(
          canvas,
          rect,
          cellSize,
          pack.board.lastMoveColor,
        );
      case BoardMarkerShape.dotAndTick:
        _drawDotAndTick(
          canvas,
          rect.center,
          cellSize,
          pack.board.lastMoveColor,
        );
    }
  }

  void _drawEndpointBrackets(
    Canvas canvas,
    Rect cellRect,
    double cellSize,
    Color color, {
    required bool isDestination,
  }) {
    final rect = cellRect.deflate(cellSize * 0.07);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square
      ..strokeWidth = math.max(1.5, cellSize * 0.025);

    if (isDestination) {
      _drawCornerBrackets(canvas, rect, cellSize * 0.14, paint);
      canvas.drawLine(
        Offset(rect.center.dx - cellSize * 0.08, rect.top),
        Offset(rect.center.dx + cellSize * 0.08, rect.top),
        paint,
      );
    } else {
      canvas
        ..drawLine(
          rect.topLeft,
          rect.topLeft + Offset(cellSize * 0.16, 0),
          paint,
        )
        ..drawLine(
          rect.topLeft,
          rect.topLeft + Offset(0, cellSize * 0.16),
          paint,
        )
        ..drawLine(
          rect.bottomRight,
          rect.bottomRight - Offset(cellSize * 0.16, 0),
          paint,
        )
        ..drawLine(
          rect.bottomRight,
          rect.bottomRight - Offset(0, cellSize * 0.16),
          paint,
        );
    }
  }

  void _drawCornerBrackets(
    Canvas canvas,
    Rect rect,
    double length,
    Paint paint,
  ) {
    canvas
      ..drawLine(rect.topLeft, rect.topLeft + Offset(length, 0), paint)
      ..drawLine(rect.topLeft, rect.topLeft + Offset(0, length), paint)
      ..drawLine(rect.topRight, rect.topRight - Offset(length, 0), paint)
      ..drawLine(rect.topRight, rect.topRight + Offset(0, length), paint)
      ..drawLine(rect.bottomLeft, rect.bottomLeft + Offset(length, 0), paint)
      ..drawLine(rect.bottomLeft, rect.bottomLeft - Offset(0, length), paint)
      ..drawLine(rect.bottomRight, rect.bottomRight - Offset(length, 0), paint)
      ..drawLine(rect.bottomRight, rect.bottomRight - Offset(0, length), paint);
  }

  Offset _cellCenter(double cellSize, Position position) {
    return Offset(
      (position.x + 0.5) * cellSize,
      (position.y + 0.5) * cellSize,
    );
  }

  @override
  bool shouldRepaint(covariant BoardPainter oldDelegate) {
    return oldDelegate.boardState != boardState ||
        oldDelegate.selectedPiece != selectedPiece ||
        oldDelegate.validMoves != validMoves ||
        oldDelegate.lastMoveFrom != lastMoveFrom ||
        oldDelegate.lastMoveTo != lastMoveTo ||
        oldDelegate.hidePiece != hidePiece ||
        oldDelegate.theme != theme ||
        oldDelegate.themePack != themePack ||
        oldDelegate.selectionPulse != selectionPulse;
  }
}
