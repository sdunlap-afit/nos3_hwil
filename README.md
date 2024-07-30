
# NOS3 FSW and NOS3 Engine Server on Different Machines


**Warning: This process is a work in progress and has not been fully tested. More modifications may be needed for full functionality.**


# FSW Machine

These instructions have been tested on a Raspberry Pi 4, with Raspberry Pi OS Lite (64-bit), and the `dev` branch of NOS3. The following steps will allow FSW to run either in a docker container OR directly on the Raspberry Pi. Either way, Docker will be used to build the FSW. This process could be more efficient, but it is the simplest way to get the FSW running with minimal changes to NOS3 files.

## One-time Setup

```bash
sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install -y git docker.io
sudo usermod -aG docker $USER
echo '* - rtprio 99' | sudo tee -a /etc/security/limits.conf
echo 'fs.mqueue.msg_max=1000' | sudo tee -a /etc/sysctl.conf
```

FSW tries to communicate with `nos_engine_server` and `cosmos` by hostname. Since those are running on a different machine, we need to map those hostnames to the host IP running those containers. Add the IP address of the host on which the NOS3 engine server and Cosmos are running to `\etc\hosts`.

```bash
echo '<IP> nos_engine_server' | sudo tee -a /etc/hosts
echo '<IP> cosmos' | sudo tee -a /etc/hosts
```

Reboot the machine to apply all the changes.

```bash
sudo reboot
```

```bash
cd ~
git clone https://github.com/nasa/nos3.git
cd nos3
git switch dev
git submodule update --init --recursive
```

## Build NOS3

Some of these steps may not be necessary, but they are the simplest way to get the FSW running with minimal changes to NOS3 files.

Note: There will be some errors at the end of `make prep`, but they won't affect the FSW build.

```bash
make prep
make config
make fsw
```

`docker_launch.sh` also creates a number of data directories. Since we're not using the docker launch script, we'll need to create them ourselves.

```bash
source scripts/env.sh
mkdir $FSW_DIR/data 2> /dev/null
mkdir $FSW_DIR/data/cam 2> /dev/null
mkdir $FSW_DIR/data/evs 2> /dev/null
mkdir $FSW_DIR/data/hk 2> /dev/null
mkdir $FSW_DIR/data/inst 2> /dev/null
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
git switch dev
sudo apt install -y ./nos3_filestore/packages/ubuntu/*arm64.deb
sudo chmod 777 /usr/lib/libitc_* /usr/lib/libnos_engine_*
```

## 

## Run FSW on Host Machine

```bash
cd ~/nos3
source scripts/env.sh
$SCRIPT_DIR/fsw_respawn.sh
```



# NOS3 Engine Server

The process for the NOS3 Engine Server is the same as the FSW machine but with a few additional steps. A couple of changes need to be made to the NOS3 scripts to disable the FSW and publish the NOS Engine Server port.

**First, disable your system firewall, or add the following ports to the firewall rules:**

- tcp:12000
- udp:5013


## One-time Setup

Note: Installing docker will depend on your host machine and is not documented here.

```bash
git clone https://github.com/nasa/nos3.git
cd nos3
git switch dev
git submodule update --init --recursive
```

### Disable the FSW

Next, NOS3 needs to be modified when running FSW separately from the rest. Disable the FSW by commenting out the docker run command.  In `scripts/docker_launch.sh`, disable FSW by commenting out the following line:

Before:
```bash
gnome-terminal --title=$SC_NUM" - NOS3 Flight Software" -- $DFLAGS -v $BASE_DIR:$BASE_DIR --name $SC_NUM"_nos_fsw" -h nos_fsw --network=$SC_NETNAME -w $FSW_DIR --sysctl fs.mqueue.msg_max=10000 --ulimit rtprio=99 --cap-add=sys_nice $DBOX $SCRIPT_DIR/fsw_respawn.sh &
```

After:
```bash 
# gnome-terminal --title=$SC_NUM" - NOS3 Flight Software" -- $DFLAGS -v $BASE_DIR:$BASE_DIR --name $SC_NUM"_nos_fsw" -h nos_fsw --network=$SC_NETNAME -w $FSW_DIR --sysctl fs.mqueue.msg_max=10000 --ulimit rtprio=99 --cap-add=sys_nice $DBOX $SCRIPT_DIR/fsw_respawn.sh &
```

### Publish the NOS Engine Server Port

Publish the NOS Engine Server port by adding `-p 12000:12000` to the docker run command for the engine server.

Before:
```bash
gnome-terminal --tab --title=$SC_NUM" - NOS Engine Server" -- $DFLAGS -v $SIM_DIR:$SIM_DIR --name $SC_NUM"_nos_engine_server"  -h nos_engine_server --network=$SC_NETNAME -w $SIM_BIN $DBOX /usr/bin/nos_engine_server_standalone -f $SIM_BIN/nos_engine_server_config.json
```
After:
```bash
gnome-terminal --tab --title=$SC_NUM" - NOS Engine Server" -- $DFLAGS -p 12000:12000 -v $SIM_DIR:$SIM_DIR --name $SC_NUM"_nos_engine_server"  -h nos_engine_server --network=$SC_NETNAME -w $SIM_BIN $DBOX /usr/bin/nos_engine_server_standalone -f $SIM_BIN/nos_engine_server_config.json
```

### Publish the COSMOS Port

Publish the COSMOS port by adding `-p 5013:5013/udp` to the docker run command in `scripts/gsw_cosmos_launch.sh`.

Before:
```bash
gnome-terminal --tab --title="Cosmos" -- $DFLAGS -v $BASE_DIR:$BASE_DIR -v /tmp/nos3:/tmp/nos3 -v /tmp/.X11-unix:/tmp/.X11-unix:ro -e DISPLAY=$DISPLAY -e QT_X11_NO_MITSHM=1 -w $GSW_DIR --name cosmos_openc3-operator_1 --network=nos3_core ballaerospace/cosmos:4.5.0
```

After:
```bash
gnome-terminal --tab --title="Cosmos" -- $DFLAGS -p 5013:5013/udp -v $BASE_DIR:$BASE_DIR -v /tmp/nos3:/tmp/nos3 -v /tmp/.X11-unix:/tmp/.X11-unix:ro -e DISPLAY=$DISPLAY -e QT_X11_NO_MITSHM=1 -w $GSW_DIR --name cosmos_openc3-operator_1 --network=nos3_core ballaerospace/cosmos:4.5.0
```

### Configure the FSW IP address

In `cfg/nos3_defs/cpu1_device_cfg.h` change `GENERIC_RADIO_CFG_FSW_IP` from `nos_fsw` to the IP address of the FSW machine.

Before:
```c
#define GENERIC_RADIO_CFG_FSW_IP           "nos_fsw"
```

After:
```c
#define GENERIC_RADIO_CFG_FSW_IP           "<IP>"
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
