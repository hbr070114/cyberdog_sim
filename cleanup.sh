#!/bin/bash
echo "=========================================="
echo "  Cleanup: Terminating all simulation processes"
echo "=========================================="

echo "[1/3] Killing processes in Docker container..."
docker exec cyberdog_slam bash -c '
for p in $(ps aux | grep -E "gzserver|gzclient" | grep -v grep | grep -v "sh -c" | awk "{print \$2}"); do kill -9 $p 2>/dev/null; done
for p in $(pgrep -f cyberdog_control 2>/dev/null); do kill -9 $p 2>/dev/null; done
for p in $(pgrep -f keybroad_commander 2>/dev/null); do kill -9 $p 2>/dev/null; done
for p in $(pgrep -f "ros2 launch" 2>/dev/null); do kill -9 $p 2>/dev/null; done
for p in $(pgrep -f rviz2 2>/dev/null); do kill -9 $p 2>/dev/null; done
for p in $(pgrep -f motion_manager 2>/dev/null); do kill -9 $p 2>/dev/null; done
' 2>/dev/null
sleep 2

echo "[2/3] Cleaning shared memory..."
docker exec cyberdog_slam bash -c 'rm -f /dev/shm/*' 2>/dev/null
rm -f /dev/shm/cyberdog_* /dev/shm/sem.* /dev/shm/development-* 2>/dev/null

echo "[3/3] Verification..."
REMAINING=$(docker exec cyberdog_slam bash -c 'ps aux | grep -E "gzserver|gzclient|cyberdog_control|keybroad|rviz2|motion_manager" | grep -v grep | grep -v "sh -c" | grep -v defunct' 2>/dev/null)
if [ -z "$REMAINING" ]; then
    echo "  CLEAN - No residual simulation processes."
else
    echo "  WARNING - Some processes still remain:"
    echo "$REMAINING"
fi

echo ""
echo "  Environment refreshed. Ready to restart."