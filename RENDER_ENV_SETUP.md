# 🔧 Render Environment Variables Setup

## ❌ Current Error
```
MongoDB connection error: connect ECONNREFUSED 127.0.0.1:27017
```

**Problem**: Render backend is trying to connect to `localhost:27017` instead of MongoDB Atlas.

**Solution**: Set the `MONGODB_URI` environment variable in Render dashboard.

---

## ✅ Fix Steps

### Step 1: Get Your MongoDB Atlas Connection String
Your connection string should look like:
```
mongodb+srv://dbDTABNOOK:1Dwyanne05@swsncnewmvp.fkuctwi.mongodb.net/sweldosync?retryWrites=true&w=majority&appName=SWSNCnewmvp
```

### Step 2: Set Environment Variables in Render

1. **Go to Render Dashboard**: https://dashboard.render.com
2. **Click on your service**: `GC2_SweldoSyncMVP`
3. **Click "Environment"** in the left sidebar
4. **Add these environment variables**:

   | Key | Value |
   |-----|-------|
   | `MONGODB_URI` | `mongodb+srv://dbDTABNOOK:1Dwyanne05@swsncnewmvp.fkuctwi.mongodb.net/sweldosync?retryWrites=true&w=majority&appName=SWSNCnewmvp` |
   | `JWT_SECRET` | `sweldosync-secret-key-change-in-production-2024` |
   | `PORT` | `10000` (or leave empty, Render sets this automatically) |

5. **Click "Save Changes"**
6. **Render will automatically redeploy** your service

### Step 3: Wait for Redeploy
- Render will restart your service with the new environment variables
- Check the logs to see if MongoDB connects successfully
- Should see: `MongoDB Connected Successfully`

---

## 🔍 Verify It's Working

After redeploy, check the logs:
- ✅ Should see: `MongoDB Connected Successfully`
- ✅ Should see: `SweldoSync Backend running on http://localhost:10000`
- ❌ Should NOT see: `ECONNREFUSED` errors

Test the health endpoint:
```bash
curl https://gc2-sweldosyncmvp.onrender.com/health
```

Should return: `{"status":"ok","message":"SweldoSync API is running"}`

---

## 📝 Important Notes

1. **Never commit `.env` file** - It's already in `.gitignore`
2. **Environment variables are set per service** in Render
3. **Changes require redeploy** - Render does this automatically
4. **MongoDB Atlas IP Whitelist** - Make sure `0.0.0.0/0` is whitelisted in MongoDB Atlas

---

## 🚨 If Still Not Working

1. **Check MongoDB Atlas**:
   - Go to MongoDB Atlas dashboard
   - Network Access → Ensure `0.0.0.0/0` is whitelisted
   - Database Access → Verify user credentials

2. **Check Render Logs**:
   - Look for the exact error message
   - Verify environment variables are set correctly

3. **Test Connection String**:
   - Try connecting with MongoDB Compass using the same connection string
   - If it works in Compass, it should work in Render

---

## ✅ After Fix

Once environment variables are set:
- ✅ Backend will connect to MongoDB Atlas
- ✅ All API endpoints will work
- ✅ Frontend will be able to communicate with backend
- ✅ Analytics dashboard will load data

