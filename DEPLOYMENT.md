# Deploying to Vercel

This Flutter web application is configured to be deployed to Vercel.

## Prerequisites

- A Vercel account (sign up at https://vercel.com)
- The Vercel CLI (optional, for local testing)

## Deployment Methods

### Method 1: Deploy via Vercel Dashboard (Recommended)

1. Go to https://vercel.com and sign in
2. Click "Add New Project"
3. Import your GitHub repository
4. Vercel will automatically detect the `vercel.json` configuration
5. Click "Deploy"
6. Wait for the build to complete (first build may take 5-10 minutes as Flutter SDK is downloaded)

### Method 2: Deploy via Vercel CLI

1. Install Vercel CLI:
   ```bash
   npm i -g vercel
   ```

2. Login to Vercel:
   ```bash
   vercel login
   ```

3. Deploy from the project directory:
   ```bash
   vercel
   ```

4. Follow the prompts to complete deployment

## Configuration Files

This project includes the following Vercel-specific files:

- **vercel.json**: Vercel configuration specifying build command and output directory
- **build.sh**: Custom build script that installs Flutter and builds the web app
- **.vercelignore**: Specifies files to exclude from deployment

## Build Process

The build process:
1. Checks if Flutter is installed
2. If not, clones Flutter SDK (stable branch)
3. Runs `flutter pub get` to fetch dependencies
4. Builds the web app with `flutter build web --release`
5. Deploys the contents of `build/web` directory

## Notes

- First deployment will take longer as Flutter SDK needs to be downloaded
- Subsequent deployments will be faster if Flutter is cached
- The app will be available at a Vercel URL (e.g., https://your-app.vercel.app)
- Custom domains can be configured in Vercel dashboard

## Troubleshooting

If deployment fails:
1. Check the build logs in Vercel dashboard
2. Ensure `pubspec.yaml` dependencies are compatible with Flutter web
3. Verify that Flutter web build works locally with `flutter build web`

## Environment Variables

Currently, no environment variables are required. If you need to add environment variables:
1. Go to your project settings in Vercel dashboard
2. Navigate to "Environment Variables"
3. Add your variables
