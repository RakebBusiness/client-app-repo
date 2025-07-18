# Rakib - Flutter Supabase App

A Flutter application using Supabase for authentication and backend services.

## Setup Instructions

### 1. Supabase Configuration

1. Create a new project at [supabase.com](https://supabase.com)
2. Go to Settings > API in your Supabase dashboard
3. Copy your project URL and anon key
4. Update the values in `lib/main.dart`:

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

- `supabase_flutter`: Supabase client for Flutter
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