#!/bin/bash
# ============================================================
# CyberDog Simulation 完整启动脚本
# 用法: ./launch_all.sh [start|stop|status]
# ============================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_DIR="$SCRIPT_DIR/logs"
GAZEBO_LOG="$LOG_DIR/gazebo.log"
CONTROL_LOG="$LOG_DIR/control.log"

# 环境变量
export GAZEBO_PLUGIN_PATH=$SCRIPT_DIR/build/cyberdog_gazebo:$SCRIPT_DIR/install/lib:$GAZEBO_PLUGIN_PATH
export LD_LIBRARY_PATH=$SCRIPT_DIR/build/cyberdog_locomotion/simbridge:$SCRIPT_DIR/build/cyberdog_locomotion/control:$SCRIPT_DIR/build/cyberdog_locomotion/common:$SCRIPT_DIR/install/lib:$LD_LIBRARY_PATH
export LC_ALL=C

do_start() {
    echo "========================================="
    echo "  CyberDog Simulation 启动中..."
    echo "========================================="

    mkdir -p "$LOG_DIR"

    cd "$SCRIPT_DIR"
    source /opt/ros/galactic/setup.bash
    source install/setup.bash

    # 清理
    killall -9 gzserver gzclient cyberdog_control 2>/dev/null || true
    sleep 2
    rm -f /dev/shm/* 2>/dev/null

    # Step 1: 启动 Gazebo (headless 模式)
    echo "[1/3] 启动 Gazebo 仿真环境..."
    nohup ros2 launch cyberdog_gazebo race_gazebo.launch.py headless:=true > "$GAZEBO_LOG" 2>&1 &
    GAZEBO_PID=$!
    echo "  Gazebo PID: $GAZEBO_PID"

    # 等待共享内存
    echo -n "  等待共享内存就绪..."
    for i in $(seq 1 30); do
        if ls /dev/shm/development-simulator /dev/shm/sem.* 2>/dev/null | grep -q .; then
            echo " OK (${i}s)"
            break
        fi
        sleep 1
        echo -n "."
    done

    if ! ls /dev/shm/development-simulator /dev/shm/sem.* 2>/dev/null | grep -q .; then
        echo " FAIL"
        echo "[ERROR] 共享内存未创建，检查日志: $GAZEBO_LOG"
        tail -20 "$GAZEBO_LOG"
        exit 1
    fi

    # Step 2: 启动 cyberdog_control
    echo "[2/3] 启动 cyberdog_control..."
    cd "$SCRIPT_DIR/install/lib/cyberdog_locomotion"
    nohup ./cyberdog_control m s > "$CONTROL_LOG" 2>&1 &
    CONTROL_PID=$!
    echo "  Control PID: $CONTROL_PID"
    sleep 3

    # 验证 cyberdog_control 存活
    if ! ps -p $CONTROL_PID > /dev/null 2>&1; then
        echo "[ERROR] cyberdog_control 启动失败，检查日志: $CONTROL_LOG"
        tail -20 "$CONTROL_LOG"
        exit 1
    fi

    # 验证成功连接
    if ! grep -q "robot is alive" "$GAZEBO_LOG" 2>/dev/null; then
        sleep 3
    fi
    if grep -q "robot is alive" "$GAZEBO_LOG" 2>/dev/null; then
        echo "  Gazebo ↔ Control 连接成功"
    fi

    echo "[3/3] 启动完成！"
    echo ""
    echo "========================================="
    echo "  使用方法："
    echo "  在新终端（Docker容器内）运行："
    echo "    cd /home/cyberdog_sim"
    echo "    ./install/lib/cyberdog_example/keybroad_commander"
    echo ""
    echo "  键盘控制："
    echo "    Y: 站立    B: 趴下"
    echo "    W/S: 前进/后退"
    echo "    A/D: 左移/右移"
    echo "    Q/E: 左转/右转"
    echo "    Ctrl+C: 退出"
    echo "========================================="
    echo "  日志文件:"
    echo "    Gazebo:  $GAZEBO_LOG"
    echo "    Control: $CONTROL_LOG"
    echo "========================================="
}

do_stop() {
    echo "停止所有仿真进程..."
    killall -9 gzserver gzclient cyberdog_control 2>/dev/null || true
    sleep 1
    rm -f /dev/shm/*
    echo "已停止"
}

do_status() {
    echo "=== 仿真系统状态 ==="
    echo ""
    echo "--- 进程 ---"
    ps aux 2>/dev/null | grep -E "(gzserver|cyberdog_control)" | grep -v grep || echo "  无运行进程"
    echo ""
    echo "--- 共享内存 ---"
    ls -la /dev/shm/ 2>/dev/null || echo "  无共享内存"
    echo ""
    echo "--- Gazebo 日志 (最后5行) ---"
    tail -5 "$GAZEBO_LOG" 2>/dev/null || echo "  无日志"
    echo ""
    echo "--- Control 日志 (最后5行) ---"
    tail -5 "$CONTROL_LOG" 2>/dev/null || echo "  无日志"
}

case "${1:-start}" in
    start)
        do_start
        ;;
    stop)
        do_stop
        ;;
    status)
        do_status
        ;;
    restart)
        do_stop
        sleep 2
        do_start
        ;;
    *)
        echo "用法: $0 {start|stop|status|restart}"
        exit 1
        ;;
esac