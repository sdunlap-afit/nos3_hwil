
# NOS3 FSW and NOS3 Engine Server on Separate Machines


**Warning: This process is a work in progress and has not been fully tested. While it appears to function, you should validate the results.**


# FSW Machine

These instructions have been tested on a Raspberry Pi with the `dev#231` branch of NOS3. The following steps will allow FSW to run either in a docker container OR directly on the Raspberry Pi. Either way, Docker will be used to build the FSW. This process could be more efficient, but it is the simplest way to get the FSW running with minimal changes to NOS3 files.

## One-time Setup

```bash
sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install -y git docker.io
sudo usermod -aG docker $USER
echo '* - rtprio 99' | sudo tee -a /etc/security/limits.conf
```

Add the IP address of the host on which the NOS3 server is running to the hosts file.

```bash
echo '10.1.10.52 nos_engine_server' | sudo tee -a /etc/hosts
```

Reboot the machine to apply all the changes.

```bash
sudo reboot
```

```bash
git clone https://github.com/nasa/nos3.git
cd nos3
git switch nos3\#231
git submodule update --init --recursive
```

## Build NOS3

Some of these steps may not be necessary, but they are the simplest way to get the FSW running with minimal changes to NOS3 files.

Note: There will be some errors at the end of `make prep`, but they won't affect the FSW build.

```bash
make prep
make config
make
```

## Run FSW in Docker

```bash
source scripts/env.sh
$DFLAGS -v $BASE_DIR:$BASE_DIR --name nos_fsw -h nos_fsw --network=host -w $FSW_DIR --sysctl fs.mqueue.msg_max=10000 --ulimit rtprio=99 --cap-add=sys_nice $DBOX $SCRIPT_DIR/fsw_respawn.sh
```



# Running FSW on RPi without Docker

The above steps will build all of the code, but there is an additional dependency that must be installed. 

## Additional Dependencies

```bash
sudo apt install -y libxerces-c-dev
```

## Install the NOS3 libraries
    
```bash
cd ~
git clone https://github.com/nasa-itc/deployment.git
cd deployment
git switch nos3\#231
sudo apt install -y ./nos3_filestore/packages/ubuntu/*arm64.deb
sudo chmod 777 /usr/lib/libitc_* /usr/lib/libnos_engine_*
```

## Run FSW on Host Machine

```bash
source scripts/env.sh
$SCRIPT_DIR/fsw_respawn.sh
```



# NOS3 Engine Server

The process for the NOS3 Engine Server is the same as the FSW machine but with a few additional steps. A couple of changes need to be made to the NOS3 scripts to disable the FSW and publish the NOS Engine Server port.

**First, disable your system firewall, or add port 12000 to the firewall rules.**


## One-time Setup

Note: Setting up docker will depend on your host machine and is not documented here.

```bash
git clone https://github.com/nasa/nos3.git
cd nos3
git switch nos3\#231
git submodule update --init --recursive
```


Next, NOS3 needs to be modified when running FSW separately from the rest. Disable the FSW by commenting out the docker run command.  In `scripts/docker_launch.sh`, disable FSW by commenting out the following line:

Before:
```bash
gnome-terminal --title=$SC_NUM" - NOS3 Flight Software" -- $DFLAGS -v $BASE_DIR:$BASE_DIR --name $SC_NUM"_nos_fsw" -h nos_fsw --network=$SC_NETNAME -w $FSW_DIR --sysctl fs.mqueue.msg_max=10000 --ulimit rtprio=99 --cap-add=sys_nice $DBOX $SCRIPT_DIR/fsw_respawn.sh &
```

After:
```bash 
# gnome-terminal --title=$SC_NUM" - NOS3 Flight Software" -- $DFLAGS -v $BASE_DIR:$BASE_DIR --name $SC_NUM"_nos_fsw" -h nos_fsw --network=$SC_NETNAME -w $FSW_DIR --sysctl fs.mqueue.msg_max=10000 --ulimit rtprio=99 --cap-add=sys_nice $DBOX $SCRIPT_DIR/fsw_respawn.sh &
```

Also, publish the NOS Engine Server port by adding `-p 12000:12000` to the docker run command for the engine server.

Before:
```bash
gnome-terminal --tab --title=$SC_NUM" - NOS Engine Server" -- $DFLAGS -v $SIM_DIR:$SIM_DIR --name $SC_NUM"_nos_engine_server"  -h nos_engine_server --network=$SC_NETNAME -w $SIM_BIN $DBOX /usr/bin/nos_engine_server_standalone -f $SIM_BIN/nos_engine_server_config.json
```
After:
```bash
gnome-terminal --tab --title=$SC_NUM" - NOS Engine Server" -- $DFLAGS -p 12000:12000 -v $SIM_DIR:$SIM_DIR --name $SC_NUM"_nos_engine_server"  -h nos_engine_server --network=$SC_NETNAME -w $SIM_BIN $DBOX /usr/bin/nos_engine_server_standalone -f $SIM_BIN/nos_engine_server_config.json
```




## Build and run

```bash
cd nos3
make prep
make config
make
make launch
```

When finished:

```bash
make stop
```


# Additional details

If you decide to run FSW in Docker on Windows/WSL, you will need to disable the enforcement of privileged operations.

Docker in Windows will not work with setschedparam so FSW will fail. To stop it from enforcing this feature, set `OSAL_CONFIG_DEBUG_PERMISSIVE_MODE = TRUE` in `nos3/fsw/osal/default_config.cmake`.

```cmake
set(OSAL_CONFIG_DEBUG_PERMISSIVE_MODE           TRUE
    CACHE BOOL "Disable enforcement of privileged operations"
)
```
