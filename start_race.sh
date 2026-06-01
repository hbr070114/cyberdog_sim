#!/bin/bash
# ═════════════════════════════════════════════════════════════════
# 一键启动脚本：Gazebo + cyberdog_control + 趴下→站立→竞赛
# 自动适配本地 / Docker 环境路径
# ═════════════════════════════════════════════════════════════════
set +e

# ── 自适应工作目录 ──────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WS_ROOT="$SCRIPT_DIR"
cd "$WS_ROOT" || { echo "FATAL: cannot cd to $WS_ROOT"; exit 1; }
echo "[$(date +%H:%M:%S)] Workspace: $WS_ROOT"

export DISPLAY=${DISPLAY:-:0}
export GAZEBO_GUI=${GAZEBO_GUI:-true}
export GAZEBO_HEADLESS=${GAZEBO_HEADLESS:-false}

source /opt/ros/galactic/setup.bash 2>/dev/null
source install/setup.bash 2>/dev/null

if ! command -v ros2 >/dev/null 2>&1; then
    if command -v docker >/dev/null 2>&1; then
        echo "[$(date +%H:%M:%S)] Host has no ROS2, switching to Docker container cyberdog_slam..."
        if ! docker info >/dev/null 2>&1; then
            echo "FATAL: 当前用户无法访问 Docker daemon。"
            echo "请确认当前用户在 docker 组，或使用: sudo -E bash start_race.sh"
            exit 1
        fi
        if ! docker inspect cyberdog_slam >/dev/null 2>&1; then
            echo "FATAL: Docker container cyberdog_slam not found."
            echo "请先运行: cd /home/fish/cyberdog_sim && bash init_fix.sh"
            exit 1
        fi
        if ! docker ps --format '{{.Names}}' | grep -qx cyberdog_slam; then
            docker start cyberdog_slam >/dev/null || exit 1
            sleep 2
        fi
        xhost +local:root >/dev/null 2>&1 || true
        exec docker exec \
            -e DISPLAY="$DISPLAY" \
            -e RACE_SOFTWARE_GL="${RACE_SOFTWARE_GL:-0}" \
            -e LIBGL_ALWAYS_SOFTWARE="${RACE_SOFTWARE_GL:-0}" \
            -e GAZEBO_HEADLESS="${GAZEBO_HEADLESS:-false}" \
            -e GAZEBO_GUI="${GAZEBO_GUI:-true}" \
            -e RACE_FORCE_COORD_ONLY="${RACE_FORCE_COORD_ONLY:-}" \
            -e RACE_FORCE_COORD_RADIUS="${RACE_FORCE_COORD_RADIUS:-}" \
            -e RACE_FORCE_COORD_VX="${RACE_FORCE_COORD_VX:-}" \
            -e RACE_FORCE_COORD_VY="${RACE_FORCE_COORD_VY:-}" \
            -e RACE_FORCE_COORD_YAW_LIMIT="${RACE_FORCE_COORD_YAW_LIMIT:-}" \
            -e RACE_FORCE_COORD_FACE_YAW="${RACE_FORCE_COORD_FACE_YAW:-}" \
            -e RACE_FORCE_COORD_FACE_VX="${RACE_FORCE_COORD_FACE_VX:-}" \
            -e RACE_FORCE_COORD_SLOW_RADIUS="${RACE_FORCE_COORD_SLOW_RADIUS:-}" \
            -e RACE_FORCE_COORD_MIN_DRIVE_VX="${RACE_FORCE_COORD_MIN_DRIVE_VX:-}" \
            -e RACE_FORCE_COORD_LINE_HIT_LATERAL="${RACE_FORCE_COORD_LINE_HIT_LATERAL:-}" \
            -e RACE_FORCE_ROUTE_YAW_GAIN="${RACE_FORCE_ROUTE_YAW_GAIN:-}" \
            -e RACE_FORCE_ROUTE_LATERAL_GAIN="${RACE_FORCE_ROUTE_LATERAL_GAIN:-}" \
            -e RACE_FORCE_ROUTE_LATERAL_LIMIT="${RACE_FORCE_ROUTE_LATERAL_LIMIT:-}" \
            -e RACE_FORCE_ROUTE_SLOW_RADIUS="${RACE_FORCE_ROUTE_SLOW_RADIUS:-}" \
            -e RACE_FORCE_ROUTE_MIN_VX="${RACE_FORCE_ROUTE_MIN_VX:-}" \
            -e RACE_FORCE_ROUTE_RADIUS="${RACE_FORCE_ROUTE_RADIUS:-}" \
            -e RACE_FORCE_ROUTE_OVERSHOOT_LATERAL="${RACE_FORCE_ROUTE_OVERSHOOT_LATERAL:-}" \
            -e RACE_FORCE_STAGE1_X_RADIUS="${RACE_FORCE_STAGE1_X_RADIUS:-}" \
            -e RACE_FORCE_STAGE1_X_DRIVE_VX="${RACE_FORCE_STAGE1_X_DRIVE_VX:-}" \
            -e RACE_FORCE_STAGE1_X_SLOW_VX="${RACE_FORCE_STAGE1_X_SLOW_VX:-}" \
            -e RACE_FORCE_STAGE1_Y_DRIVE_VX="${RACE_FORCE_STAGE1_Y_DRIVE_VX:-}" \
            -e RACE_FORCE_STAGE1_Y_SLOW_VX="${RACE_FORCE_STAGE1_Y_SLOW_VX:-}" \
            -e RACE_FORCE_STAGE1_Y_RADIUS="${RACE_FORCE_STAGE1_Y_RADIUS:-}" \
            -e RACE_FORCE_COORD_STAGE1_STONE_VY_GAIN="${RACE_FORCE_COORD_STAGE1_STONE_VY_GAIN:-}" \
            -e RACE_FORCE_COORD_STAGE1_STONE_VY_LIMIT="${RACE_FORCE_COORD_STAGE1_STONE_VY_LIMIT:-}" \
            -e RACE_STONE_GAIT="${RACE_STONE_GAIT:-}" \
            -e RACE_STONE_HIGH_GAIT="${RACE_STONE_HIGH_GAIT:-}" \
            -e RACE_STONE_CRAWL_VX="${RACE_STONE_CRAWL_VX:-}" \
            -e RACE_STONE_APPROACH_VX="${RACE_STONE_APPROACH_VX:-}" \
            -e RACE_STONE_STABLE_CRUISE_VX="${RACE_STONE_STABLE_CRUISE_VX:-}" \
            -e RACE_STONE_BALANCE_CRAWL_VX="${RACE_STONE_BALANCE_CRAWL_VX:-}" \
            -e RACE_STONE_STEPUP_VX="${RACE_STONE_STEPUP_VX:-}" \
            -e RACE_STONE_STEPUP_END_X="${RACE_STONE_STEPUP_END_X:-}" \
            -e RACE_STONE_ENTRY_ALIGN_END_X="${RACE_STONE_ENTRY_ALIGN_END_X:-}" \
            -e RACE_STONE_ENTRY_ALIGN_Y_TOL="${RACE_STONE_ENTRY_ALIGN_Y_TOL:-}" \
            -e RACE_STONE_ENTRY_ALIGN_YAW_TOL="${RACE_STONE_ENTRY_ALIGN_YAW_TOL:-}" \
            -e RACE_STONE_ENTRY_ALIGN_VX="${RACE_STONE_ENTRY_ALIGN_VX:-}" \
            -e RACE_STONE_ENTRY_ALIGN_VY_GAIN="${RACE_STONE_ENTRY_ALIGN_VY_GAIN:-}" \
            -e RACE_STONE_ENTRY_ALIGN_VY_LIMIT="${RACE_STONE_ENTRY_ALIGN_VY_LIMIT:-}" \
            -e RACE_STONE_ENTRY_ALIGN_YAW_GAIN="${RACE_STONE_ENTRY_ALIGN_YAW_GAIN:-}" \
            -e RACE_STONE_ENTRY_ALIGN_YAW_LIMIT="${RACE_STONE_ENTRY_ALIGN_YAW_LIMIT:-}" \
            -e RACE_STONE_POST_ALIGN_START_X="${RACE_STONE_POST_ALIGN_START_X:-}" \
            -e RACE_STONE_POST_ALIGN_END_X="${RACE_STONE_POST_ALIGN_END_X:-}" \
            -e RACE_STONE_POST_ALIGN_Y_TOL="${RACE_STONE_POST_ALIGN_Y_TOL:-}" \
            -e RACE_STONE_POST_ALIGN_YAW_TOL="${RACE_STONE_POST_ALIGN_YAW_TOL:-}" \
            -e RACE_STONE_POST_ALIGN_VX="${RACE_STONE_POST_ALIGN_VX:-}" \
            -e RACE_STONE_POST_ALIGN_VY_GAIN="${RACE_STONE_POST_ALIGN_VY_GAIN:-}" \
            -e RACE_STONE_POST_ALIGN_VY_LIMIT="${RACE_STONE_POST_ALIGN_VY_LIMIT:-}" \
            -e RACE_STONE_POST_ALIGN_YAW_GAIN="${RACE_STONE_POST_ALIGN_YAW_GAIN:-}" \
            -e RACE_STONE_POST_ALIGN_YAW_LIMIT="${RACE_STONE_POST_ALIGN_YAW_LIMIT:-}" \
            -e RACE_STONE_LANE_HARD_Y="${RACE_STONE_LANE_HARD_Y:-}" \
            -e RACE_STONE_LANE_HARD_VX="${RACE_STONE_LANE_HARD_VX:-}" \
            -e RACE_STONE_LANE_HARD_VY_GAIN="${RACE_STONE_LANE_HARD_VY_GAIN:-}" \
            -e RACE_STONE_LANE_HARD_VY_LIMIT="${RACE_STONE_LANE_HARD_VY_LIMIT:-}" \
            -e RACE_STONE_LANE_HARD_YAW_GAIN="${RACE_STONE_LANE_HARD_YAW_GAIN:-}" \
            -e RACE_STONE_LANE_HARD_YAW_LIMIT="${RACE_STONE_LANE_HARD_YAW_LIMIT:-}" \
            -e RACE_STONE_IMPACT_VX="${RACE_STONE_IMPACT_VX:-}" \
            -e RACE_STONE_STEP="${RACE_STONE_STEP:-}" \
            -e RACE_STONE_BODY_H="${RACE_STONE_BODY_H:-}" \
            -e RACE_STONE_PITCH_BIAS="${RACE_STONE_PITCH_BIAS:-}" \
            -e RACE_STONE_STEPUP_PITCH="${RACE_STONE_STEPUP_PITCH:-}" \
            -e RACE_STONE_LANE_VY_GAIN="${RACE_STONE_LANE_VY_GAIN:-}" \
            -e RACE_STONE_PAIR_SETTLE_SEC="${RACE_STONE_PAIR_SETTLE_SEC:-}" \
            -e RACE_STONE_PAIR_SETTLE_Y="${RACE_STONE_PAIR_SETTLE_Y:-}" \
            -e RACE_STONE_PAIR_SETTLE_VX="${RACE_STONE_PAIR_SETTLE_VX:-}" \
            -e RACE_STONE_PAIR_CENTER_VY_GAIN="${RACE_STONE_PAIR_CENTER_VY_GAIN:-}" \
            -e RACE_STONE_PAIR_CENTER_VY_LIMIT="${RACE_STONE_PAIR_CENTER_VY_LIMIT:-}" \
            -e RACE_STONE_FRONT_PAIR_WAIT_SEC="${RACE_STONE_FRONT_PAIR_WAIT_SEC:-}" \
            -e RACE_STONE_FRONT_PAIR_WAIT_VX="${RACE_STONE_FRONT_PAIR_WAIT_VX:-}" \
            -e RACE_STONE_FRONT_PAIR_HOLD_SEC="${RACE_STONE_FRONT_PAIR_HOLD_SEC:-}" \
            -e RACE_STONE_FRONT_PAIR_PULSE_VX="${RACE_STONE_FRONT_PAIR_PULSE_VX:-}" \
            -e RACE_STONE_FRONT_PAIR_PULSE_SEC="${RACE_STONE_FRONT_PAIR_PULSE_SEC:-}" \
            -e RACE_STONE_FRONT_PAIR_PULSE_GAP_SEC="${RACE_STONE_FRONT_PAIR_PULSE_GAP_SEC:-}" \
            -e RACE_STONE_FRONT_PAIR_UNLOAD_VY_GAIN="${RACE_STONE_FRONT_PAIR_UNLOAD_VY_GAIN:-}" \
            -e RACE_STONE_FRONT_PAIR_UNLOAD_VY_LIMIT="${RACE_STONE_FRONT_PAIR_UNLOAD_VY_LIMIT:-}" \
            -e RACE_STONE_FRONT_PAIR_UNLOAD_YAW_LIMIT="${RACE_STONE_FRONT_PAIR_UNLOAD_YAW_LIMIT:-}" \
            -e RACE_STONE_FRONT_PAIR_YAW_GAIN="${RACE_STONE_FRONT_PAIR_YAW_GAIN:-}" \
            -e RACE_STONE_FRONT_PAIR_PITCH="${RACE_STONE_FRONT_PAIR_PITCH:-}" \
            -e RACE_STONE_FRONT_PAIR_BODY_DROP="${RACE_STONE_FRONT_PAIR_BODY_DROP:-}" \
            -e RACE_STONE_EDGE_X_MIN="${RACE_STONE_EDGE_X_MIN:-}" \
            -e RACE_STONE_EDGE_X_MAX="${RACE_STONE_EDGE_X_MAX:-}" \
            -e RACE_STONE_EDGE_JUMP_TRIGGER_X="${RACE_STONE_EDGE_JUMP_TRIGGER_X:-}" \
            -e RACE_STONE_EDGE_JUMP_AFTER_X="${RACE_STONE_EDGE_JUMP_AFTER_X:-}" \
            -e RACE_STONE_EDGE_JUMP_DONE_X="${RACE_STONE_EDGE_JUMP_DONE_X:-}" \
            -e RACE_STONE_EDGE_JUMP_ALIGN_SEC="${RACE_STONE_EDGE_JUMP_ALIGN_SEC:-}" \
            -e RACE_STONE_EDGE_JUMP_STONE_Y_MIN="${RACE_STONE_EDGE_JUMP_STONE_Y_MIN:-}" \
            -e RACE_STONE_EDGE_JUMP_GAIT="${RACE_STONE_EDGE_JUMP_GAIT:-}" \
            -e RACE_STONE_EDGE_JUMP_Y_TOL="${RACE_STONE_EDGE_JUMP_Y_TOL:-}" \
            -e RACE_STONE_EDGE_JUMP_YAW_TOL="${RACE_STONE_EDGE_JUMP_YAW_TOL:-}" \
            -e RACE_STONE_EDGE_JUMP_FORCE_YAW_TOL="${RACE_STONE_EDGE_JUMP_FORCE_YAW_TOL:-}" \
            -e RACE_STONE_EDGE_JUMP_ROLL_TOL="${RACE_STONE_EDGE_JUMP_ROLL_TOL:-}" \
            -e RACE_STONE_EDGE_JUMP_PITCH_TOL="${RACE_STONE_EDGE_JUMP_PITCH_TOL:-}" \
            -e RACE_STONE_EDGE_JUMP_ALIGN_VX="${RACE_STONE_EDGE_JUMP_ALIGN_VX:-}" \
            -e RACE_STONE_EDGE_JUMP_ALIGN_VY_LIMIT="${RACE_STONE_EDGE_JUMP_ALIGN_VY_LIMIT:-}" \
            -e RACE_STONE_EDGE_JUMP_ALIGN_YAW_LIMIT="${RACE_STONE_EDGE_JUMP_ALIGN_YAW_LIMIT:-}" \
            -e RACE_STONE_EDGE_JUMP_RECOVER_SEC="${RACE_STONE_EDGE_JUMP_RECOVER_SEC:-}" \
            -e RACE_STONE_EDGE_JUMP_STAND_SEC="${RACE_STONE_EDGE_JUMP_STAND_SEC:-}" \
            -e RACE_STONE_EDGE_JUMP_DRIVE_SEC="${RACE_STONE_EDGE_JUMP_DRIVE_SEC:-}" \
            -e RACE_STONE_EDGE_JUMP_DRIVE_DONE_X="${RACE_STONE_EDGE_JUMP_DRIVE_DONE_X:-}" \
            -e RACE_STONE_EDGE_JUMP_DRIVE_VX="${RACE_STONE_EDGE_JUMP_DRIVE_VX:-}" \
            -e RACE_STONE_EDGE_JUMP_DRIVE_YAW_LIMIT="${RACE_STONE_EDGE_JUMP_DRIVE_YAW_LIMIT:-}" \
            -e RACE_STAGE1_STONE_ALIGN_YAW="${RACE_STAGE1_STONE_ALIGN_YAW:-}" \
            -e RACE_STAGE1_TAIL_CLEAR_X="${RACE_STAGE1_TAIL_CLEAR_X:-}" \
            -e RACE_STAGE1_TAIL_CLEAR_SEC="${RACE_STAGE1_TAIL_CLEAR_SEC:-}" \
            -e RACE_STAGE1_TAIL_CLEAR_VX="${RACE_STAGE1_TAIL_CLEAR_VX:-}" \
            -e RACE_STAGE1_TAIL_CLEAR_YAW_LIMIT="${RACE_STAGE1_TAIL_CLEAR_YAW_LIMIT:-}" \
            -e RACE_STAGE1_GAP_INNER_RADIUS="${RACE_STAGE1_GAP_INNER_RADIUS:-}" \
            -e RACE_STAGE1_GAP_X="${RACE_STAGE1_GAP_X:-}" \
            -e RACE_STAGE1_GAP_BELOW_Y="${RACE_STAGE1_GAP_BELOW_Y:-}" \
            -e RACE_STAGE1_GAP_BELOW_RADIUS="${RACE_STAGE1_GAP_BELOW_RADIUS:-}" \
            -e RACE_STAGE1_GAP_CRAWL_VX="${RACE_STAGE1_GAP_CRAWL_VX:-}" \
            -e RACE_STAGE1_GAP_YAW_LIMIT="${RACE_STAGE1_GAP_YAW_LIMIT:-}" \
            -e RACE_STAGE1_GAP_X_TOL="${RACE_STAGE1_GAP_X_TOL:-}" \
            -e RACE_STAGE1_GAP_X_ALIGN_TOL="${RACE_STAGE1_GAP_X_ALIGN_TOL:-}" \
            -e RACE_STAGE1_GAP_X_ALIGN_VX="${RACE_STAGE1_GAP_X_ALIGN_VX:-}" \
            -e RACE_STAGE1_GAP_X_ALIGN_YAW_TOL="${RACE_STAGE1_GAP_X_ALIGN_YAW_TOL:-}" \
            -e RACE_STAGE1_GAP_TURN_Y_TOL="${RACE_STAGE1_GAP_TURN_Y_TOL:-}" \
            -e RACE_STAGE1_GAP_TURN_VY_GAIN="${RACE_STAGE1_GAP_TURN_VY_GAIN:-}" \
            -e RACE_STAGE1_GAP_TURN_VY_LIMIT="${RACE_STAGE1_GAP_TURN_VY_LIMIT:-}" \
            -e RACE_STAGE1_GAP_X_SAFE_MAX="${RACE_STAGE1_GAP_X_SAFE_MAX:-}" \
            -e RACE_STAGE1_GAP_ALIGN_YAW="${RACE_STAGE1_GAP_ALIGN_YAW:-}" \
            -e RACE_STAGE1_GAP_ALIGN_YAW_TOL="${RACE_STAGE1_GAP_ALIGN_YAW_TOL:-}" \
            -e RACE_STAGE1_GAP_STRAIGHT_VX="${RACE_STAGE1_GAP_STRAIGHT_VX:-}" \
            -e RACE_STAGE1_STONE_EXIT_CROSS_X="${RACE_STAGE1_STONE_EXIT_CROSS_X:-}" \
            -e RACE_STAGE1_GAP_OVERRUN_X="${RACE_STAGE1_GAP_OVERRUN_X:-}" \
            -e RACE_STAGE1_GAP_RECOVER_YAW_LIMIT="${RACE_STAGE1_GAP_RECOVER_YAW_LIMIT:-}" \
            -e RACE_STAGE1_GATE_Y_MIN="${RACE_STAGE1_GATE_Y_MIN:-}" \
            -e RACE_STAGE1_BODY_MID_CLEAR_Y="${RACE_STAGE1_BODY_MID_CLEAR_Y:-}" \
            -e RACE_STAGE1_BODY_MID_CLEAR_X_TOL="${RACE_STAGE1_BODY_MID_CLEAR_X_TOL:-}" \
            -e RACE_STAGE1_REAR_CLEAR_Y="${RACE_STAGE1_REAR_CLEAR_Y:-}" \
            -e RACE_STAGE1_REAR_CLEAR_X_MIN="${RACE_STAGE1_REAR_CLEAR_X_MIN:-}" \
            -e RACE_STAGE1_REAR_CLEAR_X_MAX="${RACE_STAGE1_REAR_CLEAR_X_MAX:-}" \
            -e RACE_STAGE2_APPROACH_RADIUS="${RACE_STAGE2_APPROACH_RADIUS:-}" \
            -e RACE_STAGE2_ALIGN_RADIUS="${RACE_STAGE2_ALIGN_RADIUS:-}" \
            -e RACE_STAGE2_HIT_RADIUS="${RACE_STAGE2_HIT_RADIUS:-}" \
            -e RACE_STAGE2_VISUAL_FUSE_DIST="${RACE_STAGE2_VISUAL_FUSE_DIST:-}" \
            -e RACE_STAGE2_VISUAL_STEER_WEIGHT="${RACE_STAGE2_VISUAL_STEER_WEIGHT:-}" \
            -e RACE_STAGE2_VISUAL_MAX_X="${RACE_STAGE2_VISUAL_MAX_X:-}" \
            -e RACE_STAGE2_VISUAL_STEER_GATE="${RACE_STAGE2_VISUAL_STEER_GATE:-}" \
            -e RACE_STAGE2_ORANGE_MIN_AREA="${RACE_STAGE2_ORANGE_MIN_AREA:-}" \
            -e RACE_STAGE2_ORANGE_CENTER_X="${RACE_STAGE2_ORANGE_CENTER_X:-}" \
            -e RACE_STAGE2_ORANGE_HIT_AREA="${RACE_STAGE2_ORANGE_HIT_AREA:-}" \
            -e RACE_STAGE2_FORCE_ORANGE_RADIUS="${RACE_STAGE2_FORCE_ORANGE_RADIUS:-}" \
            -e RACE_STAGE2_ROUTE_RADIUS="${RACE_STAGE2_ROUTE_RADIUS:-}" \
            -e RACE_STAGE2_ROUTE_TIMEOUT="${RACE_STAGE2_ROUTE_TIMEOUT:-}" \
            -e RACE_STAGE2_ROUTE_VX="${RACE_STAGE2_ROUTE_VX:-}" \
            -e RACE_STAGE2_ALIGN_VX="${RACE_STAGE2_ALIGN_VX:-}" \
            -e RACE_STAGE2_ALIGN_VISIBLE_VX="${RACE_STAGE2_ALIGN_VISIBLE_VX:-}" \
            -e RACE_STAGE2_HIT_VX="${RACE_STAGE2_HIT_VX:-}" \
            -e RACE_STAGE2_HIT_SEARCH_VX="${RACE_STAGE2_HIT_SEARCH_VX:-}" \
            -e RACE_STAGE2_VISUAL_MEMORY_SEC="${RACE_STAGE2_VISUAL_MEMORY_SEC:-}" \
            -e RACE_STAGE2_HIT_CONFIRM_TOF="${RACE_STAGE2_HIT_CONFIRM_TOF:-}" \
            -e RACE_STAGE2_HIT_TIMEOUT="${RACE_STAGE2_HIT_TIMEOUT:-}" \
            -e RACE_STAGE2_HIT_TRAVEL_DIST="${RACE_STAGE2_HIT_TRAVEL_DIST:-}" \
            -e RACE_STAGE2_HIT_TRAVEL_MIN_SEC="${RACE_STAGE2_HIT_TRAVEL_MIN_SEC:-}" \
            -e RACE_STAGE2_AIM_PASS_DIST="${RACE_STAGE2_AIM_PASS_DIST:-}" \
            -e RACE_STAGE2_CONFIRM_NUDGE_VX="${RACE_STAGE2_CONFIRM_NUDGE_VX:-}" \
            -e RACE_STAGE2_CONFIRM_NUDGE_MS="${RACE_STAGE2_CONFIRM_NUDGE_MS:-}" \
            -e RACE_STAGE2_EXIT_VX="${RACE_STAGE2_EXIT_VX:-}" \
            -e RACE_STAGE2_BACKUP_VX="${RACE_STAGE2_BACKUP_VX:-}" \
            -e RACE_STAGE2_BACKUP_SEC="${RACE_STAGE2_BACKUP_SEC:-}" \
            -e RACE_STAGE2_ENTRY_CLEAR_X="${RACE_STAGE2_ENTRY_CLEAR_X:-}" \
            -e RACE_STAGE2_ENTRY_CLEAR_Y="${RACE_STAGE2_ENTRY_CLEAR_Y:-}" \
            -e RACE_STAGE2_ENTRY_CLEAR_VX="${RACE_STAGE2_ENTRY_CLEAR_VX:-}" \
            -e RACE_STAGE2_ENTRY_CLEAR_VY="${RACE_STAGE2_ENTRY_CLEAR_VY:-}" \
            -e RACE_STAGE2_ENTRY_CLEAR_SEC="${RACE_STAGE2_ENTRY_CLEAR_SEC:-}" \
            -e RACE_STAGE2_ENTRY_CLEAR_ENABLED="${RACE_STAGE2_ENTRY_CLEAR_ENABLED:-}" \
            -e RACE_STAGE2_VISUAL_HIT_MAX_DIST="${RACE_STAGE2_VISUAL_HIT_MAX_DIST:-}" \
            -e RACE_STAGE2_BALL_SHAKE_DIST="${RACE_STAGE2_BALL_SHAKE_DIST:-}" \
            -e RACE_STAGE2_INPLACE_TURN_YAW="${RACE_STAGE2_INPLACE_TURN_YAW:-}" \
            -e RACE_STAGE2_INPLACE_TURN_DONE_YAW="${RACE_STAGE2_INPLACE_TURN_DONE_YAW:-}" \
            -e RACE_STAGE2_INPLACE_TURN_RATE="${RACE_STAGE2_INPLACE_TURN_RATE:-}" \
            -e RACE_STAGE4_LOW_BODY_H="${RACE_STAGE4_LOW_BODY_H:-}" \
            -e RACE_STAGE4_LOW_BAR_VX="${RACE_STAGE4_LOW_BAR_VX:-}" \
            -e RACE_STAGE4_LOW_BAR_STEP="${RACE_STAGE4_LOW_BAR_STEP:-}" \
            -e RACE_STAGE4_LOW_BAR_PREP_SEC="${RACE_STAGE4_LOW_BAR_PREP_SEC:-}" \
            -e __GL_SYNC_TO_VBLANK=0 \
            -e vblank_mode=0 \
            cyberdog_slam bash -lc "cd /home/cyberdog_sim && bash start_race.sh"
    fi
    echo "FATAL: ros2 not found and docker not available."
    exit 1
fi

if [ "${RACE_SOFTWARE_GL:-0}" = "1" ]; then
    export LIBGL_ALWAYS_SOFTWARE=1
else
    unset LIBGL_ALWAYS_SOFTWARE
fi
export __GL_SYNC_TO_VBLANK=0
export vblank_mode=0
export GAZEBO_PLUGIN_PATH="$WS_ROOT/build/cyberdog_gazebo:$WS_ROOT/install/lib:$GAZEBO_PLUGIN_PATH"
export LD_LIBRARY_PATH="$WS_ROOT/build/cyberdog_locomotion/simbridge:$WS_ROOT/build/cyberdog_locomotion/control:$WS_ROOT/build/cyberdog_locomotion/common:$WS_ROOT/install/lib:/usr/local/lib:$LD_LIBRARY_PATH"

cleanup_sim_processes() {
    echo "[$(date +%H:%M:%S)] Cleaning stale simulation processes..."
    pkill -TERM -f "ros2 launch cyberdog_gazebo race_gazebo.launch.py" 2>/dev/null || true
    pkill -TERM -f "ros2 launch cyberdog_visual cyberdog_visual.launch.py" 2>/dev/null || true
    pkill -TERM -f "race_controller/race_controller.py" 2>/dev/null || true
    pkill -TERM -f "gzserver .*race.world" 2>/dev/null || true
    pkill -TERM -f "gzclient" 2>/dev/null || true
    pkill -TERM -f "cyberdog_visual" 2>/dev/null || true
    pkill -TERM -f "cyberdog_control" 2>/dev/null || true
    pkill -TERM -f "robot_state_publisher" 2>/dev/null || true
    pkill -TERM -f "motion_manager" 2>/dev/null || true
    pkill -TERM -f "keybroad_commander" 2>/dev/null || true
    sleep "${CLEAN_SLEEP:-1}"
    pkill -9 -f "ros2 launch cyberdog_gazebo race_gazebo.launch.py" 2>/dev/null || true
    pkill -9 -f "ros2 launch cyberdog_visual cyberdog_visual.launch.py" 2>/dev/null || true
    pkill -9 -f "race_controller/race_controller.py" 2>/dev/null || true
    killall -9 gzserver gzclient cyberdog_control cyberdog_visual robot_state_publisher motion_manager 2>/dev/null || true
    pkill -9 -f "keybroad_commander" 2>/dev/null || true
    rm -f /dev/shm/development-simulator /dev/shm/sem.* 2>/dev/null || true
}

CLEANED_ON_EXIT=0
cleanup_on_exit() {
    if [ "$CLEANED_ON_EXIT" = "1" ]; then
        return
    fi
    CLEANED_ON_EXIT=1
    cleanup_sim_processes
}

# ── 二进制路径（优先 install，回退 build） ──────────────────────
if [ -x "$WS_ROOT/install/lib/cyberdog_locomotion/cyberdog_control" ]; then
    CTRL_BIN="$WS_ROOT/install/lib/cyberdog_locomotion/cyberdog_control"
elif [ -x "$WS_ROOT/build/cyberdog_locomotion/control/user/cyberdog_control" ]; then
    CTRL_BIN="$WS_ROOT/build/cyberdog_locomotion/control/user/cyberdog_control"
else
    echo "FATAL: cyberdog_control binary not found!"
    exit 1
fi
echo "[$(date +%H:%M:%S)] Control binary: $CTRL_BIN"
CTRL_DIR="$(dirname "$CTRL_BIN")"

# ── 阶段 0: 清理 ────────────────────────────────────────────────
echo "[$(date +%H:%M:%S)] [0/5] Cleaning..."
cleanup_sim_processes
trap cleanup_on_exit EXIT
trap 'exit 130' INT TERM

# ── 阶段 1/2: Gazebo + 共享内存 ────────────────────────────────
GAZEBO_TIMEOUT=${GAZEBO_TIMEOUT:-60}
GAZEBO_EXIT_GRACE=${GAZEBO_EXIT_GRACE:-6}
GAZEBO_RETRIES=${GAZEBO_RETRIES:-3}
GAZEBO_READY=false
GAZEBO_LAUNCH_PID=0

for attempt in $(seq 1 "$GAZEBO_RETRIES"); do
    echo "[$(date +%H:%M:%S)] [1/5] Starting Gazebo server (attempt ${attempt}/${GAZEBO_RETRIES})..."
    : > /tmp/gazebo.log
    nohup ros2 launch cyberdog_gazebo race_gazebo.launch.py \
        use_lidar:=false use_camera:=true headless:="${GAZEBO_HEADLESS}" gui:="${GAZEBO_GUI}" wname:=race \
        > /tmp/gazebo.log 2>&1 &
    GAZEBO_LAUNCH_PID=$!

    echo "[$(date +%H:%M:%S)] [2/5] Waiting Gazebo shared memory (max ${GAZEBO_TIMEOUT}s)..."
    for i in $(seq 1 "$GAZEBO_TIMEOUT"); do
        if [ -e /dev/shm/development-simulator ] && [ -e /dev/shm/sem.sim2robot ]; then
            GAZEBO_READY=true
            echo "[$(date +%H:%M:%S)] [2/5] Gazebo shared memory ready (${i}s)"
            break
        fi

        if grep -qE "No such file or directory|Traceback|Exception|process has died|Segmentation fault|core dumped" /tmp/gazebo.log 2>/dev/null; then
            echo "[WARN] Gazebo launch failed early on attempt ${attempt}."
            echo "--- gazebo log tail ---"
            tail -40 /tmp/gazebo.log 2>/dev/null
            echo "---"
            break
        fi

        if [ "$i" -ge "$GAZEBO_EXIT_GRACE" ] && ! kill -0 "$GAZEBO_LAUNCH_PID" 2>/dev/null && ! pgrep -x gzserver >/dev/null 2>&1; then
            echo "[WARN] Gazebo launch exited before shared memory was ready on attempt ${attempt}."
            echo "--- gazebo log tail ---"
            tail -40 /tmp/gazebo.log 2>/dev/null
            ROS_LATEST_LOG="$(ls -td /root/.ros/log/* 2>/dev/null | head -1)"
            if [ -n "$ROS_LATEST_LOG" ]; then
                echo "--- ros launch log tail: $ROS_LATEST_LOG ---"
                find "$ROS_LATEST_LOG" -maxdepth 1 -type f -name '*.log' -print -exec tail -20 {} \; 2>/dev/null
            fi
            echo "---"
            break
        fi

        [ $((i % 10)) -eq 0 ] && echo "  ... ${i}s"
        sleep 1
    done

    if [ "$GAZEBO_READY" = "true" ]; then
        break
    fi
    if [ "$attempt" -lt "$GAZEBO_RETRIES" ]; then
        cleanup_sim_processes
        sleep 1
    fi
done

if [ "$GAZEBO_READY" != "true" ]; then
    echo "[FATAL] Gazebo shared memory not ready after ${GAZEBO_TIMEOUT}s."
    echo "--- gazebo log tail ---"
    tail -40 /tmp/gazebo.log 2>/dev/null
    echo "---"
    exit 1
fi
ls -la /dev/shm/development-simulator 2>/dev/null | awk '{print "  shm: "$5" bytes"}'

if [ "${GAZEBO_GUI:-true}" = "true" ] && [ "${GAZEBO_HEADLESS:-false}" != "true" ]; then
    echo "[$(date +%H:%M:%S)] [2/5] Gazebo client is managed by race_gazebo.launch.py"
fi

if [ "${RACE_EXTRA_GZCLIENT:-false}" = "true" ] && [ "${GAZEBO_GUI:-true}" = "true" ] && [ "${GAZEBO_HEADLESS:-false}" != "true" ]; then
    echo "[$(date +%H:%M:%S)] [2/5] Starting extra Gazebo client..."
    nohup gzclient > /tmp/gzclient.log 2>&1 &
    GZCLIENT_PID=$!
    sleep "${GZCLIENT_CHECK_SLEEP:-1}"
    if kill -0 "$GZCLIENT_PID" 2>/dev/null; then
        echo "  gzclient PID=$GZCLIENT_PID, alive"
    else
        echo "  WARN: gzclient未启动或已退出，仿真服务仍继续运行。"
        echo "--- gzclient log tail ---"
        tail -20 /tmp/gzclient.log 2>/dev/null
        echo "---"
    fi
fi

# ── 阶段 3: cyberdog_visual / TF ────────────────────────────────
echo "[$(date +%H:%M:%S)] [3/5] Starting cyberdog_visual (vodom TF)..."
nohup ros2 launch cyberdog_visual cyberdog_visual.launch.py \
    use_lidar:=false use_camera:=true publish_robot_state:=false rviz:=false use_sim_time:=true \
    > /tmp/visual.log 2>&1 &
VISUALPID=$!
sleep "${VISUAL_CHECK_SLEEP:-1}"
if ! kill -0 $VISUALPID 2>/dev/null; then
    echo "[FATAL] cyberdog_visual launch crashed!"
    echo "--- visual log tail ---"
    tail -30 /tmp/visual.log 2>/dev/null
    echo "---"
    exit 1
fi
echo "  PID=$VISUALPID, alive"

# ── 阶段 4: cyberdog_control ────────────────────────────────────
echo "[$(date +%H:%M:%S)] [4/5] Starting cyberdog_control..."
(
    cd "$CTRL_DIR" || exit 1
    exec ./cyberdog_control m s
) > /tmp/control.log 2>&1 &
CTLPID=$!
sleep "${CONTROL_CHECK_SLEEP:-2}"
if ! kill -0 $CTLPID 2>/dev/null; then
    echo "[FATAL] control crashed!"
    echo "--- control log tail ---"
    tail -30 /tmp/control.log 2>/dev/null
    echo "---"
    exit 1
fi
echo "  PID=$CTLPID, alive"

# ── 阶段 5: 启动竞赛 ────────────────────────────────────────────
echo "[$(date +%H:%M:%S)] [5/5] Starting RACE CONTROLLER!"
echo "══════════════════════════════════════════════════════════════"
echo "  流程: RecoveryStand(直接站立) → 6赛段竞赛"
echo "  控制器: race_controller.py (视觉 + 里程计 + IMU + TOF + 固定坐标)"
echo "══════════════════════════════════════════════════════════════"

python3 "$WS_ROOT/race_controller/race_controller.py"
RACE_STATUS=$?
exit "$RACE_STATUS"
