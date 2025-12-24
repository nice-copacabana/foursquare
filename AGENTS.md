# Repository Guidelines

## Project Structure & Module Organization

- `lib/` holds the Flutter app code, organized by domain: `ai/`, `engine/`, `bloc/`, `models/`, `services/`, and `ui/`.
- `test/` contains unit and widget tests; `integration_test/` holds end-to-end flows.
- `assets/` stores images, sounds, icons, and splash resources; see `scripts/` for generators.
- Platform targets live in `android/`, `ios/`, `web/`, `windows/`, `macos/`, and `linux/`.
- Documentation lives under `docs/` and project summaries in `README.md` and `CHANGELOG.md`.

## Build, Test, and Development Commands

- Install dependencies: `flutter pub get`
- Run app: `flutter run` (or `flutter run -d chrome` for web)
- Analyze: `flutter analyze`
- Format: `dart format .`
- Unit/widget tests: `flutter test`
- Integration tests: `flutter test integration_test`
- Coverage report: `flutter test --coverage`
- Release builds: `flutter build apk`, `flutter build appbundle`, `flutter build ios`, `flutter build web`

## Coding Style & Naming Conventions

- Follow Dart/Flutter style (2-space indentation, trailing commas for clean diffs).
- Lints are defined in `analysis_options.yaml` and include `avoid_print`, `prefer_const_constructors`, `prefer_const_literals_to_create_immutables`, `prefer_final_fields`, `always_declare_return_types`, and `require_trailing_commas`.
- Use lower_snake_case for file names (Dart standard) and keep widget, bloc, and model names in UpperCamelCase.

## Testing Guidelines

- Frameworks in use: `flutter_test`, `integration_test`, `bloc_test`, and `mocktail`.
- Test files should end with `_test.dart` and live in the matching folder under `test/` or `integration_test/`.
- Prefer fast unit tests for game engine, models, and blocs; reserve integration tests for full gameplay flows.

## Commit & Pull Request Guidelines

- Commit messages follow Conventional Commits: `feat(scope): summary`, `fix(scope): summary`, `docs(scope): summary`, `chore(scope): summary`.
- Pull requests should include a short summary, testing notes (commands run), and screenshots or recordings for UI changes. Link related issues when applicable.

## Assets, Scripts, and Configuration

- Environment files live at `.env.development` and `.env.production`; avoid committing secrets.
- Resource generators are in `scripts/`, e.g. `scripts/generate_all_resources.ps1` for placeholder icons/audio.
