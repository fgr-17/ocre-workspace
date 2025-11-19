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

### Running ocre containres on Zephyr systems

## Contributing

Pull requests are welcome. For major changes, please open an issue first
to discuss what you would like to change.

Please make sure to update tests as appropriate.

## License

[Apache 2.0](http://www.apache.org/licenses/)
