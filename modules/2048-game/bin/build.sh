#!/bin/bash

# Fail fast
set -e

# This is the order of arguments
docker_image=$1
aws_ecr_repository_url_with_tag=$2
registry=$(echo $aws_ecr_repository_url_with_tag | sed 's/\/.*//')

# Check that aws is installed
which aws > /dev/null || { echo 'ERROR: aws-cli is not installed' ; exit 1; }

# Connect into aws
$(aws ecr get-login-password | docker login --username AWS --password-stdin $registry) || { echo 'ERROR: aws ecr login failed' ; exit 1; }

# Check that docker is installed and running
which docker > /dev/null && docker ps > /dev/null || { echo 'ERROR: docker is not running' ; exit 1; }

# Some Useful Debug
echo "Pulling $docker_image"

# Pull image
docker pull $docker_image

# Some Useful Debug
echo "Tagging $docker_image"

docker tag $docker_image $aws_ecr_repository_url_with_tag

# Some Useful Debug
echo "Pushing to $aws_ecr_repository_url_with_tag"

# Push image
docker push $aws_ecr_repository_url_with_tag