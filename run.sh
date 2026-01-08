#!/bin/bash

# .env 파일이 있으면 환경 변수 로드
if [ -f .env ]; then
  echo "Loading environment variables from .env file..."
  export $(cat .env | sed 's/#.*//g' | xargs)
fi

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
    SSL_DIR="$HOME_DIR/ssl"
    NGINX_CONF="$HOME_DIR/nginx.conf"
    # STORAGE_PATH 변수는 .env 파일에서 가져옵니다.
else 
    echo "Running in development mode..."
    SSL_DIR="$HOME_DIR/ssl.dev"
    NGINX_CONF="$HOME_DIR/nginx.dev.conf"
    # STORAGE_PATH 변수는 .env 파일에서 가져옵니다.    
fi

# 필수 환경 변수 확인
if [ -z "$STORAGE_PATH" ] || [ -z "$CERT_DOMAIN" ]; then
    echo "Error: STORAGE_PATH and CERT_DOMAIN must be set in the .env file."
    echo "Please copy .env.sample to .env and fill in the required values."
    exit 1
fi

# 기존 nginx 서비스 중지
sudo systemctl stop nginx

# 인증서 경로 설정
CERT_BASE_PATH="/etc/letsencrypt/live/${CERT_DOMAIN}"

# 인증서 복사
sudo cp -L "${CERT_BASE_PATH}/fullchain.pem" "${HOME_DIR}/ssl/frontend/"
sudo cp -L "${CERT_BASE_PATH}/privkey.pem" "${HOME_DIR}/ssl/frontend/"
sudo cp -L "${CERT_BASE_PATH}/fullchain.pem" "${HOME_DIR}/ssl/backend/"
sudo cp -L "${CERT_BASE_PATH}/privkey.pem" "${HOME_DIR}/ssl/backend/"

# Hubs 관련 디렉터리로 인증서 복사 (프로젝트 루트 경로를 기준으로)
HUBS_DIR="${HOME_DIR}/../hubs-all-in-one"
sudo cp -L "${CERT_BASE_PATH}/fullchain.pem" "${HUBS_DIR}/certs/cert.pem"
sudo cp -L "${CERT_BASE_PATH}/privkey.pem" "${HUBS_DIR}/certs/key.pem"
sudo cp -L "${CERT_BASE_PATH}/fullchain.pem" "${HUBS_DIR}/dialog/certs/cert.pem"
sudo cp -L "${CERT_BASE_PATH}/privkey.pem" "${HUBS_DIR}/dialog/certs/key.pem"
sudo cp -L "${CERT_BASE_PATH}/fullchain.pem" "${HUBS_DIR}/hubs/certs/cert.pem"
sudo cp -L "${CERT_BASE_PATH}/privkey.pem" "${HUBS_DIR}/hubs/certs/key.pem"
sudo cp -L "${CERT_BASE_PATH}/fullchain.pem" "${HUBS_DIR}/reticulum/certs/cert.pem"
sudo cp -L "${CERT_BASE_PATH}/privkey.pem" "${HUBS_DIR}/reticulum/certs/key.pem"



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
