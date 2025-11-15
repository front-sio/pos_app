# Sales Management Flutter App

A comprehensive Point of Sale (POS) and Sales Management System built with Flutter. This mobile/desktop application provides a complete interface for managing sales, inventory, customers, and business operations.

## Recent Updates (Nov 15, 2025)

### Service Worker Bootstrap Error Fix (Nov 15, 2025)
- ✅ **Fixed flutter_bootstrap.js Async Error** - Removed duplicate service worker registration
- ✅ **Single Service Worker Registration** - Flutter bootstrap handles SW automatically
- ✅ **Cleaner Error Handling** - Eliminated async timeout errors in bootstrap
- ✅ **Fixed Service Worker Refresh Loop** - Removed auto-reload that caused infinite refresh on blue screen
- ✅ **Removed PWA Auto-Install Prompt** - Eliminated intrusive install prompts and update notifications
- ✅ **Fixed dart:html Import Issue** - Migrated to conditional imports for better web compatibility
- ✅ **Connectivity Service Fix** - Platform-specific implementations for web/mobile connectivity checks
- ✅ **Splash Screen Optimization** - Reduced splash duration to 3 seconds and added weather loading timeout
- ✅ **Clean Service Worker** - Simplified registration without version detection polling

**Changes:**
- Removed duplicate service worker registration from `web/index.html`
- Flutter's `flutter_bootstrap.js` now handles SW registration exclusively
- Fixed async timeout error in service worker loader
- Service worker now registers without `controllerchange` auto-reload
- Removed update notification and PWA install prompt functions
- Split connectivity service into web/mobile platform-specific modules
- Added 3-second timeout for weather data loading on splash screen
- All `dart:html` imports moved to conditional platform-specific files

**Web Performance:**
- No more flutter_bootstrap.js async errors
- No duplicate service worker registrations
- No more infinite refresh loops on blue screen
- Faster initial load (3s vs 4s splash)
- Better error handling for geolocation on web
- Cleaner console logs without polling messages

## Previous Updates (Nov 14, 2025)

### TextStyle Animation Fix (Nov 14, 2025)
- ✅ **Fixed TextButton Animation Error** - Resolved "Failed to interpolate TextStyles with different inherit values"
- ✅ **Theme Update** - Removed conflicting textStyle from TextButtonTheme and ElevatedButtonTheme
- ✅ **Login Screen Fix** - Updated TextButton to use foregroundColor instead of Theme.of(context).textTheme
- ✅ **Smooth Animations** - All button animations now work without errors
- ✅ **Material 3 Compatibility** - Theme properly configured for Material 3 animations

**Changes:**
- Removed `textStyle` property from button themes (causes inherit conflicts)
- Updated TextButton widgets to use simple TextStyle with inherit: true
- Set color via `foregroundColor` in button style instead of text style

### Customer Features Enhanced (Nov 14, 2025)
- ✅ **Email & Phone Fields** - Customers now include contact information
- ✅ **Customer Model Updated** - Added email and phone fields (nullable)
- ✅ **Backend Support** - customers-service handles email/phone in create/update
- ✅ **Enhanced UI Display** - Customer cards show email and phone with icons
- ✅ **Form Validation** - Email format validation, phone optional
- ✅ **Search Enhancement** - Search now includes email and phone fields
- ✅ **View Screen Updated** - Customer details display all contact information
- ✅ **Invoice Integration Ready** - Email field enables invoice sending to customers
- ✅ **Notification Ready** - Contact fields support customer notifications
- ✅ **Mobile & Desktop** - Both compact and grid views updated

**Customer Data Structure:**
```dart
class Customer {
  final int id;
  final String name;
  final String? email;    // NEW - For invoices & notifications
  final String? phone;    // NEW - For SMS/WhatsApp features
}
```

**Features:**
- Create/Edit customers with email and phone
- Email validation (format check)
- Display contact info in customer list
- Search by name, email, or phone
- View complete customer details

### User-Friendly Error Messages & Error Handling (Nov 14, 2025)
- ✅ **Unified Error Screen** - All features now use `ErrorPlaceholder` widget for consistent error display
- ✅ **User-Friendly Messages** - Replaced technical error messages with clear, actionable messages
- ✅ **Network Error Handling** - Features distinguish between network and application errors
- ✅ **Success Messages Improved** - Clear confirmation messages for completed operations
- ✅ **Validation Messages** - Better form validation feedback for users
- ✅ **Features Updated**:
  - Customers - Uses ErrorPlaceholder, clean error messages
  - Categories - User-friendly validation and error messages
  - Units - Clear error feedback
  - Invoices - Consistent error handling with ErrorPlaceholder
  - Expenses - Unified error screen
  - Sales - Improved return and cart error messages
  - Products - Already using ErrorPlaceholder (reference implementation)
  - Purchases - Clean error messages
  - Auth - Simplified login error messages
  - Users - Clear operation feedback
  - Settings - Consistent error messages
  - Profile - User-friendly update messages
  - Reports - Clean error handling

**Before:**
- "Error: Failed to fetch data: SocketException: Connection refused"
- "Exception: 401 Unauthorized"

**After:**
- "Oops! Something went wrong - We're having trouble loading this data. Please check your connection and try again."
- "Login failed. Please check your credentials and try again."

### WebSocket & Realtime Features Fix (Nov 14, 2025)
- ✅ **Notifications service FULLY STRUCTURED** - Express + Drizzle ORM + Socket.IO
- ✅ **Proper package.json** - All dependencies and scripts configured
- ✅ **Drizzle migrations** - Database schema managed with drizzle-kit
- ✅ **Database table created** - notifications table in PostgreSQL
- ✅ **Gateway configuration updated** - Enabled notifications endpoints
- ✅ **Flutter notifications enabled** - Full realtime connection working
- ✅ **UI completely updated** - Beautiful notification cards with type colors
- ✅ **Badge in app bar** - Shows unread count with visual indicator
- ✅ **Notification types** - Success (green), Warning (orange), Error (red), Info (blue)
- ✅ **Auto-connect on login** - Notifications start with JWT token
- ✅ **Socket.IO realtime** - Live notifications to users
- ✅ **REST API endpoints** - CRUD operations for notifications
- ✅ **Webhook endpoints** - Other services can trigger notifications
- ✅ **Business event triggers** - Invoices, sales, stock, purchases, etc.
- ✅ **Smart notification logic** - Low stock alerts, large sales, overdue invoices
- ✅ **Targeted & broadcast** - User-specific or system-wide notifications
- ✅ **Products realtime working** - Socket.IO properly configured for products
- ✅ **Clean error logs** - No more repeated connection errors
- ✅ **User authentication** - JWT token verification
- ℹ️  **Products WebSocket** - Enabled on `/socket.io-products` path
- ℹ️  **Notifications WebSocket** - Enabled on `/socket.io-notifications` path
- ℹ️  **Port 3022** - Notifications service on dedicated port

## Socket.IO Connection Errors - FIXED ✅

### Problem
The Flutter app was showing Socket.IO connection errors:
```
[NotificationSocket] connect_error: {msg: websocket error, desc: null, type: TransportError}
[RealtimeProducts] connect_error: {msg: websocket error, desc: null, type: TransportError}
```

### Root Cause
1. **Gateway Configuration Issue**: The API gateway was configured to route to Docker hostnames (e.g., `http://notifications-service:3022`) but services were running on `localhost`
2. **Services Not Running**: Some microservices (products, notifications) weren't started
3. **Missing Gateway Restart**: Gateway needed restart to apply new configuration

### What Was Fixed

#### 1. Gateway Configuration (`sales-gateway/config/gateway.config.yml`)
**Changed service endpoints from Docker hostnames to localhost:**
```yaml
serviceEndpoints:
  products-service:
    url: http://localhost:3013        # Was: http://products-service:3013
  notifications-service:
    url: http://localhost:3022        # Was: http://notifications-service:3022
  sales-service:
    url: http://localhost:3014        # Was: http://sales-service:3014
  # ... all other services updated
```

#### 2. Socket.IO Routing (Already Configured ✅)
The gateway already has proper Socket.IO WebSocket proxying:
```yaml
socketio-notifications-pipeline:
  apiEndpoints: [socketio_notifications]
  policies:
    - proxy:
        serviceEndpoint: notifications-service
        ws: true                       # WebSocket support enabled
        stripPath: false
        preserveHostHdr: true

socketio-products-pipeline:
  apiEndpoints: [socketio_products]
  policies:
    - proxy:
        serviceEndpoint: products-service
        ws: true                       # WebSocket support enabled
```

### How to Start Services

#### Option 1: Start All Services (Recommended)
```bash
cd /home/masanja/API\ GATEWAY/sales-microservices
./start-all-services.sh
```

#### Option 2: Start Individual Services
```bash
# Start Products Service
cd sales-gateway/products-service
npm run dev &

# Start Notifications Service  
cd sales-gateway/notifications-service
node dist/index.js &

# Start Sales Service
cd sales-gateway/sales-service
npm run dev &
```

#### Option 3: Use Individual Service Scripts
```bash
./start-notifications.sh    # Start notifications only
```

### Verify Services Are Running

**Check all services:**
```bash
curl http://localhost:3013/health   # Products
curl http://localhost:3014/health   # Sales  
curl http://localhost:3022/health   # Notifications
curl http://localhost:8080/health   # Gateway
```

**Test Socket.IO through gateway:**
```bash
# Test notifications socket
curl -i http://localhost:8080/socket.io-notifications/?EIO=4&transport=polling

# Test products socket
curl -i http://localhost:8080/socket.io-products/?EIO=4&transport=polling
```

### Restart Gateway (If Needed)

**If you updated the gateway config, restart it:**
```bash
sudo systemctl restart sales-gateway
# OR
sudo pkill -f "node server.js"
cd sales-gateway && sudo node server.js &
```

### Testing Socket.IO Connections

**From Flutter app:**
1. Ensure services are running (use start-all-services.sh)
2. Ensure gateway is running on port 8080
3. App should connect to `https://app.stebofarm.co.tz/socket.io-notifications`
4. Gateway proxies to `http://localhost:3022/socket.io-notifications`
5. Check logs for successful connection

**Manual test:**
```bash
# Install wscat if needed
npm install -g wscat

# Test WebSocket connection
wscat -c "ws://localhost:8080/socket.io-notifications/?EIO=4&transport=websocket"
```

### Architecture Overview

```
Flutter App (https://app.stebofarm.co.tz)
           ↓
    Nginx/Reverse Proxy
           ↓
    API Gateway :8080
     ├─ /products → localhost:3013
     ├─ /sales → localhost:3014
     ├─ /notifications → localhost:3022
     ├─ /socket.io-products → localhost:3013 (WebSocket)
     ├─ /socket.io-notifications → localhost:3022 (WebSocket)
     └─ /socket.io → localhost:3014 (WebSocket)
           ↓
    Microservices (running on localhost)
     ├─ products-service :3013
     ├─ sales-service :3014
     ├─ notifications-service :3022
     └─ ... other services
```

### Troubleshooting

**If Socket.IO still fails:**

1. **Check services are running:**
   ```bash
   ps aux | grep -E "products-service|notifications-service|sales-service"
   ```

2. **Check service logs:**
   ```bash
   tail -f /tmp/products-service.log
   tail -f /tmp/notifications-service.log
   ```

3. **Test service directly:**
   ```bash
   curl http://localhost:3013/health
   ```

4. **Test through gateway:**
   ```bash
   curl http://localhost:8080/products
   ```

5. **Check gateway logs:**
   ```bash
   tail -f /tmp/gateway.log
   ```

6. **Verify gateway config:**
   ```bash
   cat sales-gateway/config/gateway.config.yml | grep -A2 "serviceEndpoints:"
   ```

**Common Issues:**

- ❌ **"Connection refused"** → Service not running, start it
- ❌ **"EADDRINUSE"** → Port already in use, kill existing process
- ❌ **"404 Not Found"** → Gateway routing issue, check gateway.config.yml
- ❌ **"websocket error"** → Gateway not proxying WebSocket, ensure `ws: true` in config
- ❌ **"ECONNREFUSED"** → Gateway can't reach service, check service URL in config

## Summary of Changes

### ✅ Customer Email Field Added
- **File**: `customers-service/src/db/schema/accounts_customer.ts`
- **Changes**: Added `email` (VARCHAR 255) and `phone` (VARCHAR 50) fields
- **Database**: Columns added to `accounts_customer` table in `customersdb`
- **Usage**: Can now send invoices to customer email addresses

### ✅ Notification Service Setup
- **Database**: Created dedicated `notificationsdb` (following microservices pattern)
- **Port**: Service runs on 3022
- **Table**: notifications table created with proper schema
- **Status**: Service configured and tested (database connections working)

### ✅ Webhook Integration Status
- **Sales Service**: ✓ Configured to trigger notifications
- **Products Service**: ✓ Configured to trigger notifications  
- **Webhooks Available**:
  - `/webhooks/sale-completed` - Sale notifications
  - `/webhooks/product-created` - Product creation
  - `/webhooks/low-stock` - Low stock alerts
  - `/webhooks/stock-out` - Out of stock alerts

### 🔧 Starting the Notification Service

**Option 1: Using startup script**
```bash
cd /home/masanja/API\ GATEWAY/sales-microservices
./start-notifications.sh
```

**Option 2: Manual start**
```bash
cd sales-gateway/notifications-service
node dist/index.js &
```

**Verify service is running:**
```bash
curl http://localhost:3022/health
# Should return: "Notifications Service is healthy"
```

### 🧪 Testing Notifications

**Test via webhook:**
```bash
curl -X POST http://localhost:3022/webhooks/sale-completed \
  -H "Content-Type: application/json" \
  -d '{"saleId": 123, "total": 50000, "userId": 1}'
```

**Check database:**
```bash
PGPASSWORD=password psql -h 74.50.97.22 -p 5438 -U postgres -d notificationsdb \
  -c "SELECT * FROM notifications ORDER BY created_at DESC LIMIT 5;"
```

### 📊 Architecture Summary

**Microservices Database Pattern:**
- Each service has its own database (following best practices)
- `customersdb` (port 5441) - Customer data with email/phone
- `notificationsdb` (port 5438) - Notification data
- `productsdb` (port 5438) - Product data
- `salesdb` (port 5436) - Sales data

**Why Separate Databases:**
1. ✓ Data Isolation - Services don't share data
2. ✓ Independent Scaling - Scale services independently
3. ✓ Schema Autonomy - Update schemas without coordination
4. ✓ Fault Tolerance - Failures are isolated
5. ✓ Security - Separate access controls

## Notifications Service Setup

### Backend Structure (Like other microservices)
```
notifications-service/
├── package.json           # Dependencies (Express, Drizzle, Socket.IO)
├── drizzle.config.ts      # Database configuration
├── tsconfig.json          # TypeScript configuration
├── .env                   # Environment variables
├── migrations/            # Drizzle database migrations
└── src/
    ├── index.ts           # Main Express + Socket.IO server
    ├── realtime.ts        # Socket.IO handlers
    ├── notificationTriggers.ts  # Business logic triggers
    ├── db/
    │   ├── db.ts          # Drizzle database connection
    │   └── schema/
    │       ├── index.ts
    │       └── notifications.ts  # Notification model
    ├── services/
    │   └── notificationService.ts  # CRUD operations
    └── routes/
        ├── notifications.ts  # REST API routes
        └── webhooks.ts       # Webhook endpoints
```

### Webhook Integration (IMPLEMENTED)

**Sales Service** → Triggers notifications on:
- ✅ **Sale Completed** - When transaction completes
- ✅ **Large Sale Alert** - Sales ≥ 1M TZS (broadcast to admins)

**Products Service** → Triggers notifications on:
- ✅ **Product Created** - When new product added
- ✅ **Low Stock Alert** - When stock ≤ reorder level
- ✅ **Stock Out** - When stock reaches 0

**Code Integration Example (Sales Service):**
```typescript
// After successful sale creation
triggerNotification('sale-completed', {
  saleId: Number(result.id),
  total: netTotal,
  userId: userId,
});
```

**Code Integration Example (Products Service):**
```typescript
// After stock update, check levels
if (minStock > 0 && currentStock <= minStock) {
  triggerNotification('low-stock', {
    productId: product.id,
    productName: product.name,
    currentStock: currentStock,
    minStock: minStock,
    userId: 1,
  });
}
```

### Installation & Setup
```bash
cd sales-gateway/notifications-service

# Install dependencies
pnpm install

# Generate database migration
pnpm run migrate:dev

# Push migration to database
pnpm run migrate:up

# Build TypeScript
pnpm run build

# Start service
pnpm start
# OR for development
pnpm run dev
```

### Database Configuration
Update `.env` with your database credentials:
```
NOTIFICATIONS_PORT=3022
NOTIFICATIONS_DATABASE_URL=postgresql://postgres:password@74.50.97.22:5438/notificationsdb
JWT_SECRET=a59a6d94ccbae4ac5adbab06540b7d39fa1ebbfb69f583962ef63010e81807c2
```

**WHY NOTIFICATIONS HAS ITS OWN DATABASE:**
Following microservices best practices, each service should have its own database for:
- **Data isolation**: Notifications data separate from products/sales
- **Independent scaling**: Scale notification storage independently
- **Schema autonomy**: Update notification schema without affecting other services
- **Fault tolerance**: Database issues in one service don't affect others

**Database Setup:**
```bash
# Create dedicated notificationsdb
PGPASSWORD=password psql -h 74.50.97.22 -p 5438 -U postgres -c "CREATE DATABASE notificationsdb;"
```

**Note:** Ensure the database URL format is: `postgresql://user:password@host:port/database`

### Manual Table Creation (if migration hangs)
If `pnpm run migrate:up` hangs, create the table manually:
```bash
PGPASSWORD=your_password psql -h host -p port -U postgres -d notificationsdb -c "
CREATE TABLE IF NOT EXISTS notifications (
  id serial PRIMARY KEY NOT NULL,
  user_id integer NOT NULL,
  title text NOT NULL,
  message text NOT NULL,
  type text DEFAULT 'info' NOT NULL,
  is_read boolean DEFAULT false NOT NULL,
  metadata text,
  created_at timestamp DEFAULT now() NOT NULL,
  read_at timestamp
);
"
```

## Notification Triggers

The system automatically sends notifications for these business events:

### 📄 Invoice Events
- **Invoice Created**: When new invoice is generated
- **Payment Received**: When customer makes payment
- **Invoice Overdue**: Alerts for past-due invoices

### 💰 Sales Events
- **Sale Completed**: Every successful sale
- **Large Sale Alert**: High-value sales (≥1,000,000 TZS) - broadcast to admins

### 📦 Stock Events
- **Low Stock**: When inventory falls below minimum level
- **Stock Out**: When product is completely out of stock

### 🛒 Purchase Events
- **Purchase Created**: New purchase order placed
- **Purchase Received**: When goods are received

### 👥 Customer Events
- **New Customer**: When customer is registered

### 🏷️ Product Events
- **Product Created**: New product added to catalog
- **Price Changed**: When product price is updated

### 🔄 Return Events
- **Return Processed**: When sale return is completed

### ⚙️ System Events
- **System Maintenance**: Broadcast maintenance notifications
- **Daily Reports**: End-of-day business summary

### Network Error Handling & API Status Screen (Nov 14, 2025)
- ✅ **API Error Screen** - Dedicated screen showing server connection issues (English)
- ✅ **Network error detection** - Distinguishes network vs other errors
- ✅ **User-friendly error messages** - Clear messages in English
- ✅ **Detailed error info** - Shows server URL and endpoint
- ✅ **Connection tips** - Helpful suggestions for troubleshooting
- ✅ **Retry functionality** - Easy retry button to reconnect
- ✅ **Timeout handling** - 30-second timeout with proper error messages
- ✅ **ClientException handling** - Catches and displays network failures
- ✅ **All features updated** - Products, Invoices, Customers, Sales, Stocks, Suppliers, Expenses, Dashboard
- ✅ **Purchase service updated** - Uses AuthHttpClient for proper auth
- ✅ **Error state tracking** - Tracks network vs non-network errors
- ✅ **Smart error display** - Full screen for network errors, snackbar for others
- ✅ **Offline vs unreachable** - Different handling for no internet vs server down
- ✅ **Socket error handling** - Proper handling when server is unreachable
- ✅ **Status code details** - Shows HTTP status codes when available
- ✅ **Consistent error handling** - All features use same error pattern

### Invoice Discount Fix
- ✅ **Discount affects total_amount** - Backend correctly reduces invoice total
- ✅ **Discount affects paid_amount** - Overpayments automatically adjusted
- ✅ **Discount affects due_amount** - Outstanding balance recalculated
- ✅ **Payment adjustment** - Excess payments removed when discount applied
- ✅ **Sales notification** - Sales service notified of discounts
- ✅ **Status recomputation** - Invoice status (paid/credited/unpaid) updated
- ✅ **Frontend sync** - UI shows updated total, paid, and due amounts
- ✅ **Both backend & frontend** - Complete discount flow working

### Network Connectivity & PWA Features (REAL-TIME FIX - Nov 14, 2025)
- ✅ **Real-time offline detection (Web)** - Native browser online/offline events
- ✅ **Immediate feedback** - No polling delays, instant offline screen
- ✅ **Const event fixed** - ConnectivityChanged properly marked as const
- ✅ **No false positives** - Only shows offline screen when genuinely offline
- ✅ **Clean state management** - Proper debouncing with 300ms delay
- ✅ **English UI only** - All messages in English as requested
- ✅ **Removed native splash** - Only custom splash screen shows
- ✅ **Debounced state changes** - 300ms debounce prevents rapid toggling
- ✅ **Offline placeholder** - Beautiful screen with retry functionality
- ✅ **Connection tips** - Helpful dialog with troubleshooting tips (English)
- ✅ **Multi-platform support** - Web uses browser events, mobile uses connectivity_plus
- ✅ **Cross-platform** - Works on Android, iOS, Web, and Desktop
- ✅ **Version detection** - Notifies user when new version is available (English)
- ✅ **Auto-refresh prompt** - User can refresh to load new changes (English)
- ✅ **PWA install prompt** - Prompts mobile users to install app (English)
- ✅ **Smart timing** - Shows install prompt after 10 seconds on mobile
- ✅ **Service Worker** - Detects updates and manages cache

### Splash Screen & Weather Integration (COMPLETE)
- ✅ **Custom Flutter splash widget** - Beautiful animated splash screen
- ✅ **Single splash only** - Hidden Flutter default loader completely
- ✅ **Soft blue theme** - Modern solid blue (#1976D2) - no gradient
- ✅ **Optimized text sizes** - Smaller, cleaner font sizes for better UI
- ✅ **Direct app start** - Flutter loader hidden, only custom splash visible
- ✅ **Web optimized** - Blue background + hidden default loader
- ✅ **Time-based greetings** - Good Morning/Afternoon/Evening/Night with icons
- ✅ **Real weather integration** - Uses OpenWeatherMap API for live weather
- ✅ **Improved location detection** - Fallback to API if geocoding fails
- ✅ **Beautiful animations** - Fade, scale, and slide transitions
- ✅ **Weekly weather widget** - 7-day forecast on dashboard (real data)
- ✅ **Scrollable forecast** - Fixed RenderFlex overflow (99640px fix!)
- ✅ **Web scroll arrows** - Left/right arrows for easy navigation
- ✅ **Mobile-first responsive** - Adapts card sizes for small screens
- ✅ **Weather icons** - Emojis for clear, cloudy, rainy, thunderstorm, etc.
- ✅ **Web location support** - Geolocation permissions configured for web
- ✅ **Emoji support** - Fixed Noto fonts warning

### API Error Handling with User-Friendly Messages (UPDATED)
- ✅ **Comprehensive error handling** - Catches timeouts, network errors, bad gateway
- ✅ **Swahili error messages** - All errors shown in clear Swahili
- ✅ **Timeout detection** - 30-second timeout with retry suggestions
- ✅ **Server unavailable detection** - Detects 502, 503, 504 errors
- ✅ **Network error handling** - Clear messages for connection failures
- ✅ **User-friendly dialogs** - Error dialogs with retry options
- ✅ **Snackbar notifications** - Quick error feedback with icons

### Network Connectivity Monitoring (UPDATED)
- ✅ **App-level network monitoring** - Automatic detection of network loss
- ✅ **Real-time notifications** - Immediate snackbar alerts when connection lost/restored
- ✅ **Offline placeholder** - User-friendly screen with retry functionality
- ✅ **Seamless restoration** - Returns to the same page when back online
- ✅ **English UI** - All messages in English for clarity
- ✅ **Connection tips** - Helpful troubleshooting tips in English

### Backend Fixes
- ✅ Fixed TypeScript compilation error in sales service (`returnedValue` variable scope)
- ✅ Verified invoice-sales bidirectional communication for returns and discounts
- ✅ Ensured proper payment adjustments when processing returns

### Frontend Improvements
- ✅ **Fixed invoice loader issue** - Loader no longer continuously updates on invoice page (NEW)
- ✅ Added error placeholder widgets for better UX on API failures
- ✅ Improved error handling - technical errors hidden from users
- ✅ Enhanced login flow to prevent premature app loader display
- ✅ Optimized dashboard loading for faster user experience

## Features

### 📦 Product Management
- ✅ View all products with search and filter
- ✅ Add new products with categories and units (REQUIRED)
- ✅ Edit product details and pricing
- ✅ Delete products
- ✅ Stock level monitoring
- ✅ Barcode support
- ✅ Category and unit management

### 🛒 Purchase Management  
- ✅ Create purchase orders with supplier selection (REQUIRED)
- ✅ View purchase history
- ✅ Edit purchase orders
- ✅ Delete purchase orders
- ✅ Automatic stock updates
- ✅ Multi-item purchases

### 💰 Sales Management
- ✅ Create sales transactions
- ✅ View sales history
- ✅ Edit sales (before invoice)
- ✅ Multi-item sales
- ✅ Customer assignment
- ✅ Payment tracking
- ✅ Automatic invoice generation

### 📄 Invoice Management
- ✅ Auto-generated invoices from sales
- ✅ View invoice details
- ✅ Apply discounts to invoices
- ✅ Payment status tracking (paid/unpaid/credited)
- ✅ Invoice PDF generation
- ✅ Bidirectional sync with sales (discount updates sales)

### 🔄 Returns Management
- ✅ Process product returns
- ✅ Automatic stock restoration
- ✅ Sales and invoice updates
- ✅ Return history tracking

### 👥 User Management
- ✅ Create users with roles
- ✅ View all users
- ✅ Edit user information
- ✅ Delete users
- ✅ Role-based access control (RBAC)
- ✅ Permissions management

### 📊 Additional Features
- ✅ Dashboard with analytics
- ✅ Customer management
- ✅ Supplier management
- ✅ Expense tracking
- ✅ Profit analysis
- ✅ Stock reports
- ✅ Sales reports
- ✅ Real-time notifications
- ✅ Settings management
- ✅ **Network connectivity monitoring** (NEW)
- ✅ **Offline/Online detection** (NEW)
- ✅ **Auto-reconnection** (NEW)
- ✅ **API error handling with Swahili messages** (NEW)
- ✅ **Timeout and server error detection** (NEW)
- ✅ **Animated splash screen** (NEW)
- ✅ **Weather integration with 7-day forecast** (NEW)
- ✅ **Time-based greetings** (NEW)

## Prerequisites

- Flutter SDK 3.0+
- Dart 3.0+
- Running backend services (see `../sales-gateway/README.md`)

## Installation

1. **Install Flutter:**
   ```bash
   # Follow: https://flutter.dev/docs/get-started/install
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure API:**
   
   Edit `lib/config/config.dart`:
   ```dart
   static const String baseUrl = 'http://localhost:8080';
   ```

## Running

```bash
# Mobile/Desktop
flutter run

# Web
flutter run -d chrome

# Specific device
flutter run -d linux
```

## Testing Checklist

Run the testing script:
```bash
./check_app_features.sh
```

Or manually test:

### ✅ Products
- [ ] View products list
- [ ] Add product (category & unit required)
- [ ] Edit product
- [ ] Delete product

### ✅ Purchases
- [ ] View purchases
- [ ] Create purchase (supplier required)
- [ ] Edit purchase
- [ ] Delete purchase

### ✅ Sales
- [ ] Create sale
- [ ] View sales
- [ ] Verify invoice auto-created
- [ ] Verify stock reduced

### ✅ Invoices
- [ ] View invoices
- [ ] Apply discount
- [ ] Verify sale updated (bidirectional)
- [ ] Check loader doesn't continuously update at top of page (FIXED)

### ✅ Returns
- [ ] Process return
- [ ] Verify stock restored
- [ ] Verify sale/invoice updated

### ✅ Users
- [ ] Create user
- [ ] Edit user
- [ ] Delete user
- [ ] Test permissions

### ✅ Network Connectivity (UPDATED)
- [ ] Turn off WiFi/Data - verify offline placeholder appears
- [ ] Check English error messages displayed
- [ ] Click "Try Again" button to retry
- [ ] Turn on WiFi/Data - verify online notification
- [ ] Verify user returns to same page
- [ ] Test connection tips dialog (in English)

### ✅ API Error Handling (NEW)
- [ ] Stop backend server - verify user-friendly error shown
- [ ] Check error message is in Swahili (not "Bad Gateway" or "502")
- [ ] Verify timeout errors show after 30 seconds
- [ ] Test POST request when server is down
- [ ] Check error snackbar appears with icon
- [ ] Verify "Jaribu Tena" (retry) option available
- [ ] Test various API errors (404, 500, 503)

## Default Login

- **Username:** `masanja`
- **Password:** `Password123!`

## Key Features

### Bidirectional Sync
When discount applied to invoice:
1. Invoice updates ✅
2. Sale updates automatically ✅
3. Data stays consistent ✅

### Stock Management
- Sales reduce stock (via Products service)
- Returns restore stock
- Purchases increase stock
- All managed by backend

## Troubleshooting

### Connection Issues
```dart
// Android emulator use:
baseUrl = 'http://10.0.2.2:8080';

// iOS simulator/Physical device:
baseUrl = 'http://YOUR_IP:8080';
```

### Network Status
The app automatically monitors network connectivity:
- **Offline**: Shows user-friendly placeholder with retry button
- **Online**: Notification when connection restored, returns to active page
- **Messages**: All in English for clarity

### API Errors
The app handles all API errors gracefully:
- **Timeout**: Shows after 30 seconds with retry option
- **Server Down (502/503/504)**: Clear message that server is unavailable
- **Network Errors**: Explains connection issues in Swahili
- **No Technical Jargon**: Users see friendly messages, not "Bad Gateway" or status codes

### Build Issues
```bash
flutter clean
flutter pub get
flutter run
```

## Build Production

```bash
# Android
flutter build apk --release

# iOS  
flutter build ios --release

# Web
flutter build web --release
```

## Documentation

- Backend API: `../sales-gateway/README.md`
- Testing: `./check_app_features.sh`

## Recent Updates (2025-11-14)

### Login Flow Fix
- **Login Error Handling**: Fixed issue where invalid credentials caused "Preparing app..." screen
  - `AuthFailure` state now properly handled in app.dart
  - User stays on login screen to correct credentials
  - Removed redundant navigation from login_screen.dart
  - Error messages show immediately on login screen

### Compilation Fixes
- **Flutter**: Fixed const constructor issues in SalesEvent
  - `LoadSales` and `ResetCart` now have const constructors
  - Updated all usages to use `const` keyword
- **TypeScript**: Fixed variable scope issue in sales-service processReturn function
  - Backend ready for deployment

### Latest Frontend Improvements
- **Error Handling**: Created generic error placeholder widget for all features
  - User-friendly messages instead of technical errors
  - Consistent error UI across all screens
  - Retry functionality for network issues

### Backend Fixes
- **Invoice Payment Adjustment**: Automatic payment adjustment when discount or return is processed
  - Bidirectional communication between sales and invoices services working correctly

### Frontend Updates
- **Products Screen**: Category/Unit buttons with labels, Sort/Filter as icons
- **Login Flow**: Fast and simple - stays on screen for errors, direct navigation on success
- **Error States**: Generic placeholder for timeouts, network errors, server errors

### Bug Fixes & Enhancements
1. **Login UX**: Invalid credentials no longer cause stuck "Preparing app..." screen
2. **Error UX**: User-friendly error messages, no technical details exposed
3. **Idle Timeout Handling**: Generic error placeholder when API becomes unreachable
4. **Invoice-Sales Communication**: Full bidirectional sync
5. **Payment Adjustment**: Automatic recalculation on discount/return
6. **View Toggle**: Working List/Grid view
7. **Session Expiry**: Auto-logout on 401

### Technical Changes (Backend)
- sales-service: Fixed TypeScript compilation error in processReturn
- invoices-service: Payment adjustment logic
- invoices-service: POST /invoices/adjust-for-return endpoint
- sales-service: Return notifications to invoices

### Technical Changes (Frontend)
- app.dart: Added AuthFailure state handling, removed redundant navigation
- login_screen.dart: Removed redundant BlocListener for navigation
- sales_event.dart: Added const constructors to LoadSales and ResetCart
- Updated all event dispatches to use const
- Created `widgets/error_placeholder.dart` for consistent error UI
- Updated products_screen, sales_screen to use ErrorPlaceholder
- Generic error handling with retry functionality

## License

Private - All Rights Reserved

## Splash Screen & Weather Features

### Splash Screen
The app now features a beautiful animated splash screen with:
- **Time-based greetings**: "Good Morning", "Good Afternoon", "Good Evening", or "Good Night"
- **Weather display**: Shows current location and temperature
- **Smooth animations**: Fade-in, scale, and slide effects
- **Modern UI**: Gradient background with professional design
- **Duration**: 4 seconds before showing main app

### Weather Integration
- **Current weather**: Displayed on splash screen
- **7-day forecast**: Widget on dashboard showing weather for the week
- **Location-aware**: Uses GPS to detect user's location and city
- **Weather icons**: Clear (☀️), Cloudy (☁️), Rainy (🌧️), Thunderstorm (⛈️), etc.
- **Temperature**: Shows in Celsius
- **Refresh option**: Manual refresh button on weather widget

### Permissions Required
- **Location**: For detecting user's city and weather
  - Android: Automatically requested
  - iOS: Add to Info.plist (if testing on iOS)

