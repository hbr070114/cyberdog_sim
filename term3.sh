#!/bin/bash
docker exec -it cyberdog_slam bash -c 'cd /home/cyberdog_ws && source /opt/ros/galactic/setup.bash && source install/setup.bash && ros2 run motion_manager motion_manager & sleep 5 && cd /home/cyberdog_sim && source install/setup.bash && ros2 run cyberdog_example keybroad_commander'
