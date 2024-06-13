


cd nos3
source scripts/env.sh
mkdir $FSW_DIR/data 2> /dev/null
mkdir $FSW_DIR/data/cam 2> /dev/null
mkdir $FSW_DIR/data/evs 2> /dev/null
mkdir $FSW_DIR/data/hk 2> /dev/null
mkdir $FSW_DIR/data/inst 2> /dev/null


make config
make build-fsw

# echo '10.1.10.52 nos_engine_server' | sudo tee -a /etc/hosts


# Needs tested
# echo '* - rtprio 99' | sudo tee -a /etc/security/limits.conf
# Reboot