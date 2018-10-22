# Docker Image

The Dockerfile creates an image for IoTNumb3rs development.

## Create image

Calling the script creates the `iotnumb3rs:latest` image.

```bash
./build.sh
```

## Run Container

Set the `HOST_DIR` variable to specify the host's directory mapped to the container's home directory.

```bash
export HOST_DIR=<host dir to map>
```

Afterwards, spin up the container.

```bash
docker run -it --rm \
    -v $HOST_DIR:/home/iot \
    iotnumb3rs:latest
```
