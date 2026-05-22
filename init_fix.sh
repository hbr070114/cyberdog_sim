#!/bin/bash
set -e

echo "=========================================="
echo "  🔧 修复版一键初始化"
echo "=========================================="
echo ""

docker rm -f cyberdog_slam 2>/dev/null || true

echo "[1/4] 启动容器..."
docker run -itd --name cyberdog_slam --privileged=true \
  -e DISPLAY=$DISPLAY \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v /home/fish/cyberdog_sim:/home/cyberdog_sim \
  cyberdog_sim:v2026 bash -c "
    echo '=== 修复GPG密钥 ===' &&
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys F42ED6FBAB17C654 AD19BAB3CBF125EA &&
    apt-get update -qq &&
    echo '=== 安装Glog ===' &&
    apt-get install -y -qq libglog-dev &&
    echo '=== 编译SuperLIO ===' &&
    cd /home/cyberdog_sim/src/Super-LIO-ros2 &&
    source /opt/ros/galactic/setup.bash &&
    colcon build &&
    echo '✅ 初始化完成' &&
    tail -f /dev/null
  "

echo "[2/4] 等待完成 (约3-8分钟)..."
echo ""

for i in {1..120}; do
  if docker logs cyberdog_slam 2>&1 | grep -q "✅ 初始化完成"; then
    echo ""
    echo "=========================================="
    echo "  ✅ 成功！现在执行："
    echo "=========================================="
    echo ""
    echo "  终端1: ./term1.sh   (Gazebo+激光雷达)"
    echo "  终端2: ./term2.sh   (SuperLIO+RViz)"
    echo "  终端3: ./term3.sh   (键盘控制)"
    echo ""
    exit 0
  fi
  
  if docker logs cyberdog_slam 2>&1 | grep -qi "error\|failed\|Error"; then
    echo ""
    echo "❌ 发现错误！日志："
    docker logs cyberdog_slam 2>&1 | tail -30
    exit 1
  fi
  
  sleep 3
  
  if [ $((i % 10)) -eq 0 ]; then
    echo "   进度: $i/120 ($((i*3))秒)"
  fi
done

echo "⏱️ 超时，请手动检查: docker logs cyberdog_slam"
