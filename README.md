# Ocre Zephyr Workspace

This repository generates a basic workspace for creating Ocre containers and deploying them on a Zephyr ecosystem

## Installation

The repository contains two Docker containers, as [compose.yml](./compose.yml) shows:

* Ocre SDK: Contains the basic SDK to generate new Ocre containers or deploy some examples
* Ocre Runtime: Contains the ocre engine and some helper scripts. It can run on Zephyr or Linux

First things first, you need to create and deploy the containers using the compose file:

```bash
cd ocre-worskpace
docker compose up -d
```

After that, you should have 2 different containers, that should be visible when running `docker ps`:

* ocre-dev
* ocre-sdk

Both containers are mounting the working directory to have full visibility.

You can jump into the console of each container by running:

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

### Running ocre containres on Zephyr systems

## Contributing

Pull requests are welcome. For major changes, please open an issue first
to discuss what you would like to change.

Please make sure to update tests as appropriate.

## License

[Apache 2.0](http://www.apache.org/licenses/)
