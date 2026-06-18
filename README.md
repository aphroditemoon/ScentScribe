# ScentScribe

![Flutter](https://img.shields.io/badge/Flutter-Mobile%20App-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-Frontend-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Node.js](https://img.shields.io/badge/Node.js-Backend-339933?style=for-the-badge&logo=node.js&logoColor=white)
![Python](https://img.shields.io/badge/Python-ML%20Engine-3776AB?style=for-the-badge&logo=python&logoColor=white)
![Status](https://img.shields.io/badge/Status-Completed-success?style=for-the-badge)

**ScentScribe is an AI powered fragrance lifestyle mobile application that helps users manage perfume collections, log scent wearing experiences, receive weather aware recommendations, and explore perfume layering through a premium mobile interface.**

---

## Application Preview
```markdown
![ScentScribe Demo](ScentScribeDemo.png)
```
## Overview

ScentScribe was built as a smart fragrance companion that connects personal lifestyle habits, perfume data, weather conditions, and AI assisted recommendation logic into one mobile experience. The application allows users to store their perfume collection, track how a fragrance performs throughout the day, understand which scents fit current weather conditions, and discover possible layering combinations.

The project combines mobile app development, local database management, REST API integration, weather based logic, machine learning concepts, profile personalization, and polished UI/UX design. Its main goal is to make fragrance selection feel more personal, practical, and data driven while still maintaining an elegant and easy to use interface.

---

## Main Goals

ScentScribe focuses on four main goals:

- Help users organize their perfume collection and wishlist.
- Recommend fragrances based on weather, time of day, skin type, and user preferences.
- Let users document scent performance through a personal journal.
- Provide an AI inspired fragrance ecosystem for recommendation, analysis, and layering exploration.

---

## Key Features

### Perfume Collection Management

Users can add, edit, view, and remove perfumes from their personal collection. Each perfume can include brand name, fragrance family, rating, notes, bottle size, best seasons, best times, occasions, price, launch year, perfumer, and wishlist status.

### Wishlist Support

Perfumes can be saved as wishlist items, allowing users to separate owned fragrances from scents they want to try in the future.

### Weather Based Recommendations

The app reads current weather conditions and recommends perfumes that match temperature, humidity, season, and time of day. This helps users choose scents that are more suitable for the environment.

### Scent Journal

Users can log daily perfume usage and record longevity, sillage, projection, mood, occasion, skin condition, weather, and personal notes. Journal entries can also be edited or deleted.

### AI Scent Intelligence

The AI screen provides fragrance insights based on the user’s collection, weather conditions, and scent profile. It helps users understand which perfumes are more suitable for specific conditions.

### Layering Lab

The layering feature allows users to select multiple perfumes and explore potential scent combinations. The system estimates compatibility and provides predicted blend notes.

### Profile Personalization

Users can update their profile name, bio, profile photo, preferred fragrance families, signature notes, avoided notes, skin type, and climate type.

### Local Storage

The application stores collection data, journal entries, and user profile information locally using SQLite, making the core experience available without depending fully on a remote server.

### Backend API Support

The project includes a Node.js and Express backend for authentication, cloud data storage, perfume records, journal records, and analytics support using PostgreSQL.

### Machine Learning Inference Server

The project also includes a Python Flask ML server that can provide fragrance-weather compatibility predictions, batch predictions, and layering compatibility results.

---

## Application Flow

```text
User opens ScentScribe
        ↓
Splash screen with animated petals appears
        ↓
User completes onboarding and fragrance preferences
        ↓
App loads profile, perfume collection, journal data, and weather data
        ↓
Recommendation engine analyzes weather, time, preferences, and perfume data
        ↓
User can view recommended scents, manage collection, log wear, explore AI insights, or update profile
```

---

## Core Screens

### Splash Screen

The splash screen introduces the application using the ScentScribe logo and a floating petal animation. It creates a premium first impression before moving into the main app.

### Onboarding Screen

The onboarding screen collects basic user information such as name, preferred fragrance families, and skin type. This information is used later to personalize recommendations.

### Home Screen

The home screen works as the main dashboard. It displays user-related information, current weather context, AI top picks, recommendations, collection summaries, and recent journal activity.

### Collection Screen

The collection screen displays owned perfumes and wishlist items. Users can browse perfume cards, view details, and manage their fragrance library.

### Add Perfume Screen

The add perfume screen lets users input fragrance details, including perfume name, brand, family, rating, notes, best seasons, best times, occasions, and extra information.

### Perfume Detail Screen

The perfume detail screen shows complete information about a selected perfume. Users can review notes, performance-related details, best usage context, and log the perfume for the day.

### Journal Screen

The journal screen stores scent wearing history. Users can review past logs, edit entries, delete entries, and understand how perfumes perform over time.

### AI Screen

The AI screen provides scent intelligence features, recommendation insights, and layering analysis. It helps users make better scent decisions based on data and context.

### Profile Screen

The profile screen allows users to update profile data, photo, bio, preferred scent families, signature notes, skin type, and app information.

---

## System Logic

### 1. State Management Logic

ScentScribe uses a provider based state management structure. The main provider initializes the app, loads local data, manages navigation state, handles collection updates, refreshes weather data, and recalculates scent recommendations whenever needed.

Main file:

```text
lib/providers/app_provider.dart
```

### 2. Local Database Logic

The local database stores the main offline data of the app. It includes perfume records, journal entries, user profile data, and layering combinations.

Main file:

```text
lib/services/database_service.dart
```

Local database tables include:

```text
perfumes
journal_entries
user_profile
layering_combos
```

### 3. Weather Logic

The weather service uses device location and OpenWeatherMap API data to retrieve temperature, humidity, weather condition, city, wind speed, feels-like temperature, and pressure. It also uses caching to avoid unnecessary API requests.

Main file:

```text
lib/services/weather_service.dart
```

Weather logic includes:

- Location permission handling
- Current weather fetching
- Weather caching
- Location caching
- Fallback mock weather when API or location access is unavailable

### 4. Recommendation Logic

The recommendation engine ranks perfumes based on multiple factors. It calculates a compatibility score using weather profile rules for each fragrance family.

Main file:

```text
lib/services/ml_engine.dart
```

Recommendation factors include:

- Temperature
- Humidity
- Season
- Time of day
- Fragrance family
- User preferred families
- Preferred notes
- Perfume rating
- Feels like temperature
- Skin type
- Rain or storm condition
- Wind speed

Example logic:

```text
Perfume data + weather data + user profile
        ↓
Compatibility score calculation
        ↓
Match factor explanation
        ↓
Ranked recommendation list
```

### 5. Journal Logic

Journal entries record how a perfume performs in real usage. Each entry can store longevity, sillage, projection, mood rating, notes, occasion, skin condition, and weather snapshot.

Main model:

```text
JournalEntry
```

Main screens:

```text
lib/screens/journal_screen.dart
lib/screens/add_journal_screen.dart
```

### 6. Perfume Image Logic

The perfume image feature supports bottle images, placeholders, and network based images. This helps each perfume card feel more visual and polished.

Main files:

```text
lib/services/perfume_image_service.dart
lib/widgets/perfume_bottle_image.dart
```

### 7. Backend API Logic

The backend uses Express.js and PostgreSQL to support authentication, cloud perfume storage, journal storage, and analytics.

Main files:

```text
backend/server.js
backend/package.json
```

Backend tables include:

```text
users
perfumes
journal_entries
trend_data
```

Main backend endpoints include:

```text
POST /api/auth/register
POST /api/auth/login
GET  /api/perfumes
POST /api/perfumes
PUT  /api/perfumes/:id
DELETE /api/perfumes/:id
GET  /api/journal
POST /api/journal
GET  /api/analytics/stats
```

### 8. Machine Learning Server Logic

The ML server uses Flask and scikit learn to predict fragrance weather compatibility and layering compatibility.

Main files:

```text
ml/inference_server.py
ml/train_model.py
ml/model_meta.json
```

ML endpoints include:

```text
GET  /health
POST /predict
POST /predict/batch
POST /layering
```

ML input factors include:

```text
temperature
humidity
base_note_count
heart_note_count
fragrance family
time of day
season
skin type
```

---

## Tech Stack

### Mobile App

- Flutter
- Dart
- Provider
- SQLite / Sqflite
- Shared Preferences
- Dio
- Geolocator
- Google Fonts
- Flutter Animate
- Cached Network Image
- Image Picker
- Local Notifications
- FL Chart

### Backend

- Node.js
- Express.js
- PostgreSQL
- JSON Web Token
- Bcrypt
- Helmet
- CORS
- Express Rate Limit

### Machine Learning

- Python
- Flask
- NumPy
- Pandas
- Scikit learn
- Joblib

### External Service

- OpenWeatherMap API

---

## Installation and Setup

### Prerequisites

Make sure these tools are installed:

- Flutter SDK
- Dart SDK
- Android Studio or Android SDK
- Node.js 18 or later
- Python 3.10 or later
- PostgreSQL, if you want to run the backend database
- OpenWeatherMap API key, if you want real weather data

---

## Running the Flutter App

```bash
git clone https://github.com/your-username/scentscribe.git
cd scentscribe
flutter pub get
flutter run
```

If you want to build an Android APK:

```bash
flutter build apk --release
```

The generated APK will usually be located at:

```text
build/app/outputs/flutter-apk/app-release.apk
```

---

## Running the Backend API

```bash
cd backend
npm install
npm start
```

For development mode:

```bash
npm run dev
```

Recommended environment variables:

```env
PORT=3000
DATABASE_URL=postgresql://username:password@localhost:5432/scentscribe
JWT_SECRET=change_this_secret_in_production
NODE_ENV=development
```

The backend API runs by default on:

```text
http://localhost:3000
```

For Android emulator access, the Flutter API service uses:

```text
http://10.0.2.2:3000
```

---

## Running the ML Inference Server

```bash
cd ml
python -m venv .venv
```

Activate the virtual environment.

For Windows:

```bash
.venv\Scripts\activate
```

For macOS or Linux:

```bash
source .venv/bin/activate
```

Install the required libraries:

```bash
pip install flask joblib numpy pandas scikit-learn
```

Train or regenerate the model if needed:

```bash
python train_model.py
```

Run the inference server:

```bash
python inference_server.py
```

Recommended environment variable:

```env
ML_API_KEY=change_this_ml_key
```
## Project Impact

ScentScribe demonstrates how mobile app development, UI/UX design, local storage, API integration, weather data, and AI-inspired logic can be combined into a meaningful lifestyle application. The project transforms fragrance selection from a purely personal habit into a more contextual, data-driven, and interactive experience.
