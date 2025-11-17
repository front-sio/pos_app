# Sales Management Flutter App

A comprehensive Point of Sale (POS) and Sales Management System built with Flutter. This mobile/desktop application provides a complete interface for managing sales, inventory, customers, and business operations.

## Recent Updates (Nov 17, 2025)

### Web Connection Reset Fix (Nov 17, 2025)
- ✅ **Fixed Connection Reset Error** - Web app no longer shows "connection was reset" errors
- ✅ **PWA Build Flag Added** - Dockerfile and vercel_build.sh now use `--pwa-strategy=none`
- ✅ **Service Worker Disabled** - Ensures service worker is not loaded, preventing conflicts
- ✅ **Consistent Build Process** - All build scripts now properly disable PWA features

**Problem Fixed:**
Users visiting the web application were seeing "connection was reset" or "something went wrong while displaying this web page" errors. This was caused by a service worker being generated during the build process, even though PWA features were documented as removed on Nov 15, 2025.

**Solution:**
Added the `--pwa-strategy=none` flag to both the Dockerfile and vercel_build.sh build scripts. This ensures that:
- No service worker is generated (flutter_service_worker.js will be empty)
- No PWA features are included in the build
- The web app runs as a standard web application without offline caching

**Rebuild Required:**
After pulling this fix, the application must be rebuilt using either:
```bash
# Using Docker
docker build -t pos_app:latest .

# Or using the Vercel build script
./vercel_build.sh
```

### Product Cart Refresh Fix (Nov 17, 2025)
- ✅ **Fixed Product Visibility in Cart** - New products now appear immediately in cart selector
- ✅ **Removed Conditional Loading** - Cart screen now always refreshes product list on entry
- ✅ **No Login Required** - Products created immediately visible without logout/login cycle

**Problem Fixed:**
When creating a new product and immediately going to sale → new sale → add item, the new product was not visible in the cart's product selector until logout/login. This was because the cart screen only loaded products if they weren't already loaded, so newly created products weren't fetched.

**Solution:**
Modified `_loadProducts()` in `product_cart_screen.dart` to always call `FetchProducts()` when the cart screen initializes, ensuring the latest products are always available.

### Email Templates & Reset Password (Nov 15, 2025)
- ✅ **Simplified Email Templates** - Clean table-based layouts that render properly in all email clients
- ✅ **Reset Password Deep Links FIXED** - Email links now properly route to reset password page
- ✅ **Skip Splash for Reset Links** - App detects reset links and bypasses splash screen
- ✅ **Initial Route Handling** - App correctly handles /reset-password?token=xxx URLs on page load
- ✅ **Beautiful Welcome Emails** - Simple, professional design with credentials clearly displayed
- ✅ **Mobile-Responsive Emails** - Table-based layouts work on all devices and email clients
- ✅ **Invoice PDF Attachments** - Invoices automatically sent as PDF attachments via email
- ✅ **Auto-resend on Changes** - Invoice emails resent when payment/discount applied

**Email Improvements:**
- Removed CSS that breaks in some email clients (gradients, transforms, complex selectors)
- Using inline styles and table-based layouts for maximum compatibility
- Clear credential display with code formatting
- Prominent call-to-action buttons
- Clean, professional design that works everywhere

**Reset Password Fix (CRITICAL):**
- ✅ Detects reset-password URL on app initialization
- ✅ Skips splash screen if reset link detected
- ✅ Sets `initialRoute` parameter correctly
- ✅ Removes `home` widget when `initialRoute` is set (they conflict!)
- ✅ Users clicking email links now land directly on reset password page
- ✅ No more redirect to login screen on initial link click
- ✅ **After successful password reset, properly redirects to login page**
- ✅ Uses `MaterialPageRoute` instead of named routes for reliability
- ✅ Shows success message with "Redirecting to login page..." notification

**Invoice PDF Email Attachments (IMPLEMENTED):**
- ✅ **Professional billing-style email format** - Clear, direct communication
- ✅ **Fast PDF generation** - Simplified template for quick delivery
- ✅ **Automatic on sale completion** - PDF generated and emailed immediately
- ✅ Backend timeout increased to 30s (from 10s) for large invoices
- ✅ **Email format like professional billing services:**
  - Header: "[Company Name] - Billing Team"
  - Clear greeting with customer name
  - Invoice details in highlighted box (Number, Date, Status, Amount)
  - **"📎 INVOICE PDF ATTACHED"** notice in green box
  - Payment instructions (for unpaid invoices)
  - Professional footer with company info
- ✅ **PDF attachment** (invoice-{id}.pdf) with complete line items
- ✅ Customer can download PDF for printing/records
- ✅ Subject line indicates status: "Invoice #123" or "Invoice #123 - PAID"
- ✅ Different messages for paid/unpaid invoices
- ✅ Sent automatically on: invoice creation, payment, discount
- ✅ Graceful fallback if PDF generation fails

### Enhanced RBAC & User Management (Nov 15, 2025)
- ✅ **Role-Based Permission Assignment** - Assign permissions to roles dynamically
- ✅ **Create Permissions from UI** - Users with manager/superuser can create new permissions
- ✅ **Assign Roles to Users** - Manager can assign roles to users
- ✅ **Role Management UI** - View roles with expandable permission lists
- ✅ **Permission Management** - Assign/revoke permissions from roles
- ✅ **User Registration Email** - Users created by manager receive welcome email with reset link
- ✅ **Password Reset for All Users** - Users registered from UI can reset password via email
- ✅ **Invoice Email Notifications** - Customers receive invoice emails automatically
- ✅ **Manual Invoice Email** - Send invoice emails manually via API endpoint
- ✅ **Delete Operations (Manager/Superuser):**
  - Delete invoices (DELETE /invoices/:id) - **Frontend: deleteInvoice()**
  - Delete sales (DELETE /sales/:id) - **Frontend: deleteSale()**
  - Deactivate users (DELETE /auth/users/:id/deactivate) - **Frontend: deactivateUser()**
  - Delete users permanently (DELETE /auth/users/:id) - **Frontend: deleteUser()**
  - Delete roles (DELETE /auth/roles/:id) - **Frontend: deleteRole()**
  - Delete permissions (DELETE /auth/permissions/:id) - **Frontend: deletePermission()**
- ✅ **Edit Operations (Manager/Superuser):**
  - Edit roles (PUT /auth/roles/:id) - **Frontend: updateRole()**
  - Edit permissions (PUT /auth/permissions/:id) - **Frontend: updatePermission()**
  - Update invoices (PUT /invoices/:id)
- ✅ **Permission-based access control** - All operations require proper permissions
- ✅ **Frontend API Services Updated:**
  - InvoiceService: Added deleteInvoice()
  - SalesService: Added deleteSale()
  - UsersApiService: Added deactivateUser(), deleteUser(), deleteRole(), deletePermission(), updateRole(), updatePermission()
- ✅ **UI Delete Buttons Added:**
  - **Invoices Screen**: Delete button appears on hover for each invoice card
  - **Sales Screen**: Delete button visible on each sale card
  - **Confirmation dialogs** with clear warnings before deletion
  - **Success/error notifications** after delete operations
  - **Auto-refresh** of lists after successful deletion

**Features:**
- Manager and superuser roles can create roles and permissions
- Assign multiple permissions to roles with visual UI
- Users receive email with temporary credentials and password reset link
- Password reset works for both self-registered and manager-created users
- Invoice emails sent automatically when invoice is created
- Manual invoice email sending available via `/invoices/:id/send-email` endpoint

**User Management:**
- View Users, Roles, and Permissions in separate tabs
- Create users with role assignment
- Resend password reset links for any user
- Assign/revoke roles from users
- Expandable role cards showing assigned permissions
- Easy permission assignment/revocation with visual feedback
- **Detailed success messages showing email status and recipient**
- **UI shows whether email was sent or logged to console**

**Email Features:**
- Welcome emails with initial credentials for new users
- Password reset links with expiration
- Invoice emails with formatted HTML templates
- Customer invoice notifications on creation
- SMTP configuration via environment variables
- **Beautiful, responsive HTML email templates with gradients and modern design**
- Client host URL automatically detected for correct reset links

**📧 Email Configuration (Optional):**

Email features are **optional** and work without configuration. If SMTP is not configured:
- The system logs credentials and reset tokens to the console
- All other features continue to work normally
- Users can still be created and managed

**Default Password for Manager-Created Users:**
- Users created by managers get a default password: `Welcome@123` (configurable)
- The default password is sent to the user's email (or logged to console if email not configured)
- Users must change this password on first login via the reset link
- Configure via `DEFAULT_USER_PASSWORD` in `.env`

To enable email functionality, add these variables to your `.env` files:

**For auth-service** (`sales-gateway/auth-service/.env`):
```bash
# Email Configuration (Optional)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=your-email@gmail.com
SMTP_PASS=your-app-password
FROM_EMAIL=noreply@yourdomain.com
APP_NAME=Sales Management System
RESET_PASSWORD_URL=http://localhost:33117/reset-password
RESET_TOKEN_TTL_HOURS=24

# Default password for users created by manager
DEFAULT_USER_PASSWORD=Welcome@123
```

**For invoices-service** (`sales-gateway/invoices-service/.env`):
```bash
# Email Configuration (Optional)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=your-email@gmail.com
SMTP_PASS=your-app-password
FROM_EMAIL=noreply@yourdomain.com
APP_NAME=Sales Management System
CUSTOMERS_SERVICE_URL=http://localhost:3019
```

**Note:** For Gmail, use an [App Password](https://support.google.com/accounts/answer/185833) instead of your regular password.

### PWA Features Removed (Nov 15, 2025)
- ✅ **Removed PWA/Service Worker** - Disabled all Progressive Web App features
- ✅ **No Service Worker Registration** - App runs as standard web app
- ✅ **No Manifest.json** - Removed PWA manifest reference
- ✅ **Cleaner Web App** - Simplified web deployment without PWA overhead
- ✅ **No Install Prompts** - No more "Add to Home Screen" prompts
- ✅ **No Offline Caching** - Service worker caching disabled
- ✅ **Fixed Configuration Error** - Removed deprecated `window.flutterConfiguration`

**Changes:**
- Removed `manifest.json` link from `web/index.html`
- Used `--pwa-strategy=none` flag during Flutter build
- Removed deprecated `window.flutterConfiguration` approach
- Flutter bootstrap now loads without service worker settings
- Empty service worker file generated (0 bytes)
- App now runs as regular web application
- No PWA features or offline capabilities

**Web Performance:**
- Faster initial load (no service worker registration)
- No caching overhead
- Simpler deployment and updates
- No service worker conflicts
- No deprecated configuration warnings

### Service Worker Bootstrap Error Fix (Nov 15, 2025)
- ✅ **Fixed flutter_bootstrap.js Async Error** - Removed duplicate service worker registration
- ✅ **Single Service Worker Registration** - Flutter bootstrap handles SW automatically
- ✅ **Cleaner Error Handling** - Eliminated async timeout errors in bootstrap
- ℹ️ **PWA Features Removed** - Service worker completely disabled (see PWA section above)

**Changes:**
- **PWA completely disabled** - Used `--pwa-strategy=none` build flag
- Removed `manifest.json` link from index.html
- Removed deprecated `window.flutterConfiguration` usage
- App runs as standard web app without offline capabilities
- Flutter bootstrap loads without service worker settings
- Empty service worker file (0 bytes)
- Split connectivity service into web/mobile platform-specific modules
- Added 3-second timeout for weather data loading on splash screen
- All `dart:html` imports moved to conditional platform-specific files

**Web Performance:**
- No PWA overhead or caching
- Faster initial load without service worker
- No deprecated configuration errors
- No service worker conflicts
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

## Socket.IO Connection Errors - UPDATED ✅

### Problem
The Flutter app was showing Socket.IO connection errors:
```
[NotificationSocket] connect_error: {msg: websocket error, desc: null, type: TransportError}
[RealtimeProducts] connect_error: {msg: websocket error, desc: null, type: TransportError}
```

### Root Cause
1. **Notifications Service Not Running** - The notifications-service must be started manually
2. **Gateway/Nginx Proxy** - The app connects via `https://app.stebofarm.co.tz` which requires proper routing
3. **Missing Service Startup** - Notifications service needs to be started before app can connect

### Solution

#### 1. **Start Notifications Service**
```bash
# Navigate to notifications service directory
cd sales-gateway/notifications-service

# Start the service
node dist/index.js &

# Or use nohup for persistent running
nohup node dist/index.js > /tmp/notifications.log 2>&1 &

# Verify it's running
curl http://localhost:3022/health
# Should return: "Notifications Service is healthy"
```

#### 2. **Check Service Status**
```bash
# Check if service is running
ps aux | grep "node.*3022"

# Test Socket.IO endpoint directly
curl "http://localhost:3022/socket.io-notifications/?EIO=4&transport=polling"
# Should return: 0{"sid":"...","upgrades":["websocket"],...}
```

#### 3. **Frontend Error Handling**
- ✅ **Limited error logging** - Only shows first 3 connection errors
- ✅ **Auto-retry with backoff** - Retries 3 times with 2-5 second delays
- ✅ **Graceful degradation** - App works without notifications if service unavailable
- ✅ **Clean console** - No spam after max errors reached

### What Was Fixed (Nov 15, 2025)

#### 1. **Frontend Error Handling**
- Limited error logging to first 3 attempts
- Increased timeout to 20 seconds
- Reduced reconnection attempts to 3 (prevents spam)
- Added error counter to suppress repeated logs
- Better reconnection delays (2-5 seconds backoff)

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

### Network Connectivity Features (REAL-TIME FIX - Nov 14, 2025)
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

