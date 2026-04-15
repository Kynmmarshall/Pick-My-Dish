# 🍽️ Pick My Dish

**Your Personal Recipe Companion - Cook Smarter, Not Harder**

![App Screenshots](https://via.placeholder.com/800x400?text=Pick+My+Dish+Screenshots)

## 👥 **Developed By**
**Kamdeu Yamdjeuson Neil Marshall** & **Tuheu Tchoubi Pempem Moussa Fahdil**  
*Final Year Computer Science Students*

## 📱 About The App

Pick My Dish is an intelligent recipe management application that helps you discover, save, and organize recipes based on your mood, available ingredients, and cooking preferences. Whether you're a busy professional, a cooking enthusiast, or just looking for meal inspiration, Pick My Dish makes cooking enjoyable and personalized.

### ✨ Key Features

- **🎭 Mood-Based Recipes** - Find recipes that match your current emotions (Happy, Comfort, Energetic, etc.)
- **🥗 Ingredient Filtering** - Cook with what you already have in your kitchen
- **⏱️ Time-Smart Suggestions** - Get recipes based on available cooking time
- **❤️ Personalized Favorites** - Save and organize your favorite recipes
- **👤 User Profiles** - Track your cooking history and preferences
- **📱 Cross-Platform** - Works seamlessly on iOS and Android
- **🌐 Cloud Sync** - Access your recipes from any device

## 📲 **Download App**

### **🌐 Download APK**
[**🔗 Download Pick My Dish APK**](https://pickmydish.duckdns.org)

### **📱 Direct Installation**
1. Visit: **https://pickmydish.duckdns.org**
2. Download the latest APK file
3. Enable "Install from unknown sources" in settings
4. Install and enjoy!

### **📥 Alternative Download**
```bash
# Direct APK download
wget https://pickmydish.duckdns.org/latest.apk

# Or via curl
curl -O https://pickmydish.duckdns.org/app-release.apk
```

## 🛠️ Tech Stack

### Frontend
- **Flutter 3.0+** - Beautiful, natively compiled applications
- **Dart 3.0** - Client-optimized language for fast apps
- **Provider** - State management solution

### Backend
- **Node.js** - Scalable server runtime
- **Express.js** - Web application framework
- **PostgreSQL** - Relational database
- **JWT** - Secure authentication

### Architecture
```
📱 Flutter Frontend → 🌐 REST API → 🗄️ PostgreSQL Database
     │                       │
     ├── State Management    ├── User Authentication
     ├── UI Components       ├── Recipe Management  
     └── Local Storage       └── File Upload (Images)
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.0+
- Dart 3.0+
- Node.js 16+
- PostgreSQL 14+
- Android Studio / Xcode (for mobile development)

### Installation

#### 1. Clone the Repository
```bash
git clone https://github.com/yourusername/pick-my-dish.git
cd pick-my-dish
```

#### 2. Flutter Setup
```bash
# Install dependencies
flutter pub get

# Run the app
flutter run
```

#### 3. Backend Setup
```bash
cd backend
npm install

# Set up environment variables
cp .env.example .env
# Edit .env with your database credentials

# Run database migrations
npm run migrate

# Start the server
npm start
```

### Environment Variables
```env
# Backend (.env)
DATABASE_URL=postgresql://user:password@localhost:5432/pickmydish
JWT_SECRET=your_jwt_secret_here
PORT=3000
UPLOAD_DIR=./uploads

# Flutter (lib/Services/api_service.dart)
BASE_URL=http://localhost:3000  # Development
# BASE_URL=http://your-vps-ip:3000  # Production
```

## 📁 Project Structure

```
pick-my-dish/
├── lib/
│   ├── Models/              # Data models
│   │   ├── recipe_model.dart
│   │   └── user_model.dart
│   ├── Providers/           # State management
│   │   ├── recipe_provider.dart
│   │   └── user_provider.dart
│   ├── Screens/            # UI Screens
│   │   ├── home_screen.dart
│   │   ├── login_screen.dart
│   │   ├── recipe_screen.dart
│   │   └── ...
│   ├── Services/           # API services
│   │   ├── api_service.dart
│   │   └── database_service.dart
│   ├── Widgets/            # Reusable widgets
│   │   ├── cached_image.dart
│   │   └── ingredient_selector.dart
│   └── main.dart           # App entry point
├── backend/
│   ├── src/
│   │   ├── controllers/    # API controllers
│   │   ├── middleware/     # Auth middleware
│   │   ├── models/         # Database models
│   │   └── routes/         # API routes
│   └── server.js          # Server entry point
└── tests/                 # Test suites
```

## 🧪 Testing

### Running Tests
```bash
# Unit Tests
flutter test

# Integration Tests
flutter test integration_test/

# With Coverage
flutter test --coverage
```

### Test Coverage
Current coverage: **68.5%** (Improving daily!)

## 🎨 UI/UX Design

### Design Principles
- **Minimalist Interface** - Clean, distraction-free cooking experience
- **Dark Mode Focus** - Easy on eyes during cooking
- **Intuitive Navigation** - Three-tap recipe discovery
- **Visual Hierarchy** - Clear information presentation

### Color Palette
```dart
Primary: #FF9800 (Orange) - Energy, Creativity
Background: #000000 (Black) - Elegance, Focus
Text: #FFFFFF (White) - Readability
Accent: #2958FF (Blue) - Trust, Calm
```

## 📊 Database Schema

### Core Tables
```sql
-- Users
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE,
    email VARCHAR(100) UNIQUE,
    password_hash TEXT,
    profile_image_path TEXT,
    is_admin BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Recipes
CREATE TABLE recipes (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    user_id INTEGER REFERENCES users(id),
    category VARCHAR(50),
    cooking_time VARCHAR(20),
    calories INTEGER,
    image_path TEXT,
    ingredients JSONB,
    instructions JSONB,
    emotions JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Favorites
CREATE TABLE favorites (
    user_id INTEGER REFERENCES users(id),
    recipe_id INTEGER REFERENCES recipes(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, recipe_id)
);
```

## 🔄 API Endpoints

### Authentication
```
POST   /api/auth/register    # Register new user
POST   /api/auth/login       # User login
```

### Recipes
```
GET    /api/recipes          # Get all recipes
POST   /api/recipes          # Create new recipe
GET    /api/recipes/:id      # Get specific recipe
PUT    /api/recipes/:id      # Update recipe
DELETE /api/recipes/:id      # Delete recipe
```

### Users
```
GET    /api/users/favorites  # Get user favorites
POST   /api/users/favorites  # Add favorite
DELETE /api/users/favorites  # Remove favorite
PUT    /api/users/username   # Update username
PUT    /api/users/profile-picture  # Update profile picture
```

## 🚀 Deployment

### Mobile Apps
```bash
# Build for Android
flutter build apk --release

# Build for iOS
flutter build ios --release

# Build for Web
flutter build web --release
```

### Backend Deployment (VPS)
```bash
# Using PM2 for process management
pm2 start server.js --name pick-my-dish-api

# NGINX Reverse Proxy
server {
    listen 80;
    server_name yourdomain.com;
    
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

## 📈 Performance Metrics

- **App Size:** < 30MB (Android APK)
- **Startup Time:** < 2 seconds
- **API Response:** < 200ms average
- **Image Loading:** Cached for instant display
- **Database Queries:** Optimized with indexes

## 🤝 Contributing

We love contributions! Here's how you can help:

1. **Fork the repository**
2. **Create a feature branch**
   ```bash
   git checkout -b feature/amazing-feature
   ```
3. **Commit your changes**
   ```bash
   git commit -m 'Add amazing feature'
   ```
4. **Push to the branch**
   ```bash
   git push origin feature/amazing-feature
   ```
5. **Open a Pull Request**

### Code Standards
- Follow Dart/Flutter style guide
- Write meaningful commit messages
- Add tests for new features
- Update documentation as needed

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Flutter Community** for amazing packages and support
- **Recipe API Providers** for inspiration
- **Beta Testers** for valuable feedback
- **Open Source Contributors** for making this possible

## 📞 Support

Having issues? Here's how to get help:

1. **Check the [Issues](https://github.com/yourusername/pick-my-dish/issues)** - Your problem might already be solved
2. **Create a New Issue** - Provide detailed information
3. **Email Support** - support@pickmydish.app

---

<div align="center">

## **🌟 Download Now!**
[**🔗 https://pickmydish.duckdns.org**](https://pickmydish.duckdns.org)

---

**Developed with ❤️ by:**  
**Kamdeu Yamdjeuson Neil Marshall** & **Tuheu Tchoubi Pempem Moussa Fahdil**  
*Final Year Computer Science Project*

⭐ Star us on GitHub if you like this project!
</div>