# User Photos: Upload + World-Class Viewer

## Scope
- Backend: Add 2 new endpoints (upload via FormData, single delete)
- Frontend: Rewrite UserPhotos.vue as a polished photo gallery with upload
- NO likes/reactions/comments UI (backend is ready for when we want it later)

---

## Step 1: Backend — Add `POST /photos/upload` endpoint

**File:** `UserPhotos.py`

Add a new FormData upload endpoint that:
1. Accepts `photo` file + optional `caption` form field
2. Validates file type (png, jpg, jpeg, gif, webp)
3. Uploads to S3 via `boto3.upload_fileobj()` (same pattern as Portal_Details.py)
4. Creates S3Content record (tbl_index=7 for user photos)
5. Creates UserPhoto record with next position
6. Returns the new photo dict with full S3 URL

Follows exact Portal_Details.py pattern: boto3 client, S3_BUCKET, uuid filename, S3Content creation.

## Step 2: Backend — Add `DELETE /photos/<int:photo_id>` endpoint

**File:** `UserPhotos.py`

Add a single-photo delete by URL param (needed because `api.delete()` in frontend doesn't send request bodies). Owner-only permission check.

## Step 3: Frontend — Rewrite `UserPhotos.vue`

**File:** `web-app/src/pages/RepProfile/UserPhotos.vue`

Convert from render functions to template syntax. Build a polished, Instagram-style photo gallery:

**Header:**
- Back button (left), title "Photos" (center), camera/add icon (right, own profile only)

**Empty State (own profile):**
- Elegant prompt to add first photo with camera icon

**Photo Grid/Feed:**
- Clean card layout, each photo as a full-width image with caption underneath
- Subtle shadow, rounded corners, smooth spacing
- Tap photo to open fullscreen viewer

**Upload Flow:**
- Tap camera icon → file picker (accept images only)
- Show preview in a modal with optional caption input
- Upload button with loading spinner
- On success: prepend new photo to feed

**Delete Flow (own profile only):**
- Trash icon overlay on each photo (subtle, top-right corner)
- Confirmation dialog before delete
- Smooth removal animation

**Fullscreen Viewer (the showpiece):**
- Black background, photo fills screen
- Swipe left/right to navigate (touch + mouse drag)
- Photo counter "1 / 5" at top
- Close button (X) top-right
- Smooth transitions between photos
- Pinch-to-zoom support via CSS `touch-action`
- Caption overlay at bottom (semi-transparent)
- Keyboard navigation (arrow keys, Escape to close)

**Owner vs. Viewer:**
- `isCurrentUser` computed from `localStorage.getItem('userId')` vs route param (matches ProfileView.vue pattern)
- Upload button and delete buttons only shown for owner
- Viewers see a clean, distraction-free gallery

## Step 4: Verify Integration

- Ensure the route `/profile/:id/photos` still works
- Clicking profile picture on ProfileView navigates to photos page
- Upload → view → delete cycle works end-to-end
