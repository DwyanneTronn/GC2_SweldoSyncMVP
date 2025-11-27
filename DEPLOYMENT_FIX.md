# 🚀 Deployment Fix Guide

## Problem
The deployed app shows the old version because:
1. API URL was pointing to `localhost` instead of production backend
2. Frontend needs to be rebuilt with the correct API URL

## ✅ Fix Applied
- Updated `api_service.dart` to use production backend: `https://gc2-sweldosyncmvp.onrender.com/api`

## 📝 Next Steps to Deploy

### Step 1: Commit the Fix
```bash
cd /Users/dwybal/Desktop/FINAL_ECOMMERCE/GC2_SweldoSyncMVP
git add frontend_flutter/lib/services/api_service.dart
git commit -m "Fix: Update API URL to production backend"
git push origin main
```

### Step 2: Trigger Vercel Deployment
Vercel should automatically deploy when you push to GitHub. If not:

1. Go to [Vercel Dashboard](https://vercel.com/dashboard)
2. Find your SweldoSync project
3. Click "Redeploy" or wait for auto-deploy (usually 1-2 minutes)

### Step 3: Verify Backend is Running
Check your Render backend:
```bash
curl https://gc2-sweldosyncmvp.onrender.com/health
```

Should return: `{"status":"ok","message":"SweldoSync API is running"}`

### Step 4: Clear Browser Cache
After deployment:
1. Hard refresh: `Cmd+Shift+R` (Mac) or `Ctrl+Shift+R` (Windows)
2. Or open in incognito/private window

### Step 5: Test the Deployment
1. Visit: `https://sweldosync.vercel.app`
2. Should show login screen (not old app)
3. Register/Login should work
4. Analytics button should work

---

## 🔍 If Still Shows Old App

### Option 1: Force Vercel Redeploy
1. Go to Vercel Dashboard
2. Click on your project
3. Go to "Deployments" tab
4. Click "..." on latest deployment
5. Click "Redeploy"

### Option 2: Check Vercel Build Settings
Make sure Vercel has:
- **Build Command**: `cd frontend_flutter && flutter build web --release`
- **Output Directory**: `frontend_flutter/build/web`
- **Root Directory**: (leave empty or set to repo root)

### Option 3: Manual Build & Deploy
```bash
cd frontend_flutter
flutter build web --release
# Then manually upload build/web folder to Vercel
```

---

## ✅ Verification Checklist

After deployment, verify:
- [ ] Frontend loads at `https://sweldosync.vercel.app`
- [ ] Shows login screen (not old app)
- [ ] Can register new account
- [ ] Can login
- [ ] Analytics dashboard loads
- [ ] All features work

---

## 🎯 Expected Result

After fix:
- ✅ API calls go to `https://gc2-sweldosyncmvp.onrender.com/api`
- ✅ Frontend shows new login/register screens
- ✅ Analytics dashboard works
- ✅ All new features visible

