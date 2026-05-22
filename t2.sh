#!/bin/bash
# 终端2: SuperLIO建图 + RViz (使用Gazebo真实激光雷达)
# 用法: bash /home/fish/cyberdog_sim/t2.sh (需先运行t1, 确认数据流正常)

docker exec -it cyberdog_slam bash -c '
export DISPLAY=:0 XAUTHORITY=/run/user/1000/gdm/Xauthority
export LD_LIBRARY_PATH=/home/cyberdog_sim/build/cyberdog_locomotion/simbridge:/home/cyberdog_sim/build/cyberdog_locomotion/control:/home/cyberdog_sim/build/cyberdog_locomotion/common:/home/cyberdog_sim/install/lib:$LD_LIBRARY_PATH
source /opt/ros/galactic/setup.bash
source /home/cyberdog_sim/install/setup.bash

echo "[t2] 检查cyberdog_control..."
if pgrep -f "cyberdog_control" > /dev/null; then
    echo "  ✅ control已运行"
else
    echo "  ❌ control未运行! 请先执行 bash /home/fish/cyberdog_sim/t1.sh"
    exit 1
fi

echo "[t2] 验证Gazebo数据流..."
sleep 3
JOINT_OK="false"
CLOCK_OK="false"
IMU_OK="false"
LIDAR_OK="false"

HZ=$(timeout 5 ros2 topic hz /joint_states 2>&1 | grep "average rate") && JOINT_OK="true"
HZ=$(timeout 5 ros2 topic hz /clock 2>&1 | grep "average rate") && CLOCK_OK="true"
HZ=$(timeout 5 ros2 topic hz /imu 2>&1 | grep "average rate") && IMU_OK="true"
HZ=$(timeout 5 ros2 topic hz /velodyne_points 2>&1 | grep "average rate") && LIDAR_OK="true"

echo "  /joint_states:   $([ "$JOINT_OK" = "true" ] && echo "✅" || echo "❌")"
echo "  /clock:          $([ "$CLOCK_OK" = "true" ] && echo "✅" || echo "❌")"
echo "  /imu:            $([ "$IMU_OK" = "true" ] && echo "✅" || echo "❌")"
echo "  /velodyne_points: $([ "$LIDAR_OK" = "true" ] && echo "✅" || echo "❌")"

if [ "$LIDAR_OK" != "true" ]; then
    echo ""
    echo "  ⚠️ /velodyne_points 无数据! Gazebo仿真可能未完全启动"
    echo "  请确认终端1显示 ✅ Gazebo仿真正常运行 后再执行此脚本"
fi

echo ""
echo "[t2] 启动静态TF发布器 (world->map)..."
ros2 run tf2_ros static_transform_publisher 0 0 0 0 0 0 world map &
sleep 1

echo "[t2] 启动Super-LIO..."
cd /home/cyberdog_sim/src/Super-LIO-ros2 && source install/setup.bash
ros2 run super_lio super_lio_node --ros-args \
    --params-file install/share/super_lio/config/hesai.yaml \
    --log-level info &
SUPER_PID=$!
echo "[t2] Super-LIO PID=$SUPER_PID"
sleep 8

if ps -p $SUPER_PID > /dev/null 2>&1; then
    echo "  ✅ Super-LIO 运行中"
else
    echo "  ❌ Super-LIO 已退出!"
fi

echo ""
echo "[t2] 启动RViz (独立启动，避免崩溃)..."
# 不使用lio.rviz配置(会导致SIGSEGV)，用空配置手动添加
ros2 run rviz2 rviz2 --ros-args -r __node:=rviz_lio &
RVIZ_PID=$!
echo "[t2] RViz PID=$RVIZ_PID"
sleep 3

echo ""
echo "============================================="
echo "[t2] 启动完成! 请在RViz中手动配置:"
echo "============================================="
echo ""
echo "  1. Global Options → Fixed Frame: world"
echo "  2. 点击 Add → By topic → 选择 /lio/cloud_world"
echo "  3. PointCloud2 设置:"
echo "     Style: Points"
echo "     Size: 3"
echo "     Color Transformer: Intensity 或 AxisColor"
echo "     Decay Time: 0"
echo ""
echo "============================================="
echo "[t2] 保持此终端打开. 按 Ctrl+C 停止"
wait
'