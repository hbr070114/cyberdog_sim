#!/bin/bash
# ============================================================
# 🚀 CyberDog SLAM 初始化工具（仅编译准备）
# 用法: ./init.sh
# 功能：编译代码、创建3个启动命令文件
# 注意：不会自动打开任何终端！
# ============================================================

echo "=========================================="
echo "  🔧 CyberDog SLAM 初始化"
echo "  仅编译准备，不自动开窗"
echo "=========================================="
echo ""

cd /home/cyberdog_sim

source /opt/ros/galactic/setup.bash

echo "[1/2] 编译更新..."
colcon build --packages-select cyberdog_gazebo cyberdog_example --symlink-install 2>&1 | grep -E "error|Error" || true
source install/setup.bash 2>/dev/null || true

echo ""
echo "[2/2] 检查SuperLIO..."
cd src/Super-LIO-ros2
if [ ! -d "install" ]; then
    echo "首次编译SuperLIO..."
    colcon build 2>&1 | tail -5
fi
source install/setup.bash
cd /home/cyberdog_sim

echo ""
cat > /tmp/cmd_terminal1.txt << 'EOF'
cd /home/cyberdog_sim && source /opt/ros/galactic/setup.bash && source install/setup.bash && ros2 launch cyberdog_gazebo race_gazebo.launch.py use_lidar:=true
EOF

cat > /tmp/cmd_terminal2.txt << 'EOF'
cd /home/cyberdog_sim/src/Super-LIO-ros2 && source /opt/ros/galactic/setup.bash && source install/setup.bash && ros2 launch super_lio Livox_mid360.py rviz:=true --ros-args -r /livox/lidar:=/scan -r /livox/imu:=/imu
EOF

cat > /tmp/cmd_terminal3.txt << 'EOF'
cd /home/cyberdog_ws && source /opt/ros/galactic/setup.bash && source install/setup.bash && ros2 run motion_manager motion_manager & sleep 8 && cd /home/cyberdog_sim && source install/setup.bash && ros2 run cyberdog_example keybroad_commander
EOF

chmod +x /tmp/cmd_terminal*.txt

echo "✅ 准备完成！"
echo ""
echo "=========================================="
echo "  📋 操作步骤"
echo "=========================================="
echo ""
echo "手动打开3个终端，分别执行以下命令："
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "【终端1】Gazebo仿真 + 机器狗"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
cat /tmp/cmd_terminal1.txt
echo ""
echo "等待15-20秒，确认："
echo "  ✓ Gazebo窗口弹出"
echo "  ✓ 机器狗站立在地上"
echo "  ✓ 有激光射线（头部）"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "【终端2】SuperLIO算法 + Rviz"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
cat /tmp/cmd_terminal2.txt
echo ""
echo "等待10-20秒，确认："
echo "  ✓ Rviz窗口弹出"
echo "  ✓ 左侧显示 Global Status: OK"
echo "  ✓ 主视图有点云数据"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "【终端3】键盘控制"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
cat /tmp/cmd_terminal3.txt
echo ""
echo "然后依次输入："
echo "  y     (恢复站立)"
echo "  r     (行走模式)"
echo "  1     (慢速步态)"
echo "  w     (开始建图)"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "💾 手动保存地图（建图完成后）："
echo ""
echo "在任意新终端执行："
echo "  ros2 run nav2_map_server map_saver_cli -f ~/race_map"
echo ""
echo "或保存点云："
echo "  ros2 topic echo /super_lio/map --once > race_map.pcd"
echo ""
echo "地图保存位置:"
echo "  ~/race_map.yaml 或当前目录的race_map.pcd"
echo ""
echo "=========================================="
