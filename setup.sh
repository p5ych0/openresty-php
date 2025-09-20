#!/bin/bash
# OpenResty PHP Setup Script

set -e

echo "🚀 Setting up OpenResty PHP environment..."

# Create necessary directories for OpenResty
mkdir -p ssl-certs logs www/public

# Set proper permissions for directories
chmod 755 ssl-certs logs www

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    echo "📝 Creating .env file with your user/group IDs..."
    cp .env.example .env

    # Set current user/group IDs
    sed -i "s/PUID=1000/PUID=$(id -u)/" .env
    sed -i "s/PGID=1000/PGID=$(id -g)/" .env

    echo "✅ Created .env file with PUID=$(id -u) and PGID=$(id -g)"
else
    echo "ℹ️  .env file already exists"
fi

echo "🎉 Setup complete!"
echo ""
echo "Configuration:"
echo "- User/Group: $(id -u):$(id -g) (your current user)"
echo "- SSL domains: localhost,*.local,127.0.0.1 (development mode)"
echo ""
echo "Next steps:"
echo "1. Edit .env file to configure your domains and SSL settings:"
echo "   - Set ALLOWED_DOMAINS (e.g., 'example.com,*.example.com')"
echo "   - Set SSL_EMAIL for production SSL certificates"
echo "   - Set SSL_STAGING=true for testing with Let's Encrypt"
echo ""
echo "2. Copy your nginx configuration files to example/conf/ and example/conf.d/"
echo ""
echo "3. Build and start:"
echo "   docker-compose up --build"
echo ""
echo "4. Access your site:"
echo "   - HTTP: http://localhost:33333 (redirects to HTTPS)"
echo "   - HTTPS: https://localhost:33334"
echo ""
echo "SSL Certificate Management:"
echo "- Development: Uses fallback certificates for localhost"
echo "- Production: Automatically requests Let's Encrypt certificates"
echo "- Certificates stored in: ./ssl-certs/"
echo "- Logs available in: ./logs/ (OpenResty nginx logs)"
echo ""
echo "Domain Examples:"
echo "- Development: localhost,*.local,127.0.0.1"
echo "- Single domain: example.com,www.example.com"
echo "- Wildcard: *.example.com,example.com"
echo "- Multiple: domain1.com,*.domain1.com,domain2.com,*.domain2.com"