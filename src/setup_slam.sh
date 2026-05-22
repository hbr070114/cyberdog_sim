#!/bin/bash
# ============================================================
# 🚀 CyberDog SuperLIO SLAM 一键配置与编译脚本
# 功能：自动编译SuperLIO + 增强版键盘控制器
# 使用方法：chmod +x setup_slam.sh && ./setup_slam.sh
# ============================================================

set -e  # 遇到错误立即停止

echo "========================================"
echo "  🔧 CyberDog SuperLIO 配置工具"
echo "========================================"
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 检查是否在Docker容器内
if [ -f /.dockerenv ]; then
    echo -e "${GREEN}✅ 检测到已在Docker容器内${NC}"
else
    echo -e "${YELLOW}⚠️  当前不在Docker容器中${NC}"
    echo ""
    echo "请先启动Docker容器，然后在容器内执行此脚本："
    echo ""
    echo "  步骤1: 加载镜像（已完成）"
    echo "  步骤2: 授权X显示"
    echo "        xhost +"
    echo ""
    echo "  步骤3: 启动容器并挂载当前目录"
    echo "        sudo docker run -it --privileged=true \\"
    echo "          -e DISPLAY=\$DISPLAY \\"
    echo "          -v /tmp/.X11-unix:/tmp/.X11-unix \\"
    echo "          -v /home/fish/cyberdog_sim:/home/cyberdog_sim \\"
    echo "          cyberdog_sim:v2026"
    echo ""
    echo "  步骤4: 在容器内执行此脚本"
    echo "        cd /home/cyberdog_sim"
    echo "        bash src/setup_slam.sh"
    exit 1
fi

echo -e "${YELLOW}[1/5] 检查SuperLIO源码...${NC}"
if [ -d "/home/cyberdog_sim/src/Super-LIO-ros2" ]; then
    echo -e "${GREEN}✅ SuperLIO已解压${NC}"
else
    echo -e "${RED}❌ 找不到SuperLIO目录${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}[2/5] 编译SuperLIO算法...${NC}"
cd /home/cyberdog_sim/src/Super-LIO-ros2
source /opt/ros/galactic/setup.bash

if [ -d "install" ] && [ -f "install/setup.bash" ]; then
    echo -e "${GREEN}✅ SuperLIO已编译过，跳过编译${NC}"
else
    echo "正在编译SuperLIO（首次需要5-10分钟）..."
    colcon build
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ SuperLIO编译成功${NC}"
    else
        echo -e "${RED}❌ SuperLIO编译失败${NC}"
        exit 1
    fi
fi

source install/setup.bash

echo ""
echo -e "${YELLOW}[3/5] 编译增强版键盘控制器...${NC}"
cd /home/cyberdog_sim
source /opt/ros/galactic/setup.bash

if [ -d "install" ]; then
    source install/setup.bash
    echo "重新编译cyberdog_example包..."
    colcon build --packages-select cyberdog_example --symlink-install
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ 键盘控制器编译成功${NC}"
    else
        echo -e "${RED}❌ 键盘控制器编译失败${NC}"
        exit 1
    fi
else
    echo -e "${RED}❌ cyberdog_sim工作空间未初始化${NC}"
    echo "请先编译整个cyberdog_sim工作空间："
    echo "  cd /home/cyberdog_sim"
    echo "  colcon build"
    exit 1
fi

echo ""
echo -e "${YELLOW}[4/5] 验证配置文件...${NC}"

CONFIG_FILE="/home/fish/cyberdog_sim/src/Super-LIO-ros2/src/super_lio/config/livox_360.yaml"
if grep -q "lio.map.save_map: true" "$CONFIG_FILE"; then
    echo -e "${GREEN}✅ 自动保存已启用${NC}"
else
    echo -e "${YELLOW}⚠️  正在配置自动保存...${NC}"
    sed -i 's/lio.map.save_map: false/lio.map.save_map: true/' $CONFIG_FILE
    sed -i 's/lio.map.map_name: "map.pcd"/lio.map.map_name: "race_map.pcd"/' $CONFIG_FILE
    sed -i 's/lio.map.ds_size: 0.25/lio.map.ds_size: 0.15/' $CONFIG_FILE
    sed -i 's/lio.map.save_interval: 500/lio.map.save_interval: 300/' $CONFIG_FILE
    echo -e "${GREEN}✅ 自动保存配置完成${NC}"
fi

echo ""
echo -e "${YELLOW}[5/5] 创建快速启动脚本...${NC}"

cat > /home/cyberdog_sim/start_slam.sh << 'EOF'
#!/bin/bash
# CyberDog SuperLIO SLAM 三步启动脚本

echo "=========================================="
echo "  🐕 CyberDog SuperLIO SLAM 建图系统"
echo "=========================================="

if [ "$1" == "1" ] || [ "$1" == "" ]; then
    echo ""
    echo "📍 [终端1] 启动Gazebo仿真..."
    cd /home/cyberdog_sim
    source /opt/ros/galactic/setup.bash
    source install/setup.bash
    ros2 launch cyberdog_gazebo race_gazebo.launch.py use_lidar:=true
    
elif [ "$1" == "2" ]; then
    echo ""
    echo "📍 [终端2] 启动SuperLIO + Rviz..."
    cd /home/cyberdog_sim/src/Super-LIO-ros2
    source /opt/ros/galactic/setup.bash
    source install/setup.bash
    ros2 launch super_lio Livox_mid360.py rviz:=true \
        --ros-args \
        -r /livox/lidar:=/scan \
        -r /livox/imu:=/imu
        
elif [ "$1" == "3" ]; then
    echo ""
    echo "📍 [终端3] 启动键盘控制（增强版）..."
    cd /home/cyberdog_ws
    source /opt/ros/galactic/setup.bash
    source install/setup.bash
    ros2 run motion_manager motion_manager &
    sleep 3
    cd /home/cyberdog_sim
    source install/setup.bash
    ros2 run cyberdog_example keybroad_commander
    
elif [ "$1" == "help" ] || [ "$1" == "-h" ]; then
    echo ""
    echo "用法:"
    echo "  ./start_slam.sh 1     # 终端1: Gazebo仿真"
    echo "  ./start_slam.sh 2     # 终端2: SuperLIO+Rviz"
    echo "  ./start_slam.sh 3     # 终端3: 键盘控制"
    echo ""
    echo "完整流程:"
    echo "  1. 打开3个终端窗口"
    echo "  2. 分别执行: ./start_slam.sh 1 / 2 / 3"
    echo ""
    echo "键盘控制说明:"
    echo "  WASD   - 前后左右移动"
    echo "  JL     - 左右转向"
    echo "  Q/E    - 加速/减速"
    echo "  1/2/3  - 切换步态(慢速/中速/快速)"
    echo "  空格   - 急停"
    echo "  Y      - 恢复站立"
    echo "  R      - 行走模式"
    echo "  T      - 趴下"
    echo "  H      - 显示帮助"
    
else
    echo "未知参数: $1"
    echo "使用 './start_slam.sh help' 查看帮助"
fi
EOF

chmod +x /home/cyberdog_sim/start_slam.sh
echo -e "${GREEN}✅ 快速启动脚本已创建${NC}"

echo ""
echo "========================================"
echo -e "${GREEN}  ✅ 所有配置完成！${NC}"
echo "========================================"
echo ""
echo "📋 接下来的操作步骤："
echo ""
echo "  打开3个新终端，分别执行："
echo ""
echo -e "  ${YELLOW}终端1:${NC}  bash start_slam.sh 1"
echo -e "         （等待Gazebo窗口打开）"
echo ""
echo -e "  ${YELLOW}终端2:${NC}  bash start_slam.sh 2"
echo -e "         （Rviz打开后开始建图）"
echo ""
echo -e "  ${YELLOW}终端3:${NC}  bash start_slam.sh 3"
echo -e "         （用键盘控制机器狗移动）"
echo ""
echo "💡 地图保存位置："
echo "  /home/cyberdog_sim/src/Super-LIO-ros2/src/super_lio/map/race_map.pcd"
echo ""
echo "🎯 建图完成后："
echo "  在终端2按 Ctrl+C 即可自动保存地图"
echo ""
echo "========================================"
