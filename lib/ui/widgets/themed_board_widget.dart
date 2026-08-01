import 'package:flutter/material.dart';

import '../../constants/ui_constants.dart';
import '../../models/board_state.dart';
import '../../models/position.dart';
import '../../services/storage_service.dart';
import '../../theme/theme_pack.dart';
import '../../theme/theme_pack_registry.dart';
import 'animated_board_widget.dart';
import 'board_painter.dart';
import 'board_widget.dart';

class ThemedBoardWidget extends StatefulWidget {
  const ThemedBoardWidget({
    super.key,
    required this.boardState,
    required this.onPositionTapped,
    this.selectedPiece,
    this.validMoves = const [],
    this.lastMoveFrom,
    this.lastMoveTo,
    this.capturedPiecePositions = const [],
    this.size,
    this.flipBoard = false,
    this.themePack,
  });

  final BoardState boardState;
  final Position? selectedPiece;
  final List<Position> validMoves;
  final Position? lastMoveFrom;
  final Position? lastMoveTo;
  final List<Position> capturedPiecePositions;
  final ValueChanged<Position> onPositionTapped;
  final double? size;
  final bool flipBoard;

  /// Optional injection seam used by previews, tests and future theme packs.
  /// The phase-one registry supplies modern eastern when omitted.
  final ThemePack? themePack;

  @override
  State<ThemedBoardWidget> createState() => _ThemedBoardWidgetState();
}

class _ThemedBoardWidgetState extends State<ThemedBoardWidget> {
  final StorageService _storageService = StorageService();
  final ThemePackRegistry _themeRegistry = ThemePackRegistry.phaseOne();
  bool _animationEnabled = true;
  bool _particleEnabled = true;
  bool _vibrationEnabled = true;

  ThemePack get _themePack => widget.themePack ?? _themeRegistry.defaultPack;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _storageService.loadSettings();
    if (!mounted) return;
    setState(() {
      _animationEnabled = settings.animationEnabled;
      _particleEnabled = settings.particleEnabled;
      _vibrationEnabled = settings.vibrationEnabled;
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.maybeOf(context);
    final systemReduceMotion = mediaQuery?.disableAnimations ?? false;
    final reduceMotion = systemReduceMotion || !_animationEnabled;
    final effectiveMotion = _themePack.motion.resolve(
      reduceMotion: reduceMotion,
    );
    final boardSize = widget.size ?? _calculateBoardSize(context);

    return SizedBox.square(
      dimension: boardSize,
      child: Stack(
        children: [
          Positioned.fill(
            child: ExcludeSemantics(
              child: AnimatedBoardWidget(
                boardState: widget.boardState,
                selectedPiece: widget.selectedPiece,
                validMoves: widget.validMoves,
                lastMoveFrom: widget.lastMoveFrom,
                lastMoveTo: widget.lastMoveTo,
                capturedPiecePositions: widget.capturedPiecePositions,
                onPositionTapped: widget.onPositionTapped,
                size: boardSize,
                vibrationEnabled: _vibrationEnabled,
                animationEnabled: effectiveMotion.moveDuration != Duration.zero,
                particleEnabled:
                    _particleEnabled && effectiveMotion.particlesEnabled,
                flipBoard: widget.flipBoard,
                theme: ThemePackBoardThemeAdapter(_themePack),
              ),
            ),
          ),
          Positioned.fill(
            child: BoardSemanticsOverlay(
              boardState: widget.boardState,
              selectedPiece: widget.selectedPiece,
              validMoves: widget.validMoves,
              lastMoveFrom: widget.lastMoveFrom,
              lastMoveTo: widget.lastMoveTo,
              flipBoard: widget.flipBoard,
              onPositionTapped: widget.onPositionTapped,
            ),
          ),
        ],
      ),
    );
  }

  double _calculateBoardSize(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final shortestSide = screenSize.shortestSide;
    return (shortestSide * UIConstants.boardScreenRatio).clamp(
      UIConstants.boardMinSize,
      UIConstants.boardMaxSize,
    );
  }
}
