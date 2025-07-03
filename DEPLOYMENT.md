# Cambiatus Backend Deployment Guide

This guide covers deploying the Cambiatus backend to EC2 using PM2 process manager with modern Elixir releases.

## Prerequisites

### Local Development Machine
- Elixir 1.18.4 with OTP 28
- Mix and Hex installed
- SSH access to your EC2 instance

### EC2 Server Requirements
- Ubuntu 20.04+ or Amazon Linux 2
- Node.js 18+ (for PM2)
- PM2 installed globally: `npm install -g pm2`
- PostgreSQL database (can be RDS)
- Minimum 1GB RAM, 2GB recommended

## Server Setup

### 1. Install Dependencies on EC2

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Node.js and npm
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install PM2
sudo npm install -g pm2

# Create deployment user (if not using ubuntu)
sudo useradd -m -s /bin/bash deploy
sudo usermod -aG sudo deploy

# Create deployment directory
sudo mkdir -p /opt/cambiatus/backend
sudo chown ubuntu:ubuntu /opt/cambiatus/backend

# Create log directory
sudo mkdir -p /var/log/cambiatus
sudo chown ubuntu:ubuntu /var/log/cambiatus
```

### 2. Configure Environment Variables

Copy the environment template and configure it:

```bash
# On your server
cd /opt/cambiatus/backend
cp .env.production.example .env.production

# Edit the file with your actual values
nano .env.production
```

Key variables to configure:
- `DATABASE_URL`: Your PostgreSQL connection string
- `SECRET_KEY_BASE`: Generate with `mix phx.gen.secret`
- `PHX_HOST`: Your domain name
- EOS/Blockchain settings
- AWS SES credentials (for email)
- Sentry DSN (for error tracking)

## Deployment Process

### Option 1: Automated Deployment (Recommended)

Use the provided deployment script:

```bash
# From your local development machine
./deploy.sh <server-ip>

# Example:
./deploy.sh 54.123.45.67
```

This script will:
1. Build the release locally
2. Create a deployment package
3. Upload to your server
4. Extract and configure the release
5. Start the service with PM2

### Option 2: Manual Deployment

#### Step 1: Build Release Locally

```bash
# Clean previous builds
rm -rf _build/prod

# Get production dependencies
MIX_ENV=prod mix deps.get --only prod

# Compile
MIX_ENV=prod mix compile

# Build assets (if applicable)
MIX_ENV=prod mix assets.deploy

# Create release
MIX_ENV=prod mix release
```

#### Step 2: Package and Upload

```bash
# Create deployment package
tar -czf cambiatus-release.tar.gz \
    _build/prod/rel/cambiatus \
    ecosystem.config.js \
    start.sh \
    config/runtime.exs

# Upload to server
scp cambiatus-release.tar.gz ubuntu@<server-ip>:/tmp/
```

#### Step 3: Deploy on Server

```bash
# SSH to server
ssh ubuntu@<server-ip>

# Navigate to deployment directory
cd /opt/cambiatus/backend

# Stop existing service
pm2 stop cambiatus-backend || true
pm2 delete cambiatus-backend || true

# Backup current deployment
if [ -d "current" ]; then
    mv current backup-$(date +%Y%m%d_%H%M%S)
fi

# Extract new release
tar -xzf /tmp/cambiatus-release.tar.gz
mv _build/prod/rel/cambiatus current

# Copy configuration files
cp ecosystem.config.js current/
cp start.sh current/
mkdir -p current/config
cp config/runtime.exs current/config/

# Set permissions
chmod +x current/start.sh
chmod +x current/bin/cambiatus

# Start with PM2
cd current
pm2 start ecosystem.config.js

# Save PM2 configuration
pm2 save
pm2 startup
```

## Configuration Files

### config/runtime.exs
Modern Elixir runtime configuration that replaces the old `config/releases.exs`. This file:
- Loads configuration at runtime from environment variables
- Supports dynamic configuration
- Is evaluated when the release starts

### ecosystem.config.js
PM2 configuration file that defines:
- Application name and script
- Environment variables
- Process management options
- Logging configuration
- Health checks

### start.sh
Startup script that:
- Validates environment variables
- Checks database connectivity
- Runs migrations
- Starts the release

## Management Commands

### PM2 Commands

```bash
# Start service
pm2 start ecosystem.config.js

# Stop service
pm2 stop cambiatus-backend

# Restart service
pm2 restart cambiatus-backend

# View logs
pm2 logs cambiatus-backend

# Monitor status
pm2 status

# Monitor in real-time
pm2 monit

# Save configuration
pm2 save

# Setup startup script
pm2 startup
```

### Application Commands

```bash
# Run migrations
./current/bin/cambiatus eval "Cambiatus.Release.migrate()"

# Run seeds
./current/bin/cambiatus eval "Cambiatus.Release.seed()"

# Get release info
./current/bin/cambiatus version

# Connect to running application
./current/bin/cambiatus remote

# Check application status
./current/bin/cambiatus pid
```

## Monitoring and Logs

### Log Locations
- Application logs: `/var/log/cambiatus/`
- PM2 logs: `~/.pm2/logs/`

### Health Checks
The application exposes a health check endpoint:
```bash
curl http://localhost:4000/health
```

### Monitoring with PM2
```bash
# Real-time monitoring
pm2 monit

# Web-based monitoring (optional)
pm2 web
```

## Troubleshooting

### Common Issues

1. **Database Connection Issues**
   - Verify `DATABASE_URL` is correct
   - Ensure database server is running
   - Check network connectivity and security groups

2. **Environment Variable Issues**
   - Verify all required variables are set
   - Check for typos in variable names
   - Ensure secrets are properly generated

3. **Permission Issues**
   - Verify file permissions: `chmod +x start.sh`
   - Check directory ownership
   - Ensure log directories are writable

4. **Memory Issues**
   - Monitor with `pm2 monit`
   - Adjust `max_memory_restart` in ecosystem.config.js
   - Consider increasing EC2 instance size

### Debugging

```bash
# Check application logs
pm2 logs cambiatus-backend --lines 100

# Check system resources
htop
df -h

# Test database connectivity
./current/bin/cambiatus eval "Cambiatus.Repo.query!(\"SELECT 1\")"

# Check environment variables
./current/bin/cambiatus eval "System.get_env(\"DATABASE_URL\")"
```

## Security Considerations

1. **Environment Variables**: Store sensitive data in environment variables, not in code
2. **File Permissions**: Ensure proper file permissions and ownership
3. **Network Security**: Configure security groups to only allow necessary ports
4. **SSL/TLS**: Use HTTPS in production with proper certificates
5. **Database Security**: Use strong passwords and network isolation for database

## Rollback Procedure

If deployment fails or issues arise:

```bash
# Stop current service
pm2 stop cambiatus-backend

# Restore backup
cd /opt/cambiatus/backend
rm -rf current
mv backup-<timestamp> current

# Start service
cd current
pm2 start ecosystem.config.js
```

## Updates and Maintenance

### Regular Updates
1. Update dependencies: `mix deps.update --all`
2. Test locally
3. Deploy using the deployment script
4. Monitor for issues

### Database Migrations
Migrations run automatically during deployment via the `start.sh` script. For manual migration management:

```bash
# Run specific migration
./current/bin/cambiatus eval "Cambiatus.Release.migrate()"

# Rollback migration
./current/bin/cambiatus eval "Cambiatus.Release.rollback(Cambiatus.Repo, 20231201000000)"
```

This deployment setup provides a modern, robust foundation for running Cambiatus in production with proper process management, monitoring, and operational tools.
