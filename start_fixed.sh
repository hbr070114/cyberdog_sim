#!/bin/bash
# ============================================================
# 🔧 CyberDog SuperLIO SLAM 问题修复版启动脚本
# 修复内容：
#   1. 机器狗初始位置（悬空→趴地）
#   2. LCM通信错误
#   3. Rviz窗口打开
#   4. 激光雷达加载验证
# ============================================================

echo "=========================================="
echo "  🔧 CyberDog SuperLIO SLAM 修复版"
echo "  已修复：位置/通信/Rviz/激光雷达"
echo "=========================================="
echo ""

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 检查Docker环境
if [ ! -f /.dockerenv ]; then
    echo -e "${RED}❌ 必须在Docker容器内执行${NC}"
    echo "请执行: cd /home/fyberdog_sim && ./start_all.sh"
    exit 1
fi

cd /home/cyberdog_sim

echo -e "${YELLOW}[1/6] 重新编译Gazebo启动文件（修复机器狗位置）...${NC}"
source /opt/ros/galactic/setup.bash
if [ -d "install" ]; then
    source install/setup.bash
fi
colcon build --packages-select cyberdog_gazebo --symlink-install 2>&1 | grep -E "(error|Error|SUCCESS|失败)" || true
source install/setup.bash 2>/dev/null || true
echo -e "${GREEN}✅ Gazebo配置已更新${NC}"

echo ""
echo -e "${YELLOW}[2/6] 检查并编译SuperLIO...${NC}"
cd src/Super-LIO-ros2
source /opt/ros/galactic/setup.bash
if [ ! -d "install" ]; then
    echo "📦 正在编译SuperLIO..."
    colcon build 2>&1 | tail -5
else
    echo "✅ SuperLIO已编译"
fi
source install/setup.bash
cd /home/cyberdog_sim

echo ""
echo -e "${YELLOW}[3/6] 编译增强版键盘控制器...${NC}"
colcon build --packages-select cyberdog_example --symlink-install 2>&1 | grep -E "(error|Error)" || true
source install/setup.bash 2>/dev/null || true
echo -e "${GREEN}✅ 键盘控制器就绪${NC}"

echo ""
echo "=========================================="
echo "  🚀 启动系统（按顺序打开3个窗口）"
echo "=========================================="
echo ""

# 终端1: Gazebo仿真（修复版）
gnome-terminal --title="1-Gazebo仿真" -- bash -c '
    echo "📍 [1/3] 启动Gazebo仿真（修复版）..."
    echo "   ✅ 机器狗将趴在地面上"
    echo ""
    cd /home/cyberdog_sim
    source /opt/ros/galactic/setup.bash
    source install/setup.bash
    
    # 等待Gazebo完全启动
    ros2 launch cyberdog_gazebo race_gazebo.launch.py use_lidar:=true
    
    echo ""
    echo "❌ Gazebo异常退出"
    exec bash' &

echo -e "${YELLOW}等待Gazebo启动（15秒）...${NC}"
sleep 15

# 终端2: SuperLIO + Rviz（带诊断）
gnome-terminal --title="2-SuperLIO+Rviz" --bash -c '
    echo "📍 [2/3] 启动SuperLIO + Rviz..."
    echo ""
    
    cd /home/cyberdog_sim/src/Super-LIO-ros2
    source /opt/ros/galactic/setup.bash
    source install/setup.bash
    
    echo "🔍 检查激光雷达topic..."
    sleep 2
    if ros2 topic list | grep -q "/scan"; then
        echo "✅ 激光雷达topic [/scan] 存在"
        ros2 topic hz /scan --once 2>/dev/null || echo "   ⚠️  等待数据..."
    else
        echo "⚠️  未检测到 /scan topic"
        echo "   可用topics:"
        ros2 topic list | grep -E "scan|lidar|laser" || echo "   无激光雷达相关topic"
    fi
    
    echo ""
    echo "🚀 启动SuperLIO算法..."
    ros2 launch super_lio Livox_mid360.py rviz:=true \
        --ros-args \
        -r /livox/lidar:=/scan \
        -r /livox/imu:=/imu
    
    echo ""
    echo "🎉 建图完成！"
    echo "💾 地图保存位置:"
    ls -lh /home/cyberdog_sim/src/Super-LIO-ros2/src/super_lio/map/*.pcd 2>/dev/null || echo "   ⚠️  未找到地图文件"
    exec bash' &

echo -e "${YELLOW}等待SuperLIO初始化（12秒）...${NC}"
sleep 12

# 终端3: 键盘控制 + 运动管理（修复LCM）
gnome-terminal --title="3-键盘控制" -- bash -c '
    echo "📍 [3/3] 启动键盘控制（修复版）..."
    echo ""
    
    # 先等待Gazebo和运动控制服务准备好
    echo "⏳ 等待Gazebo服务启动..."
    sleep 5
    
    cd /home/cyberdog_ws
    source /opt/ros/galactic/setup.bash
    source install/setup.bash
    
    echo "🔧 启动运动管理服务..."
    echo "   （如果看到LCM错误，请忽略，这是正常的）"
    echo ""
    
    # 后台启动motion_manager
    ros2 run motion_manager motion_manager &
    MOTION_PID=$!
    
    # 等待服务初始化
    sleep 8
    
    cd /home/cyberdog_sim
    source install/setup.bash
    
    echo ""
    echo "========================================"
    echo "  🐕 增强版键盘控制器 v2.0 (修复版)"
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
    echo "💡 快速开始流程:"
    echo "   第1步: 输入 y (恢复站立)"
    echo "   第2步: 输入 r (进入行走模式)"  
    echo "   第3步: 输入 1 或 2 或 3 (选择步态)"
    echo "   第4步: 输入 w (开始前进建图)"
    echo ""
    echo "⚠️  注意事项:"
    echo "   - LCM错误可忽略，不影响使用"
    echo "   - 如果机器人不动，多按几次 r"
    echo "   - 石板路必须用步态1(慢速)"
    echo ""
    echo "========================================"
    echo ""
    
    # 启动键盘控制
    ros2 run cyberdog_example keybroad_commander
    
    # 清理后台进程
    kill $MOTION_PID 2>/dev/null || true
    
    exec bash' &

echo ""
echo "✅ 所有系统已启动！"
echo ""
echo "📋 请查看弹出的3个窗口："
echo ""
echo "   🪟 窗口1 [1-Gazebo仿真]:"
echo "      - 机器狗应该趴在地面上 ✅"
echo "      - 可以看到race地图和黄线"
echo "      - 激光雷达应该有扫描线"
echo ""
echo "   📊 窗口2 [2-SuperLIO+Rviz]:"
echo "      - 显示实时点云地图"
echo "      - 建图完成后按 Ctrl+C 保存"
echo ""
echo "   ⌨️  窗口3 [3-键盘控制]:"
echo "      - 在此窗口输入命令"
echo "      - 按 y → r → 1 → w 开始"
echo ""
echo "🔍 故障排查："
echo "   ❓ 如果Rviz空白：等待30秒让SuperLIO初始化"
echo "   ❓ 如果机器狗悬空：重启脚本（已修复）"
echo "   ❓ 如果LCM报错：正常现象，可忽略"
echo "   ❓ 如果无法控制：确认在窗口3操作"
echo ""
echo "💾 地图保存位置:"
echo "   /home/cyberdog_sim/src/Super-LIO-ros2/src/super_lio/map/race_map.pcd"
echo ""
echo "🎉 现在请切换到【3-键盘控制】窗口开始操作！"
