# Docker Image

The Dockerfile creates an image for IoTNumb3rs development.

## Create image

Calling the script creates the `iotnumb3rs:latest` iamge.

```
./build.sh
```

## Run Container

Set the `HOST_DIR` variable to specify the host's directory mapped to the container's home directory.

```
export HOST_DIR=<host dir to map>
```

Afterwards, spin up the container.

```
docker run -it --rm \
    -v $HOST_DIR:/home/iot \
    iotnumb3rs:latest
```
