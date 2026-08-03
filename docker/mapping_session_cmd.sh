#!/usr/bin/env bash
# Container CMD: auto-starts the mapping tmux session on `docker compose up`,
# then blocks so the container stays alive (tmux runs detached in the
# background). Attach any time with:
#   docker compose exec interactive_slam tmux attach -t interactive_slam_mapping

set -euo pipefail

BAG_DIR="/root/rosbags/${BAG_SUBDIR:?BAG_SUBDIR not set}"
POINTS_TOPIC="${LIDAR_POINTS_TOPIC:?LIDAR_POINTS_TOPIC not set}"
BASE_LINK_FRAME="${BASE_LINK_FRAME:?BASE_LINK_FRAME not set}"
NUM_SECONDS="${NUM_SECONDS:-}"

/root/catkin_ws/src/interactive_slam/docker/mapping_session_inner.sh \
  "$BAG_DIR" "$POINTS_TOPIC" "$BASE_LINK_FRAME" "$NUM_SECONDS"

exec sleep infinity
