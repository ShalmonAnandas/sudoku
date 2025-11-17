# Sudoku

A Flutter-based Sudoku game application.

## Features

- Interactive Sudoku game
- Multiple difficulty levels
- Save and load games
- Cross-platform support (Web, iOS, Android, Desktop)

## Development

This is a Flutter project. To run it locally:

```bash
flutter pub get
flutter run -d chrome  # For web
```

## Deployment

### Deploy to Vercel

This application is configured for easy deployment to Vercel. See [DEPLOYMENT.md](DEPLOYMENT.md) for detailed instructions.

Quick deployment:
1. Push to GitHub
2. Import the repository in Vercel
3. Deploy!

The build process is automated and will:
- Install Flutter SDK
- Build the web application
- Deploy to Vercel's CDN

## Project Structure

- `lib/` - Dart source code
- `web/` - Web-specific files
- `build.sh` - Vercel build script
- `vercel.json` - Vercel configuration

