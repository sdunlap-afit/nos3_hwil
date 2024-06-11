# nos3_hwil


## Setup

```bash
git submodule update --init --recursive

cd nos3
source scripts/env.sh
mkdir $FSW_DIR/data 2> /dev/null
mkdir $FSW_DIR/data/cam 2> /dev/null
mkdir $FSW_DIR/data/evs 2> /dev/null
mkdir $FSW_DIR/data/hk 2> /dev/null
mkdir $FSW_DIR/data/inst 2> /dev/null
```



## Map NOS Engine IP

```bash
echo '10.1.10.52 nos_engine_server' | sudo tee -a /etc/hosts
```


## Config

Docker in Windows will not work with setschedparam so FSW will fail. To stop it from enforcing this feature, set `OSAL_CONFIG_DEBUG_PERMISSIVE_MODE = TRUE` in `nos3/fsw/osal/default_config.cmake`.

```cmake
set(OSAL_CONFIG_DEBUG_PERMISSIVE_MODE           TRUE
    CACHE BOOL "Disable enforcement of privileged operations"
)
```

## Build and run

```bash
cd nos3
make config
make build-fsw
./scripts/fsw_respawn.sh
```

## Clear submodules

```bash
git submodule deinit -f nos3
```


# NOS3 Engine Server

NOS3 needs to be slightly modified when running FSW separate from the rest. In `scripts/docker_launch.sh`, change the following lines:

```bash
echo $SC_NUM " - Flight Software..."
cd $FSW_DIR
gnome-terminal --title=$SC_NUM" - NOS3 Flight Software" -- $DFLAGS -v $BASE_DIR:$BASE_DIR --name $SC_NUM"_nos_fsw" -h nos_fsw --network=$SC_NETNAME -w $FSW_DIR --sysctl fs.mqueue.msg_max=10000 --ulimit rtprio=99 --cap-add=sys_nice $DBOX $SCRIPT_DIR/fsw_respawn.sh &
#gnome-terminal --window-with-profile=KeepOpen --title=$SC_NUM" - NOS3 Flight Software" -- $DFLAGS -v $BASE_DIR:$BASE_DIR --name $SC_NUM"_nos_fsw" -h nos_fsw --network=$SC_NETNAME -w $FSW_DIR --sysctl fs.mqueue.msg_max=10000 --ulimit rtprio=99 --cap-add=sys_nice $DBOX $FSW_DIR/core-cpu1 -R PO &
echo ""
```
to
```bash 
echo $SC_NUM " - Flight Software..."
cd $FSW_DIR
# gnome-terminal --title=$SC_NUM" - NOS3 Flight Software" -- $DFLAGS -v $BASE_DIR:$BASE_DIR --name $SC_NUM"_nos_fsw" -h nos_fsw --network=$SC_NETNAME -w $FSW_DIR --sysctl fs.mqueue.msg_max=10000 --ulimit rtprio=99 --cap-add=sys_nice $DBOX $SCRIPT_DIR/fsw_respawn.sh &
#gnome-terminal --window-with-profile=KeepOpen --title=$SC_NUM" - NOS3 Flight Software" -- $DFLAGS -v $BASE_DIR:$BASE_DIR --name $SC_NUM"_nos_fsw" -h nos_fsw --network=$SC_NETNAME -w $FSW_DIR --sysctl fs.mqueue.msg_max=10000 --ulimit rtprio=99 --cap-add=sys_nice $DBOX $FSW_DIR/core-cpu1 -R PO &
echo ""
```

And:

```bash
gnome-terminal --tab --title=$SC_NUM" - NOS Engine Server" -- $DFLAGS -v $SIM_DIR:$SIM_DIR --name $SC_NUM"_nos_engine_server"  -h nos_engine_server --network=$SC_NETNAME -w $SIM_BIN $DBOX /usr/bin/nos_engine_server_standalone -f $SIM_BIN/nos_engine_server_config.json
```
to
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

