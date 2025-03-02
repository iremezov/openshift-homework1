#!/bin/sh

set -e

buildFrontend() {
  ./backend/gradlew clean build -p backend -x test
  DOCKER_BUILDKIT=1 docker build -f frontend.Dockerfile frontend/ --tag frontend:v1.0-"$STUDENT_LABEL"
}

buildBackend() {
  ./backend/gradlew clean build -p backend -x test
  DOCKER_BUILDKIT=1 docker build -f backend.Dockerfile backend/ --tag backend:v1.0-"$STUDENT_LABEL"
}

createNetworks() {
  echo "TODO create networks"
  docker network create -d bridge db_bridge --label $BASE_LABEL-$STUDENT_LABEL
  docker network create -d bridge app_bridge --label $BASE_LABEL-$STUDENT_LABEL  
  
}

createVolume() {
  echo "TODO create volume for postgres"
  echo "create volume fpr db"
  docker volume create pg-data --label "$BASE_LABEL"-"$STUDENT_LABEL"
}

runPostgres() {
  echo "TODO run postgres"
  echo "run postgres"
  docker run -d \
	--name postgres \
	--network=net-backend-"$BASE_LABEL"-"$STUDENT_LABEL" \
	-p 5432:5432 \
	-e POSTGRES_USER=program \
    -e POSTGRES_PASSWORD=test \
    -e POSTGRES_DB=todo_list \
	-e PGDATA=/var/lib/postgresql/data/pgdata \
	-v pg-data:/var/lib/postgresql/data \
	--label "$BASE_LABEL"-"$STUDENT_LABEL" \
	postgres:13-alpine 
}

runBackend() {
  echo "TODO run backend"
  echo "run backend" 
  docker create  \
    --name backend-"$BASE_LABEL"-"$STUDENT_LABEL" \
	-p 8080:8080 \
	--label "$BASE_LABEL"-"$STUDENT_LABEL" \
	backend:v1.0-"$STUDENT_LABEL"
	docker network connect net-backend-"$BASE_LABEL"-"$STUDENT_LABEL" backend-"$BASE_LABEL"-"$STUDENT_LABEL"
	docker network connect net-frontend-"$BASE_LABEL"-"$STUDENT_LABEL" backend-"$BASE_LABEL"-"$STUDENT_LABEL"
	docker start backend-"$BASE_LABEL"-"$STUDENT_LABEL" 
}

runFrontend() {
  echo "RUN frontend"
  echo "frontend"
  docker run -d  \
    --name frontend-"$BASE_LABEL"-"$STUDENT_LABEL" \
  	--network=net-frontend-"$BASE_LABEL"-"$STUDENT_LABEL" \
	-p 3000:80 \
	--label "$BASE_LABEL"-"$STUDENT_LABEL" \
	frontend:v1.0-"$STUDENT_LABEL" 
}

checkResult() {
  sleep 10
  http_response=$(
    docker exec \
      frontend-"$BASE_LABEL"-"$STUDENT_LABEL" \
      curl -s -o response.txt -w "%{http_code}" http://backend-"$BASE_LABEL"-"$STUDENT_LABEL":8080/api/v1/public/items
  )

  if [ "$http_response" != "200" ]; then
    echo "Check failed"
    exit 1
  fi
}

BASE_LABEL=homework1
# TODO student surname name
STUDENT_LABEL=iremezov

echo "=== Build backend backend:v1.0-$STUDENT_LABEL ==="
buildBackend

echo "=== Build frontend frontend:v1.0-$STUDENT_LABEL ==="
buildFrontend

echo "=== Create networks between backend <-> postgres and backend <-> frontend ==="
createNetworks

echo "=== Create persistence volume for postgres ==="
createVolume

echo "== Run Postgres ==="
runPostgres

echo "=== Run backend backend:v1.0-$STUDENT_LABEL ==="
runBackend

echo "=== Run frontend frontend:v1.0-$STUDENT_LABEL ==="
runFrontend

echo "=== Run check ==="
checkResult
