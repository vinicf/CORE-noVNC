#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
DEFAULT_SHARED_DIR="$SCRIPT_DIR/shared"
DEFAULT_IMAGE="ghcr.io/vinicf/core9.2.1-novnc:latest"

usage() {
    cat <<EOF
Usage: $0 <command> [shared-directory]

Commands:
    start [--ssh] [shared-directory]
                              Start the CORE container
    stop                      Stop the running CORE container
    status                    Show container status
    logs                      Follow container logs
    help                      Show this help

Examples:
    $0 start
    $0 start --ssh
    CORE_IMAGE=core-novnc:local $0 start
    CORE_IMAGE=core-novnc:local $0 start ./shared
    $0 start /path/to/shared
    $0 start --ssh /path/to/shared
    $0 stop
    $0 status
    $0 logs

Notes:
    Default image: ${CORE_IMAGE:-$DEFAULT_IMAGE}
    Override the image with CORE_IMAGE=<image-ref>.
    Default shared directory: ${CORE_SHARED_DIR:-$DEFAULT_SHARED_DIR}
    SSH is disabled by default and is enabled only with start --ssh.
    The noVNC web UI is exposed on http://127.0.0.1:${NOVNC_PORT:-6080}/vnc.html
EOF
}

SHARED="${CORE_SHARED_DIR:-$DEFAULT_SHARED_DIR}"
PLATFORM=$(uname)
ARCH=$(uname -m)
NOVNC_PORT="${NOVNC_PORT:-6080}"
ACTION=""
ENABLE_SSH=0

IMAGE="${CORE_IMAGE:-$DEFAULT_IMAGE}"

case "${1:-}" in
    "")
        usage
        exit 0
        ;;
    start)
        ACTION="start"
        shift
        ;;
    stop|status|logs)
        ACTION="$1"
        shift
        ;;
    help|-h|--help)
        usage
        exit 0
        ;;
    *)
        echo "Error: unknown command: $1"
        echo
        usage
        exit 1
        ;;
esac

echo "Architecture: $ARCH"
echo "Using image: $IMAGE"

if [ "$ACTION" = "stop" ]; then
    docker stop core
    exit 0
fi

if [ "$ACTION" = "status" ]; then
    docker ps --filter name=core
    exit 0
fi

if [ "$ACTION" = "logs" ]; then
    docker logs -f core
    exit 0
fi

while [ "$#" -gt 0 ]; do
    case "$1" in
        --ssh)
            ENABLE_SSH=1
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        --*)
            echo "Error: unknown option: $1"
            echo
            usage
            exit 1
            ;;
        *)
            if [ "$SHARED" != "${CORE_SHARED_DIR:-$DEFAULT_SHARED_DIR}" ]; then
                echo "Error: too many positional arguments"
                echo
                usage
                exit 1
            fi
            SHARED=$(readlink -f "$1")
            ;;
    esac
    shift
done

if [ "$SHARED" != "${CORE_SHARED_DIR:-$DEFAULT_SHARED_DIR}" ]; then
    echo Using custom shared directory: $SHARED
else
    echo Using default shared directory: $SHARED
fi

if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
    echo "Image $IMAGE not found locally. Pulling..."
    if ! docker pull "$IMAGE"; then
        echo "Error: unable to pull image $IMAGE"
        echo "To build locally from this repository:"
        echo "  docker build -t core-novnc:local $SCRIPT_DIR"
        echo "  CORE_IMAGE=core-novnc:local $0 start"
        exit 1
    fi
fi

if [ "$PLATFORM" != "Darwin" ] && [ "$PLATFORM" != "Linux" ]; then
    echo "Warning: untested platform $PLATFORM"
fi

set -- docker run -itd --rm \
    --name core \
    -p 50051:50051 \
    -p "$NOVNC_PORT":6080 \
    -v "$SHARED":/shared \
    --privileged

if [ "$ENABLE_SSH" = "1" ]; then
    set -- "$@" -p 2022:22 -e ENABLE_SSH=1
fi

set -- "$@" "$IMAGE"
"$@"

sleep 3
status=$(docker ps --filter status=running | grep core)
while true; do
    if [ -n "$status" ]; then
        echo "CORE container is running."
        echo "noVNC web UI: http://127.0.0.1:$NOVNC_PORT/vnc.html"
        if [ "$ENABLE_SSH" = "1" ]; then
            echo "SSH is enabled on port 2022."
            echo "Add a key with: docker exec -i core sh -c 'umask 077; mkdir -p /root/.ssh; cat >> /root/.ssh/authorized_keys' < ~/.ssh/id_ed25519.pub"
            echo "Then connect with: ssh -i ~/.ssh/id_ed25519 root@127.0.0.1 -p 2022"
        fi
        break
    else
        sleep 1
        status=$(docker ps --filter status=running | grep core)
    fi
done

trap 'docker stop core >/dev/null 2>&1 || true' INT TERM EXIT

docker logs -f core