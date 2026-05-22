#!/bin/bash
set -e
# 终端1: Gazebo图形化 + 激光雷达 + cyberdog_control
# 用法: bash /home/fish/cyberdog_sim/t1.sh

xhost +local:docker 2>/dev/null || true

docker exec -it cyberdog_slam bash -c '
killall -9 gzserver gzclient cyberdog_control rviz2 super_lio_node 2>/dev/null
sleep 2
rm -f /dev/shm/*
export DISPLAY=:0 XAUTHORITY=/run/user/1000/gdm/Xauthority
export GAZEBO_PLUGIN_PATH=/home/cyberdog_sim/build/cyberdog_gazebo:/home/cyberdog_sim/install/lib:$GAZEBO_PLUGIN_PATH
export LD_LIBRARY_PATH=/home/cyberdog_sim/build/cyberdog_locomotion/simbridge:/home/cyberdog_sim/build/cyberdog_locomotion/control:/home/cyberdog_sim/build/cyberdog_locomotion/common:/home/cyberdog_sim/install/lib:$LD_LIBRARY_PATH
export LIBGL_ALWAYS_SOFTWARE=1
mkdir -p /tmp/runtime-root
source /opt/ros/galactic/setup.bash
source /home/cyberdog_sim/install/setup.bash

echo "[t1] 启动Gazebo (use_lidar:=true)..."
ros2 launch cyberdog_gazebo race_gazebo.launch.py use_lidar:=true headless:=false &
GAZEBO_PID=$!

echo "[t1] 等待Gazebo加载世界(15秒)..."
sleep 15

echo "[t1] 检查Gazebo是否存活..."
if ! ps -p $(pgrep -f "gzserver" | head -1) > /dev/null 2>&1; then
    echo "  ❌ Gazebo已崩溃! 检查world文件"
    exit 1
fi
echo "  ✅ GzServer 运行中"

echo "[t1] 启动cyberdog_control..."
/home/cyberdog_sim/install/lib/cyberdog_locomotion/cyberdog_control m s > /home/cyberdog_sim/logs/control.log 2>&1 &
CONTROL_PID=$!
echo "[t1] Control PID=$CONTROL_PID"

echo "[t1] 等待control连接Gazebo(20秒)..."
sleep 20

echo ""
echo "[t1] === 验证数据流 ==="
JOINT_HZ=$(timeout 5 ros2 topic hz /joint_states 2>&1 | grep "average rate" | grep -oP "[\d.]+" || echo "0")
CLOCK_HZ=$(timeout 5 ros2 topic hz /clock 2>&1 | grep "average rate" | grep -oP "[\d.]+" || echo "0")
IMU_HZ=$(timeout 5 ros2 topic hz /imu 2>&1 | grep "average rate" | grep -oP "[\d.]+" || echo "0")
LIDAR_HZ=$(timeout 5 ros2 topic hz /velodyne_points 2>&1 | grep "average rate" | grep -oP "[\d.]+" || echo "0")

echo "  /joint_states: ${JOINT_HZ} Hz"
echo "  /clock:        ${CLOCK_HZ} Hz"
echo "  /imu:          ${IMU_HZ} Hz"
echo "  /velodyne_points: ${LIDAR_HZ} Hz"

if [ "$JOINT_HZ" != "0" ] && [ "$CLOCK_HZ" != "0" ]; then
    echo ""
    echo "  ✅ Gazebo仿真正常运行!"
else
    echo ""
    echo "  ⚠️ 仿真可能未完全启动，但继续等待..."
fi

echo ""
echo "[t1] 就绪! 保持此终端打开."
echo "[t1] 按 Ctrl+C 停止所有进程"
wait
'