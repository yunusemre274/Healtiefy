# 🏃 Healtiefy

**Walk, Build, Compete!**

A modern, AI-powered fitness companion that makes walking fun and addictive. Track your steps, listen to Spotify, and stay motivated with personalized AI coaching.

![Flutter](https://img.shields.io/badge/Flutter-3.38+-02569B?logo=flutter)
![Platform](https://img.shields.io/badge/Platform-Android-3DDC84?logo=android)
![License](https://img.shields.io/badge/License-MIT-green)

---

## 📥 Download Test APK

**[⬇️ Download Healtiefy v1.0.0 APK](build/app/outputs/flutter-apk/app-release.apk)**

> **Installation:** Enable "Install from unknown sources" in your Android settings, then install the APK.

---

## 🤔 Why Healtiefy Instead of Other Fitness Apps?

### The Problem with Current Fitness Apps

| 😤 Other Apps | ✨ Healtiefy |
|---------------|--------------|
| **Boring dashboards** - Just numbers and graphs that you stop caring about after a week | **Engaging experience** - Beautiful, Duolingo-style UI that makes checking your progress actually enjoyable |
| **No music integration** - You need to switch between apps constantly | **Built-in Spotify** - Control your music right from the app, no app-switching needed |
| **Generic advice** - Same tips for everyone regardless of their actual performance | **AI-powered coaching** - Personalized tips based on YOUR data, YOUR patterns, YOUR goals |
| **Complicated setup** - Sync with 5 different devices, connect accounts, configure settings... | **Just works** - Uses your phone's built-in sensors. No smartwatch required. |
| **Subscription walls** - Basic features locked behind $10/month paywalls | **100% Free** - All features available, no premium tiers, no hidden costs |
| **Battery draining GPS** - Constantly tracking location kills your battery | **Smart tracking** - GPS only when you're actively walking, pedometer for passive counting |
| **No personality** - Cold, clinical interfaces that feel like medical software | **Fun & friendly** - Feels like a game, not a doctor's appointment |

### What Makes Healtiefy Special?

#### 1. 🎯 **Duolingo-Style Motivation**
Remember how Duolingo makes you *want* to learn every day? We brought that same energy to fitness:
- **Streak tracking** - Don't break your walking streak!
- **Daily challenges** - Fresh goals every day
- **Achievement badges** - Unlock rewards as you progress
- **Friendly reminders** - Not annoying, just encouraging

#### 2. 🤖 **AI That Actually Helps**
Our AI doesn't just say "walk more." It analyzes your patterns:
- *"You usually walk less on Wednesdays. How about a short evening walk today?"*
- *"Great momentum! You're 20% more active than last week."*
- *"You're at 80% of your goal with 3 hours left. A 10-minute walk will get you there!"*

#### 3. 🎵 **Spotify Integration**
Walking is better with music. We get it:
- Connect your Spotify account with one tap
- See what's playing without leaving the app
- Control playback while tracking your walk
- Your music, your pace, your workout

#### 4. 🗺️ **Real GPS Route Tracking**
Not just step counting:
- See your walking routes on a beautiful map
- Track distance, pace, and duration
- Save your favorite routes
- Works offline too

#### 5. 📊 **Actually Useful Stats**
- Daily, weekly, and monthly progress
- Calories burned (calculated from YOUR height/weight)
- Fat burned estimation
- Session history with detailed breakdowns
- Beautiful charts that make sense

#### 6. 🔋 **Respects Your Phone**
- Pedometer uses minimal battery for daily step counting
- GPS only activates during active tracking sessions
- No background processes eating your battery
- No unnecessary network calls

---

## ✨ Features

### 📊 Smart Dashboard
- Live step counting using phone sensors
- Daily progress ring (like Apple Watch)
- Calories, distance, and fat burned
- Water intake tracker
- AI-powered personalized tips
- Weekly challenges

### 🗺️ GPS Walk Tracking
- Real-time route mapping
- Start/pause/stop controls
- Live stats during walk
- Session saving with full details

### 📈 Progress Analytics
- Daily/Weekly/Monthly views
- Session history
- Achievement tracking
- Streak monitoring
- Beautiful FL Charts visualizations

### 🎵 Spotify Integration
- OAuth login (secure, official)
- Now playing display
- Playback controls
- Works during walks

### 👤 Profile & Settings
- Personal stats (height, weight, age)
- Custom goals (steps, water, sessions)
- Achievement badges
- Account management

---

## 🛠️ Tech Stack

| Category | Technology |
|----------|------------|
| **Framework** | Flutter 3.38+ |
| **State Management** | flutter_bloc, Provider |
| **Navigation** | go_router |
| **Backend** | Firebase (Auth, Firestore) |
| **Maps** | Google Maps Flutter |
| **Health** | Pedometer (native sensors) |
| **Music** | Spotify Web API + OAuth |
| **Storage** | Hive, SharedPreferences, SecureStorage |
| **Charts** | fl_chart |
| **Animations** | flutter_animate, Lottie |

---

## 🚀 Getting Started (For Developers)

### Prerequisites
- Flutter 3.38+
- Android Studio / VS Code
- Firebase project
- Spotify Developer account
- Google Maps API key

### Setup

1. **Clone the repo**
```bash
git clone https://github.com/yunusemre274/Healtiefy.git
cd Healtiefy
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Configure environment**
```bash
# Copy example files
cp .env.example .env
cp android/secrets.properties.example android/secrets.properties

# Edit with your API keys
```

4. **Run the app**
```bash
flutter run
```

### Environment Variables

Create `.env` in project root:
```env
SPOTIFY_CLIENT_ID=your_spotify_client_id
SPOTIFY_REDIRECT_URI=healtiefy://callback/
GOOGLE_MAPS_API_KEY=your_google_maps_key
API_BASE_URL=https://api.spotify.com/v1
```

Create `android/secrets.properties`:
```properties
GOOGLE_MAPS_API_KEY=your_google_maps_key
SPOTIFY_CLIENT_ID=your_spotify_client_id
SPOTIFY_REDIRECT_URI=healtiefy://callback/
```

---

## 📁 Project Structure

```
lib/
├── core/
│   ├── config/          # Environment configuration
│   ├── constants/       # App constants, strings
│   ├── router/          # GoRouter setup
│   └── theme/           # Colors, typography
├── data/
│   └── models/          # Data models
├── features/
│   ├── auth/            # Login, signup
│   ├── dashboard/       # Main dashboard
│   ├── map/             # GPS tracking
│   ├── progress/        # Stats & history
│   ├── spotify/         # Music integration
│   ├── account/         # Profile & settings
│   └── onboarding/      # First-time setup
├── services/
│   ├── ai_service.dart          # AI tips & analysis
│   ├── health_service.dart      # Health calculations
│   ├── spotify_service.dart     # Spotify API
│   ├── step_tracking_service.dart # Pedometer
│   └── storage_service.dart     # Local storage
└── widgets/             # Reusable UI components
```

---

## 🧪 Testing

### Install Test APK
1. Download `app-release.apk` from `build/app/outputs/flutter-apk/`
2. Transfer to your Android device
3. Enable "Install unknown apps" for your file manager
4. Install and enjoy!

### Build Your Own
```bash
# Debug build
flutter build apk --debug

# Release build
flutter build apk --release
```

---

## 🐛 Known Issues & TODOs

- [ ] iOS support (coming soon)
- [ ] Social features (friend challenges)
- [ ] Wear OS companion app
- [ ] Apple Health / Google Fit sync
- [ ] Offline map tiles

---

## 🤝 Contributing

This is an open project! Feel free to:
1. Fork the repo
2. Create a feature branch
3. Make your changes
4. Submit a PR

---

## 📄 License

MIT License - do whatever you want with it!

---

## 🙏 Credits

- **UI Inspiration:** Duolingo, Apple Fitness+, Nike Run Club
- **Icons:** Material Design Icons
- **Charts:** FL Chart
- **Music:** Spotify Web API

---

**Made with 💚 and lots of walking**

*Questions? Issues? Open a GitHub issue or reach out!*
