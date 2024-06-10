

sudo apt update




cd nos3
make config
make build-fsw

# echo '10.1.10.52 nos_engine_server' | sudo tee -a /etc/hosts


# Needs tested
# echo '* - rtprio 99' | sudo tee -a /etc/security/limits.conf
# Reboot