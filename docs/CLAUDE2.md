# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is **Four Square Chess** (四子游戏) - a cross-platform strategy board game built with Flutter. The game is played on a 4×4 grid where players move pieces to form three-in-a-row patterns and capture opponent pieces.

## Common Development Commands

### Environment Setup
```bash
# Install dependencies
flutter pub get

# Run code generation (if needed)
flutter packages pub run build_runner build

# Check connected devices
flutter devices
```

### Development
```bash
# Run on connected device/emulator
flutter run

# Run on web (Chrome)
flutter run -d chrome

# Run on specific device
flutter run -d [device_id]

# Hot reload while running
# Press 'r' in terminal for hot reload
# Press 'R' for hot restart
```

### Build
```bash
# Debug builds
flutter build apk --debug
flutter build web --debug

# Release builds
flutter build apk --release
flutter build appbundle --release
flutter build web --release
flutter build ios --release
```

### Testing
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/bloc/game_bloc_test.dart

# Run tests with coverage
flutter test --coverage

# Run tests on specific platform
flutter test --platform chrome
```

### Code Quality
```bash
# Analyze code
flutter analyze

# Fix imports and format code
dart fix --apply
dart format .

# Run linting
flutter analyze --no-fatal-infos
```

## Architecture Overview

The project follows **BLoC (Business Logic Component) architecture** with clear separation of concerns:

```
UI Layer (lib/ui/)
    ↓ Events
BLoC Layer (lib/bloc/)
    ↓ Business Logic
Engine Layer (lib/engine/)
    ↓ Data
Model Layer (lib/models/)
```

### Key Architectural Components

1. **GameEngine** (`lib/engine/game_engine.dart`) - Core game logic
   - Move validation and execution
   - Capture detection and game rules
   - Win condition checking
   - Provides interfaces for AI simulation

2. **GameBloc** (`lib/bloc/game_bloc.dart`) - State management
   - Handles all game events via BLoC pattern
   - Manages game state transitions
   - Coordinates between services (audio, storage, music)
   - Integrates AI for single-player mode

3. **AI System** (`lib/ai/`)
   - `AIPlayer` - Abstract interface for AI players
   - `MinimaxAI` - Minimax algorithm with alpha-beta pruning
   - `BoardEvaluator` - Position evaluation heuristics

4. **Services Layer** (`lib/services/`)
   - `StorageService` - Local data persistence with Hive
   - `AudioService` - Sound effects management
   - `MusicService` - Background music system
   - `GameReplayService` - Game replay functionality
   - `WebSocketService` - Online multiplayer connectivity

5. **Models** (`lib/models/`) - Data structures
   - `BoardState` - Current board configuration
   - `Move` - Game move representation
   - `Position` - Board coordinates
   - `GameResult` - Game outcome information

## Key Dependencies and Their Purpose

- **flutter_bloc**: State management using BLoC pattern
- **hive**: Local NoSQL database for data persistence
- **audioplayers**: Audio playback for sound effects and music
- **fl_chart**: Chart rendering for statistics visualization
- **flutter_animate**: Animation utilities
- **web_socket_channel**: WebSocket support for online multiplayer
- **intl**: Internationalization support (Chinese, English, Japanese)

## Game Rules and Logic

### Basic Rules
- 4×4 grid board with 4 pieces per player (black/white)
- Black moves first
- Pieces move to adjacent empty positions (no diagonal moves)
- Capturing occurs when a move forms "own-own-enemy" line horizontally or vertically
- Win by capturing all opponent pieces or blocking all moves

### Key Files for Game Logic
- `lib/engine/move_validator.dart` - Valid move checking
- `lib/engine/capture_detector.dart` - Capture detection logic
- `lib/ai/evaluation.dart` - AI board evaluation heuristics

## Development Guidelines

### State Management
- All game state changes must go through GameBloc events
- Use equatable for state equality comparison
- Never mutate state directly - create new instances

### File Organization
- Keep UI components in `lib/ui/widgets/`
- Screen-level widgets in `lib/ui/screens/`
- Business logic in BLoC layer
- Data models in `lib/models/`

### Testing
- Unit tests for models, engine logic, and BLoC
- Widget tests for UI components
- Integration tests for complete game flows
- Use mocktail for mocking dependencies

### Internationalization
- All user-facing strings must use `AppLocalizations`
- Supported languages: Chinese (zh), English (en), Japanese (ja)
- Localization files in `lib/l10n/`

### Storage
- Use Hive for complex data structures
- Use SharedPreferences for simple key-value settings
- All storage operations go through StorageService

## Environment Configuration

The project uses environment-specific configuration files:
- `.env.development` - Development environment
- `.env.production` - Production environment
- Uses `flutter_dotenv` for environment variable management

## Common Tasks

### Adding New Game Features
1. Update game logic in `lib/engine/`
2. Add events/states in `lib/bloc/`
3. Update UI components in `lib/ui/`
4. Add corresponding tests

### Adding New AI Difficulty
1. Update evaluation logic in `lib/ai/evaluation.dart`
2. Modify depth parameters in `lib/ai/minimax_ai.dart`
3. Update AI configuration in settings

### Updating UI Theme
1. Modify theme configurations in `lib/theme/theme_manager.dart`
2. Update color schemes and styles
3. Test across different screen sizes

### Debugging Game Logic
1. Use LoggerService for structured logging
2. Test game engine logic independently
3. Use BLoC observer for state change tracking