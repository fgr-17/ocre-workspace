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

    # Migrate older workspaces that used the "application" manifest directory name.
    if [ -f /workspace/.west/config ] && grep -q '^path = application' /workspace/.west/config 2>/dev/null; then
        echo "Updating west manifest path: application -> ocre-runtime"
        sed -i 's/^path = application$/path = ocre-runtime/' /workspace/.west/config
    fi

    if [ ! -f /workspace/.west/config ]; then
        west init -l /workspace/ocre-runtime
        cd /workspace/ocre-runtime
        west update

        touch /workspace/.west/initialized
        echo "West workspace initialized successfully"
    else
        echo "West workspace already initialized"
    fi

    cd /workspace/ocre-runtime && west zephyr-export 2>/dev/null || true

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

git config --global --add safe.directory /workspace/ocre-runtime
git config --global --add safe.directory /workspace/ocre-runtime/ocre-sdk
git config --global --add safe.directory /workspace/ocre-runtime/wasm-micro-runtime

install_xxd
pip3 install --no-cache-dir littlefs-python >/dev/null 2>&1 || pip3 install --no-cache-dir littlefs-python
init_zephyr_env

exec "$@"
