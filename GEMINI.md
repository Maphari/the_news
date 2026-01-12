# 🤖 GEMINI.md - Updated Project Rules & Standards

## 🎯 Overview
**Project Name:** The News
**Architecture:** Clean Architecture (MVVM + Service Layer)
**Core Principle:** Offline-first, consistency through Singletons, and Enriched Content.

---

## 🏗️ Flutter Architecture Rules (lib/)

### 1. Networking & API Calls (CRITICAL)
- **Use ApiClient Only**: All network requests **must** use `ApiClient.instance`. 
- **No Direct HTTP**: Never use `http.get` or `http.post` directly in services.
- **No EnvConfig**: Do not create instances of `EnvConfig` or call `dotenv.env` inside services; the `ApiClient` handles the Base URL centrally.
- **Validation**: Use `_api.isSuccess(response)` and `_api.parseJson(response)` for consistency.

### 2. Service Layer Standards
- **Singleton Pattern**: Every service must implement a private constructor and a `static final instance`.
- **Logic Placement**: Services handle data transformation, business logic, and error logging (`dart:developer`'s `log`).
- **Caching**: Implement the Three-Level Caching Strategy:
    1. **Memory**: Current session data.
    2. **Local**: `SharedPreferences` for offline-first access.
    3. **Backend**: Final source of truth.

### 3. Model & Data Standards
- **Enrichment**: Articles should use `EnrichedArticle` model to support `fullText`, `images` (List), and `videos` (VideoEmbed) extracted by the backend scraper.
- **Serialization**: Every model must have `fromJson` and `toJson` for caching and Firestore sync.

---

## ⚙️ Backend Rules (server/)

### 1. Scraper Logic
- **Readability**: Use `@mozilla/readability` for clean text extraction.
- **Asset Extraction**: Scraper must extract up to 10 images and detect video embeds (YouTube/Vimeo).
- **Security**: Validate all `sourceUrl` inputs to prevent SSRF and validate article IDs.

### 2. Firestore Structure
- **Collections**: Stick to the 11 core collections (users, savedArticles, userPreferences, etc.) defined in `FIREBASE_ONLY_GUIDE.md`.
- **Sync**: Ensure `userPreferences` sync includes `fontSize`, `themeMode`, and `aiProvider`.

---

## 🎨 UI & UX Standards

### 1. Theming & Styling
- **Global Theme**: Use `KAppColors` and `KAppTextStyles`.
- **Calm Mode**: Check `CalmModeService.instance.isCalmModeEnabled` to toggle font weights (W400) and simplified layouts.
- **Adaptive UI**: Use `AdaptiveScaffold` and `AdaptiveNavigationDestination`. Note: Use **String names** (e.g., 'house.fill') for icons instead of Material `IconData` for native compatibility.

### 2. Interactions
- **Swipe Actions**: (Upcoming Phase 3) 
    - Right -> Save
    - Left -> Dislike/Hide
    - Up -> Read Later
- **Error Handling**: Always provide a "Retry" button and local storage fallback if the API is unreachable.

---

## 🚫 Prohibited Patterns
- ❌ **Direct View-to-API**: Views must never call the network.
- ❌ **Hardcoded Strings**: No hardcoded API paths or keys; use `ApiConfig` or `ApiClient`.
- ❌ **Print Statements**: Use `log()` from `dart:developer` for debug info.
- ❌ **Blocking build()**: Never perform heavy async logic inside a widget's `build` method.