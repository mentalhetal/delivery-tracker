#!/bin/bash
set -e

ACCOUNT_ID="122996776662"  # ✅ 본인 AWS 계정 ID 입력
ECR_URI="$ACCOUNT_ID.dkr.ecr.ap-northeast-2.amazonaws.com"
REPO="tracking-app"

echo "[1] Docker Build"
docker build -t $REPO ./app
docker tag $REPO:latest $ECR_URI/$REPO:latest

echo "[2] Docker Push"
aws ecr get-login-password --region ap-northeast-2 | \
  docker login --username AWS --password-stdin $ECR_URI
docker push $ECR_URI/$REPO:latest

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
