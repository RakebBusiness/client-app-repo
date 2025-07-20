# Rakib - Flutter Supabase App

A Flutter ride-sharing application using Supabase for authentication and backend services, with Google Maps integration.

## Setup Instructions

### 0. Testing with Real Supabase Data

The app is configured to work with test data in the **Lakhdaria, Bouira** area. Here's how to test:

#### **Quick Test Steps:**
1. **Run the app** - Test data will be created automatically
2. **Allow location permissions** when prompted
3. **Wait for map to load** - you'll see blue rider markers
4. **Tap rider markers** to see details
5. **Use "Book a Ride" button** to test booking flow

#### **Test Data Created:**
- **6 test riders** in Lakhdaria area (within 10km)
- **6 test motorcycles** with realistic data
- **All riders online and verified** for immediate testing

#### **Testing Features:**
- ✅ **Real-time rider locations** on map
- ✅ **Distance calculations** from your location
- ✅ **Rider ratings and details**
- ✅ **Location selection** for pickup/destination
- ✅ **Booking flow** with price estimation

### 0. Google Maps API Setup

1. Go to the [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the following APIs:
   - Maps SDK for Android
   - Maps SDK for iOS
   - Places API
   - Geocoding API
4. Create API credentials (API Key)
5. Restrict the API key to your app's package name for security
6. Replace `YOUR_GOOGLE_MAPS_API_KEY` in the following files:
   - `android/app/src/main/AndroidManifest.xml`
   - `ios/Runner/AppDelegate.swift`
   - `lib/screens/booking/ride_booking_screen.dart`

### 1. Supabase Configuration

1. Create a new project at [supabase.com](https://supabase.com)
2. Go to Settings > API in your Supabase dashboard
3. Copy your project URL and anon key
4. Replace `YOUR_SUPABASE_URL` and `YOUR_SUPABASE_ANON_KEY` in `lib/main.dart`:

```dart
await Supabase.initialize(
  url: 'YOUR_SUPABASE_URL',
  anonKey: 'YOUR_SUPABASE_ANON_KEY',
);
```

### 2. Phone Authentication Setup

1. In your Supabase dashboard, go to Authentication > Settings
2. Enable Phone authentication
3. Configure your SMS provider (Twilio recommended)
4. Add your phone number format validation rules

### 3. Database Setup (Optional)

If you need to store additional user data:

1. Go to the SQL Editor in Supabase
2. Create a profiles table:

```sql
create table profiles (
  id uuid references auth.users on delete cascade,
  display_name text,
  phone text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  primary key (id)
);

-- Enable RLS
alter table profiles enable row level security;

-- Create policies
create policy "Users can view own profile" 
  on profiles for select 
  using (auth.uid() = id);

create policy "Users can update own profile" 
  on profiles for update 
  using (auth.uid() = id);
```

### 4. Running the App

```bash
flutter pub get
flutter run
```

## Features

- Phone number authentication with OTP
- User profile management
- Clean architecture with Provider state management
- Responsive UI design
- Error handling and loading states

## Dependencies

- `google_maps_flutter`: Google Maps integration
- `geolocator`: Location services
- `provider`: State management
- `pin_code_fields`: OTP input UI

## Project Structure

```
lib/
├── core/
│   └── routes.dart
├── models/
│   └── auth_state.dart
├── screens/
│   ├── auth/
│   ├── home/
│   └── otp/
├── services/
│   └── auth_service.dart
├── widgets/
└── main.dart
```