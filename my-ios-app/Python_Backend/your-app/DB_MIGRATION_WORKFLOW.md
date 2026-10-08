# Rep Database Migration Workflow

**Purpose**: Safe, reliable database migrations for production
**Last Updated**: February 4, 2026
**Status**: ✅ Production-tested and battle-hardened

---

## 🚀 QUICK REFERENCE

**For experienced users - complete workflow in 10 commands:**

```bash
# LOCAL (MUST be in .../Python_Backend/your-app directory!)
cd "C:\Users\Stephanie\Desktop\Git Rep app draft 1\my-ios-app\my-ios-app\Python_Backend\your-app"
flask db migrate -m "Description"
# ⚠️ REVIEW migrations/versions/xxx_*.py - Check server_default values!
flask db upgrade
flask db current  # Note revision ID
git add migrations/ app/
git commit -m "Migration: [description]"
git push origin Adam_July2025

# RENDER (Dashboard → Shell tab)
flask db current  # Verify old version
flask db upgrade  # Apply migration (watch for errors!)
flask db current  # Verify matches local

# TEST IMMEDIATELY: iOS app → Messages + Writes
# IF ISSUES: flask db downgrade -1
```

---

## 📋 COMPLETE WORKFLOW

### Phase 1: Local Development

#### Step 1: Navigate to Correct Directory ⚠️ CRITICAL

```bash
cd "C:\Users\Stephanie\Desktop\Git Rep app draft 1\my-ios-app\my-ios-app\Python_Backend\your-app"

# Verify you're in the right place
ls migrate_run.py  # Should exist
ls migrations/     # Should exist
```

**Why**: Flask-Migrate only works from this directory. Wrong directory = migration chaos.

---

#### Step 2: Install Dependencies (If Needed)

```bash
pip install -r requirements.txt
```

---

#### Step 3: Create Migration

```bash
flask db migrate -m "Add content_format to writes and messaging enhancements"
```

**Output should show:**
```
INFO  [alembic.autogenerate.compare] Detected added column 'writes.content_format'
Generating migrations/versions/abc123_description.py ... done
```

---

#### Step 4: Review Migration File ⚠️ CRITICAL

**Open:** `migrations/versions/abc123_*.py`

**Must check:**
- ✅ Correct table/column names
- ✅ **server_default values for new NOT NULL columns**
- ✅ No destructive operations (DROP without backups)
- ✅ Foreign key constraints
- ✅ Indexes

**Critical Pattern - Always Use server_default:**

```python
# ❌ BAD - Will FAIL on existing data
op.add_column('messages',
    sa.Column('is_deleted', sa.Boolean(), nullable=False))

# ✅ GOOD - Safe for existing data
op.add_column('messages',
    sa.Column('is_deleted', sa.Boolean(), nullable=False, server_default='false'))

# ✅ GOOD - String defaults
op.add_column('writes',
    sa.Column('content_format', sa.String(10), server_default='plain'))

# ✅ GOOD - Nullable columns (no default needed)
op.add_column('messages',
    sa.Column('edited_at', sa.DateTime(), nullable=True))
```

**Why server_default matters:**
- Python `default=` only works for NEW inserts
- `server_default=` applies to EXISTING rows during migration
- Without it, migration FAILS on production with existing data

**Edit the file if needed** - You can manually fix issues before running.

---

#### Step 5: Run Migration Locally

```bash
flask db upgrade
```

**Expected output:**
```
INFO  [alembic.runtime.migration] Running upgrade xyz456 -> abc123, Description
```

**No errors = success**

---

#### Step 6: Verify Version Locally ⚠️ CRITICAL

```bash
flask db current
```

**Expected:**
```
abc123def456 (head)
```

**Write this down** - Production must match this revision ID exactly.

---

#### Step 7: Test Locally

```bash
# Start Flask
flask run

# Test in another terminal/Postman:
# - Create/read/update operations
# - Verify new fields work
# - Verify old functionality still works
```

**If errors occur:** Fix models/routes, then `flask db downgrade -1` and repeat from Step 3.

---

### Phase 2: Version Control

#### Step 8: Update .gitignore (One-Time Setup)

Verify `.gitignore` excludes development files:

```gitignore
# Python cache and local DB
**/__pycache__/
*.pyc
instance/test.db

# Draft/Enhanced files
*_Enhanced.py
*_Enhanced.vue
*_ENHANCED*
*_FIXED*

# Personal settings
.claude/settings.local.json
```

---

#### Step 9: Git Commit and Push

```bash
git status
# Should show: migrations/versions/abc123_*.py + model/route changes

git add migrations/ app/models/ app/routes/ requirements.txt
git commit -m "Add Write and Messaging enhancements

- Add content_format to writes (HTML support)
- Add message reactions, attachments, edit history
- Feature parity for Direct + Group messages
- Backward compatible with iOS app

Migration: abc123_add_messaging_enhancements.py"

git push origin Adam_July2025
```

---

### Phase 3: Production Deployment (Render)

#### Step 10: Optional - Backup Database (Risk-Based)

**When backup is MANDATORY:**
- ❌ Dropping columns or tables
- ❌ Changing column types
- ❌ Complex data transformations

**When backup is OPTIONAL (Low Risk):**
- ✅ Adding nullable columns
- ✅ Adding new tables
- ✅ Adding columns with server_default (today's deployment)

**Backup command (if needed):**
```bash
pg_dump $DATABASE_URL > backup_$(date +%Y%m%d_%H%M%S).sql
```

---

#### Step 11: Deploy to Render

**Auto-deploy:**
- Push triggers deployment automatically
- Watch Render dashboard "Deploy" tab
- Wait for "Live" status

**What to verify in deploy logs:**
```
✓ Installing dependencies...
✓ Successfully installed bleach-6.x.x
✓ Build succeeded
```

**If bleach fails to install:**
- Migration still works (has graceful fallback)
- HTML sanitization will be less secure
- Verify `bleach>=6.0.0` in requirements.txt

---

#### Step 12: Run Migration on Render ⚠️ CRITICAL

**Connect to Render Shell:**
1. Go to Render Dashboard
2. Click your Python backend service
3. Click **"Shell"** tab at top
4. Wait for prompt: `render@srv-xxx:~/project/src/...`

**Run migration commands:**

```bash
# 1. Check current version (should be OLD)
flask db current
# Expected: 2688c1fbf109 (or whatever your old revision is)

# 2. Verify new migration is available
flask db history
# Should show: 2688c1fbf109 -> abc123def456 (head), Your description

# 3. Run migration
flask db upgrade
# Watch for: INFO [alembic.runtime.migration] Running upgrade...
# NO ERRORS = success

# 4. Verify new version (should match local)
flask db current
# Expected: abc123def456 (head)
```

**⚠️ Harmless Warnings (IGNORE THESE):**

You'll see these eventlet warnings on EVERY command - they're pre-existing and harmless:

```
An exception was thrown while monkey_patching for eventlet...
RuntimeError: Working outside of application context.
```

**What they mean:** Eventlet patching happens before Flask app context exists
**Impact:** None - commands execute successfully
**Action:** Ignore warnings, focus on INFO messages and final output

**How to verify success:** Look for:
- `INFO [alembic.runtime.migration]` messages
- Final revision output: `abc123def456 (head)`
- No actual ERROR lines

---

#### Step 13: Verify Version Match ⚠️ CRITICAL

**Compare:**
```
Local:      abc123def456 (head)
Production: abc123def456 (head)
✅ MATCH - Good to proceed!

Local:      abc123def456 (head)
Production: xyz789old123 (head)
❌ MISMATCH - DO NOT PROCEED! Roll back and investigate.
```

---

#### Step 14: Test Production IMMEDIATELY ⚠️ CRITICAL

**Test iOS App First (Most Important):**
1. View existing Write → Should display
2. Create new Write → Should save
3. Send message → Should send/receive
4. View messages → Should load
5. View profile → Should work

**If ANY fail → Roll back immediately:** `flask db downgrade -1`

**Test Web App (Secondary):**
1. Create Write with formatting
2. Send/receive messages
3. All existing features work

**Check Render Logs:**
- Dashboard → "Logs" tab
- Look for 500 errors, database errors, import errors
- Should see successful API requests

---

#### Step 15: Monitor for 24 Hours

**Watch:**
- Error logs in Render
- User reports
- API response times

**Be ready to:**
- Roll back: `flask db downgrade -1`
- Restore backup (if created)
- Hot-fix critical bugs

---

## 🚨 ROLLBACK PROCEDURES

### Scenario 1: Migration Fails During Execution

```bash
# In Render shell
flask db downgrade -1
flask db current  # Should show old version
# Render auto-restarts app
```

---

### Scenario 2: Migration Succeeds But App Breaks

```bash
# In Render shell
flask db downgrade -1
flask db current  # Verify rollback

# Or downgrade to specific version
flask db downgrade 2688c1fbf109
```

---

### Scenario 3: Need to Revert Code + Database

```bash
# LOCAL: Revert git commit
git revert abc123
git push origin Adam_July2025

# Wait for Render redeploy, then in Render shell:
flask db downgrade -1
flask db current  # Verify old version
```

---

### Scenario 4: Critical Failure - Restore Backup

```bash
# Only if you created a backup
psql $DATABASE_URL < backup_20251206.sql
flask db current  # Automatically shows old version after restore
```

---

## 📊 COMMON ISSUES & SOLUTIONS

| Issue | Cause | Solution |
|-------|-------|----------|
| **"Target database is not up to date"** | Versions don't match | Run `flask db upgrade` on the one that's behind |
| **"Can't locate revision 'abc123'"** | Migration file not deployed | Ensure migration committed to git and deployed |
| **Migration fails: "column cannot be null"** | Missing server_default | Add `server_default='value'` to migration file |
| **"Multiple heads detected"** | Parallel migrations conflict | `flask db merge heads -m "Merge"` then upgrade |
| **Commands fail: "wrong directory"** | Not in `your-app/` folder | `cd .../Python_Backend/your-app` |

---

## ✅ SUCCESS CHECKLIST

**Migration is successful when:**
- [x] Local and production versions match exactly
- [x] `flask db upgrade` completed with no errors
- [x] iOS app works perfectly (all existing features)
- [x] Web app works (new + old features)
- [x] No 500 errors in production logs
- [x] Can create/edit/delete data
- [x] Database queries are fast

---

## 📝 BEST PRACTICES

### Critical Do's ✅
- ✅ **ALWAYS run from correct directory** (`your-app/` folder)
- ✅ **ALWAYS add server_default** to new NOT NULL columns
- ✅ **ALWAYS verify versions match** between local and production
- ✅ **ALWAYS test locally first** before production
- ✅ **ALWAYS review migration file** for correctness
- ✅ **ALWAYS test iOS app immediately** after production migration
- ✅ **ALWAYS commit migrations to git**

### Critical Don'ts ❌
- ❌ **DON'T run from wrong directory** (must be in `your-app/`)
- ❌ **DON'T skip version verification**
- ❌ **DON'T add NOT NULL columns without server_default**
- ❌ **DON'T manually edit database** without migration
- ❌ **DON'T delete or merge migration files**
- ❌ **DON'T ignore errors** in migration output
- ❌ **DON'T deploy Friday evening** (weekend monitoring risk)

---

## 🔍 VERIFICATION COMMANDS

```bash
# Current version
flask db current

# Migration history
flask db history

# Pending migrations (should show one head)
flask db heads

# Database schema inspection
psql $DATABASE_URL
\dt                          # List tables
\d writes                    # Describe table
\d message_reactions         # Describe table
SELECT * FROM alembic_version;  # Check version
```

---

## 🎯 FOR THIS DEPLOYMENT (Example: Write + Messaging)

### Pre-Flight Checklist
- [x] Navigate to correct directory
- [x] Verify `migrate_run.py` exists
- [x] Create migration: `flask db migrate -m "..."`
- [x] **Review migration - check server_default values**
- [x] Run locally: `flask db upgrade`
- [x] Verify local: `flask db current` → Note revision ID
- [x] Test locally: Flask server + API calls
- [x] Commit: `git add migrations/ app/` → `git commit` → `git push`

### Deployment Checklist
- [x] Optional: Backup production DB
- [x] Deploy code to Render (auto-deploy from git)
- [x] Verify deploy succeeded (check logs)
- [x] Connect to Render shell
- [x] Check current: `flask db current` (old version)
- [x] Run migration: `flask db upgrade`
- [x] Verify version: `flask db current` (should match local)
- [x] **Test iOS app immediately** (critical!)
- [x] Test web app
- [x] Check logs (no 500 errors)
- [x] Monitor for 1 hour, then 24 hours

### If Issues Occur
- [ ] Roll back: `flask db downgrade -1`
- [ ] Or restore from backup (if created)
- [ ] Review migration file for issues
- [ ] Fix locally and repeat process

---

## 📞 EMERGENCY CONTACTS & RESOURCES

**Before Starting:**
- [ ] Database admin access
- [ ] Render dashboard access
- [ ] Backup storage access (if backing up)
- [ ] This document open
- [ ] Test device/simulator ready

**Related Documentation:**
- This file: Complete migration workflow
- `MASTER_DEPLOYMENT_PLAN.md`: Overall deployment strategy
- Flask-Migrate docs: https://flask-migrate.readthedocs.io/

---

## 🎉 SUMMARY

**This workflow prevents:**
- ❌ Alembic version mismatches
- ❌ Production deployment failures
- ❌ Data corruption
- ❌ App crashes
- ❌ Manual database cleanup

**Why it works:**
- ✅ Test locally first (catches errors early)
- ✅ Review migrations (prevents bad SQL)
- ✅ Verify versions (prevents sync issues)
- ✅ Git workflow (ensures same files everywhere)
- ✅ Immediate testing (confirms success)

**Keep following this process** - It's battle-tested and proven to work!

---

**Created By**: Claude Code Assistant
**Last Updated**: February 4, 2026
**Status**: ✅ Production-Ready
