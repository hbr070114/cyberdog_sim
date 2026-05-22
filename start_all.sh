#!/bin/bash
# ============================================================
# 🚀 CyberDog SuperLIO SLAM 终极一键启动脚本
# 用法: ./start_all.sh
# 功能: 从宿主机一条命令完成所有操作（自动启动Docker）
# ============================================================

echo "=========================================="
echo "  🐕 CyberDog SuperLIO SLAM 建图系统"
echo "  🚀 终极一键版 - 自动处理一切"
echo "=========================================="
echo ""

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 检查Docker是否安装
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker未安装${NC}"
    exit 1
fi

# 检查Docker镜像是否存在
if ! docker images cyberdog_sim:v2026 | grep -q "cyberdog_sim"; then
    echo -e "${YELLOW}⚠️  Docker镜像未加载，正在加载...${NC}"
    sudo docker load -i /home/fish/dog/cyberdog_race2026.tar
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ 镜像加载失败${NC}"
        echo "请确认文件存在: /home/fish/dog/cyberdog_race2026.tar"
        exit 1
    fi
    echo -e "${GREEN}✅ 镜像加载成功${NC}"
fi

# 授权X显示
echo -e "${YELLOW}[1/4] 授权X显示...${NC}"
xhost + 2>/dev/null || true

# 检查是否有运行的容器
RUNNING_CONTAINER=$(docker ps -q -f name=cyberdog_slam)
if [ -n "$RUNNING_CONTAINER" ]; then
    echo -e "${YELLOW}发现已运行的CyberDog容器，停止它...${NC}"
    docker stop $RUNNING_CONTAINER > /dev/null 2>&1
    sleep 2
fi

# 启动Docker容器（后台模式）
echo -e "${YELLOW}[2/4] 启动Docker容器...${NC}"

# 创建临时脚本用于容器内编译和启动
TEMP_SCRIPT="/tmp/cyberdog_slam_$$"
cat > $TEMP_SCRIPT << 'CONTAINER_SCRIPT'
#!/bin/bash

cd /home/cyberdog_sim

# 检查SuperLIO是否已编译
if [ ! -d "src/Super-LIO-ros2/install" ]; then
    echo "📦 首次使用，正在编译SuperLIO（需要5-10分钟）..."
    cd src/Super-LIO-ros2
    source /opt/ros/galactic/setup.bash
    colcon build
    source install/setup.bash
    cd /home/cyberdog_sim
    echo "✅ SuperLIO编译完成！"
else
    echo "✅ SuperLIO已编译，跳过..."
fi

# 编译键盘控制器
source /opt/ros/galactic/setup.bash
source install/setup.bash > /dev/null 2>&1 || true
colcon build --packages-select cyberdog_example --symlink-install 2>/dev/null || true
source install/setup.bash > /dev/null 2>&1 || true

echo "✅ 系统准备就绪！正在启动..."

# 终端1: Gazebo
gnome-terminal --title="Gazebo仿真" -- bash -c '
    echo "📍 [1/3] 启动Gazebo仿真..."
    cd /home/cyberdog_sim
    source /opt/ros/galactic/setup.bash
    source install/setup.bash
    ros2 launch cyberdog_gazebo race_gazebo.launch.py use_lidar:=true
    exec bash' &

sleep 12

# 终端2: SuperLIO + Rviz  
gnome-terminal --title="SuperLIO+Rviz" -- bash -c '
    echo "📍 [2/3] 启动SuperLIO + Rviz..."
    cd /home/cyberdog_sim/src/Super-LIO-ros2
    source /opt/ros/galactic/setup.bash
    source install/setup.bash
    ros2 launch super_lio Livox_mid360.py rviz:=true \
        --ros-args \
        -r /livox/lidar:=/scan \
        -r /livox/imu:=/imu
    echo ""
    echo "🎉 地图已保存到:"
    echo "   /home/cyberdog_sim/src/Super-LIO-ros2/src/super_lio/map/race_map.pcd"
    exec bash' &

sleep 10

# 终端3: 键盘控制
gnome-terminal --title="⌨️ 键盘控制(增强版)" -- bash -c '
    echo "📍 [3/3] 启动键盘控制..."
    cd /home/cyberdog_ws
    source /opt/ros/galactic/setup.bash
    source install/setup.bash
    ros2 run motion_manager motion_manager &
    sleep 4
    
    cd /home/cyberdog_sim
    source install/setup.bash
    
    echo ""
    echo "========================================"
    echo "  🐕 增强版键盘控制器 v2.0"
    echo "========================================"
    echo ""
    echo "【基本移动】WASD + JL (转向)"
    echo "【速度控制】Q/E 加速/减速"
    echo ""
    echo "【步态切换】"
    echo "  1 → 慢速行走(303) ⭐石板路/独木桥/坡道"
    echo "  2 → 中速行走(308) ✅平地建图(默认)"
    echo "  3 → 快速行走(305) ⚡开阔地带"
    echo ""
    echo "【姿态控制】I/K 俯仰 | 空格 急停"
    echo "【系统控制】Y 恢复站立 | R 行走 | T 趴下"
    echo ""
    echo "💡 快速开始:"
    echo "   y → r → 1 → w (开始建图)"
    echo ""
    echo "========================================"
    
    ros2 run cyberdog_example keybroad_commander
    exec bash' &

echo ""
echo "✅ 所有系统已启动！请查看弹出的窗口"
echo "   窗口1: Gazebo仿真器"
echo "   窗口2: SuperLIO + Rviz"
echo "   窗口3: 键盘控制（在此操作）"
echo ""
tail -f /dev/null
CONTAINER_SCRIPT
chmod +x $TEMP_SCRIPT

echo -e "${YELLOW}[3/4] 正在启动容器并初始化系统...${NC}"
echo -e "${YELLOW}       （首次需要5-10分钟编译，之后只需30秒）${NC}"
echo ""

# 启动容器并执行脚本
sudo docker run -it --rm \
    --name cyberdog_slam \
    --privileged=true \
    -e DISPLAY=$DISPLAY \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -v /home/fish/cyberdog_sim:/home/cyberdog_sim \
    -v $TEMP_SCRIPT:/start.sh \
    cyberdog_sim:v2026 \
    /bin/bash /start.sh

# 清理临时文件
rm -f $TEMP_SCRIPT

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  ✅ 系统已关闭${NC}"
echo -e "${GREEN}========================================${NC}"
