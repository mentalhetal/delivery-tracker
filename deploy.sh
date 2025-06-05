#!/bin/bash
set -e

export AWS_REGION="ap-northeast-2"
export ECR_REPO="tracking-app"
export ECR_URI="122996776662.dkr.ecr.$AWS_REGION.amazonaws.com"

echo "[1] Docker Build"
docker build -t $ECR_REPO ./app
docker tag $ECR_REPO:latest $ECR_URI/$ECR_REPO:latest

echo "[2] ECR Push"
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

echo "[4] Ansible 배포"
ansible-playbook -i ansible/inventory.ini ansible/playbook.yml
