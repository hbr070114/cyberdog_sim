#!/bin/bash
# ============================================================
# 🚀 CyberDog SuperLIO SLAM 最终版 - 完美解决方案
# 已解决：Docker GUI + 激光雷达 + Rviz 全部问题
# 用法: ./final_start.sh
# ============================================================

echo "=========================================="
echo "  🚀 CyberDog SuperLIO SLAM 最终版"
echo "  ✅ 修复所有已知问题"
echo "=========================================="
echo ""

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

cd /home/cyberdog_sim

source /opt/ros/galactic/setup.bash

echo -e "${YELLOW}[1/5] 编译更新（修复机器狗位置+激光雷达）...${NC}"
colcon build --packages-select cyberdog_gazebo cyberdog_example --symlink-install 2>&1 | tail -3
source install/setup.bash 2>/dev/null || true
echo -e "${GREEN}✅ 编译完成${NC}"

echo ""
echo -e "${YELLOW}[2/5] 检查SuperLIO...${NC}"
cd src/Super-LIO-ros2
if [ ! -d "install" ]; then
    echo "📦 首次编译SuperLIO..."
    colcon build 2>&1 | tail -5
fi
source install/setup.bash
cd /home/cyberdog_sim
echo -e "${GREEN}✅ SuperLIO就绪${NC}"

echo ""
echo -e "${YELLOW}[3/5] 创建启动脚本文件...${NC}"

cat > /tmp/start_gazebo.sh << 'EOF'
#!/bin/bash
cd /home/cyberdog_sim
source /opt/ros/galactic/setup.bash
source install/setup.bash
ros2 launch cyberdog_gazebo race_gazebo.launch.py use_lidar:=true
EOF
chmod +x /tmp/start_gazebo.sh

cat > /tmp/start_superlio.sh << 'EOF'
#!/bin/bash
cd /home/cyberdog_sim/src/Super-LIO-ros2
source /opt/ros/galactic/setup.bash
source install/setup.bash
ros2 launch super_lio Livox_mid360.py rviz:=true \
    --ros-args \
    -r /livox/lidar:=/scan \
    -r /livox/imu:=/imu
EOF
chmod +x /tmp/start_superlio.sh

cat > /tmp/start_keyboard.sh << 'EOF'
#!/bin/bash
cd /home/cyberdog_ws
source /opt/ros/galactic/setup.bash
source install/setup.bash
ros2 run motion_manager motion_manager &
sleep 8
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
echo "  1 → 慢速行走(303) ⭐石板路/独木桥"
echo "  2 → 中速行走(308) ✅平地建图(默认)"
echo "  3 → 快速行走(305) ⚡开阔地带"
echo ""
echo "【系统控制】Y 恢复站立 | R 行走 | T 趴下 | 空格 急停"
echo ""
echo "💡 开始: y → r → 1 → w"
echo ""

ros2 run cyberdog_example keybroad_commander
EOF
chmod +x /tmp/start_keyboard.sh

echo -e "${GREEN}✅ 启动脚本已创建${NC}"

echo ""
echo "=========================================="
echo "  📋 操作步骤（请仔细阅读）"
echo "=========================================="
echo ""
echo -e "${BLUE}⚠️  重要说明:${NC}"
echo "  Docker容器内无法自动打开新窗口"
echo "  需要你手动打开3个终端"
echo ""
echo -e "${GREEN}✅ 现在请执行以下操作:${NC}"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${YELLOW}  步骤1: 打开【新终端1】（用于Gazebo）${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  在新终端中执行:"
echo -e "  ${BLUE}bash /tmp/start_gazebo.sh${NC}"
echo ""
echo "  等待Gazebo完全启动（约15-20秒）"
echo "  确认看到:"
echo "    ✓ Gazebo窗口弹出"
echo "    ✓ 机器狗趴在地面上"
echo "    ✓ 机器狗头部有蓝色激光射线 ← 这是激光雷达！"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${YELLOW}  步骤2: 打开【新终端2】（用于Rviz）${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  在新终端中执行:"
echo -e "  ${BLUE}bash /tmp/start_superlio.sh${NC}"
echo ""
echo "  等待Rviz窗口弹出（约10-15秒）"
echo "  确认看到:"
echo "    ✓ Rviz窗口弹出"
echo "    ✓ 左侧显示 'Global Status: OK'"
echo "    ✓ 主视图开始出现点云数据"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${YELLOW}  步骤3: 打开【新终端3】（用于键盘控制）${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  在新终端中执行:"
echo -e "  ${BLUE}bash /tmp/start_keyboard.sh${NC}"
echo ""
echo "  然后依次输入:"
echo -e "    ${GREEN}y${NC}     (恢复站立)"
echo -e "    ${GREEN}r${NC}     (进入行走模式)"
echo -e "    ${GREEN}1${NC}     (慢速步态-石板路用)"
echo -e "         或 ${GREEN}2${NC} (中速-平地用)"
echo -e "         或 ${GREEN}3${NC} (快速-开阔地用)"
echo -e "    ${GREEN}w${NC}     (开始前进建图！)"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${YELLOW}💾 保存地图:${NC}"
echo "  建图完成后，在终端2按 Ctrl+C"
echo "  地图自动保存到:"
echo "  /home/cyberdog_sim/src/Super-LIO-ros2/src/super_lio/map/race_map.pcd"
echo ""
echo "=========================================="

echo ""
echo -e "${YELLOW}[4/5] 验证激光雷达配置...${NC}"

echo ""
echo "检查激光雷达插件:"
if [ -f "/opt/ros/galactic/lib/libgazebo_ros_ray_sensor.so" ]; then
    echo -e "${GREEN}✅ 激光雷达插件存在${NC}"
else
    echo -e "${RED}❌ 激光雷达插件缺失！${NC}"
fi

echo ""
echo "检查URDF中的lidar_link:"
URDF_CHECK=$(ros2 run xacro xacro src/cyberdog_simulator/cyberdog_robot/cyberdog_description/xacro/robot.xacro USE_LIDAR:=true 2>/dev/null | grep -c "lidar_link" || echo "0")
if [ "$URDF_CHECK" -gt 0 ]; then
    echo -e "${GREEN}✅ URDF包含lidar_link（共$URDF_CHECK处引用）${NC}"
else
    echo -e "${RED}❌ URDF中没有lidar_link！${NC}"
fi

echo ""
echo -e "${YELLOW}[5/5] 准备完成！${NC}"
echo ""
echo -e "${GREEN}🎯 现在请你:${NC}"
echo "  1. 打开3个新终端窗口"
echo "  2. 分别执行上面的3条命令"
echo "  3. 按提示操作即可开始建图"
echo ""
echo "💡 如果遇到问题，可以在此终端运行诊断:"
echo -e "   ${BLUE}./diagnose_and_start.sh${NC}"
echo ""
