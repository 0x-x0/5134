#!/bin/bash -e

export CURR_JOB="buildJob"
export IMAGE_NAME=runimagein
export IMAGE_TAG=latest
export RES_IMAGE="runimagein"
export RES_REPO="fiveonethreefour"

export RES_REPO_UP=$(echo $RES_REPO | awk '{print toupper($0)}')
export RES_REPO_COMMIT=$(eval echo "$"$RES_REPO_UP"_COMMIT")

set_context() {
  echo "RES_REPO_COMMIT=$RES_REPO_COMMIT"
}

build_tag_push_image() {
  echo "Starting Docker build"
  ls IN
  cd ./IN/$RES_REPO/gitRepo
  sudo docker build -t="chetantarale/"$IMAGE_NAME:$IMAGE_TAG .
  echo "Completed Docker build"
}

create_image_version() {
  echo "Creating a state file for" $RES_IMAGE
  echo versionName=$IMAGE_TAG > /build/state/$RES_IMAGE.env
  echo REPO_COMMIT_SHA=$RES_REPO_COMMIT >> /build/state/$RES_IMAGE.env
  echo "Completed creating a state file for" $RES_IMAGE
}

main() {
  set_context
  build_tag_push_image
  create_image_version
}

main

