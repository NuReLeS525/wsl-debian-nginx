#!/bin/bash
set -e

echo "Starting Django deployment script..."

echo "Ensure Python and pip are installed on your Windows machine."

#pwd ctrl+c ctrl+v
PROJECT_DIR="/mnt/c/Users/Aelita/Desktop/asfdjadfijbi"

if [ "$PWD" = "$PROJECT_DIR" ]; then
    echo "Already in project directory"
else
    cd "$PROJECT_DIR"
fi

if [ -d ".git" ]; then
    echo "Git repository already exists, pulling latest changes..."
    git pull origin main
else
    echo "Cloning repository..."
    rm -rf * .[!.] .??*
    git clone https://github.com/DireSky/OSEExam.git .
fi
sudo apt update
sudo apt install -y python3 python3-venv python3-pip git nginx


if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv venv
fi

echo "Activating virtual environment..."
source "$PROJECT_DIR/venv/bin/activate"


if [ -f "requirements.txt" ]; then
    echo "Installing requirements from requirements.txt..."
    pip install -r requirements.txt
else
    echo "Creating requirements.txt with necessary packages..."
    cat > requirements.txt << EOF
Django>=4.2
pytest>=7.4
Whitenoise
EOF
    pip install -r requirements.txt
fi


# Set DJANGO_SETTINGS_MODULE to the correct path
export DJANGO_SETTINGS_MODULE=testPrj.settings

# Collect static files
echo "Running collectstatic..."
python "$PROJECT_DIR/testPrj/manage.py" collectstatic --noinput --clear

# Migrate the database
echo "Running database migrations..."
python "$PROJECT_DIR/testPrj/manage.py" migrate

# Start downloading Nginx
echo "Installing Nginx..."
sudo apt-get install -y nginx

# Configure Nginx
echo "Configuring Nginx..."
cat > /etc/nginx/sites-available/django_app << EOF
server {
    listen 80;
    server_name _;

    location = /favicon.ico { access_log off; log_not_found off; }
    
    location /static/ {
        root "$PROJECT_DIR";
    }

    location / {
        proxy_pass http://127.0.0.1:8000;  # Assuming Django is running with manage.py runserver
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Enable the Nginx configuration
ln -sf /etc/nginx/sites-available/django_app /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Set proper permissions
echo "Setting proper permissions..."
chown -R www-data:www-data "$PROJECT_DIR"
chmod -R 755 "$PROJECT_DIR"

# Start and enable services
echo "Starting services..."
sudo sudo systemctl start nginx
sudo systemctl enable nginx
sudo systemctl restart nginx

python "$PROJECT_DIR/testPrj/manage.py" runserver 127.0.0.1:8000

echo "Deployment completed successfully!"
echo "I HATE PHP"
echo "Your Django application should now be accessible via http://$SERVER_NAME:8000"

echo "I HATE PHP"
