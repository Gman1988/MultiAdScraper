#!/bin/bash

# FileBrowser Setup Script with Custom Credentials

echo "=== FileBrowser Setup ==="

# Default credentials (change these!)
FB_USERNAME="${FB_USERNAME:-adscraper}"
FB_PASSWORD="${FB_PASSWORD:-SecurePass123!}"

echo "Setting up FileBrowser with custom credentials..."
echo "Username: $FB_USERNAME"
echo "Password: [hidden]"

# Create filebrowser config if it doesn't exist
if [ ! -f "filebrowser-config.json" ]; then
    cat > filebrowser-config.json << 'EOF'
{
  "port": 80,
  "baseURL": "",
  "address": "0.0.0.0",
  "log": "stdout",
  "database": "/database.db",
  "root": "/srv",
  "auth": {
    "method": "json"
  },
  "branding": {
    "name": "MultiAdScraper Files",
    "disableExternal": true
  },
  "commands": [],
  "shell": [],
  "rules": [
    {
      "allow": true,
      "regex": true,
      "raw": "\\.(jpg|jpeg|mp4|png|log|txt|json)$"
    }
  ],
  "signup": false,
  "createUserDir": false
}
EOF
    echo "✓ Created filebrowser-config.json"
fi

# Remove existing database to start fresh
if [ -f "filebrowser.db" ]; then
    rm filebrowser.db
    echo "✓ Removed existing database"
fi

# Start filebrowser container temporarily to create user
echo "Creating FileBrowser user..."

# Pull the image first
docker pull filebrowser/filebrowser:latest

# Create user using docker run
docker run --rm \
  -v $(pwd)/filebrowser.db:/database.db \
  -v $(pwd)/filebrowser-config.json:/.filebrowser.json \
  filebrowser/filebrowser:latest \
  users add "$FB_USERNAME" "$FB_PASSWORD" --perm.admin

if [ $? -eq 0 ]; then
    echo "✓ FileBrowser user created successfully!"
    echo ""
    echo "🌐 Access FileBrowser at: http://localhost:8080"
    echo "👤 Username: $FB_USERNAME"
    echo "🔑 Password: $FB_PASSWORD"
    echo ""
    echo "📁 Available folders:"
    echo "  - /ads_output - Your captured ads"
    echo "  - /logs - System logs"
    echo ""
    echo "Now run: docker-compose up -d"
else
    echo "❌ Failed to create FileBrowser user"
    exit 1
fi