#!/bin/bash

# MultiAdScraper Startup Script

set -e

echo "=== MultiAdScraper Startup ==="

# Function to check if Docker is installed
check_docker() {
    if command -v docker &> /dev/null && command -v docker-compose &> /dev/null; then
        echo "✓ Docker and Docker Compose found"
        return 0
    else
        echo "✗ Docker or Docker Compose not found"
        return 1
    fi
}

# Function to check if Python is installed
check_python() {
    if command -v python3 &> /dev/null; then
        echo "✓ Python 3 found"
        return 0
    else
        echo "✗ Python 3 not found"
        return 1
    fi
}

# Function to run with Docker
run_docker() {
    echo "Starting MultiAdScraper with Docker..."
    
    # Create necessary directories
    mkdir -p ads_output logs
    
    # Check if config.json exists
    if [ ! -f "config.json" ]; then
        echo "Creating default config.json..."
        cat > config.json << 'EOF'
{
    "global_config": {
        "server_port": 5000,
        "headless": true,
        "base_refresh_interval": 300,
        "base_output_folder": "ads_output"
    },
    "ad_units": []
}
EOF
    fi
    
    # Build and start
    docker-compose up --build -d
    
    echo "✓ MultiAdScraper started successfully!"
    echo "📱 Web interface: http://localhost:5000"
    echo "📋 View logs: docker-compose logs -f"
    echo "🛑 Stop system: docker-compose down"
}

# Function to run manually
run_manual() {
    echo "Starting MultiAdScraper manually..."
    
    # Create necessary directories
    mkdir -p ads_output logs templates
    
    # Check if config.json exists
    if [ ! -f "config.json" ]; then
        echo "Creating default config.json..."
        cat > config.json << 'EOF'
{
    "global_config": {
        "server_port": 5000,
        "headless": true,
        "base_refresh_interval": 300,
        "base_output_folder": "ads_output"
    },
    "ad_units": []
}
EOF
    fi
    
    # Install dependencies
    echo "Installing Python dependencies..."
    pip3 install -r requirements.txt
    
    # Install Playwright
    echo "Installing Playwright browsers..."
    playwright install chromium
    playwright install-deps chromium
    
    # Start the application
    echo "Starting MultiAdScraper..."
    python3 multi_ad_scraper.py
}

# Function to show status
show_status() {
    if check_docker; then
        echo "=== Docker Status ==="
        docker-compose ps
    fi
    
    echo "=== Process Status ==="
    if pgrep -f "multi_ad_scraper.py" > /dev/null; then
        echo "✓ MultiAdScraper process is running"
    else
        echo "✗ MultiAdScraper process not found"
    fi
    
    echo "=== Port Status ==="
    if netstat -tuln 2>/dev/null | grep -q ":5000 "; then
        echo "✓ Port 5000 is in use (MultiAdScraper likely running)"
    else
        echo "✗ Port 5000 is not in use"
    fi
}

# Function to stop the system
stop_system() {
    echo "Stopping MultiAdScraper..."
    
    # Stop Docker containers
    if check_docker && [ -f "docker-compose.yml" ]; then
        docker-compose down
        echo "✓ Docker containers stopped"
    fi
    
    # Stop manual processes
    if pgrep -f "multi_ad_scraper.py" > /dev/null; then
        pkill -f "multi_ad_scraper.py"
        echo "✓ Manual processes stopped"
    fi
    
    echo "✓ MultiAdScraper stopped"
}

# Function to show logs
show_logs() {
    if check_docker && [ -f "docker-compose.yml" ]; then
        echo "=== Docker Logs ==="
        docker-compose logs -f
    elif [ -f "ad_scraper.log" ]; then
        echo "=== Application Logs ==="
        tail -f ad_scraper.log
    else
        echo "No logs found"
    fi
}

# Main script logic
case "${1:-start}" in
    "start")
        if check_docker && [ -f "docker-compose.yml" ]; then
            run_docker
        elif check_python; then
            run_manual
        else
            echo "❌ Neither Docker nor Python 3 found. Please install one of them."
            exit 1
        fi
        ;;
    "stop")
        stop_system
        ;;
    "restart")
        stop_system
        sleep 2
        $0 start
        ;;
    "status")
        show_status
        ;;
    "logs")
        show_logs
        ;;
    "docker")
        if check_docker; then
            run_docker
        else
            echo "❌ Docker not available"
            exit 1
        fi
        ;;
    "manual")
        if check_python; then
            run_manual
        else
            echo "❌ Python 3 not available"
            exit 1
        fi
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|logs|docker|manual}"
        echo ""
        echo "Commands:"
        echo "  start   - Start MultiAdScraper (auto-detect Docker/manual)"
        echo "  stop    - Stop MultiAdScraper"
        echo "  restart - Restart MultiAdScraper"
        echo "  status  - Show system status"
        echo "  logs    - Show logs (follow mode)"
        echo "  docker  - Force Docker deployment"
        echo "  manual  - Force manual deployment"
        exit 1
        ;;
esac