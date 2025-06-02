# Save Game and Resume Game Feature Implementation

This feature allows players to save their current game progress and resume it later.

## Components Implemented:

### 1. Game Storage Service
- Created a service to interact with SharedPreferences
- Save/load game state to/from local storage
- Auto-save preference management

### 2. Serialization
- Added JSON serialization to all model classes
  - GameState
  - SudokuBoard
  - SudokuCell
  - SudokuMove
  - Position

### 3. Auto-Save Features
- Automatic saving of game progress:
  - After each move
  - When pausing the game
  - When exiting the game
  - When the app is closed/backgrounded

### 4. UI Features
- Updated "Resume Game" button on home screen
  - Button is disabled when no saved game exists
  - Button automatically refreshes when returning to home screen
- Added settings option to toggle auto-save
- Added success message when manually saving game

### 5. App Lifecycle Management
- Added AppLifecycleHandler to capture app state changes
- Ensures game is saved when app is backgrounded or closed

## Usage Instructions:
1. During gameplay, the game is saved automatically if auto-save is enabled
2. Manual save via the game menu's "Save Game" option
3. Resume a saved game from the home screen's "Resume Game" button

## Key Files Modified:
- `services/game_storage_service.dart` (new file)
- `models/game_state.dart` (added serialization)
- `models/sudoku_board.dart` (added serialization)
- `models/sudoku_cell.dart` (added serialization)
- `providers/game_provider.dart` (added save/load functionality)
- `screens/home_screen.dart` (updated resume button)
- `screens/game_screen.dart` and `game_screen_new.dart` (updated save button)
- `screens/settings_screen.dart` (updated auto-save toggle)
- `widgets/app_lifecycle_handler.dart` (new file for auto-save)

The feature is now fully implemented and ready to use!
