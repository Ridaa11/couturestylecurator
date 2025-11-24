 Couture Style Curator

this is an application that generates outfit suggestions to the user according to the weather and occasion
It uses realtime weather data with the help of APIs

API URL : "https://api.openweathermap.org/data/2.5/weather"


## How to Run Locally

### What You Need
- Web browser
- Internet connection
- OpenWeatherMap API key (free)

### Setup

1. Get the code
```bash
git clone https://github.com/yourusername/fashion-outfit-generator.git
cd fashion-outfit-generator
```

2. Get an API key
- Go to https://openweathermap.org/api
- Sign up (it's free)
- Get your API key
- Wait about 2 hours for it to activate

3. Add your API key
- Open `index.html` in a text editor
- Find this line: `const API_KEY = 'YOUR_API_KEY_HERE';`
- Replace `YOUR_API_KEY_HERE` with your actual key
- Save the file

4. Open in browser
- Just double-click `index.html`
- Or run a local server:
```bash
python3 -m http.server 8000
```
Then go to `http://localhost:8000`

## Deployment

### Setting Up Web Servers

I deployed this on two web servers (Web01 and Web02) with a load balancer (Lb01).

#### On Web01 and Web02

First, I installed nginx:
```bash
sudo apt update
sudo apt install nginx -y
```

Created the folder for my app:
```bash
sudo mkdir -p /var/www/fashion-app
```

Copied my file to the server:
```bash
scp index.html username@server_ip:/tmp/
sudo mv /tmp/index.html /var/www/fashion-app/
```

Then I set up nginx config:
```bash
sudo nano /etc/nginx/sites-available/fashion-app
```

Added this:
```nginx
server {
    listen 80;
    server_name SERVER_IP;
    
    root /var/www/fashion-app;
    index index.html;
    
    location / {
        try_files $uri $uri/ =404;
    }
}
```

Enabled it:
```bash
sudo ln -s /etc/nginx/sites-available/fashion-app /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

Did the same thing on Web02.

#### Setting Up Load Balancer

On Lb01, I set up nginx to balance traffic:

```bash
sudo nano /etc/nginx/sites-available/fashion-lb
```

Config:
```nginx
upstream fashion_backend {
    server WEB01_IP:80;
    server WEB02_IP:80;
}

server {
    listen 80;
    server_name LB01_IP;
    
    location / {
        proxy_pass http://fashion_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

Enabled it:
```bash
sudo ln -s /etc/nginx/sites-available/fashion-lb /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### Testing

To check if load balancing works:
```bash
# On Web01
sudo tail -f /var/log/nginx/access.log

# On Web02  
sudo tail -f /var/log/nginx/access.log
```

Then I refreshed the page at `http://LB01_IP` multiple times and saw requests going to both servers.

## How to Use

1. Type in a city name
2. Pick what you're doing (work, party, etc)
3. Choose your style
4. Pick a budget
5. Click "Generate Outfits"
6. See your outfit suggestions

## Problems I Ran Into

### API Key Not Working
At first my API key didn't work. Turns out you have to wait a couple hours after signing up for it to activate. Just had to be patient.

### CORS Issues
The browser was blocking my API requests at first. Fixed it by using the correct API endpoint that allows cross-origin requests.

### Load Balancer Setup
Getting the load balancer to distribute traffic evenly took some tweaking. Had to make sure the upstream config was right and both servers were actually responding.



## Demo Video

https://youtu.be/r8Bn7cWd8W8
