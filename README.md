# Ocre/Zephyr Workspace

This repository generates a basic workspace for creating Ocre containers and deploying them on a Zephyr ecosystem

## Downloading the repo correctly

**Important**: this repository contains 2 submodules, that contains 1 submodule each. To avoid running into future issues, download everything at once by running:

~~~bash
git clone --recurse-submodules <repo>
~~~

If you are reading this from your local copy of the repo, run this:

~~~bash
git submodule update --init --recursive
~~~

Addionally, you probably want to run this last command on the root repo every time you update something in the repo, at least as a healthy check. Read this [ref](https://git-scm.com/book/en/v2/Git-Tools-Submodules) to dig deeper on submodules management

## Workspace layout

The repository contains two Docker containers, as [compose.yml](./compose.yml) shows:

* **Ocre SDK**:
    * brief: Contains the basic SDK to generate new Ocre containers or deploy some examples mapped in [`/ocre-sdk'](./ocre-sdk/) dir
* **Ocre Runtime**:
    * brief: Contains the ocre engine and some helper scripts. It can run on Zephyr or Linux
    * mapped in [`/application`](./application/) dir

~~~mermaid
stateDiagram-v2

    state "OcreSDK" as ocre-sdk {
        sdk: Ocre SDK
        samples: generic/examples
        wasm_runtime: wasm-micro-runtime
        container: container.wasm
        sdk --> container
        samples --> container
        wasm_runtime --> container

    }

    state "OcreRuntime" as ocre-runtime {
        app: `./application` Zephyr project
        container_moved: container.wasm
    }

    zephyr: Zephyr SDK
    binary: binary [zephyr.elf]

    container --> container_moved
    
    zephyr --> binary
    container_moved --> app
    app --> binary
~~~


## Setting up the environment

```bash
cd ocre-worskpace
docker compose up -d
```

After that, you should have 2 different containers, that should be visible when running `docker ps`:

* ocre-dev >> mapped in `/application` dir for west compatibility
* ocre-sdk

Both containers are mounting the working directory to have full visibility.

You can jump into the terminal of each container by running:

~~~bash
docker exec -it ocre-dev bash
~~~

or

~~~bash
docker exec -it ocre-sdk bash
~~~

## Usage

### Generating WASM files from example containers

To generate Ocre containers from the examples contained in Ocre-SDK, follow the steps:

1. Jump into the `ocre-sdk` container

~~~bash
docker compose up -d
docker exec -it ocre-sdk bash
~~~

2. cd into the example you want to build and create a `build` dir:

~~~bash
cd /workspace/ocre-sdk/generic/blinky
mkdir -p build
~~~

3. Run CMake and Make:

~~~bash
cd build
cmake ..
make
~~~

Done! you should see something like this:

~~~bash
[ 25%] Building C object ocre-sdk-build/CMakeFiles/ocre_api.dir/ocre_api.c.obj
/workspace/ocre-sdk/ocre-sdk/ocre_api.c:174:9: warning: label at end of compound statement is a C23 extension
      [-Wc23-extensions]
  174 |         }
      |         ^
1 warning generated.
[ 50%] Linking C static library libocre_api.a
[ 50%] Built target ocre_api
[ 75%] Building C object CMakeFiles/blinky.wasm.dir/main.c.obj
[100%] Linking C executable blinky.wasm
[100%] Built target blinky.wasm
~~~

The outuput file of this process is `blinky.wasm` and should be placed
into `build` dir

### Building ocre for Zephyr targets

First thing you need is the `ocre-dev` container up and running. Then jump into the terminal:

~~~bash
docker exec -it ocre-dev bash
~~~

This container has everything you need to compile Zephyr targets, mainly West and the needed env variables. Everything should be configured from the [entrypoint-dev.sh](./scripts/entrypoint-dev.sh) script. You can check printing `ZEPHYR_BASE` env var inside the container to check that:

~~~bash
root@3949daec268e:/workspace# echo $ZEPHYR_BASE/
/workspace/zephyr/
~~~

This script also initializes the Ocre-Runtime project, mapped into the `application` directory (this name is because it seems the project was named like this when it was created, so to avoid conflicts with west...) by running `west -l /workspace/application`[link](./scripts/entrypoint-dev.sh#L27), so that way the ocre-runtime repo can be managed as a submodule by the main repo, instead of letting west manage the version control.

Once the application is initialized, ocre-runtime container takes a while to download all the dependencies (`west update`) the first time that is created. You can check if the progess of the process by checking the logs of the container (`docker logs ocre-dev`), or waiting until you see the message `"West workspace initialized successfully"`.

Finally, everything should be ready to build the Ocre application for Zephyr. 

For example, to run the generic/blinky example on the default board, you can follow this 2 steps (summarizing all the previoius info):


#### Terminal#1: Compile blinky example in `ocre-sdk` container:

Get into the `ocre-sdk` container and build:

~~~bash
docker exec -it ocre-sdk bash
cd ocre-sdk/generic/blinky
mkdir -p build && cd build
cmake ..
make
~~~

You should see something like this:

~~~bash
root@68bc3f6ddfac:/workspace/ocre-sdk/generic/blinky/build# cmake ..
-- Configuring done (0.0s)
-- Generating done (0.0s)
-- Build files have been written to: /workspace/ocre-sdk/generic/blinky/build
root@68bc3f6ddfac:/workspace/ocre-sdk/generic/blinky/build# make
[ 25%] Building C object ocre-sdk-build/CMakeFiles/ocre_api.dir/ocre_api.c.obj
/workspace/ocre-sdk/ocre-sdk/ocre_api.c:174:9: warning: label at end of compound statement is a C23
      extension [-Wc23-extensions]
  174 |         }
      |         ^
1 warning generated.
[ 50%] Linking C static library libocre_api.a
[ 50%] Built target ocre_api
[ 75%] Building C object CMakeFiles/blinky.wasm.dir/main.c.obj
[100%] Linking C executable blinky.wasm
[100%] Built target blinky.wasm
~~~

#### Terminal#2: Use the `blinky.wasm` file into Zephyr build and run the example

Get into the container and use the `build.sh` script to compile. Pass the `blinky.wasm` file as `-f` parameter:

~~~bash
docker exec -it ocre-dev bash
cd /workspace/application
./build.sh -t z -f ../ocre-sdk/generic/blinky/build/blinky.wasm -r
~~~

You should see the blinky example starting on the default board:

~~~bash
*** Booting Zephyr OS build v4.2.0-32-g8d0d392f8cc7 ***
I: /lfs mount: 0

I: OCRE common initialized successfully
I: Registered cleanup handler for type 0
I: Timer system initialized
I: Registered cleanup handler for type 3
I: Messaging system initialized
I: Container Supervisor started.

ocre:~$ 

Ocre runtime started
I: Request to create new container in slot: 0
I: Request to run container in slot:0
I: EVENT_CREATE_CONTAINER
I: Allocating memory for container 0
I: File path: /lfs/ocre/images/blinky.bin, size: 21068
I: Loaded binary to buffer for container 0
W: Created container:0
I: Created container in slot:0
I: EVENT_RUN_CONTAINER
I: Instantiating WASM runtime for container:0
I: Module registered: 0x80ebb00
W: Running container:0 in dedicated thread
I: Started container in slot:0
I: Container thread 0 started
=== Generic Blinky Example (Printf Only) ===
This example demonstrates software blinking without physical hardware.
I: Registered dispatcher for type 0: timer_callback
I: Incremented resource count: type=0, count=1
I: Created timer 1 for module 0x80ebb00
Timer created. ID: 1, Interval: 1000ms
I: Started timer 1 with interval 1000ms, periodic=1
Generic blinking started. You should see 'blink' messages every 1000ms.
Press Ctrl+C to stop.
blink (count: 1, state: -)
blink (count: 2, state: +)
...
~~~

## Creating your own wasm app (your own container)

To avoid modifying the [`./ocre-sdk`](./ocre-sdk/) repository when creating apps, I created a copy of the [`generic/blinky`](./ocre-sdk/generic/blinky/) example into the root dir of the repo and renamed as [`my_blinky`](./my_blinky/). Dir layout will look like this:

~~~bash
├── ocre-sdk/        # needed to create your wasm container
├── application/     # zephyr project that has to embed your wasm container
├── ...
└── my_blinky/       # << your project! normal dir or git submodule (better!)
~~~

This would be my recommended flow for creating new wasm apps:

* Make a copy of this repo, or just select "Use this template in GitHub"
* Update the Ocre-SDK and Ocre-Runtime submodules to the latest or any tag you prefer/need
* make a copy of the most similar example into the root dir of this repo (or even better encapsulated, track it as a submodule)
* Compile your wasm app in the Ocre-SDK container as shown in [this section](#generating-wasm-files-from-example-containers)


~~~bash
docker compose up -d
docker exec -it ocre-sdk bash

cd /workspace/my_blinky
mkdir -p build
cd build
cmake ..
make
~~~

* Then, as you may guess, you can follow the steps described in [this section](#building-ocre-for-zephyr-targets). So, jump into the ocre-runtime container and run the `build.sh` script:

~~~bash
docker exec -it ocre-dev bash
cd /workspace/application
./build.sh -t z -f ../my_blinky/build/my_blinky.wasm -r
~~~

~~~mermaid
flowchart TD
    zephyr[Zephyr SDK]
    binary[binary zephyr.elf]
    container[container.wasm]

    subgraph "**OcreSDK**"
        sdk[Ocre SDK]
        wasm_runtime[wasm-micro-runtime]
    end

    subgraph "**OcreRuntime**"
        app[`./application` Zephyr project]
        container_moved[container.wasm]
    end

    subgraph "**myBlinky**"
        my_blinky_app[my_blinky_app]
    end

    sdk --> container
    wasm_runtime --> container
    my_blinky_app --> container


    container --> container_moved
    
    zephyr --> binary
    container_moved --> app
    app --> binary
~~~

## Contributing

Pull requests are welcome. For major changes, please open an issue first
to discuss what you would like to change.

Please make sure to update tests as appropriate.

## License

[Apache 2.0](http://www.apache.org/licenses/)
