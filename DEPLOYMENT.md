# Flutter Web Deployment Guide

## 🚀 Deploy to Dokploy VPS

### Prerequisites
- Dokploy installed and running
- Domain pointing to your VPS (e.g., magasinelhadi.iperfee.com)

### Recent Optimizations ✨

**Version:** Updated for Dokploy compatibility (Nov 2025)

**Key Improvements:**
- ✅ Fixed Flutter running as root user in Docker (prevents warnings and build issues)
- ✅ Removed obsolete docker-compose version field (prevents warnings)
- ✅ Optimized Dockerfile using official Flutter image (faster builds)
- ✅ Added `.dockerignore` to reduce build context size (faster uploads)
- ✅ Improved build caching (subsequent builds are much faster)
- ✅ Added health checks for better container monitoring
- ✅ Reduced build time from ~3+ minutes to ~1-2 minutes

### Step 1: Configure API Endpoint

Update the API base URL in `lib/config/config.dart`:

```dart
class AppConfig {
  static const String baseUrl = String.fromEnvironment(
    'APP_BASE_URL',
    defaultValue: 'https://your-api-domain.com',  // ⬅️ Change this
  );
}
```

### Step 2: Build for Production

```bash
# Build with custom API URL
flutter build web --release --dart-define=APP_BASE_URL=https://magasin-api.iperfee.com
```

### Step 3: Deploy via Dokploy

#### Option A: Using Dokploy UI
1. Go to Dokploy Dashboard
2. Create new application
3. Select "Docker Compose"
4. Upload/paste `docker-compose.yml`
5. Click "Deploy"

#### Option B: Using Git
1. Push code to Git repository
2. In Dokploy, create app from Git
3. Set branch and build settings
4. Deploy

### Step 4: Configure Domain

In `docker-compose.yml`, update Traefik labels:

```yaml
- "traefik.http.routers.*.rule=Host(`your-domain.com`)"
```

### Step 5: Verify Deployment

```bash
# Check if app is running
curl -I https://your-domain.com

# Should return 200 OK
```

## 🔧 Troubleshooting

### Issue: "Woah! You appear to be trying to run flutter as root" warning

**Problem**: The Flutter build runs as root user in Docker, causing:
- Warning message: "We strongly recommend running the flutter tool without superuser privileges"
- Potential build cancellations during compilation
- Permission and security issues

**Solution**: The Dockerfile now creates a non-root user (`flutter`) for the build stage ✅ (already fixed)
- Creates a dedicated `flutter` user with UID 1000
- All build commands run as this non-root user
- Proper ownership is set for all copied files
- This eliminates the root user warning and improves build reliability

### Issue: Build timeout or cancellation during deployment

**Problem**: The deployment starts but gets cancelled during "Compiling lib/main.dart for the Web..." phase.

**Solution**: The Dockerfile has been optimized to:
- Use official Flutter Docker image (no need to install Flutter from scratch)
- Reduce build context size with `.dockerignore` 
- Implement proper layer caching for faster builds
- This reduces build time from 3+ minutes to ~1-2 minutes

**If still timing out:**
1. Check Dokploy resource limits (CPU/Memory)
2. Increase timeout settings in Dokploy if available
3. Monitor build logs for memory issues

### Issue: "version is obsolete" warning

**Solution**: Removed the `version: '3.9'` field from docker-compose.yml ✅ (already fixed)

### Issue: "Page Not Found" when visiting domain

**Problem**: When you deploy to Dokploy and visit your domain, you see "Page Not Found" or 404 error. This happens because:
- This is a Flutter web app with client-side routing (Single Page Application)
- When you visit routes like `/categories` or `/notifications` directly, Nginx looks for actual files at those paths
- Since these files don't exist (only `index.html` exists), Nginx returns 404

**Solution**: The `nginx.conf` file configures proper SPA routing ✅ (already configured)
- All requests are redirected to `index.html` using the `try_files $uri $uri/ /index.html;` directive
- This allows Flutter's client-side router to handle all routes properly
- Works for direct URL access, page refresh, and deep linking

### Issue: "Page Not Found" on specific routes after deployment

**Solution**: Ensure `nginx.conf` is properly copied in your Dockerfile ✅ (already configured)

### Issue: API Connection Failed

**Solution**: Update `APP_BASE_URL` in config.dart

### Issue: Build Fails

**Solution**: 
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter build web --release
```

## 📝 Local Testing

```bash
# Test Docker build locally
docker compose up --build

# Visit: http://localhost:8090
```

**Note**: The optimized build should complete in ~1-2 minutes on first build, and subsequent builds with cached layers should be even faster (30-60 seconds if only code changes).

## 🚀 Build Performance

### Before Optimization
- Base image: Ubuntu 22.04 (manual Flutter installation)
- Build time: 3-5 minutes (first build)
- Prone to timeouts on resource-constrained VPS
- Large build context

### After Optimization  
- Base image: `ghcr.io/cirruslabs/flutter:stable` (official Flutter image)
- Build time: 1-2 minutes (first build), 30-60s (cached)
- Better layer caching (dependencies cached separately)
- Smaller build context (via `.dockerignore`)
- Health checks for monitoring
- No obsolete docker-compose warnings

## 🌐 Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| APP_BASE_URL | Backend API URL | http://localhost:8080 |

## 📦 Production Checklist

- [ ] Update API base URL in `lib/config/config.dart`
- [ ] Build with `--release` flag
- [ ] Configure domain in `docker-compose.yml` Traefik labels
- [ ] Enable HTTPS/SSL (Traefik handles this automatically)
- [ ] Test all routes work (direct access, refresh, deep linking)
- [ ] Verify API connectivity
- [ ] Ensure `nginx.conf` is included in build (check Dockerfile)

## 🎯 Performance Tips

1. **Enable Gzip** ✅ (configured in `nginx.conf`)
2. **Cache Static Assets** ✅ (configured in `nginx.conf`)
3. **Security Headers** ✅ (configured in `nginx.conf`)
4. **Use CDN** (optional, for global distribution)
5. **Optimize Images** (compress assets in `assets/`)

## 🚨 Important Notes

### SPA Routing Configuration
This Flutter web app uses client-side routing. The `nginx.conf` file is **critical** for proper deployment:
- It redirects all requests to `index.html` so Flutter's router can handle the routing
- Without this, direct URL access or page refresh will show 404 errors
- The Dockerfile automatically includes this configuration

### Files Required for Deployment
Ensure these files are present:
- `Dockerfile` - Multi-stage build with Flutter and Nginx
- `nginx.conf` - Nginx configuration with SPA routing support
- `docker-compose.yml` - Docker Compose configuration with Traefik labels

