# MultiAdScraper - Google Ad Manager Ad Capture System

A comprehensive system for capturing ads from Google Ad Manager and distributing them to digital displays in venues.

## Features

- Multiple Ad Unit support with individual configurations
- Custom targeting parameters for precise ad selection
- **Dual format support**: JPEG images and MP4 videos
- Automated ad capture at configurable intervals
- Manual refresh capabilities
- Web-based administration interface
- Docker support for easy deployment
- Integration-ready output for CMS systems

## Quick Start with Docker

### Prerequisites

- Docker and Docker Compose installed
- At least 2GB RAM available
- Internet connection for downloading dependencies

### 1. Clone/Download Files

Create a new directory and save these files:

```
multi-ad-scraper/
├── multi_ad_scraper.py
├── requirements.txt
├── Dockerfile
├── docker-compose.yml
├── config.json
├── templates/
│   └── index.html
└── README.md
```

### 2. Run with Docker Compose

```bash
# Build and start the container
docker-compose up -d

# View logs
docker-compose logs -f

# Stop the system
docker-compose down
```

### 3. Access the Web Interface

Open your browser and go to: `http://localhost:5000`

## Manual Installation (Without Docker)

### Prerequisites

- Python 3.11+
- pip
- At least 2GB RAM

### 1. Install Dependencies

```bash
# Install Python dependencies
pip install -r requirements.txt

# Install Playwright browsers
playwright install chromium
playwright install-deps chromium
```

### 2. Create Directory Structure

```bash
mkdir -p templates
mkdir -p ads_output
mkdir -p logs
```

### 3. Run the Application

```bash
python multi_ad_scraper.py
```

## Supported Ad Formats

The system automatically detects and handles two types of ads:

### 📸 **Image Ads (JPEG)**
- Banner ads, display ads, static images
- Automatically converted to high-quality JPEG format
- Supports all standard IAB ad sizes
- Optimized for digital display screens

### 🎥 **Video Ads (MP4)**
- Video banner ads, video display ads
- Downloads original MP4 files when possible
- Falls back to video screenshot if download fails
- Perfect for dynamic digital signage

## Getting Real Ad Units for Testing

Since Google Ad Manager requires authentication, you'll need to create a free account:

### Free Google Ad Manager Setup (5 minutes):

1. **Go to:** https://admanager.google.com
2. **Sign in** with any Google account (free)
3. **Create new network:**
   - Network name: "Test Network" (or any name)
   - Country: Your country
   - Currency: Your currency
4. **Create ad units:**
   - Go to **Inventory** > **Ad units** > **New ad unit**
   - Name: "Test Banner 320x50"
   - Size: 320x50 (or any size you want)
   - Click **Save**
5. **Copy the ad unit path** (e.g., `/123456789/test_banner`)
6. **Use this path** in our system

### Example Real Ad Unit Paths:
After creating your Google Ad Manager account, you'll get paths like:
- `/123456789/test_banner` - for banner ads
- `/123456789/restaurant_display` - for restaurant displays  
- `/123456789/retail_screens` - for retail screens

**Note:** Replace `123456789` with your actual network ID from Google Ad Manager.

### Global Configuration

The `config.json` file contains global settings:

- `server_port`: Web interface port (default: 5000)
- `headless`: Run browsers in headless mode (default: true)
- `base_refresh_interval`: Default refresh interval in seconds
- `base_output_folder`: Base directory for ad outputs

### Ad Unit Configuration

Each ad unit can be configured with:

- **Name**: Descriptive name for the ad unit
- **Ad Unit Path**: Google Ad Manager ad unit path (e.g., `/6355419/Travel/Europe`)
- **Size**: Ad dimensions in pixels [width, height]
- **Refresh Interval**: How often to capture ads (in seconds)
- **Output Folder**: Where to save captured ads
- **Custom Targeting**: Key-value pairs for ad targeting

### Custom Targeting Examples

```json
{
    "location": "warsaw",
    "venue_type": "restaurant",
    "audience": ["premium", "adult"],
    "time_of_day": "evening"
}
```

## Web Interface Usage

### Adding Ad Units

1. Go to the "Ad Unity" tab
2. Click "Dodaj nowy Ad Unit"
3. Fill in the configuration
4. Add custom targeting parameters as needed
5. Save

### Managing Ad Units

- **Refresh**: Manually trigger ad capture for a specific unit
- **Edit**: Modify ad unit configuration
- **Delete**: Remove an ad unit
- **Refresh All**: Trigger manual refresh for all units

### Monitoring

The interface shows:
- Last captured ad preview
- Capture timestamps
- Ad unit status
- Configuration details

## API Endpoints

The system provides REST API endpoints:

- `GET /` - Web interface
- `POST /refresh/<unit_id>` - Manual refresh for specific unit
- `POST /refresh_all` - Refresh all units
- `GET /get_ad_units` - List all ad units
- `POST /add_ad_unit` - Add new ad unit
- `POST /update_ad_unit/<unit_id>` - Update ad unit
- `POST /delete_ad_unit/<unit_id>` - Delete ad unit



## Troubleshooting

### Common Issues

1. **Browser fails to start**
   - Ensure sufficient RAM (2GB+)
   - Check Docker memory limits
   - Verify Playwright installation

2. **Ads not loading**
   - Verify ad unit paths in Google Ad Manager
   - Check custom targeting configuration
   - Ensure internet connectivity

3. **Permission errors**
   - Check file/folder permissions
   - Ensure output directories are writable

### Logs

View application logs:

```bash
# Docker
docker-compose logs -f

# Manual installation
tail -f ad_scraper.log
```

### Debug Mode

Run in debug mode (shows browser):

1. Set `"headless": false` in config.json
2. Restart the application

## Performance Considerations

### Resource Usage

- **Memory**: ~500MB per browser instance
- **CPU**: Moderate during ad capture
- **Disk**: Depends on capture frequency and retention

### Optimization Tips

1. **Adjust refresh intervals** based on ad change frequency
2. **Limit concurrent ad units** to prevent resource exhaustion
3. **Regular cleanup** of old ad files
4. **Monitor disk space** for output folders

## Security Considerations

- Run in isolated Docker container
- Restrict network access if possible
- Regular updates of dependencies
- Monitor for unusual activity

## Production Deployment

### Recommended Setup

```yaml
# docker-compose.prod.yml
version: '3.8'
services:
  multi-ad-scraper:
    build: .
    restart: always
    mem_limit: 4g
    cpus: 2.0
    volumes:
      - /data/ads:/app/ads_output
      - /config/scraper.json:/app/config.json
    environment:
      - PYTHONUNBUFFERED=1
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
```

### Monitoring

Set up monitoring for:
- Container health
- Disk space usage
- Ad capture success rates
- Application logs

## Support

For technical support:
1. Check logs for error messages
2. Verify configuration settings
3. Test with minimal ad unit setup
4. Contact system administrator

## License

Commercial license - contact for licensing details.