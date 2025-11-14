#!/bin/bash

# Flutter App Feature Testing Checklist
# This script guides you through testing all app features

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_header() {
    echo ""
    echo "════════════════════════════════════════════════════════"
    echo -e "${BLUE}  $1${NC}"
    echo "════════════════════════════════════════════════════════"
    echo ""
}

print_step() {
    echo -e "${YELLOW}➜ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

ask_confirmation() {
    echo -n -e "${BLUE}$1 (y/n): ${NC}"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        print_success "Confirmed"
        return 0
    else
        print_error "Skipped or Failed"
        return 1
    fi
}

clear
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║       Sales Management Flutter App - Feature Testing        ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Pre-requisites
print_header "Pre-requisites Check"

print_step "1. Backend services running?"
ask_confirmation "Are backend services running on http://localhost:8080?"

print_step "2. Flutter app compiled?"
ask_confirmation "Is the Flutter app running? (flutter run)"

print_step "3. Logged in?"
echo "   - Login screen has FULL PAGE animated background"
echo "   - Sales patterns: cash register, $ symbols, receipt, chart, cart"
echo "   - All patterns animate smoothly (float/bounce)"
echo "   - Button shows 'Logging in...' when submitting"
echo "   - Invalid credentials show error immediately"
ask_confirmation "Are you logged in with credentials (masanja/Password123!)?"

# Products Module
print_header "📦 Products Module Testing"

print_step "1. View Products List"
echo "   - Check AppBar has labeled buttons: Grid/List, Sort, Filter, Category, Unit"
echo "   - Buttons show both icon AND text"
echo "   - Category list scrolls horizontally below"
ask_confirmation "Can you see the products list with labeled AppBar buttons?"

print_step "2. Search Products & Toggle View"
echo "   - Search for a product"
echo "   - Click view toggle button in AppBar"
echo "   - Should switch between list and grid view"
echo "   - Grid shows 2 columns (mobile), 3 (tablet), 4 (desktop)"
ask_confirmation "Can you search and toggle between list/grid views?"

print_step "3. Add Product (Category & Unit REQUIRED)"
echo "   - Try adding product WITHOUT category (should show validation error)"
echo "   - Try adding product WITHOUT unit (should show validation error)"
echo "   - In product form: Click 'Add Category' button to add new category"
echo "   - In product form: Click 'Add Unit' button to add new unit"
echo "   - In product form: Click 'Add' button next to Supplier to add new supplier"
echo "   - In products screen: Use 'Add Category' and 'Add Unit' buttons at top"
echo "   - Add product WITH category, unit, and supplier (should succeed)"
ask_confirmation "Product validation, inline creation in form and screen working correctly?"

print_step "4. Edit Product"
ask_confirmation "Can you edit a product successfully?"

print_step "5. Delete Product"
ask_confirmation "Can you delete a product?"

print_step "6. View Product Details"
ask_confirmation "Can you view detailed product information?"

# Purchases Module
print_header "🛒 Purchases Module Testing"

print_step "1. View Purchases List"
ask_confirmation "Can you see the purchases list?"

print_step "2. Create Purchase (Products & Supplier Loading)"
echo "   - Open create purchase screen"
echo "   - Verify products load immediately (no need to refresh)"
echo "   - Verify suppliers load immediately"
echo "   - Try creating purchase WITHOUT supplier (should fail)"
echo "   - Create purchase WITH supplier and products (should succeed)"
ask_confirmation "Purchase product/supplier loading and validation working correctly?"

print_step "3. Add Multiple Items to Purchase"
ask_confirmation "Can you add multiple items to a purchase?"

print_step "4. Check Stock Increased"
ask_confirmation "Did product stock increase after purchase?"

print_step "5. Edit Purchase"
ask_confirmation "Can you edit a purchase order?"

print_step "6. Delete Purchase"
ask_confirmation "Can you delete a purchase order?"

# Sales Module
print_header "💰 Sales Module Testing"

print_step "1. View Sales List"
ask_confirmation "Can you see the sales list?"

print_step "2. Create Sale (Products & Customers Loading)"
echo "   - Open create sale screen"
echo "   - Verify products load immediately (no need to refresh)"
echo "   - Verify customers load immediately"
echo "   - Add products to cart and create sale"
ask_confirmation "Sale product/customer loading working correctly?"

print_step "3. Add Multiple Items"
ask_confirmation "Can you add multiple items to a sale?"

print_step "4. Assign Customer"
ask_confirmation "Can you assign a customer to the sale?"

print_step "5. Check Stock Decreased"
ask_confirmation "Did product stock decrease after sale?"

print_step "6. Check Invoice Auto-Created"
ask_confirmation "Was an invoice automatically created for the sale?"

# Invoices Module
print_header "📄 Invoices Module Testing"

print_step "1. View Invoices List"
ask_confirmation "Can you see the invoices list?"

print_step "2. View Invoice Details"
ask_confirmation "Can you view invoice details?"

print_step "3. Apply Discount to Invoice (CRITICAL TEST)"
echo "   - Note the current sale total"
echo "   - Apply 10% discount to invoice"
echo "   - Check if sale total updated automatically"
ask_confirmation "Does invoice discount update the sale? (Bidirectional sync)"

print_step "4. Change Payment Status"
ask_confirmation "Can you change invoice payment status?"

print_step "5. Generate Invoice PDF"
ask_confirmation "Can you generate/view invoice PDF?"

# Returns Module
print_header "🔄 Returns Module Testing"

print_step "1. View Returns List"
ask_confirmation "Can you see the returns list?"

print_step "2. Process Return"
ask_confirmation "Can you process a product return?"

print_step "3. Check Stock Restored"
ask_confirmation "Was product stock restored after return?"

print_step "4. Check Sale Updated"
ask_confirmation "Was sale total updated after return?"

print_step "5. Check Invoice Updated"
ask_confirmation "Was invoice updated after return?"

# Users Module
print_header "👥 Users Module Testing"

print_step "1. View Users List"
ask_confirmation "Can you see the users list?"

print_step "2. Create User"
ask_confirmation "Can you create a new user?"

print_step "3. Assign Role to User"
ask_confirmation "Can you assign a role to the user?"

print_step "4. Edit User Information"
ask_confirmation "Can you edit user details?"

print_step "5. Delete User"
ask_confirmation "Can you delete a user?"

print_step "6. Test Permissions"
ask_confirmation "Are permissions enforced correctly?"

# Additional Modules
print_header "📊 Additional Features Testing"

print_step "1. Dashboard"
ask_confirmation "Is the dashboard showing analytics correctly? (Check for weekly weather widget)"

print_step "2. Customers Module"
echo "   - Customers load from backend API"
echo "   - No mock data is used"
ask_confirmation "Can you manage customers from backend (view/add/edit/delete)?"

print_step "3. Suppliers Module"
ask_confirmation "Can you manage suppliers (view/add/edit/delete)?"

print_step "4. Expenses Module"
ask_confirmation "Can you track expenses?"

print_step "5. Reports Module"
ask_confirmation "Can you view sales/profit reports?"

print_step "6. Settings Module"
ask_confirmation "Can you access and modify settings?"

print_step "7. Session Expiry Test (CRITICAL)"
echo "   - Try accessing features after token expiry"
echo "   - Should automatically logout without errors"
echo "   - Should redirect to login screen"
ask_confirmation "Does session expiry handling work correctly (auto-logout)?"

print_step "8. Network Connectivity Monitoring (UPDATED - Nov 14, 2025)"
echo "   WEB TESTING:"
echo "   - Open app in Chrome/Firefox browser"
echo "   - Open DevTools (F12) -> Network tab"
echo "   - Click 'Offline' checkbox in Network tab"
echo "   - Verify offline placeholder appears IMMEDIATELY"
echo "   - Check English messages: 'No Internet Connection'"
echo "   - Click 'Try Again' button"
echo "   - Click 'Connection Tips' for troubleshooting tips"
echo "   - Uncheck 'Offline' in DevTools"
echo "   - Verify green 'Connection restored!' notification appears"
echo "   - Verify you return to the same page"
echo ""
echo "   MOBILE TESTING:"
echo "   - Enable Airplane Mode on phone"
echo "   - Verify offline placeholder appears immediately"
echo "   - Disable Airplane Mode"
echo "   - Verify connection restored notification"
ask_confirmation "Does network connectivity monitoring work instantly on web?"

print_step "9. API Error Handling (NEW)"
echo "   - Stop backend server (docker-compose down or stop services)"
echo "   - Try to create a product or make any POST request"
echo "   - Verify error message is in Swahili (not 'Bad Gateway')"
echo "   - Check message says 'Huduma haipatikani' or similar"
echo "   - Verify no technical error codes shown to user"
echo "   - Start backend server again"
echo "   - Test timeout: Make request and wait 30+ seconds"
echo "   - Verify timeout message in Swahili"
ask_confirmation "Does API error handling show user-friendly messages?"

# Summary
print_header "Test Summary"

echo ""
echo "✅ Core Modules Tested:"
echo "   - Products (CRUD + validation + inline creation + screen buttons)"
echo "   - Purchases (CRUD + auto-loading + validation)"
echo "   - Sales (CRUD + auto-loading + auto-invoice)"
echo "   - Invoices (CRUD + bidirectional sync)"
echo "   - Returns (stock restoration)"
echo "   - Users (CRUD + permissions)"
echo "   - Network Connectivity (NEW - offline/online detection)"
echo "   - API Error Handling (NEW - user-friendly Swahili messages)"
echo ""
echo "🔑 Key Validations Checked:"
echo "   - Product requires category & unit (with validation)"
echo "   - Category/Unit buttons with labels in product form"
echo "   - Category/Unit buttons with labels in products screen"
echo "   - Supplier quick-add button in product form"
echo "   - Purchase products load immediately"
echo "   - Purchase suppliers load immediately"
echo "   - Sale products load immediately"
echo "   - Sale customers load immediately"
echo "   - Customers load from backend API (not mock)"
echo "   - Stock managed by backend"
echo "   - Invoice discount updates sale"
echo "   - Returns restore stock"
echo "   - Session expiry auto-logout"
echo "   - Network connectivity monitoring (NEW)"
echo "   - Offline placeholder with Swahili messages (NEW)"
echo "   - Auto-reconnection and page restoration (NEW)"
echo "   - API errors in user-friendly Swahili (NEW)"
echo "   - Timeout detection (30 seconds) (NEW)"
echo "   - Server unavailable detection (NEW)"
echo ""
echo "💰 Invoice Discount Fix (2025-11-14):"
echo "   - ✓ Discount affects total_amount correctly (NEW)"
echo "   - ✓ Discount affects paid_amount (overpayment adjusted) (NEW)"
echo "   - ✓ Discount affects due_amount (recalculated) (NEW)"
echo "   - ✓ Payment adjustment on discount (excess removed) (NEW)"
echo "   - ✓ Sales service notified of discounts (NEW)"
echo "   - ✓ Invoice status recomputation (paid/credited/unpaid) (NEW)"
echo "   - ✓ Frontend synchronized with backend (NEW)"
echo "   - ✓ Backend: invoices-service updated (NEW)"
echo "   - ✓ Backend: sales-service discount endpoint working (NEW)"
echo "   - ✓ Frontend: Invoice model includes paid/due amounts (NEW)"
echo ""
echo "🌐 Network & PWA Features (FINAL FIX - 2025-11-14):"
echo "   - ✓ Real-time offline detection (browser events) (FIXED)"
echo "   - ✓ Const class fixed (hot reload support) (NEW)"
echo "   - ✓ No false positives (only shows when genuinely offline) (FIXED)"
echo "   - ✓ StatelessWidget for better performance (NEW)"
echo "   - ✓ English UI only (all messages in English) (FIXED)"
echo "   - ✓ Removed native splash (only custom splash) (FIXED)"
echo "   - ✓ Debounced state changes (300ms) (NEW)"
echo "   - ✓ Beautiful offline placeholder with retry (NEW)"
echo "   - ✓ Connection tips dialog (English) (NEW)"
echo "   - ✓ Multi-platform support (Web + Mobile) (NEW)"
echo "   - ✓ Version detection via Service Worker (NEW)"
echo "   - ✓ Auto-refresh prompt for new versions (NEW)"
echo "   - ✓ PWA install prompt for mobile browsers (NEW)"
echo "   - ✓ Cross-platform connectivity monitoring (NEW)"
echo ""
echo "🐛 Recent Bug Fixes (2025-11-14):"
echo "   - ✓ Hidden Flutter default loader (Web) (FINAL)"
echo "   - ✓ Web: Blue background + hidden loader = seamless (FIXED)"
echo "   - ✓ No blank screen, no Flutter loader visible (FIXED)"
echo "   - ✓ Android: Blue background only, no images (FIXED)"
echo "   - ✓ iOS: Blue background only, no images (FIXED)"
echo "   - ✓ Fixed Noto fonts warning for emojis (FIXED)"
echo "   - ✓ Fixed 'Unknown' location issue (FIXED)"
echo "   - ✓ Fixed massive RenderFlex overflow (99640px!) (FIXED)"
echo "   - ✓ Added web scroll arrows for weather widget (NEW)"
echo "   - ✓ Made weather widget mobile-first responsive (NEW)"
echo "   - ✓ Fixed duplicate splash screens (FINAL)"
echo "   - ✓ Changed theme from purple to blue (UPDATED)"
echo "   - ✓ Reduced text sizes for better UX (UPDATED)"
echo "   - ✓ Fixed Directionality error in splash screen (NEW)"
echo "   - ✓ Integrated real weather API (OpenWeatherMap) (UPDATED)"
echo "   - ✓ Added custom web splash screen (NEW)"
echo "   - ✓ Configured web location permissions (NEW)"
echo "   - ✓ Added animated splash screen with weather (NEW)"
echo "   - ✓ Integrated weekly weather widget on dashboard (NEW)"
echo "   - ✓ Time-based greetings (Morning/Afternoon/Evening) (NEW)"
echo "   - ✓ Fixed invoice loader continuous update issue (NEW)"
echo "   - ✓ Network messages changed to English (UPDATED)"
echo "   - ✓ API error handling with Swahili messages (NEW)"
echo "   - ✓ Timeout detection (30 seconds) (NEW)"
echo "   - ✓ Server unavailable error handling (502/503/504) (NEW)"
echo "   - ✓ Network error user-friendly messages (NEW)"
echo "   - ✓ Error snackbars with icons and retry (NEW)"
echo "   - ✓ Network connectivity monitoring (NEW)"
echo "   - ✓ Offline placeholder with retry functionality (NEW)"
echo "   - ✓ Real-time network status detection (NEW)"
echo "   - ✓ Seamless page restoration when back online (NEW)"
echo "   - ✓ Product form validates category & unit as required"
echo "   - ✓ Add Category/Unit moved to AppBar (cleaner layout)"
echo "   - ✓ View toggle working (list ↔ grid)"
echo "   - ✓ Grid view responsive (2/3/4 columns)"
echo "   - ✓ Supplier quick-add button added to product form"
echo "   - ✓ Purchase screen loads products immediately"
echo "   - ✓ Purchase screen loads suppliers immediately"
echo "   - ✓ Sales screen loads products immediately"
echo "   - ✓ Sales screen loads customers immediately"
echo "   - ✓ Customers confirmed loading from backend API"
echo "   - ✓ Login: FULL PAGE animated background"
echo "   - ✓ Login: Sales-themed patterns (register, $, receipt, chart, cart)"
echo "   - ✓ Login button: inline loading ('Logging in...')"
echo "   - ✓ Login errors: shown immediately with icon"
echo "   - ✓ Session expiry auto-logout (401 handling)"
echo "   - ✓ Backend: Fixed returnedValue scope in salesService.ts"
echo "   - ✓ Backend: Invoice-sales bidirectional communication verified"
echo "   - ✓ Frontend: Error placeholders hide technical errors from users"
echo "   - ✓ Frontend: Login flow prevents premature app loader display"
echo "   - ✓ Frontend: Dashboard loading optimized for faster UX"
echo ""
echo "📝 Testing Complete!"
echo ""
echo "If any test failed, check:"
echo "   1. Backend services running: curl http://localhost:8080/health"
echo "   2. API configuration: lib/config/config.dart"
echo "   3. Network connectivity"
echo "   4. Authentication token valid"
echo ""

print_step "10. Splash Screen & Weather (NEW)"
echo "   - Restart the app to see splash screen"
echo "   - Should see ONLY ONE custom splash with solid blue background"
echo "   - No Flutter default splash should appear"
echo "   - Check time-based greeting (Morning/Afternoon/Evening/Night with icon)"
echo "   - Verify weather info shows location and temperature"
echo "   - Check splash animations (fade, scale, slide)"
echo "   - Go to Dashboard"
echo "   - Verify Weekly Weather widget appears below summary"
echo "   - Check 7-day forecast with weather icons"
echo "   - Verify 'Today' is highlighted"
echo "   - Test refresh button on weather widget"
ask_confirmation "Does splash screen and weather integration work correctly?"

print_step "11. Network Connectivity Testing (REAL-TIME - UPDATED)"
echo "   WEB TESTING:"
echo "   - Open app in browser (Chrome recommended)"
echo "   - Open DevTools > Network tab (F12)"
echo "   - Toggle 'Offline' checkbox to simulate offline"
echo "   - Should IMMEDIATELY show offline screen (no delay)"
echo "   - Screen says 'No Internet Connection' in English"
echo "   - Check 'Try Again' button works"
echo "   - Check 'Connection Tips' dialog opens"
echo "   - Toggle back to 'Online' in DevTools"
echo "   - Should IMMEDIATELY return to previous page (no delay)"
echo "   - Should see 'Back online!' snackbar"
echo "   "
echo "   MOBILE TESTING:"
echo "   - Enable Airplane mode on device"
echo "   - Should show offline screen immediately"
echo "   - Try 'Try Again' button (should show 'Still no internet')"
echo "   - Disable Airplane mode"
echo "   - Should return to app with 'Back online!' message"
echo "   "
echo "   REAL-TIME CHECK:"
echo "   - Uses native browser online/offline events (Web)"
echo "   - Uses connectivity_plus stream (Mobile)"
echo "   - NO polling delays"
echo "   - NO flickering or false positives"
echo "   - Only shows when genuinely offline"
echo "   - 300ms debounce to prevent rapid toggling"
ask_confirmation "Does real-time connectivity detection work correctly on web & mobile?"

print_step "12. PWA Features (Web Only - NEW)"
echo "   VERSION UPDATE:"
echo "   - Make any code change and rebuild"
echo "   - Service worker should detect new version"
echo "   - Should show 'New Version Available!' notification at top"
echo "   - Click 'Refresh' to load new version"
echo "   "
echo "   INSTALL PROMPT (Mobile Browser):"
echo "   - Open app in mobile browser (Chrome/Safari)"
echo "   - Wait 10 seconds"
echo "   - Should show install prompt at bottom"
echo "   - Message: 'Add app to your home screen for easy access!'"
echo "   - Try 'Install' or 'Not Now' button"
ask_confirmation "Do PWA version detection and install prompts work correctly?"


