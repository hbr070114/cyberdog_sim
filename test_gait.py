#!/usr/bin/env python3
import sys, time
sys.path.insert(0, '/home/cyberdog_sim/src/cyberdog_locomotion/common/lcm_type/lcm')

import lcm
from robot_control_cmd_lcmt import robot_control_cmd_lcmt

lc = lcm.LCM("udpm://239.255.76.67:7671?ttl=255")
msg = robot_control_cmd_lcmt()
life_count = 0

def send(mode, gait_id=0, vel=[0,0,0], desc=""):
    global life_count
    life_count = (life_count + 1) % 127
    msg.mode = mode
    msg.gait_id = gait_id
    msg.vel_des = [float(vel[0]), float(vel[1]), float(vel[2])]
    msg.pos_des = [0.0, 0.0, 0.0]
    msg.step_height = [0.06, 0.06] if mode == 11 else [0.0, 0.0]
    msg.duration = 0
    msg.life_count = life_count
    lc.publish("robot_control_cmd", msg.encode())
    print(f"[{time.strftime('%H:%M:%S')}] {desc} mode={mode} gait={gait_id} vel={vel}")

print("=" * 60)
print("[TEST] 测试不同gait_id避免崩溃")
print("=" * 60)

# Step 1: RecoveryStand
print("\n[1] RecoveryStand...")
send(12, 0, [0,0,0], "RecoveryStand")
time.sleep(8)

# Step 2: 用gait_id=10 (TROT_FAST) + 小速度
print("\n[2] Locomotion gait=10 vel=0.05...")
send(11, 10, [0.05, 0.0, 0.0], "Loco-gait10-v0.05")
time.sleep(5)

# 检查进程是否还活着
import subprocess
result = subprocess.run(['pgrep', '-f', 'cyberdog_control'], capture_output=True, text=True)
if result.stdout.strip():
    print(f"\n[✓] Control还在运行! PID={result.stdout.strip()}")
else:
    print(f"\n[✗] Control又崩溃了!")

print("=" * 60)
