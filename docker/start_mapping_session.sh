#!/usr/bin/env bash
# The mapping tmux session now auto-starts inside the container on
# `docker compose up` (see docker/mapping_session_cmd.sh). This script is
# just for (re)triggering it manually, e.g. with different bag/topic/frame
# args than what's in .env, without recreating the container.
#
# Usage:
#   docker/start_mapping_session.sh [bag_dir] [points_topic] [base_link_frame] [num_seconds]
#
# bag_dir must be a path *inside the container* (i.e. under /root/rosbags,
# per the ROSBAGS_DIR mount in docker-compose.yml). Defaults come from .env.
# num_seconds is optional and caps rosbag playback duration.

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

if [[ -f .env ]]; then
  set -a
  source .env
  set +a
fi

BAG_DIR="${1:-/root/rosbags/${BAG_SUBDIR:-}}"
POINTS_TOPIC="${2:-${LIDAR_POINTS_TOPIC:-}}"
BASE_LINK_FRAME="${3:-${BASE_LINK_FRAME:-}}"
NUM_SECONDS="${4:-${NUM_SECONDS:-}}"

if ! docker compose ps --status running --services | grep -q interactive_slam; then
  echo "interactive_slam container is not running. Start it first with: docker compose up -d"
  exit 1
fi

docker compose exec interactive_slam \
  /root/catkin_ws/src/interactive_slam/docker/mapping_session_inner.sh \
  "$BAG_DIR" "$POINTS_TOPIC" "$BASE_LINK_FRAME" "$NUM_SECONDS"

echo "Attach with:  docker compose exec interactive_slam tmux attach -t interactive_slam_mapping"
echo "Switch windows with Ctrl-b then window number (0-3), or Ctrl-b w to list."
echo "Tear down with:  docker compose exec interactive_slam tmux kill-session -t interactive_slam_mapping"
