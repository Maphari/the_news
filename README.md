# The News - Mindful News Application

A Flutter-based news aggregation app with a Node.js backend that provides a mindful, personalized news reading experience.

## Features

### 🎯 Core Features
- **Multi-source News Aggregation** - Fetch news from various sources via News API
- **Country-based Filtering** - Filter news by preferred countries
- **Smart Article Merging** - Fresh API articles on top, older cached articles below
- **Offline Support** - Articles cached in backend database
- **Reading History** - Track and sync reading progress
- **Article Engagement** - Like, save, and share articles

### 🎨 User Experience
- **Calm Mode** - Distraction-free reading experience
- **Multiple View Modes** - Card stack and compact list views
- **Multi-Perspective View** - See different perspectives on stories
- **Daily Digest** - Personalized summary of important news
- **Dark/Light Themes** - Full theme support

### 👤 User Features
- **Authentication** - Email, Google, and Apple sign-in
- **User Profiles** - Personalized preferences and settings
- **Premium Subscription** - Ad-free experience with exclusive features
- **Social Features** - Follow publishers, engage with content
- **Comments** - Discuss articles with other users

### 🌍 Personalization
- **Country Preferences** - Select preferred countries for news
- **Auto-location Detection** - Automatic country detection
- **Category Filtering** - Browse by news categories
- **Trending Topics** - See what's trending in the news

## Tech Stack

### Frontend (Flutter)
- **Framework**: Flutter 3.x
- **State Management**: ChangeNotifier, Provider pattern
- **HTTP Client**: Custom ApiClient with retry logic
- **Local Storage**: SharedPreferences
- **Firebase**: Authentication, Analytics
- **UI**: Material Design 3

### Backend (Node.js)
- **Runtime**: Node.js
- **Framework**: Express.js
- **Database**: Firebase Realtime Database
- **Authentication**: JWT, OAuth (Google, Apple)
- **APIs**: News API integration
- **Email**: Nodemailer for notifications

## Getting Started

### Prerequisites
- Flutter SDK (latest stable)
- Node.js (v14 or higher)
- Firebase account
- News API key from [newsdata.io](https://newsdata.io)

### Frontend Setup

1. **Clone the repository**
   ```bash
   git clone <your-repo-url>
   cd the_news
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure environment variables**
   ```bash
   cp .env.example .env
   # Edit .env with your actual keys
   ```

4. **Add Firebase configuration**
   - Download `google-services.json` from Firebase Console
   - Place in `android/app/`
   - Download `GoogleService-Info.plist` for iOS
   - Place in `ios/Runner/`

5. **Run the app**
   ```bash
   flutter run
   ```

### Backend Setup

1. **Navigate to server directory**
   ```bash
   cd server
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Configure environment variables**
   ```bash
   cp .env.example .env
   # Edit .env with your actual keys
   ```

4. **Add Firebase service account**
   - Download service account JSON from Firebase Console
   - Save as `server/src/firebase_service.json`

5. **Start the server**
   ```bash
   npm start
   ```

   The server will run on `http://localhost:8080`

## Environment Variables

### Frontend (.env)
```env
API_BASE_URL=http://localhost:8080/api/v1
NEWS_API_KEY=your_news_api_key
NEWS_API_BASE_URL=https://newsdata.io/api/1/latest?
CLAUDE_AI_KEY=your_claude_key (optional)
GEMINI_AI_KEY=your_gemini_key (optional)
OPENAI_DIRECT_KEY=your_openai_key (optional)
GITHUB_PAT_KEY=your_github_pat (optional)
PAYSTACK_PUBLIC_KEY=your_paystack_public_key
```

### Backend (.env)
```env
PORT=8080
JWT_SECRET=your_jwt_secret
GOOGLE_CLIENT_ID=your_google_client_id
APPLE_CLIENT_ID=your_apple_client_id
FIREBASE_DB_URL=your_firebase_url
PAYSTACK_SECRET_KEY=your_paystack_secret
GOOGLE_APP_EMAIL=your_email@gmail.com
GOOGLE_APP_PASSWORD=your_app_password
```

## Project Structure

```
the_news/
├── lib/
│   ├── constant/       # App constants and themes
│   ├── core/          # Core utilities and network
│   ├── model/         # Data models
│   ├── service/       # Business logic services
│   ├── utils/         # Helper utilities
│   ├── view/          # UI screens and widgets
│   └── main.dart      # App entry point
├── server/
│   ├── src/           # Server source code
│   ├── .env           # Environment variables
│   └── package.json   # Node dependencies
├── android/           # Android specific code
├── ios/              # iOS specific code
└── test/             # Test files
```

## Key Services

### Frontend Services
- **NewsProviderService** - Manages article fetching and caching
- **LocationService** - Handles country preferences and detection
- **AuthService** - User authentication
- **SubscriptionService** - Premium subscription management
- **ReadingHistoryService** - Track reading progress

### Backend Endpoints
- `/api/v1/auth/*` - Authentication endpoints
- `/api/v1/articles/*` - Article management
- `/api/v1/users/*` - User management
- `/api/v1/subscriptions/*` - Subscription management

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## Security Notes

- Never commit `.env` files or API keys
- Keep `firebase_service.json` secure and out of version control
- Use environment variables for all sensitive data
- Rotate secrets regularly

## License

[Add your license here]

## Contact

[Add your contact information]

---
Built with ❤️ using Flutter and Node.js
