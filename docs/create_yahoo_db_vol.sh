#!/usr/bin/env bash
set -Eeuo pipefail

# Matches the existing fmp_db setup, using a separate volume and host port.
CONTAINER_NAME="yahoo_db"
VOLUME_NAME="yahoo_db_vol"
NETWORK_NAME="default_network"
MYSQL_IMAGE="mysql:8.0.35"
DB_NAME="yahoo"
HOST_PORT="${HOST_PORT:-3311}"

command -v docker >/dev/null || { echo 'ERROR: Docker is not installed.' >&2; exit 1; }
docker info >/dev/null 2>&1 || { echo 'ERROR: Docker daemon is unavailable.' >&2; exit 1; }

# Preserve existing resources; never delete volumes or containers.
if ! docker volume inspect "$VOLUME_NAME" >/dev/null 2>&1; then
  docker volume create --driver local "$VOLUME_NAME"
fi

if ! docker network inspect "$NETWORK_NAME" >/dev/null 2>&1; then
  docker network create "$NETWORK_NAME"
fi

if docker container inspect "$CONTAINER_NAME" >/dev/null 2>&1; then
  echo "Container '$CONTAINER_NAME' already exists; no configuration changed."
  if [[ "$(docker inspect -f '{{.State.Running}}' "$CONTAINER_NAME")" != true ]]; then
    docker start "$CONTAINER_NAME"
  fi
  docker ps --filter "name=^/${CONTAINER_NAME}$"
  exit 0
fi

# Avoid mounting the same database files in two containers.
if [[ -n "$(docker ps -aq --filter "volume=$VOLUME_NAME")" ]]; then
  echo "ERROR: Volume '$VOLUME_NAME' is attached to another container." >&2
  exit 1
fi

if [[ -z "${MYSQL_ROOT_PASSWORD:-}" ]]; then
  if [[ ! -t 0 ]]; then
    echo 'ERROR: Set MYSQL_ROOT_PASSWORD for non-interactive execution.' >&2
    exit 1
  fi
  read -r -s -p 'Enter a new MySQL root password: ' MYSQL_ROOT_PASSWORD
  printf '\n'
fi
[[ -n "$MYSQL_ROOT_PASSWORD" ]] || { echo 'ERROR: Empty root password.' >&2; exit 1; }
export MYSQL_ROOT_PASSWORD

docker run -d \
  --name "$CONTAINER_NAME" \
  --restart always \
  --network "$NETWORK_NAME" \
  -p "127.0.0.1:${HOST_PORT}:3306" \
  -e MYSQL_ROOT_PASSWORD \
  -e "MYSQL_DATABASE=$DB_NAME" \
  -v "$VOLUME_NAME:/var/lib/mysql" \
  "$MYSQL_IMAGE"

unset MYSQL_ROOT_PASSWORD

echo "MySQL container: $CONTAINER_NAME"
echo "Database:        $DB_NAME (created on first initialization of an empty volume)"
echo "Volume:          $VOLUME_NAME"
echo "Network:         $NETWORK_NAME"
echo "Host connection: 127.0.0.1:$HOST_PORT"
echo "Status:          docker logs -f $CONTAINER_NAME"
