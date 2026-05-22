#!/bin/bash
# 一键启动 Gazebo + cyberdog_control + 机器狗站立就绪
# 用法: bash /home/fish/cyberdog_sim/quick_start.sh
set +e
cd /home/cyberdog_sim

source /opt/ros/galactic/setup.bash
source install/setup.bash

export DISPLAY=${DISPLAY:-:0}
if [ "${RACE_SOFTWARE_GL:-0}" = "1" ]; then
    export LIBGL_ALWAYS_SOFTWARE=1
else
    unset LIBGL_ALWAYS_SOFTWARE
fi
export GAZEBO_PLUGIN_PATH="$PWD/build/cyberdog_gazebo:$PWD/install/lib:$GAZEBO_PLUGIN_PATH"
export LD_LIBRARY_PATH="$PWD/build/cyberdog_locomotion/simbridge:$PWD/build/cyberdog_locomotion/control:$PWD/build/cyberdog_locomotion/common:$PWD/install/lib:$LD_LIBRARY_PATH"

echo "[$(date +%H:%M:%S)] Cleaning..."
killall -9 gzserver gzclient cyberdog_control 2>/dev/null || true
sleep 2
rm -f /dev/shm/development-simulator /dev/shm/sem.* 2>/dev/null || true

echo "[$(date +%H:%M:%S)] Starting Gazebo..."
nohup ros2 launch cyberdog_gazebo race_gazebo.launch.py \
    use_lidar:=false use_camera:=true headless:=false wname:=race \
    > /tmp/gazebo.log 2>&1 &

echo "[$(date +%H:%M:%S)] Waiting Gazebo params sync..."
for i in $(seq 1 90); do sleep 2
    grep -q "All parameters sent to robot" /tmp/gazebo.log 2>/dev/null && \
        echo "[$(date +%H:%M:%S)] Gazebo ready!" && break
done

echo "[$(date +%H:%M:%S)] Waiting shared memory..."
for i in $(seq 1 60); do
    [ -e /dev/shm/development-simulator ] && [ -e /dev/shm/sem.sim2robot ] && break
    sleep 2
done

echo "[$(date +%H:%M:%S)] Starting cyberdog_control..."
nohup $PWD/install/lib/cyberdog_locomotion/cyberdog_control m s > /tmp/control.log 2>&1 &
CTLPID=$!
sleep 3
if ! kill -0 $CTLPID 2>/dev/null; then
    echo "ERROR: control died!"; tail -20 /tmp/control.log; exit 1
fi

echo "[$(date +%H:%M:%S)] Init: PureDamper → RecoveryStand → hold..."
# 后台持续发 LCM 让狗保持站立,直到用户 Ctrl+C
( while kill -0 $CTLPID 2>/dev/null; do
    python3 -c "
import lcm,time,sys
sys.path.insert(0,'/home/cyberdog_sim/race_controller')
from robot_control_cmd_lcmt import robot_control_cmd_lcmt
lc=lcm.LCM('udpm://239.255.76.67:7671?ttl=255')
cmd=robot_control_cmd_lcmt()
cmd.gait_id=0;cmd.step_height=[0,0];cmd.rpy_des=[0,0,0];cmd.pos_des=[0,0,0];cmd.contact=15;cmd.duration=0
cmd.mode=12;cmd.vel_des=[0,0,0]
for i in range(250):
    cmd.life_count=(i+1)%127;lc.publish('robot_control_cmd',cmd.encode());time.sleep(0.02)
" 2>/dev/null
  done
) &
KEEP_PID=$!

sleep 8
echo "[$(date +%H:%M:%S)] =========================================="
echo "  System READY! 机器狗已站立就绪"
echo "  Gazebo PIDs: $(pgrep gzserver | tr '\n' ' ')"
echo "  Control PID: $CTLPID"
echo "  Keep-alive PID: $KEEP_PID"
echo "  现在可以启动竞赛程序:"
echo "    docker exec -e DISPLAY=:0 cyberdog_slam bash -c 'cd /home/cyberdog_sim && export LD_LIBRARY_PATH=/home/cyberdog_sim/build/cyberdog_locomotion/simbridge:/home/cyberdog_sim/build/cyberdog_locomotion/control:/home/cyberdog_sim/build/cyberdog_locomotion/common:/home/cyberdog_sim/install/lib:\$LD_LIBRARY_PATH && python3 /home/cyberdog_sim/race_controller/race_controller.py'"
echo "  或发送测试行走:"
echo "    docker exec cyberdog_slam bash -c 'cd /home/cyberdog_sim && export LD_LIBRARY_PATH=... && python3 /home/cyberdog_sim/race_controller/race_controller.py'"
echo "  按 Ctrl+C 停止所有进程"
echo "[$(date +%H:%M:%S)] =========================================="

trap "kill $KEEP_PID $CTLPID 2>/dev/null; echo 'Shutting down...'" EXIT
wait $CTLPID 2>/dev/null
echo "[$(date +%H:%M:%S)] Control exited"
