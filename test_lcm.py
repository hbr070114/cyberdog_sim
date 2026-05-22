#!/usr/bin/env python3
"""CyberDog LCM robot_control_cmd Test Script"""

import lcm
import time
import sys
sys.path.insert(0, '/home/cyberdog_sim/code_and_readme/loco_hl_example/basic_motion')
from robot_control_cmd_lcmt import robot_control_cmd_lcmt

LCM_URL = "udpm://239.255.76.67:7671?ttl=255"

lc = lcm.LCM(LCM_URL)
msg = robot_control_cmd_lcmt()

print("=" * 50)
print("CyberDog LCM robot_control_cmd Test")
print("=" * 50)

print("[INFO] LCM initialized OK")
print()

print("[1/3] Send RecoveryStand (mode=12)...")
msg.life_count += 1
msg.mode = 12
msg.gait_id = 0
msg.duration = 0
lc.publish("robot_control_cmd", msg.encode())
print(f"  Sent: life_count={msg.life_count} mode={msg.mode}")
time.sleep(3)

print("\n[2/3] Send Locomotion Forward (mode=11, vel_x=0.2)...")
msg.life_count += 1
msg.mode = 11
msg.gait_id = 29
msg.vel_des = [0.2, 0.0, 0.0]
msg.pos_des = [0.0, 0.0, 0.24]
msg.step_height = [0.06, 0.06]
lc.publish("robot_control_cmd", msg.encode())
print(f"  Sent: life_count={msg.life_count} mode={msg.mode} gait={msg.gait_id} vel={msg.vel_des}")
time.sleep(3)

print("\n[3/3] Send Locomotion Stop...")
msg.life_count += 1
msg.mode = 11
msg.gait_id = 29
msg.vel_des = [0.0, 0.0, 0.0]
lc.publish("robot_control_cmd", msg.encode())
print(f"  Sent: life_count={msg.life_count} mode={msg.mode} gait={msg.gait_id} vel={msg.vel_des}")
time.sleep(2)

print("\n[DONE] Test complete!")
print("Check if the dog stood up and moved forward.")