#!/bin/bash

# Installing specific version as the CMakeLists.txt file uses `-n`
# present from 9 version onwards, not present in Zephyr base container
install_xxd() {
    if xxd --help 2>&1 | grep -q "\-n"; then
        echo "xxd with -n flag already installed"
        return 0
    fi

    echo "Building xxd from vim 9.1 source..."
    cd /tmp
    rm -rf vim
    git clone --depth 1 --branch v9.1.0 https://github.com/vim/vim.git
    cd vim/src/xxd
    make
    cp xxd /usr/local/bin/xxd
    chmod +x /usr/local/bin/xxd
    cd /
    rm -rf /tmp/vim
    echo "xxd installed successfully"
}

init_zephyr_env() {

    if [ ! -f /workspace/.west/config ]; then
        west init -l /workspace/application
        cd /workspace/application
        west update

        touch /workspace/.west/initialized
        echo "West workspace initialized successfully"
    else
        echo "West workspace already initialized"
    fi

    if [ -f /workspace/zephyr/zephyr-env.sh ]; then
        echo "Sourcing Zephyr environment..."
        source /workspace/zephyr/zephyr-env.sh
    fi

    if [ ! -f /root/.zephyr_sourced ]; then
        echo 'if [ -f /workspace/zephyr/zephyr-env.sh ]; then source /workspace/zephyr/zephyr-env.sh; fi' >> /root/.bashrc
        touch /root/.zephyr_sourced
    fi
}
set -e

echo "Initializing west workspace..."

git config --global --add safe.directory /workspace/application
git config --global --add safe.directory /workspace/application
git config --global --add safe.directory /workspace/ocre-sdk

install_xxd
init_zephyr_env

exec "$@"
