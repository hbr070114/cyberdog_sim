#!/bin/bash
# ============================================================
# 🔍 CyberDog SLAM 诊断 + 手动分步启动脚本
# 解决问题：
#   1. Docker容器内无法自动打开多个窗口
#   2. 激光雷达未加载/未显示
#   3. Rviz无法启动
# 用法: ./diagnose_and_start.sh
# ============================================================

echo "=========================================="
echo "  🔍 CyberDog SuperLIO SLAM 诊断工具"
echo "=========================================="
echo ""

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 检查环境
if [ ! -f /.dockerenv ]; then
    echo -e "${RED}❌ 必须在Docker容器内执行${NC}"
    exit 1
fi

cd /home/cyberdog_sim

echo -e "${YELLOW}[准备] 编译更新后的代码...${NC}"
source /opt/ros/galactic/setup.bash
colcon build --packages-select cyberdog_gazebo cyberdog_example --symlink-install 2>&1 | grep -E "error|Error" || true
source install/setup.bash 2>/dev/null || true
echo -e "${GREEN}✅ 编译完成${NC}"

echo ""
echo "=========================================="
echo "  📋 分步启动指南（请开3个终端）"
echo "=========================================="
echo ""
echo -e "${BLUE}问题原因分析:${NC}"
echo "  Docker容器内的gnome-terminal无法在宿主机"
echo "  上打开新窗口，所以需要你手动开3个终端。"
echo ""
echo -e "${YELLOW}操作步骤:${NC}"
echo ""
echo "  ${GREEN}步骤1${NC}: 保持当前终端不动（这是主终端）"
echo "         在你的图形界面中打开2个新终端"
echo ""
echo "  ${GREEN}步骤2${NC}: 在【新终端1】中复制粘贴以下命令："
echo ""
echo -e "         ${BLUE}cd /home/cyberdog_sim && source /opt/ros/galactic/setup.bash && source install/setup.bash && ros2 launch cyberdog_gazebo race_gazebo.launch.py use_lidar:=true${NC}"
echo ""
echo "  ${GREEN}步骤3${NC}: 等待Gazebo完全启动（看到机器狗后），"
echo "         在【新终端2】中复制粘贴："
echo ""
echo -e "         ${BLUE}cd /home/cyberdog_sim/src/Super-LIO-ros2 && source /opt/ros/galactic/setup.bash && source install/setup.bash && ros2 launch super_lio Livox_mid360.py rviz:=true --ros-args -r /livox/lidar:=/scan -r /livox/imu:=/imu${NC}"
echo ""
echo "  ${GREEN}步骤4${NC}: 等待Rviz窗口出现后，在【新终端3】中："
echo ""
echo -e "         ${BLUE}cd /home/cyberdog_ws && source /opt/ros/galactic/setup.bash && source install/setup.bash && ros2 run motion_manager motion_manager & sleep 5 && cd /home/cyberdog_sim && source install/setup.bash && ros2 run cyberdog_example keybroad_commander${NC}"
echo ""
echo "=========================================="
echo ""

# 自动诊断功能
echo -e "${YELLOW}🔍 是否需要运行自动诊断？(y/n)${NC}"
read -p "> " run_diagnose

if [ "$run_diagnose" = "y" ] || [ "$run_diagnose" = "Y" ]; then
    echo ""
    echo "=========================================="
    echo "  🔍 系统诊断报告"
    echo "=========================================="
    
    echo ""
    echo "[1/6] 检查ROS2环境..."
    if command -v ros2 &> /dev/null; then
        echo -e "${GREEN}✅ ROS2已安装${NC}"
        ros2 --version | head -1
    else
        echo -e "${RED}❌ ROS2未安装${NC}"
    fi
    
    echo ""
    echo "[2/6] 检查Gazebo插件..."
    if ls /opt/ros/galactic/lib/libgazebo_ros_ray_sensor.so 2>/dev/null; then
        echo -e "${GREEN}✅ 激光雷达插件存在${NC}"
    else
        echo -e "${RED}❌ 激光雷达插件缺失${NC}"
        echo "   路径: /opt/ros/galactic/lib/libgazebo_ros_ray_sensor.so"
    fi
    
    echo ""
    echo "[3/6] 检查cyberdog_gazebo包..."
    if [ -d "/home/cyberdog_sim/install/cyberdog_gazebo" ]; then
        echo -e "${GREEN}✅ cyberdog_gazebo已编译${NC}"
    else
        echo -e "${RED}❌ cyberdog_gazebo未编译${NC}"
        echo "   请执行: colcon build --packages-select cyberdog_gazebo"
    fi
    
    echo ""
    echo "[4/6] 检查SuperLIO包..."
    if [ -d "/home/cyberdog_sim/src/Super-LIO-ros2/install" ]; then
        echo -e "${GREEN}✅ SuperLIO已编译${NC}"
    else
        echo -e "${RED}❌ SuperLIO未编译${NC}"
        echo "   请执行: cd src/Super-LIO-ros2 && colcon build"
    fi
    
    echo ""
    echo "[5/6] 检查当前ROS topics..."
    TOPIC_COUNT=$(ros2 topic list 2>/dev/null | wc -l)
    if [ "$TOPIC_COUNT" -gt 0 ]; then
        echo -e "${GREEN}✅ 发现 $TOPIC_COUNT 个活跃topics${NC}"
        echo "   Topics列表:"
        ros2 topic list 2>/dev/null | head -10
        echo "   ..."
        
        # 特别检查激光雷达topic
        if ros2 topic list 2>/dev/null | grep -q "/scan"; then
            echo -e "\n${GREEN}✅✅✅ 激光雷达topic [/scan] 存在！${NC}"
            echo "   正在测试数据频率..."
            timeout 3 ros2 topic hz /scan 2>/dev/null || echo "   ⚠️  暂无数据（Gazebo可能未启动）"
        else
            echo -e "\n${RED}❌ 未发现 [/scan] topic${NC}"
            echo "   可能原因:"
            echo "   - Gazebo未启动或未使用 use_lidar:=true"
            echo "   - 机器人URDF中没有lidar_link"
        fi
        
        # 检查IMU topic
        if ros2 topic list 2>/dev/null | grep -q "/imu"; then
            echo -e "${GREEN}✅ IMU topic [/imu] 存在${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  无活跃topics（Gazebo未启动）${NC}"
    fi
    
    echo ""
    echo "[6/6] 检查X显示连接..."
    if [ -n "$DISPLAY" ]; then
        echo -e "${GREEN}✅ DISPLAY=$DISPLAY${NC}"
        if xdpyinfo &>/dev/null; then
            echo -e "${GREEN}✅ X显示连接正常${NC}"
        else
            echo -e "${YELLOW}⚠️  X显示连接可能有问题${NC}"
        fi
    else
        echo -e "${RED}❌ DISPLAY变量未设置${NC}"
    fi
    
    echo ""
    echo "=========================================="
    echo "  📊 诊断完成"
    echo "=========================================="
fi

echo ""
echo -e "${YELLOW}💡 提示:${NC}"
echo "  如果遇到问题，可以随时重新运行此脚本进行诊断"
echo ""
echo -e "${BLUE}常用排查命令:${NC}"
echo "  查看所有topics:  ros2 topic list"
echo "  检查激光雷达:    ros2 topic hz /scan"
echo "  检查IMU:         ros2 topic hz /imu"
echo "  查看TF树:        ros2 run tf2_tools view_frames"
echo "  查看节点:        ros2 node list"
echo ""
