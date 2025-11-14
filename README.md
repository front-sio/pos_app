# Sales Management Flutter App

A comprehensive Point of Sale (POS) and Sales Management System built with Flutter. This mobile/desktop application provides a complete interface for managing sales, inventory, customers, and business operations.

## Recent Updates (Nov 14, 2025)

### Invoice Discount Fix (NEW)
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

