#!/bin/bash
docker exec -it cyberdog_slam bash -c 'cd /home/cyberdog_sim/src/Super-LIO-ros2 && source /opt/ros/galactic/setup.bash && source install/setup.bash && ros2 launch super_lio Livox_mid360.py rviz:=true --ros-args -r /livox/lidar:=/scan -r /livox/imu:=/imu'
