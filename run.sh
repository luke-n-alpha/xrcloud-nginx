#!/bin/bash

# 실행 모드 확인
MODE=$1
HOME_DIR=$(pwd)

# 파라미터가 없을 때 메시지 출력하고 종료
if [ -z "$MODE" ]; then
    echo "Error: Please provide a mode (prod or dev)."
    echo "Usage: $0 [prod|dev]"
    exit 1
fi

if [ "$MODE" == "prod" ]; then
    echo "Running in production mode..."
    # nginx home 위치는 현재 위치를 받아서 설정
    SSL_DIR="$HOME_DIR/ssl"
    NGINX_CONF="$HOME_DIR/nginx.conf"
    STORAGE_PATH="/mnt/xrcloud-prod-ko/xrcloud/storage"
else 
    echo "Running in development mode..."
    # dev 모드에서 다른 디렉토리로 설정, 일반적으로 storage사용하나, cnu의 경우 subStoage 사용 (cnu설정에서는 동일하게 써야 할까?)
    SSL_DIR="$HOME_DIR/ssl.dev"
    NGINX_CONF="$HOME_DIR/nginx.dev.conf"
    STORAGE_PATH="/mnt/xrcloud-prod-ko/xrcloud.dev/storage"    
fi

# 기존 nginx 서비스 중지
sudo systemctl stop nginx
sudo cp -L /etc/letsencrypt/live/xrcloud.app/fullchain.pem /home/belivvr/xrcloud/xrcloud-nginx/ssl/frontend/
sudo cp -L /etc/letsencrypt/live/xrcloud.app/privkey.pem /home/belivvr/xrcloud/xrcloud-nginx/ssl/frontend/
sudo cp -L /etc/letsencrypt/live/xrcloud.app/fullchain.pem /home/belivvr/xrcloud/xrcloud-nginx/ssl/backend/
sudo cp -L /etc/letsencrypt/live/xrcloud.app/privkey.pem /home/belivvr/xrcloud/xrcloud-nginx/ssl/backend/

sudo cp -L /etc/letsencrypt/live/xrcloud.app/fullchain.pem /home/belivvr/xrcloud/hubs-all-in-one/certs/cert.pem
sudo cp -L /etc/letsencrypt/live/xrcloud.app/privkey.pem /home/belivvr/xrcloud/hubs-all-in-one/certs/key.pem
sudo cp -L /etc/letsencrypt/live/xrcloud.app/fullchain.pem /home/belivvr/xrcloud/hubs-all-in-one/dialog/certs/cert.pem
sudo cp -L /etc/letsencrypt/live/xrcloud.app/privkey.pem /home/belivvr/xrcloud/hubs-all-in-one/dialog/certs/key.pem
sudo cp -L /etc/letsencrypt/live/xrcloud.app/fullchain.pem /home/belivvr/xrcloud/hubs-all-in-one/hubs/certs/cert.pem
sudo cp -L /etc/letsencrypt/live/xrcloud.app/privkey.pem /home/belivvr/xrcloud/hubs-all-in-one/hubs/certs/key.pem
sudo cp -L /etc/letsencrypt/live/xrcloud.app/fullchain.pem /home/belivvr/xrcloud/hubs-all-in-one/reticulum/certs/cert.pem
sudo cp -L /etc/letsencrypt/live/xrcloud.app/privkey.pem /home/belivvr/xrcloud/hubs-all-in-one/reticulum/certs/key.pem



# 기존 도커 컨테이너 중지 및 삭제
sudo docker stop xrcloud-nginx
sudo docker rm xrcloud-nginx

# 도커 이미지 빌드
sudo docker build -t xrcloud-nginx .

# 도커 컨테이너 실행
sudo docker run -d --name xrcloud-nginx --restart always --network xrcloud \
    -p 80:80 -p 443:443 \
    -v "$SSL_DIR:/etc/ssl" \
    -v "$NGINX_CONF:/etc/nginx/nginx.conf" \
    -v "$STORAGE_PATH:/app/xrcloud-backend/storage" \
    -v "/var/www/certbot:/var/www/certbot" \
    -v /app/xrcloud-nginx/logs:/var/log/nginx \
    xrcloud-nginx:latest
