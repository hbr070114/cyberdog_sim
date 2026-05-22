#!/bin/bash
set -e

echo "=========================================="
echo "  🔧 安装 Glog 依赖 + 编译 SuperLIO"
echo "=========================================="

cd /home/cyberdog_sim

echo ""
echo "[1/3] 检查 Glog 是否已安装..."
if dpkg -l | grep -q libglog-dev; then
    echo "✅ Glog 已安装"
else
    echo "⏳ 正在安装 libglog-dev..."
    apt-get update -qq
    apt-get install -y libglog-dev
    echo "✅ Glog 安装完成"
fi

echo ""
echo "[2/3] 编译 SuperLIO-ros2..."
cd /home/fish/cyberdog_sim/src/Super-LIO-ros2
source /opt/ros/galactic/setup.bash
colcon build
echo "✅ SuperLIO 编译完成"

echo ""
echo "[3/3] 验证编译结果..."
if [ -d "install" ]; then
    echo "✅ install 目录已生成"
    ls -la install/
else
    echo "❌ 编译可能失败，请检查错误信息"
    exit 1
fi

echo ""
echo "=========================================="
echo "  ✅ 全部完成！现在可以启动 SLAM 了"
echo "=========================================="
echo ""
echo "下一步操作（开3个终端）："
echo ""
echo "终端1 - 启动Gazebo:"
echo "  docker exec -it cyberdog_slam bash -c 'cd /home/cyberdog_sim && source /opt/ros/galactic/setup.bash && source install/setup.bash && ros2 launch cyberdog_gazebo race_gazebo.launch.py use_lidar:=true'"
echo ""
echo "终端2 - 启动SuperLIO+RViz (等Gazebo完全启动后):"
echo "  docker exec -it cyberdog_slam bash -c 'cd /home/cyberdog_sim/src/Super-LIO-ros2 && source /opt/ros/galactic/setup.bash && source install/setup.bash && ros2 launch super_lio Livox_mid360.py rviz:=true --ros-args -r /livox/lidar:=/scan -r /livox/imu:=/imu'"
echo ""
echo "终端3 - 键盘控制 (等RViz出现后):"
echo "  docker exec -it cyberdog_slam bash -c 'cd /home/cyberdog_ws && source /opt/ros/galactic/setup.bash && source install/setup.bash && ros2 run motion_manager motion_manager & sleep 5 && cd /home/cyberdog_sim && source install/setup.bash && ros2 run cyberdog_example keybroad_commander'"
