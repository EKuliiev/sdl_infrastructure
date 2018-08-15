## This repository contains build, environment setup utils for working with OpenSDL

Tested under Ubuntu 16.04 with default shell

## ******* Prepare ATF for working under host linux for OpenSDL *********
1. Create directory where you want to store opensdl artifacts.
For example:
```
mkdir -p ~/work/OpenSDL
```
2. Clone sdl_infrastructure to your root project directory
(make shure you are able to work via SSH: [Account SSH keys](https://github.com/settings/keys))
```
git -C ~/work/OpenSDL clone git@github.com:EKuliiev/sdl_infrastructure.git
```
3. Execute script to setup environment:
```
~/work/OpenSDL/sdl_infrastructure/setup_dependencies.sh
```
4. Execute script to load SDL repositories and setup them to the actual states:
```
~/work/OpenSDL/sdl_infrastructure/sync.sh
```
5. Build sdl_core:
```
~/work/OpenSDL/sdl_infrastructure/build.sh --install (type --help to see all opts)
```
6. Execute script to prepare and build ATF:
```
~/work/OpenSDL/sdl_infrastructure/prepare_atf.sh
```
7. Go to sdl_atf directory to work with ATF scripts:
```
cd ~/work/OpenSDL/sdl_atf/
```
8. To perform test run script start_test.sh by passing scenario script to it:
```
./start_test.sh test_scripts/Smoke/Policies/001_PTU_all_flows.lua # for running smoke tests
```
If you need to run smartDeviceLinkCore manualy you need to setup runtime environment first:
First perform sourcing script:
source ~/work/OpenSDL/sdl_infrastructure/setup_runtime_env.sh
After that you able to run service


