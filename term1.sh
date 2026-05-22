#!/bin/bash
docker exec -it cyberdog_slam bash -c 'cd /home/cyberdog_sim && source /opt/ros/galactic/setup.bash && source install/setup.bash && ros2 launch cyberdog_gazebo race_gazebo.launch.py use_lidar:=true'
