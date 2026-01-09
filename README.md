# Personal Diary App

A simple and clean personal diary application built with Django, HTML, and CSS.

## Features

- **User Authentication**: Simple registration, login, and logout functionality
- **Private Diary Entries**: Each user's entries are completely private
- **Create & Delete Entries**: Add new diary entries with title, date, and content
- **Clean Design**: Simple, responsive interface with modern styling
- **SQLite Database**: Lightweight database for easy setup

## Project Structure

```
Django-personal-diary-app/
├── manage.py
├── requirements.txt
├── db.sqlite3 (created after migration)
├── diary_project/
│   ├── __init__.py
│   ├── settings.py
│   ├── urls.py
│   ├── wsgi.py
│   └── asgi.py
├── diary/
│   ├── __init__.py
│   ├── admin.py
│   ├── apps.py
│   ├── models.py
│   ├── views.py
│   └── urls.py
├── templates/
│   ├── base.html
│   ├── login.html
│   ├── register.html
│   ├── home.html
│   └── add_entry.html
└── static/
    └── style.css
```

## Setup Instructions

### 1. Install Dependencies

```bash
pip install -r requirements.txt
```

### 2. Run Migrations

```bash
python manage.py makemigrations
python manage.py migrate
```

### 3. Create a Superuser (Optional)

```bash
python manage.py createsuperuser
```

### 4. Run the Development Server

```bash
python manage.py runserver
```

### 5. Access the Application

Open your browser and navigate to:
- **Main App**: http://127.0.0.1:8000/
- **Admin Panel**: http://127.0.0.1:8000/admin/

## Usage

1. **Register**: Create a new account with a username and password
2. **Login**: Sign in with your credentials
3. **Add Entry**: Click "Add Entry" to write a new diary entry
4. **View Entries**: See all your diary entries on the home page
5. **Delete Entry**: Remove any entry you no longer want to keep
6. **Logout**: Sign out when you're done

## Features in Detail

### User Authentication
- Simple username/password registration
- Secure login system
- Session-based authentication
- Easy logout functionality

### Diary Entries
- **Title**: Give your entry a descriptive title
- **Date**: Automatically recorded when you create an entry
- **Content**: Write as much as you want about your day
- **Privacy**: Only you can see your own entries

### Navigation
- **Home**: View all your diary entries
- **My Entries**: Same as home (quick access)
- **Add Entry**: Create a new diary entry
- **Logout**: Sign out of your account

## Technologies Used

- **Backend**: Django 4.2+
- **Database**: SQLite
- **Frontend**: HTML5, CSS3
- **Authentication**: Django's built-in authentication system

## Security Notes

- Change the `SECRET_KEY` in `settings.py` before deploying to production
- Set `DEBUG = False` in production
- Configure `ALLOWED_HOSTS` properly for production
- Use strong passwords for user accounts
- Consider adding email verification for production use

## Screenshots

The app features:
- A clean purple gradient background
- White card-based design for entries
- Responsive layout that works on mobile devices
- Simple, intuitive navigation
- Beautiful hover effects on cards

## Contributing

Feel free to fork this project and submit pull requests for any improvements!

## License

This project is open source and available for educational purposes.
