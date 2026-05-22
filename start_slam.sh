#!/bin/bash
# ============================================================
# 🚀 CyberDog SuperLIO SLAM 一键启动脚本（终极版）
# 用法: ./start_slam.sh
# 功能: 一条命令自动打开3个终端并启动所有系统
# ============================================================

echo "=========================================="
echo "  🐕 CyberDog SuperLIO SLAM 建图系统"
echo "  🚀 一键启动版 v1.0"
echo "=========================================="
echo ""

# 检查是否在Docker容器内
if [ ! -f /.dockerenv ]; then
    echo "❌ 错误：必须在Docker容器内执行此脚本"
    echo ""
    echo "请先执行："
    echo "  xhost +"
    echo "  sudo docker run -it --privileged=true \\"
    echo "    -e DISPLAY=\$DISPLAY \\"
    echo "    -v /tmp/.X11-unix:/tmp/.X11-unix \\"
    echo "    -v /home/fish/cyberdog_sim:/home/cyberdog_sim \\"
    echo "    cyberdog_sim:v2026"
    echo ""
    echo "然后在容器内执行: cd /home/cyberdog_sim && ./start_slam.sh"
    exit 1
fi

# 检查SuperLIO是否已编译
if [ ! -d "/home/cyberdog_sim/src/Super-LIO-ros2/install" ]; then
    echo "⚠️  SuperLIO尚未编译，正在执行一键编译..."
    bash /home/cyberdog_sim/src/setup_slam.sh
    if [ $? -ne 0 ]; then
        echo "❌ 编译失败，请检查错误信息"
        exit 1
    fi
fi

echo "✅ 系统检查通过，正在启动..."
echo ""

# 定义公共环境变量
ENV_CMD="source /opt/ros/galactic/setup.bash"

# 终端1: Gazebo仿真
gnome-terminal --title="Gazebo仿真" -- bash -c "
    echo '📍 [1/3] 启动Gazebo仿真...'
    cd /home/cyberdog_sim
    $ENV_CMD
    source install/setup.bash
    ros2 launch cyberdog_gazebo race_gazebo.launch.py use_lidar:=true
    exec bash" &

sleep 10

# 终端2: SuperLIO + Rviz
gnome-terminal --title="SuperLIO+Rviz" -- bash -c "
    echo '📍 [2/3] 启动SuperLIO + Rviz...'
    cd /home/cyberdog_sim/src/Super-LIO-ros2
    $ENV_CMD
    source install/setup.bash
    ros2 launch super_lio Livox_mid360.py rviz:=true \
        --ros-args \
        -r /livox/lidar:=/scan \
        -r /livox/imu:=/imu
    echo ''
    echo '🎉 地图已保存到:'
    echo '   /home/cyberdog_sim/src/Super-LIO-ros2/src/super_lio/map/race_map.pcd'
    exec bash" &

sleep 8

# 终端3: 键盘控制 + 运动管理
gnome-terminal --title="键盘控制(增强版)" -- bash -c "
    echo '📍 [3/3] 启动键盘控制系统...'
    echo ''
    cd /home/cyberdog_ws
    $ENV_CMD
    source install/setup.bash
    echo '[后台] 启动运动管理服务...'
    ros2 run motion_manager motion_manager &
    sleep 3
    
    cd /home/cyberdog_sim
    source install/setup.bash
    
    echo ''
    echo '========================================'
    echo '  🐕 增强版键盘控制器已就绪'
    echo '========================================'
    echo ''
    echo '【基本移动】WASD + JL (转向)'
    echo '【速度控制】Q/E 加速/减速'
    echo ''
    echo '【步态切换】'
    echo '  1 → 慢速行走(303) ⭐石板路/独木桥/坡道'
    echo '  2 → 中速行走(308) ✅平地建图(默认)'
    echo '  3 → 快速行走(305) ⚡开阔地带'
    echo ''
    echo '【姿态控制】I/K 俯仰 | 空格 急停'
    echo '【系统控制】Y 恢复站立 | R 行走模式 | T 趴下 | H帮助'
    echo ''
    echo '💡 开始建图流程:'
    echo '   1. 输入 y (恢复站立)'
    echo '   2. 输入 r (进入行走模式)'
    echo '   3. 输入 1 或 2 或 3 (选择步态)'
    echo '   4. 使用 WASD 控制移动'
    echo '   5. 建图完成后在Rviz窗口按 Ctrl+C 保存地图'
    echo ''
    echo '========================================'
    
    ros2 run cyberdog_example keybroad_commander
    exec bash" &

echo ""
echo "✅ 所有系统已启动！"
echo ""
echo "📋 已打开的窗口："
echo "   ✅ 窗口1: Gazebo仿真器"
echo "   ✅ 窗口2: SuperLIO算法 + Rviz可视化"
echo "   ✅ 窗口3: 键盘控制（在此窗口输入命令）"
echo ""
echo "🎮 请切换到【键盘控制】窗口，按提示操作："
echo "   第一步: 输入 y (恢复站立)"
echo "   第二步: 输入 r (进入行走模式)"
echo "   第三步: 输入 1/2/3 (选择合适步态)"
echo "   第四步: 用 WASD 控制机器狗开始建图"
echo ""
echo "💾 建图完成后:"
echo "   在Rviz窗口(窗口2)按 Ctrl+C → 地图自动保存"
echo "   保存位置: ~/cyberdog_sim/src/Super-LIO-ros2/src/super_lio/map/race_map.pcd"
echo ""
echo "🎉 现在请切换到【键盘控制】窗口开始操作！"
