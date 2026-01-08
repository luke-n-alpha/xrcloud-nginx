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

# 환경 변수 파일 로드
ENV_FILE="$HOME_DIR/.env.$MODE"
if [ ! -f "$ENV_FILE" ]; then
    echo "Error: Environment file $ENV_FILE does not exist."
    exit 1
fi

# 환경 변수 로드
source "$ENV_FILE"

if [ "$MODE" == "prod" ]; then
    echo "Running in production mode..."
else 
    echo "Running in development mode..."
fi

# 필수 환경 변수 체크
if [ -z "$SSL_DIR" ] || [ -z "$NGINX_CONF" ] || [ -z "$STORAGE_PATH" ]; then
    echo "Error: Required environment variables are not set."
    echo "Please check your $ENV_FILE file."
    exit 1
fi

# 기존 nginx 서비스 중지
sudo systemctl stop nginx

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
    -v /app/xrcloud-nginx/logs:/var/log/nginx \
    xrcloud-nginx:latest