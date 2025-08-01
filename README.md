# 🎯 MultiAdScraper

**Professional Google Ad Manager ad capture system for digital signage and content management.**

Automatically capture ads from Google Ad Manager and distribute them to digital displays in restaurants, retail stores, and other venues.

[![Docker](https://img.shields.io/badge/Docker-Ready-blue)](https://www.docker.com/)
[![Python](https://img.shields.io/badge/Python-3.11+-green)](https://python.org)
[![License](https://img.shields.io/badge/License-Commercial-orange)](LICENSE)

## 🚀 Quick Start

### **One-Command Deployment**

```bash
# Clone and run (requires Docker Desktop)
git clone https://github.com/Gman1988/MultiAdScraper.git
cd MultiAdScraper
docker-compose up --build -d

# Access: http://localhost:5000
```

### **Windows One-Click Setup**

```powershell
# Download and run automatic installer
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Gman1988/MultiAdScraper/main/deploy.ps1" -OutFile "deploy.ps1"
powershell -ExecutionPolicy Bypass -File deploy.ps1
```

## ✨ Features

- 🎬 **Dual Format Support**: Automatic JPEG image and MP4 video capture
- 🎯 **Custom Targeting**: Key-value targeting for precise ad selection
- 🔄 **Multi-Unit Management**: Support for unlimited ad units with individual configurations
- ⏰ **Flexible Scheduling**: Configurable refresh intervals per ad unit
- 🌐 **Web Interface**: Full-featured admin panel for management
- 📁 **Organized Output**: Dedicated folders per ad unit for easy CMS integration
- 🐳 **Docker Ready**: Containerized deployment for any environment
- 🔧 **API Integration**: REST endpoints for external system integration
- 📊 **Real-time Monitoring**: Live preview and status monitoring
- 🎨 **Professional UI**: Modern, responsive web interface

## 📋 Requirements

### **System Requirements**
- **OS**: Windows 10/11, macOS, Linux
- **RAM**: 4GB minimum, 8GB recommended
- **Storage**: 5GB available space
- **Network**: Stable internet connection

### **Software Requirements**
- **Docker Desktop** (recommended) OR Python 3.11+
- **Modern web browser**
- **Google Ad Manager account** (free)

## 🔧 Installation

### **Method 1: Docker (Recommended)**

**Prerequisites:**
1. Install [Docker Desktop](https://www.docker.com/products/docker-desktop/)
2. Ensure Docker is running (whale icon in system tray)

**Installation:**
```bash
# Clone repository
git clone https://github.com/Gman1988/MultiAdScraper.git
cd MultiAdScraper

# Start system
docker-compose up --build -d

# Verify installation
docker-compose ps
```

**Access**: http://localhost:5000

### **Method 2: Local Python Installation**

```bash
# Clone repository
git clone https://github.com/Gman1988/MultiAdScraper.git
cd MultiAdScraper

# Install dependencies
pip install -r requirements.txt
playwright install chromium

# Create directories
mkdir -p ads_output logs templates

# Run application
python multi_ad_scraper.py
```

### **Method 3: Windows Automatic Setup**

Download and run the automatic installer:
- [deploy.ps1](deploy.ps1) - PowerShell automatic installer
- [deploy.bat](deploy.bat) - Command Prompt installer

## 🎯 Google Ad Manager Setup

### **1. Create Free Account**
1. Go to [Google Ad Manager](https://admanager.google.com)
2. Sign in with any Google account (free)
3. Create new network (e.g., "Your Business Name")
4. Choose your country and currency

### **2. Create Ad Units**
1. Navigate to **Inventory** → **Ad units**
2. Click **New ad unit**
3. Configure:
   - **Name**: Descriptive name (e.g., "Restaurant Display 1")
   - **Size**: Match your display dimensions (e.g., 1920x1080)
   - **Ad unit type**: Display
4. Copy the **ad unit path** (e.g., `/123456789/restaurant_display`)

### **3. Add to MultiAdScraper**
1. Open http://localhost:5000
2. Click **"Add New Ad Unit"**
3. Enter your ad unit details:
   - **Name**: Friendly name for identification
   - **Ad Unit Path**: Path from Google Ad Manager
   - **Size**: Width x Height in pixels
   - **Refresh Interval**: How often to capture (seconds)
   - **Output Folder**: Subfolder name for captured ads
   - **Custom Targeting**: Key-value pairs for ad targeting

## 🎨 Web Interface Guide

### **Dashboard Overview**
- **Ad Units Tab**: Manage all your ad units
- **Global Configuration**: System-wide settings
- **Real-time Preview**: See captured ads instantly
- **Manual Controls**: Force refresh any ad unit

### **Adding Ad Units**
1. Click **"Add New Ad Unit"**
2. Fill in configuration:
   ```
   Name: Restaurant Main Display
   Ad Unit Path: /123456789/restaurant/main
   Size: 1920 x 1080
   Refresh Interval: 300 (5 minutes)
   Output Folder: restaurant_main
   ```
3. Add **Custom Targeting** (optional):
   ```
   location: warsaw
   venue_type: restaurant
   time_of_day: dinner
   audience: premium
   ```
4. Click **Save**

### **Managing Ad Units**
- **🔄 Refresh**: Manual ad capture
- **✏️ Edit**: Modify configuration
- **🗑️ Delete**: Remove ad unit
- **👁️ Preview**: View latest captured ad

## 📁 File Structure

```
MultiAdScraper/
├── 🐍 multi_ad_scraper.py      # Main application
├── 🌐 templates/
│   └── index.html              # Web interface
├── 📋 requirements.txt         # Python dependencies
├── 🐳 Dockerfile              # Container configuration
├── 🐳 docker-compose.yml       # Service orchestration
├── ⚙️ config.json             # System configuration (auto-created)
├── 📂 ads_output/             # Captured ads (auto-created)
│   ├── restaurant_main/
│   │   ├── ad_unit1_20241220_143022.jpg
│   │   ├── ad_unit1_20241220_143322.mp4
│   │   └── ad_unit1_20241220_143622.jpg
│   └── retail_display/
│       ├── ad_unit2_20241220_143025.mp4
│       └── ad_unit2_20241220_143325.jpg
└── 📜 logs/                   # System logs (auto-created)
    └── ad_scraper.log
```

## 🎬 Supported Ad Formats

### **📸 Image Ads (JPEG)**
- Static banner ads, display ads, images
- Automatically converted to high-quality JPEG
- Optimized for digital displays
- Supports all standard IAB ad sizes

### **🎥 Video Ads (MP4)**
- Video banners, animated displays
- Downloads original MP4 files when possible
- Falls back to video screenshots if needed
- Perfect for dynamic digital signage

**File naming**: `ad_{unit_id}_{timestamp}.{jpg|mp4}`

## 🔗 CMS Integration

### **Direct File Access**
Your CMS can directly monitor the output folders:

```python
import os
import glob

def get_latest_ads():
    """Get latest ad files for each unit"""
    ads = {}
    
    for unit_folder in os.listdir('ads_output'):
        unit_path = f'ads_output/{unit_folder}'
        if os.path.isdir(unit_path):
            # Get newest file
            files = glob.glob(f'{unit_path}/*.(jpg|mp4)')
            if files:
                latest = max(files, key=os.path.getctime)
                ads[unit_folder] = {
                    'path': latest,
                    'type': 'video' if latest.endswith('.mp4') else 'image',
                    'timestamp': os.path.getctime(latest)
                }
    
    return ads

# Usage
latest_ads = get_latest_ads()
for unit, info in latest_ads.items():
    print(f"{unit}: {info['type']} - {info['path']}")
```

### **API Integration**
Use REST endpoints for real-time integration:

```bash
# Get all ad units with latest info
curl http://localhost:5000/get_ad_units

# Get specific ad unit
curl http://localhost:5000/get_ad_unit/{unit_id}

# Trigger manual refresh
curl -X POST http://localhost:5000/refresh/{unit_id}

# Refresh all ad units
curl -X POST http://localhost:5000/refresh_all
```

## 🛠️ Management Commands

### **Docker Commands**
```bash
# Check status
docker-compose ps

# View logs (follow mode)
docker-compose logs -f

# Stop system
docker-compose down

# Start system
docker-compose up -d

# Restart with updates
docker-compose up --build -d

# Update from GitHub
git pull
docker-compose up --build -d
```

### **Direct File Access**
```bash
# View captured ads
ls -la ads_output/*/

# Monitor logs
tail -f logs/ad_scraper.log

# Check latest captures
find ads_output -name "*.jpg" -o -name "*.mp4" | head -10

# Watch for new files
watch -n 5 "find ads_output -type f | wc -l"
```

## ⚙️ Configuration

### **Global Settings**
Edit via web interface or modify `config.json`:

```json
{
  "global_config": {
    "server_port": 5000,
    "headless": true,
    "base_refresh_interval": 300,
    "base_output_folder": "ads_output"
  }
}
```

### **Ad Unit Configuration**
Each ad unit supports:

| Setting | Description | Example |
|---------|-------------|---------|
| **Name** | Friendly identifier | "Restaurant Main Display" |
| **Ad Unit Path** | Google Ad Manager path | "/123456789/restaurant/main" |
| **Size** | Dimensions in pixels | [1920, 1080] |
| **Refresh Interval** | Capture frequency (seconds) | 300 |
| **Output Folder** | Dedicated subfolder | "restaurant_main" |
| **Custom Targeting** | Key-value targeting | {"location": "warsaw"} |

### **Custom Targeting Examples**
```json
{
  "location": "warsaw",
  "venue_type": "restaurant", 
  "time_of_day": "dinner",
  "audience": ["premium", "adult"],
  "device": "digital_display",
  "content_type": "promotional"
}
```

## 🔒 Production Deployment

### **Security Considerations**
- Run in isolated Docker containers
- Use internal networks when possible
- Regular system updates
- Monitor resource usage
- Backup configurations

### **Performance Optimization**
- Adjust refresh intervals based on ad change frequency
- Limit concurrent ad units to prevent resource exhaustion
- Regular cleanup of old ad files
- Monitor disk space usage

### **Scaling for Multiple Locations**
```bash
# Location 1
git clone https://github.com/Gman1988/MultiAdScraper.git location1
cd location1 && docker-compose up -d

# Location 2  
git clone https://github.com/Gman1988/MultiAdScraper.git location2
cd location2 && docker-compose up -d

# Centralized monitoring
# Each location runs on different ports or servers
```

## 🐛 Troubleshooting

### **Common Issues**

**❌ Docker not starting**
```bash
# Check Docker Desktop is running
docker --version

# Restart Docker Desktop
# Check system resources (RAM/disk space)
```

**❌ Port 5000 already in use**
```bash
# Change port in docker-compose.yml
ports:
  - "5001:5000"  # Access via localhost:5001
```

**❌ Ads not loading**
```bash
# Check ad unit paths in Google Ad Manager
# Verify custom targeting configuration
# Check container logs: docker-compose logs -f
```

**❌ Permission errors**
```bash
# Ensure output directories are writable
chmod 755 ads_output logs

# Check Docker container permissions
docker-compose logs multi-ad-scraper
```

### **Log Analysis**
```bash
# View recent logs
docker-compose logs --tail=50 multi-ad-scraper

# Follow logs in real-time
docker-compose logs -f

# Check specific ad unit activity
grep "unit_name" logs/ad_scraper.log
```

## 📊 API Reference

### **Endpoints**

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/` | Web interface |
| `GET` | `/get_ad_units` | List all ad units |
| `GET` | `/get_ad_unit/{id}` | Get specific ad unit |
| `POST` | `/add_ad_unit` | Add new ad unit |
| `POST` | `/update_ad_unit/{id}` | Update ad unit |
| `POST` | `/delete_ad_unit/{id}` | Delete ad unit |
| `POST` | `/refresh/{id}` | Manual refresh ad unit |
| `POST` | `/refresh_all` | Refresh all ad units |
| `POST` | `/update_global_config` | Update global settings |

### **Example API Usage**
```python
import requests

# Add new ad unit
new_unit = {
    "name": "Retail Display",
    "ad_unit_path": "/123456789/retail",
    "ad_unit_size": [1920, 1080],
    "refresh_interval": 180,
    "output_folder": "retail_display",
    "custom_targeting": {
        "location": "krakow",
        "venue_type": "retail"
    }
}

response = requests.post('http://localhost:5000/add_ad_unit', json=new_unit)
print(response.json())
```

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

## 📄 License

This project is licensed under a Commercial License. Contact for licensing details.

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/Gman1988/MultiAdScraper/issues)
- **Documentation**: This README
- **Updates**: Watch this repository for updates

## 🎯 Roadmap

- [ ] Dashboard analytics and reporting
- [ ] Multiple Google Ad Manager account support
- [ ] Advanced scheduling (time-based targeting)
- [ ] Cloud storage integration (AWS S3, Azure Blob)
- [ ] RESTful webhook notifications
- [ ] Mobile app for monitoring
- [ ] Advanced image/video processing filters

---

**Made with ❤️ for digital signage professionals**

⭐ **Star this repository if it helps your business!**