#!/usr/bin/env bash
# Runs INSIDE the interactive_slam container. Sets up a tmux session with
# roscore, hdl_graph_slam, rviz, and rosbag play, all as local processes.
#
# Usage: mapping_session_inner.sh <bag_dir> <points_topic> <base_link_frame> [num_seconds]
#
# num_seconds is optional: caps rosbag playback to that many seconds of bag
# time. roscore/hdl_graph_slam/rviz keep running after playback stops.

set -euo pipefail

SESSION="interactive_slam_mapping"
BAG_DIR="${1:?bag_dir required}"
POINTS_TOPIC="${2:?points_topic required}"
BASE_LINK_FRAME="${3:?base_link_frame required}"
NUM_SECONDS="${4:-}"

if tmux has-session -t "$SESSION" 2>/dev/null; then
  echo "tmux session '$SESSION' already exists."
  exit 0
fi

SETUP='source /root/catkin_ws/devel/setup.bash'

tmux new-session -d -s "$SESSION" -n roscore
tmux send-keys -t "$SESSION:roscore" "$SETUP; roscore" C-m

tmux new-window -t "$SESSION" -n hdl_graph_slam
tmux send-keys -t "$SESSION:hdl_graph_slam" \
  "sleep 3; $SETUP; rosparam set use_sim_time true; roslaunch hdl_graph_slam hdl_graph_slam.launch points_topic:=$POINTS_TOPIC base_link_frame_id:=$BASE_LINK_FRAME" C-m

tmux new-window -t "$SESSION" -n rviz
tmux send-keys -t "$SESSION:rviz" \
  "sleep 6; $SETUP; rviz -d /root/catkin_ws/src/hdl_graph_slam/rviz/hdl_graph_slam.rviz" C-m

DURATION_FLAG=""
if [[ -n "$NUM_SECONDS" ]]; then
  DURATION_FLAG="--duration=$NUM_SECONDS"
fi

# After playback ends (full bag or NUM_SECONDS cutoff), dump the graph and
# open interactive_slam so it's ready for File > Open on the dumped folder.
DUMP_DIR="/root/data_out/latest_graph"
POST_PLAY="echo '--- dumping graph to $DUMP_DIR ---'; \
rosservice call /hdl_graph_slam/dump \"destination: '$DUMP_DIR'\"; \
echo '--- launching interactive_slam (File > Open -> $DUMP_DIR) ---'; \
tmux new-window -t $SESSION -n interactive_slam \"bash -lc '$SETUP; rosrun interactive_slam interactive_slam'\""

tmux new-window -t "$SESSION" -n rosbag_play
tmux send-keys -t "$SESSION:rosbag_play" \
  "sleep 8; $SETUP; rosbag play --clock $DURATION_FLAG ${BAG_DIR}/robot_1_sensors_*.bag ${BAG_DIR}/robot_1_tf_*.bag; $POST_PLAY" C-m

echo "tmux session '$SESSION' started with windows: roscore, hdl_graph_slam, rviz, rosbag_play"
echo "On playback completion, the graph will be dumped to $DUMP_DIR and interactive_slam will launch automatically."
