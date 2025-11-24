#!/bin/bash

# Smart Fashion Outfit Generator - Deployment Script
# This script automates the deployment to web servers and load balancer

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=================================${NC}"
echo -e "${GREEN}Fashion App Deployment Script${NC}"
echo -e "${GREEN}=================================${NC}"

# Configuration - UPDATE THESE VALUES
WEB01_IP="your_web01_ip"
WEB02_IP="your_web02_ip"
LB01_IP="your_lb01_ip"
SSH_USER="your_username"
APP_DIR="/var/www/fashion-app"

# Function to check if command was successful
check_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ $1${NC}"
    else
        echo -e "${RED}✗ $1 failed${NC}"
        exit 1
    fi
}

# Deploy to Web Server
deploy_to_web_server() {
    SERVER_IP=$1
    SERVER_NAME=$2
    
    echo -e "\n${YELLOW}Deploying to $SERVER_NAME ($SERVER_IP)...${NC}"
    
    # Create directory on server
    ssh ${SSH_USER}@${SERVER_IP} "sudo mkdir -p ${APP_DIR}"
    check_status "Created directory on $SERVER_NAME"
    
    # Copy application files
    scp index.html ${SSH_USER}@${SERVER_IP}:${APP_DIR}/
    check_status "Copied files to $SERVER_NAME"
    
    # Set permissions
    ssh ${SSH_USER}@${SERVER_IP} "sudo chmod -R 755 ${APP_DIR}"
    check_status "Set permissions on $SERVER_NAME"
    
    # Create nginx configuration
    ssh ${SSH_USER}@${SERVER_IP} "sudo tee /etc/nginx/sites-available/fashion-app > /dev/null <<EOF
server {
    listen 80;
    server_name ${SERVER_IP};
    
    root ${APP_DIR};
    index index.html;
    
    location / {
        try_files \\\$uri \\\$uri/ =404;
    }
    
    access_log /var/log/nginx/fashion-app-access.log;
    error_log /var/log/nginx/fashion-app-error.log;
}
EOF"
    check_status "Created nginx config on $SERVER_NAME"
    
    # Enable site and reload nginx
    ssh ${SSH_USER}@${SERVER_IP} "sudo ln -sf /etc/nginx/sites-available/fashion-app /etc/nginx/sites-enabled/ && sudo nginx -t && sudo systemctl reload nginx"
    check_status "Enabled site and reloaded nginx on $SERVER_NAME"
    
    echo -e "${GREEN}✓ Deployment to $SERVER_NAME completed!${NC}"
}

# Configure Load Balancer
configure_load_balancer() {
    echo -e "\n${YELLOW}Configuring Load Balancer ($LB01_IP)...${NC}"
    
    # Create load balancer configuration
    ssh ${SSH_USER}@${LB01_IP} "sudo tee /etc/nginx/sites-available/fashion-lb > /dev/null <<EOF
upstream fashion_backend {
    server ${WEB01_IP}:80;
    server ${WEB02_IP}:80;
}

server {
    listen 80;
    server_name ${LB01_IP};
    
    location / {
        proxy_pass http://fashion_backend;
        proxy_set_header Host \\\$host;
        proxy_set_header X-Real-IP \\\$remote_addr;
        proxy_set_header X-Forwarded-For \\\$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \\\$scheme;
    }
    
    access_log /var/log/nginx/fashion-lb-access.log;
    error_log /var/log/nginx/fashion-lb-error.log;
}
EOF"
    check_status "Created load balancer config"
    
    # Enable load balancer and reload nginx
    ssh ${SSH_USER}@${LB01_IP} "sudo ln -sf /etc/nginx/sites-available/fashion-lb /etc/nginx/sites-enabled/ && sudo nginx -t && sudo systemctl reload nginx"
    check_status "Enabled load balancer and reloaded nginx"
    
    echo -e "${GREEN}✓ Load balancer configuration completed!${NC}"
}

# Test deployment
test_deployment() {
    echo -e "\n${YELLOW}Testing deployment...${NC}"
    
    # Test Web01
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://${WEB01_IP})
    if [ "$HTTP_CODE" = "200" ]; then
        echo -e "${GREEN}✓ Web01 responding (HTTP $HTTP_CODE)${NC}"
    else
        echo -e "${RED}✗ Web01 not responding properly (HTTP $HTTP_CODE)${NC}"
    fi
    
    # Test Web02
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://${WEB02_IP})
    if [ "$HTTP_CODE" = "200" ]; then
        echo -e "${GREEN}✓ Web02 responding (HTTP $HTTP_CODE)${NC}"
    else
        echo -e "${RED}✗ Web02 not responding properly (HTTP $HTTP_CODE)${NC}"
    fi
    
    # Test Load Balancer
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://${LB01_IP})
    if [ "$HTTP_CODE" = "200" ]; then
        echo -e "${GREEN}✓ Load Balancer responding (HTTP $HTTP_CODE)${NC}"
    else
        echo -e "${RED}✗ Load Balancer not responding properly (HTTP $HTTP_CODE)${NC}"
    fi
}

# Main deployment process
main() {
    echo -e "\n${YELLOW}Starting deployment process...${NC}\n"
    
    # Check if index.html exists
    if [ ! -f "index.html" ]; then
        echo -e "${RED}Error: index.html not found in current directory${NC}"
        exit 1
    fi
    
    # Deploy to web servers
    deploy_to_web_server $WEB01_IP "Web01"
    deploy_to_web_server $WEB02_IP "Web02"
    
    # Configure load balancer
    configure_load_balancer
    
    # Test deployment
    test_deployment
    
    echo -e "\n${GREEN}=================================${NC}"
    echo -e "${GREEN}Deployment Completed Successfully!${NC}"
    echo -e "${GREEN}=================================${NC}"
    echo -e "\n${YELLOW}Access your application at:${NC}"
    echo -e "Web01: http://${WEB01_IP}"
    echo -e "Web02: http://${WEB02_IP}"
    echo -e "Load Balancer: http://${LB01_IP}"
}

# Run main function
main