#!/bin/bash

az acr login --name ${ACR_REGISTRY_NAME}

# Docker Build Sender Image
docker build -t ${ACR_REGISTRY_NAME}.azurecr.io/${ACR_IMAGE_PATH} ${DOCKERFILE_PATH}
docker push ${ACR_REGISTRY_NAME}.azurecr.io/${ACR_IMAGE_PATH}