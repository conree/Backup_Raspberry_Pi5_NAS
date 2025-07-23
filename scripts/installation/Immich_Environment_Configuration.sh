# Immich Environment Configuration
# Copy this file to .env and update the paths to match your setup

# The location where your uploaded files are stored
# Update this UUID to match your photos drive
UPLOAD_LOCATION=/srv/dev-disk-by-uuid-cccccccc-dddd-eeee-ffff-333333333333/immich/upload

# Optional: The location of your existing photo library for import
# Uncomment and update if you have existing photos to import
# EXTERNAL_PATH=/srv/dev-disk-by-uuid-cccccccc-dddd-eeee-ffff-333333333333/photo_collection

# Version of Immich to use
IMMICH_VERSION=release

# Database settings
# Change these to secure values
DB_PASSWORD=your_secure_database_password_here
DB_USERNAME=postgres
DB_DATABASE_NAME=immich

# Redis settings (usually no need to change)
REDIS_HOSTNAME=immich_redis

# Optional: Public login page message
PUBLIC_LOGIN_PAGE_MESSAGE=Welcome to the Home Photo Server

# Machine Learning settings
# Set to false to disable machine learning features (saves resources)
IMMICH_MACHINE_LEARNING_ENABLED=true

# Face detection and recognition
IMMICH_MACHINE_LEARNING_FACIAL_RECOGNITION_ENABLED=true

# Object detection and tagging
IMMICH_MACHINE_LEARNING_CLIP_ENABLED=true

# Log level (error, warn, log, debug, verbose)
LOG_LEVEL=log

# Reverse geocoding (requires internet connection)
DISABLE_REVERSE_GEOCODING=false

# Upload file extensions (modify as needed)
# IMMICH_MEDIA_LOCATION=/usr/src/app/upload

# Optional: Custom timezone (if different from system)
# TZ=America/New_York

# Optional: Disable password login (if using OAuth only)
# DISABLE_PASSWORD_LOGIN=false

# Optional: Enable public sharing
# IMMICH_PUBLIC_SHARING_ENABLED=true

# Optional: Server external URL (for email links, etc.)
# IMMICH_SERVER_URL=https://photos.yourdomain.com

# Optional: Email settings for notifications
# SMTP_HOSTNAME=smtp.gmail.com
# SMTP_PORT=587
# SMTP_USERNAME=your-email@gmail.com
# SMTP_PASSWORD=your-app-password
# SMTP_FROM=your-email@gmail.com
# SMTP_REPLY_TO=noreply@yourdomain.com

# Security settings
# Generate a secure random key: openssl rand -base64 32
JWT_SECRET=your_jwt_secret_key_here_replace_with_random_string

# Optional: OAuth settings (Google, Apple, etc.)
# Uncomment and configure if you want OAuth login
# OAUTH_ENABLED=true
# OAUTH_ISSUER_URL=https://accounts.google.com
# OAUTH_CLIENT_ID=your-google-client-id
# OAUTH_CLIENT_SECRET=your-google-client-secret
# OAUTH_SCOPE=openid email profile
# OAUTH_AUTO_REGISTER=true
# OAUTH_AUTO_LAUNCH=false
# OAUTH_BUTTON_TEXT=Login with Google

# Storage template (how files are organized)
# Default: {{y}}/{{y}}-{{MM}}-{{dd}}/{{filename}}
# Options: {{y}} = year, {{MM}} = month, {{dd}} = day, {{filename}} = original filename
IMMICH_STORAGE_TEMPLATE={{y}}/{{y}}-{{MM}}-{{dd}}/{{filename}}

# Backup settings
# Automatically backup uploaded files to another location
# IMMICH_BACKUP_LOCATION=/srv/dev-disk-by-uuid-xxx/immich-backup

# Performance settings
# Job concurrency (adjust based on your Pi 5 performance)
IMMICH_JOB_CONCURRENCY=2

# Thumbnail quality (1-100, higher = better quality but larger files)
IMMICH_THUMBNAIL_QUALITY=80

# Preview quality for web interface
IMMICH_PREVIEW_QUALITY=90

# Optional: Custom asset upload location per user
# IMMICH_MEDIA_LOCATION=/usr/src/app/upload

# Optional: Custom backup location
# BACKUP_LOCATION=/usr/src/app/backup

# Development/Debug settings (set to false for production)
IMMICH_ENV=production
NODE_ENV=production

# Optional: Custom theme
# IMMICH_THEME=dark

# Optional: Map provider (openstreetmap or mapbox)
# MAP_TILE_URL=https://tile.openstreetmap.org/{z}/{x}/{y}.png

# Performance: Enable/disable features to save resources on Pi 5
# Set to false to disable resource-intensive features
IMMICH_MACHINE_LEARNING_ENABLED=true
IMMICH_BACKGROUND_TASK=true
IMMICH_THUMBNAIL_GENERATION=true

# Optional: Custom ffmpeg settings for video processing
# IMMICH_FFMPEG_CRF=23
# IMMICH_FFMPEG_PRESET=medium
# IMMICH_FFMPEG_TARGET_RESOLUTION=1080p

# Optional: Security headers
# IMMICH_SECURITY_HEADERS_ENABLED=true

# Optional: Rate limiting
# IMMICH_RATE_LIMIT_ENABLED=true
# IMMICH_RATE_LIMIT_TTL=60
# IMMICH_RATE_LIMIT_MAX=100