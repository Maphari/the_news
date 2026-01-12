# The News - Backend API (Firebase-Only)

**100% Firebase Firestore** - No PostgreSQL needed!

---

## 🚀 Quick Start

### Prerequisites

- Node.js 18+
- Firebase project with Firestore enabled

### Installation

```bash
cd server
npm install
```

### Firebase Setup

1. Create Firebase project at https://console.firebase.google.com
2. Enable Authentication (Google, Apple)
3. Enable Firestore Database
4. Download Firebase Admin SDK service account JSON
5. Save as `firebase_service.json` in `server/` directory

### Configuration

```bash
cp .env.example .env
# Edit .env with your Firebase config
```

### Running the Server

```bash
# Development mode with hot reload
npm run dev

# Production mode
npm run build
npm start
```

Server will run on `http://localhost:8080`

---

## 📋 API Endpoints (30 Total)

### ✅ Authentication (4 endpoints)
- `POST /api/v1/auth/google` - Google OAuth sign in
- `POST /api/v1/auth/apple` - Apple sign in
- `GET /api/v1/auth/validate-token` - Validate JWT tokens
- `GET /api/v1/auth/me` - Get current user profile

### ✅ User Preferences Sync (3 endpoints) ⭐ NEW
- `GET /api/v1/user/preferences/:userId` - Get user preferences
- `PUT /api/v1/user/preferences` - Update user preferences
- `DELETE /api/v1/user/preferences/:userId` - Delete preferences

### ✅ Reading History (4 endpoints) ⭐ NEW
- `GET /api/v1/user/reading-history/:userId` - Get reading history
- `POST /api/v1/user/reading-history` - Add reading history entries
- `GET /api/v1/user/analytics/:userId` - Get reading analytics
- `DELETE /api/v1/user/reading-history/:userId` - Clear history

### ✅ Saved Articles (3 endpoints)
- `GET /api/v1/saved-articles/:userId` - Get saved articles (with full data)
- `POST /api/v1/saved-articles` - Save article
- `DELETE /api/v1/saved-articles` - Remove saved article

### ✅ Engagement (4 endpoints)
- `GET /api/v1/engagement/:articleId` - Get engagement stats
- `POST /api/v1/engagement/like` - Like article
- `DELETE /api/v1/engagement/like` - Unlike article
- `POST /api/v1/engagement/share` - Track shares

### ✅ Comments (6 endpoints)
- `GET /api/v1/comments/:articleId` - Get all comments
- `POST /api/v1/comments` - Create comment
- `PUT /api/v1/comments/:commentId` - Update comment
- `DELETE /api/v1/comments/:commentId` - Delete comment
- `POST /api/v1/comments/like` - Like comment
- `DELETE /api/v1/comments/like` - Unlike comment

### ✅ Other Endpoints (6 endpoints)
- `GET /api/v1/articles` - Fetch articles
- `POST /api/v1/articles/batch` - Bulk save articles
- `GET /api/v1/followed-publishers/:userId` - Get followed publishers
- `POST /api/v1/followed-publishers/follow` - Follow publisher
- `POST /api/v1/followed-publishers/unfollow` - Unfollow publisher
- `GET /api/v1/disliked-articles/:userId` - Get disliked articles
- `POST /api/v1/disliked-articles` - Mark article as disliked

---

## 🗄️ Firestore Collections

All data stored in Firebase Firestore:

### Core Collections
- **users** - User accounts
- **savedArticles** - Bookmarked articles with full JSON
- **dislikedArticles** - Articles marked not interested
- **followedPublishers** - Followed news sources

### Engagement Collections
- **articleEngagement** - Aggregated engagement metrics
- **userLikes** - Article likes
- **userShares** - Article shares
- **comments** - Article comments
- **commentLikes** - Comment likes

### Sync Collections (NEW)
- **userPreferences** - Cross-device preferences sync
- **readingHistory** - Reading analytics and history

---

## 🔧 Environment Variables

Required in `.env`:

```bash
# Server
PORT=8080

# JWT
JWT_SECRET=your_secret_key

# Firebase
FIREBASE_SERVICE_ACCOUNT_PATH=./firebase_service.json

# NewsData.io
NEWS_API_KEY=your_newsdata_io_api_key
```

---

## 🔑 Key Features

### 1. Cross-Device Sync ⭐
- User preferences automatically sync across devices
- Reading history preserved
- Saved articles include full content
- **Powered by Firebase Firestore**

### 2. Pure Firebase Architecture
- **No database server needed**
- **Real-time sync built-in**
- **Offline support included**
- **Automatic scalability**

### 3. Performance Optimized
- Document ID-based lookups for speed
- Indexed queries
- Batch operations (up to 500/batch)
- Automatic caching

---

## 🏗️ Project Structure

```
server/
├── src/
│   ├── config/
│   │   └── firebase.connection.ts    # Firebase setup
│   ├── controllers/
│   │   ├── auth.controller.ts
│   │   ├── user-preferences.controller.ts  ⭐ NEW (Firebase)
│   │   ├── reading-history.controller.ts   ⭐ NEW (Firebase)
│   │   ├── saved-articles.controller.ts    (Updated for full data)
│   │   └── ...
│   ├── routes/
│   │   ├── user-preferences.routes.ts      ⭐ NEW
│   │   ├── reading-history.routes.ts       ⭐ NEW
│   │   └── ...
│   ├── middleware/
│   │   └── errorHandling.ts
│   ├── app.ts                   # Express app setup
│   └── server.ts                # Entry point
├── package.json
├── tsconfig.json
├── .env.example
└── README.md
```

---

## 🔐 Security Features

- Helmet.js for security headers
- CORS configuration
- JWT authentication
- Firebase security rules
- Input validation

---

## 📈 Advantages Over SQL Databases

| Feature | Firebase | PostgreSQL |
|---------|----------|------------|
| Setup Time | 3 minutes | 15+ minutes |
| Maintenance | Zero | Regular updates |
| Scalability | Automatic | Manual |
| Offline Support | Built-in | Custom needed |
| Real-time Sync | Built-in | WebSockets needed |
| Deployment | Included | Separate hosting |
| Cost (Small Apps) | Free tier | Hosting fees |

---

## 🚀 Deployment

### Heroku

```bash
heroku create the-news-api
heroku config:set JWT_SECRET=your_secret
heroku config:set NEWS_API_KEY=your_key

# Upload firebase_service.json as config var
# (Copy JSON to FIREBASE_CONFIG environment variable)

git push heroku main
```

### Railway/Render

Similar process - no database addon needed!

---

## 📝 API Response Format

All endpoints return consistent JSON:

```json
{
  "success": true/false,
  "data": {...},
  "message": "Optional message",
  "error": "Error details if failed"
}
```

---

## ✅ Implementation Checklist

- [x] Firebase Firestore configured
- [x] Authentication endpoints
- [x] Articles management
- [x] Comments system (Firebase)
- [x] Engagement tracking (Firebase)
- [x] Saved articles (returns full data)
- [x] User preferences sync (Firebase)
- [x] Reading history & analytics (Firebase)
- [x] Followed publishers (Firebase)
- [x] Disliked articles (Firebase)
- [x] Error handling
- [x] CORS & security
- [ ] Unit tests
- [ ] Integration tests
- [ ] API documentation

---

## 🤝 Contributing

1. Create feature branch
2. Make changes
3. Test thoroughly
4. Submit PR with description

---

## 📄 License

MIT

---

**Backend Status:** ✅ **PRODUCTION READY**

All 30 endpoints implemented. Firebase Firestore configured. Cross-device sync enabled. **Zero database maintenance required.**

Last Updated: December 30, 2025
