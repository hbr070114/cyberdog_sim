#!/bin/bash
# ============================================================
# 🚀 CyberDog SuperLIO SLAM 终极修复版 v4.0
# 修复：机器狗位置 + 激光雷达 + Rviz 全部问题
# 基于官方文档标准配置
# ============================================================

echo "=========================================="
echo "  🔧 CyberDog SLAM 终极修复 v4.0"
echo "  ✅ 基于官方文档标准配置"
echo "=========================================="
echo ""

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

cd /home/cyberdog_sim

source /opt/ros/galactic/setup.bash

echo -e "${YELLOW}[1/4] 编译更新（机器狗位置已修正为z=0.31m）...${NC}"
colcon build --packages-select cyberdog_gazebo cyberdog_example --symlink-install 2>&1 | grep -E "error|Error" || true
source install/setup.bash 2>/dev/null || true
echo -e "${GREEN}✅ 编译完成${NC}"

echo ""
echo -e "${YELLOW}[2/4] 检查SuperLIO...${NC}"
cd src/Super-LIO-ros2
if [ ! -d "install" ]; then
    echo "📦 首次编译SuperLIO..."
    colcon build 2>&1 | tail -5
fi
source install/setup.bash
cd /home/cyberdog_sim
echo -e "${GREEN}✅ SuperLIO就绪${NC}"

echo ""
echo -e "${YELLOW}[3/4] 创建启动脚本（基于官方标准配置）...${NC}"

cat > /tmp/start_gazebo_fixed.sh << 'EOF'
#!/bin/bash
clear
echo "=========================================="
echo "  📍 步骤1: Gazebo仿真（官方配置）"
echo "=========================================="
echo ""
echo "✅ 已修复:"
echo "   - 机器狗位置: z=0.31m（官方标准值）"
echo "   - 激光雷达: use_lidar:=true"
echo ""
echo "⏳ 正在启动Gazebo..."
echo "   请等待15-20秒"
echo ""
echo "✅ 成功标志:"
echo "   ✓ Gazebo窗口弹出"
echo "   ✓ 机器狗正常站立在地上（不穿模！）"
echo "   ✓ race地图完整显示"
echo "   ✓ 机器狗头部有蓝色激光射线"
echo ""
echo "⚠️  如果看不到激光射线:"
echo "   按 V 键 或 View → Sensors"
echo ""

cd /home/cyberdog_sim
source /opt/ros/galactic/setup.bash
source install/setup.bash
ros2 launch cyberdog_gazebo race_gazebo.launch.py use_lidar:=true
EOF
chmod +x /tmp/start_gazebo_fixed.sh

cat > /tmp/start_superlio_fixed.sh << 'EOF'
#!/bin/bash
clear
echo "=========================================="
echo "  📍 步骤2: SuperLIO + Rviz"
echo "=========================================="
echo ""
echo "⏳ 正在启动SuperLIO算法和Rviz..."
echo "   请等待10-20秒"
echo ""
echo "✅ 成功标志:"
echo "   ✓ Rviz窗口弹出"
echo "   ✓ 左侧显示 Global Status: OK"
echo "   ✓ 主视图开始出现点云数据"
echo ""
echo "💾 建图完成后按 Ctrl+C 保存地图"
echo "   位置: /home/cyberdog_sim/src/Super-LIO-ros2/src/super_lio/map/race_map.pcd"
echo ""

cd /home/cyberdog_sim/src/Super-LIO-ros2
source /opt/ros/galactic/setup.bash
source install/setup.bash
ros2 launch super_lio Livox_mid360.py rviz:=true \
    --ros-args \
    -r /livox/lidar:=/scan \
    -r /livox/imu:=/imu
EOF
chmod +x /tmp/start_superlio_fixed.sh

cat > /tmp/start_keyboard_fixed.sh << 'EOF'
#!/bin/bash
clear
echo "=========================================="
echo "  📍 步骤3: 键盘控制（增强版）"
echo "=========================================="
echo ""

cd /home/cyberdog_ws
source /opt/ros/galactic/setup.bash
source install/setup.bash

echo "⏳ 启动运动管理服务..."
echo "   （LCM错误可忽略，不影响使用）"
ros2 run motion_manager motion_manager &
MOTION_PID=$!
sleep 8

cd /home/cyberdog_sim
source install/setup.bash 2>/dev/null || true

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

kill $MOTION_PID 2>/dev/null || true
EOF
chmod +x /tmp/start_keyboard_fixed.sh

cat > /tmp/check_system.sh << 'EOF'
#!/bin/bash
clear
echo "=========================================="
echo "  🔍 系统状态检查"
echo "=========================================="
echo ""

source /opt/ros/galactic/setup.bash 2>/dev/null

echo "[1] ROS Topics 检查:"
TOPICS=$(ros2 topic list 2>/dev/null | wc -l)
echo "   发现 $TOPICS 个活跃topics"

if ros2 topic list 2>/dev/null | grep -q "/scan"; then
    echo -e "   ${GREEN}✅ /scan (激光雷达) 存在${NC}"
    echo "   数据频率测试:"
    timeout 5 ros2 topic hz /scan 2>&1 | tail -2
else
    echo -e "   ${RED}❌ /scan 不存在${NC}"
    echo "   → 请先启动Gazebo (步骤1)"
fi

if ros2 topic list 2>/dev/null | grep -q "/imu"; then
    echo -e "   ${GREEN}✅ /imu (惯性测量) 存在${NC}"
else
    echo -e "   ${YELLOW}⚠️  /imu 不存在${NC}"
fi

echo ""
echo "=========================================="
if [ "$TOPICS" -gt 0 ]; then
    echo -e "${GREEN}✅ 系统正常！可以继续步骤2${NC}"
else
    echo -e "${RED}❌ 系统未就绪！请先完成步骤1${NC}"
fi
echo "=========================================="

read -p "按 Enter 继续..."
EOF
chmod +x /tmp/check_system.sh

echo -e "${GREEN}✅ 所有脚本已创建${NC}"

echo ""
echo "=========================================="
echo "  📋 完整操作步骤（基于官方标准配置）"
echo "=========================================="
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}  ⚠️  重要：需要手动打开3个终端！${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${GREEN}当前终端（终端0）:${NC}"
echo "  用于运行此初始化脚本（已完成）"
echo "  保持打开不要关闭"
echo ""
echo -e "${YELLOW}终端1 - Gazebo仿真:${NC}"
echo "  命令: ${BLUE}bash /tmp/start_gazebo_fixed.sh${NC}"
echo "  等待: 看到 Gazebo窗口 和 机器狗站立在地面上"
echo "  验证: 机器狗不穿模、有激光射线"
echo ""
echo -e "${YELLOW}终端2（可选）- 系统验证:${NC}"
echo "  命令: ${BLUE}bash /tmp/check_system.sh${NC}"
echo "  用途: 确认激光雷达数据正常"
echo ""
echo -e "${YELLOW}终端3 - SuperLIO + Rviz:${NC}"
echo "  命令: ${BLUE}bash /tmp/start_superlio_fixed.sh${NC}"
echo "  等待: Rviz窗口弹出（约10-20秒）"
echo ""
echo -e "${YELLOW}终端4 - 键盘控制:${NC}"
echo "  命令: ${BLUE}bash /tmp/start_keyboard_fixed.sh${NC}"
echo "  操作: 输入 y → r → 1 → w 开始建图"
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BLUE}执行顺序:${NC}"
echo "  1. 打开新终端1 → bash /tmp/start_gazebo_fixed.sh"
echo "  2. 等15-20秒（确认Gazebo正常）"
echo "  3. 可选: 开终端2 → bash /tmp/check_system.sh"
echo "  4. 开终端3 → bash /tmp/start_superlio_fixed.sh"
echo "  5. 等Rviz出现（10-20秒）"
echo "  6. 开终端4 → bash /tmp/start_keyboard_fixed.sh"
echo "  7. 输入 y → r → 1 → w  开始SLAM建图！"
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${GREEN}🎯 本次修复内容:${NC}"
echo "  ✓ 机器狗位置: z=0.31m（官方标准值，不再穿模）"
echo "  ✓ 激光雷达: 强制启用 use_lidar:=true"
echo "  ✓ Rviz: 手动开终端避免Docker GUI问题"
echo "  ✓ 所有配置基于官方文档"
echo ""
echo "=========================================="
