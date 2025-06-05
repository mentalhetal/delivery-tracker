#!/bin/bash
set -e

# AWS 계정 ID 자동 추출
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
AWS_REGION="ap-northeast-2"
ECR_REPO="tracking-app"
ECR_URI="$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"

echo "AWS 계정 ID: $ACCOUNT_ID"
echo "ECR 주소: $ECR_URI/$ECR_REPO"

echo "[1] Docker Build"
docker build -t $ECR_REPO ./app
docker tag $ECR_REPO:latest $ECR_URI/$ECR_REPO:latest

echo "[2] Docker Push to ECR"
aws ecr get-login-password --region $AWS_REGION | \
  docker login --username AWS --password-stdin $ECR_URI
docker push $ECR_URI/$ECR_REPO:latest

echo "[3] EC2 인벤토리 생성"
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=tracking-ec2" \
  --query "Reservations[*].Instances[*].PrivateIpAddress" \
  --output text > ips.txt

echo "[app_servers]" > ansible/inventory.ini
while read ip; do
  echo "$ip ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/seoul.key.pem" >> ansible/inventory.ini
done < ips.txt

echo "[4] Ansible 실행"
ansible-playbook -i ansible/inventory.ini ansible/playbook.yml
