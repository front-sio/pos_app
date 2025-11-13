# Flutter Web Deployment Guide

## 🚀 Deploy to Dokploy VPS

### Prerequisites
- Dokploy installed and running
- Domain pointing to your VPS (e.g., magasinelhadi.iperfee.com)

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

### Issue: "Page Not Found" on Routes

**Solution**: Nginx config handles SPA routing ✅ (already configured in `nginx.conf`)

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
docker-compose up --build

# Visit: http://localhost:8090
```

## 🌐 Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| APP_BASE_URL | Backend API URL | http://localhost:8080 |

## 📦 Production Checklist

- [ ] Update API base URL
- [ ] Build with `--release` flag
- [ ] Configure domain in docker-compose.yml
- [ ] Enable HTTPS/SSL (Traefik handles this)
- [ ] Test all routes work
- [ ] Verify API connectivity

## 🎯 Performance Tips

1. **Enable Gzip** ✅ (configured in nginx.conf)
2. **Cache Static Assets** ✅ (configured in nginx.conf)
3. **Use CDN** (optional, for global distribution)
4. **Optimize Images** (compress assets in `assets/`)

