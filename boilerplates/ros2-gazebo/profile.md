# Profile — ros2-gazebo

## Identity and licence

- Name: ROS 2 and Gazebo project template
- Origin: https://github.com/gazebosim/ros_gz_project_template
- Licence: Apache-2.0
- Commit profiled: 045e981d03aac1cc3712ab6bb086f52ea79aebf9

The head of branch `main`, which targets Gazebo Harmonic and later; branch `fortress` serves Gazebo Fortress. The repository has no tag. Profiled for ROS 2 Jazzy, whose vendor packages ship Gazebo Harmonic (`gz-sim8`).

## Platform

- Platform: robot

## QA driver

- QA driver: simulation

## Commands

```
Install:           —
Test:              —
Typecheck:         —
E2E:               —
Build:             source /opt/ros/jazzy/setup.bash && GZ_VERSION=harmonic colcon build
Dev:               —
```

System dependencies come from `rosdep install --from-paths . --ignore-src -i -y`, which installs through apt as root: it runs once per machine and is not a project command, hence `Install: —`. No test file ships, and `colcon test` only runs each package's `ament_lint_auto` linters and takes package names rather than paths, hence `Test: —`. `GZ_VERSION=harmonic` is what makes `ros_gz_example_gazebo/CMakeLists.txt` look for `gz-sim8`. The simulation serves no address, hence `Dev: —`.

Simulation command: `source /opt/ros/jazzy/setup.bash && source install/setup.bash && ros2 launch ros_gz_example_bringup diff_drive.launch.py rviz:=false`. This is the line the `simulation` driver reads.

Resume command: `gz service -s /world/demo/control --reqtype gz.msgs.WorldControl --reptype gz.msgs.Boolean --timeout 5000 --req 'pause: false'`. The world starts paused, so the driver runs this when `/clock` stays still.

## Code map

- `ros_gz_example_application/` — the ROS 2 package for the robot's own nodes; empty apart from its build files.
- `ros_gz_example_bringup/` — launch files, the ROS 2 and Gazebo bridge configuration and the RViz configurations.
- `ros_gz_example_description/` — the SDF models of the robots and their environment hooks.
- `ros_gz_example_gazebo/` — Gazebo systems written in C++, and the world.
- `README.md` — workspace layout, dependencies, build and launch.
- `LICENSE` — Apache License 2.0.
- `.gitignore` — compiled objects only.

## Ownership granularity

A story owns a new package `<package>/`, a new model `ros_gz_example_description/models/<model>/`, or a new system in `ros_gz_example_gazebo/src/`. These paths are shared, and a story touching any of them runs alone: `ros_gz_example_bringup/config/ros_gz_example_bridge.yaml` (it lists every bridged topic), `ros_gz_example_bringup/launch/diff_drive.launch.py`, `ros_gz_example_gazebo/worlds/diff_drive.sdf`, `ros_gz_example_gazebo/CMakeLists.txt`, and the `package.xml` of each package.

## Where each rule lives

Robot behaviour lives in ROS 2 nodes under `ros_gz_example_application/`. Logic on the simulation side lives in Gazebo systems under `ros_gz_example_gazebo/src/`. Which topic crosses between ROS 2 and Gazebo lives in `ros_gz_example_bringup/config/ros_gz_example_bridge.yaml`. The robot's sensors and actuators live in its model SDF. There is no access, validation or tenant code.

## Capabilities

| Capability | Brick | Notes |
| --- | --- | --- |

The template provides none of the capabilities of the list.

## UI inventory

No screen: the viewers are Gazebo's interface and RViz, with `ros_gz_example_bringup/config/diff_drive.rviz` and `ros_gz_example_bringup/config/rrbot.rviz`.

## Known traps

- The world starts paused: the launch passes no `-r` to `gz sim`, so nothing moves until the world is resumed.
- The launch opens Gazebo's interface and RViz; `rviz:=false` closes only RViz.
- Without `GZ_VERSION=harmonic`, the build looks for Gazebo Garden.
- `colcon` writes `build/`, `install/` and `log/` beside the sources, and the template's `.gitignore` ignores none of them.
- The template expects to sit in `<ws>/src/` of a colcon workspace.
- The `.dsv.in` and `.sh.in` hooks of `ros_gz_example_gazebo/hooks/` set different plugin variables (`GZ_SIM_SYSTEM_PLUGIN_PATH`, `GZ_SIM_PLUGIN_PATH`); rename the hooks together with the package.
- The `gpu_lidar` sensor under `ogre2` needs OpenGL; on Mesa without a GPU the scan may be slow or empty.
- ROS 2 discovery and Gazebo transport reach the whole network unless `ROS_AUTOMATIC_DISCOVERY_RANGE` and `GZ_PARTITION` say otherwise.
- `ros_gz_example_bringup/launch/rrbot_setup.launch.py` opens `joint_state_publisher_gui`, one more window.
