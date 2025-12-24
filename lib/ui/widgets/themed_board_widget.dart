import 'dart:async';
import 'package:flutter/material.dart';
import '../../constants/theme_presets.dart';
import '../../models/board_state.dart';
import '../../models/position.dart';
import '../../models/board_theme.dart';
import '../../services/storage_service.dart';
import '../../theme/theme_manager.dart';
import 'animated_board_widget.dart';

class ThemedBoardWidget extends StatefulWidget {
  final BoardState boardState;
  final Position? selectedPiece;
  final List<Position> validMoves;
  final Position? lastMoveFrom;
  final Position? lastMoveTo;
  final Position? capturedPiecePosition;
  final Function(Position) onPositionTapped;
  final double? size;
  final bool flipBoard;

  const ThemedBoardWidget({
    super.key,
    required this.boardState,
    required this.onPositionTapped,
    this.selectedPiece,
    this.validMoves = const [],
    this.lastMoveFrom,
    this.lastMoveTo,
    this.capturedPiecePosition,
    this.size,
    this.flipBoard = false,
  });

  @override
  State<ThemedBoardWidget> createState() => _ThemedBoardWidgetState();
}

class _ThemedBoardWidgetState extends State<ThemedBoardWidget> {
  final StorageService _storageService = StorageService();
  final ThemeManager _themeManager = ThemeManager();
  StreamSubscription<BoardTheme>? _themeSubscription;
  BoardTheme _boardTheme = ThemePresets.defaultTheme;
  bool _animationEnabled = true;
  bool _particleEnabled = true;
  bool _vibrationEnabled = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadSettings();
  }

  @override
  void initState() {
    super.initState();
    _boardTheme = _themeManager.currentBoardTheme;
    _themeSubscription = _themeManager.themeStream.listen((theme) {
      if (!mounted) return;
      setState(() {
        _boardTheme = theme;
      });
    });
    _loadSettings();
  }

  @override
  void dispose() {
    _themeSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final settings = await _storageService.loadSettings();
    if (!mounted) return;
    setState(() {
      _animationEnabled = settings.animationEnabled;
      _particleEnabled = settings.particleEnabled;
      _vibrationEnabled = settings.vibrationEnabled;
      _boardTheme = _themeManager.currentBoardTheme;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBoardWidget(
      boardState: widget.boardState,
      selectedPiece: widget.selectedPiece,
      validMoves: widget.validMoves,
      lastMoveFrom: widget.lastMoveFrom,
      lastMoveTo: widget.lastMoveTo,
      capturedPiecePosition: widget.capturedPiecePosition,
      onPositionTapped: widget.onPositionTapped,
      size: widget.size,
      vibrationEnabled: _vibrationEnabled,
      animationEnabled: _animationEnabled,
      particleEnabled: _particleEnabled,
      flipBoard: widget.flipBoard,
      theme: _boardTheme,
    );
  }
}
