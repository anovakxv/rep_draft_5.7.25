# Deep Linking Setup Guide

This guide explains how to complete the Universal Links (Deep Linking) setup for the Rep iOS app.

## ✅ Part 1: iOS App Changes (COMPLETE)

The following changes have been made to the iOS app:

### Files Modified:
1. **RepApp.swift**
   - Added `.onOpenURL` handler to capture Universal Links
   - Added `handleUniversalLink()` function to parse URLs
   - Posts notifications for Portal and Goal deep links

2. **MainScreen.swift**
   - Added state variables for deep link navigation
   - Added `setupDeepLinkObservers()` to listen for deep link notifications
   - Added `navigationDestination` modifiers to navigate to Portal/Goal pages

### What it does:
- When a user taps `https://www.repsomething.com/portal/123`, the app opens to that Portal
- When a user taps `https://www.repsomething.com/goal/456`, the app opens to that Goal
- If the app is not installed, the URL opens in Safari (the web app)

---

## ⚠️ Part 2: Xcode Configuration (YOU NEED TO DO THIS)

### Step 1: Add Associated Domains Capability

1. Open your Xcode project
2. Select your app target (Rep)
3. Go to "Signing & Capabilities" tab
4. Click "+ Capability"
5. Search for and add "Associated Domains"
6. Under "Associated Domains", click the "+" button
7. Add: `applinks:www.repsomething.com`

**IMPORTANT:** Replace `applinks:www.repsomething.com` with your exact domain. Do NOT include `https://` or trailing slashes.

### Step 2: Find Your Team ID

1. In Xcode, go to your project settings
2. Under "Signing & Capabilities", look for "Team"
3. Your Team ID is a 10-character alphanumeric code (e.g., `AB12CD34EF`)
4. **Copy this Team ID** - you'll need it for the next step

---

## ⚠️ Part 3: Web Server Setup (YOU NEED TO DO THIS)

### Step 1: Update the apple-app-site-association file

1. Open the file: `apple-app-site-association` (in this directory)
2. Replace `TEAM_ID` with your actual Apple Team ID from Xcode
   - Find this line: `"appID": "TEAM_ID.com.rep.RepApp"`
   - Replace `TEAM_ID` with your actual Team ID
   - Example: `"appID": "AB12CD34EF.com.rep.RepApp"`

### Step 2: Add to Vercel Web App

You need to add the `apple-app-site-association` file to your Vercel deployment so it's accessible at:

```
https://www.repsomething.com/.well-known/apple-app-site-association
```

**For a Vue/Vite Web App on Vercel:**

1. In your web app directory (`web-app/`), create a `public` folder if it doesn't exist
2. Inside `public`, create a `.well-known` folder
3. Copy `apple-app-site-association` into `public/.well-known/`
4. Your structure should be:
   ```
   web-app/
   ├── public/
   │   └── .well-known/
   │       └── apple-app-site-association
   ├── src/
   ├── package.json
   └── ...
   ```

5. Commit and push to your repository
6. Vercel will automatically deploy the file
7. Verify it's accessible: https://www.repsomething.com/.well-known/apple-app-site-association

**Requirements:**
- File must be accessible at the EXACT URL above
- File must be served with `Content-Type: application/json` (Vercel handles this automatically)
- File must NOT have a `.json` extension - keep it as `apple-app-site-association` (no extension)
- File must be accessible via HTTPS (Vercel provides this automatically)

### Step 3: Verify the Setup

After uploading, test the file is accessible:

1. Open a browser and go to: `https://www.repsomething.com/.well-known/apple-app-site-association`
2. You should see the JSON content
3. Use Apple's validator: https://search.developer.apple.com/appsearch-validation-tool/
   - Enter: `https://www.repsomething.com`
   - It should show your app is associated

---

## 🧪 Testing Deep Links

### Testing on a Real Device (After completing all steps above):

1. Build and install the app on your iPhone
2. Send yourself a link via Messages or Email:
   - `https://www.repsomething.com/portal/123` (replace 123 with a real portal ID)
   - `https://www.repsomething.com/goal/456` (replace 456 with a real goal ID)
3. Tap the link - it should open directly in the Rep app!

### Testing on Simulator:

Universal Links don't work reliably in the iOS Simulator. Always test on a real device.

### Debugging:

If the link opens in Safari instead of your app:
1. Verify the `apple-app-site-association` file is accessible
2. Check that your Team ID is correct in the file
3. Ensure "Associated Domains" capability is added in Xcode
4. Try uninstalling and reinstalling the app
5. Check that the domain exactly matches (www.repsomething.com vs repsomething.com)

---

## 📱 Share Feature (Already Working)

The Share functionality is already complete and working:
- Portal pages have a "Share" button in the menu
- Goal pages have a "Share" button in the action sheet
- These generate URLs like `https://www.repsomething.com/portal/123`
- Once deep linking is fully configured, these shared links will open the app!

---

## ⚠️ IMPORTANT: Bundle Identifier

The code assumes your bundle identifier is: `com.rep.RepApp`

If it's different, you'll need to update the `appID` in `apple-app-site-association`:
- Format: `TEAM_ID.YOUR_BUNDLE_ID`
- Example: `AB12CD34EF.com.yourcompany.YourApp`

To find your bundle identifier:
1. Open Xcode
2. Select your target
3. Go to "General" tab
4. Look for "Bundle Identifier"

---

## Need Help?

If you run into issues:
1. Double-check your Team ID
2. Verify the file is accessible at the .well-known URL
3. Make sure Associated Domains capability is added in Xcode
4. Test on a real device (not simulator)
