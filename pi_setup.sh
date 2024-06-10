

sudo apt update
sudo apt install -y make cmake

echo '10.1.10.52 nos_engine_server' | sudo tee -a /etc/hosts

# Dependencies from Deployment Dockerfile
sudo apt install -y \
        cmake \
        git \
		gdb \
        python3-dev \
        python3-pip \
        dwarves \
        freeglut3-dev \
        libboost-dev \
        libboost-system-dev \
        libboost-program-options-dev \
        libboost-filesystem-dev \
        libboost-thread-dev \
        libboost-regex-dev \
        libgtest-dev \
        libicu-dev \
        libncurses5-dev \
        libreadline-dev \
        libsocketcan-dev \
        libxerces-c-dev \
        wget 

        # g++-multilib \
        # lib32z1 \
        # python-apt \
        # gcc-multilib \