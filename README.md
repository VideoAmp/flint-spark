# Flint Spark

This project is for building Docker images of Spark for [Flint](https://github.com/VideoAmp/flint). You will need to build your own images for use with Flint, customized with a specific Spark binary distribution and Hadoop native libraries for your Hadoop installation. Even if you don't need the Hadoop native libs to run your Spark jobs, VideoAmp's experience has shown that Spark jobs which are run without the Hadoop native libs are *much* slower than those run with them.

## Building a Flint Spark Image

For starters, building a Docker image of Spark for use with Flint requires a Spark binary distribution tarball, either an [official distribution](http://spark.apache.org/downloads.html) or one built from source. Suppose we download the official Spark 2.2.0 distribution for Hadoop 2.7 and later to `/tmp`. This file path is `/tmp/spark-2.2.0-bin-hadoop2.7.tgz`. Clone this Git repo into a local working directory and copy `Dockerfile-base` to `Dockerfile`. Add a step at the end of `Dockerfile` to copy your Hadoop native libs into the Docker image at `/opt/spark/lib/native`. At VideoAmp, these instructions look like

```Dockerfile
RUN mkdir -p /opt/spark/lib/native
RUN wget -O - https://static.vamp/hadoop-native-libs/hadoop-libs.gz | tar xzf - -C /opt/spark/lib/native
```

When using a Flint Spark cluster, ensure you have set the `spark.executor.extraLibraryPath` Spark config option to `/opt/spark/lib/native`. The bootstrapping mechanism from the [ammonium-util](https://github.com/VideoAmp/ammonium-util) library will set this for you.

Use `build-image.sh` to build your image. You will need to decide on a Docker repo name for your organization's Flint Spark images. For example, at VideoAmp we use `videoamp/flint-spark`. You also need to provide an "image number" to the build script. This will become a part of the image tag. It should be unique within your org to ensure uniqueness of each image you push to your registry. At VideoAmp, we build and deploy our Flint Spark images with a CI system that uses an incrementing build number as the image number. As an example, to create a Docker image named `acme/flint-spark` with image number 1, we would run

```
./build-image.sh /tmp/spark-2.2.0-bin-hadoop2.7.tgz acme/flint-spark 1
```

The script will print the name of the Docker image it will create and ask to proceed. In this case, it will create `acme/flint-spark:2.2.0-hadoop2.7-1`. Once the image has been created, you can push it to your Docker registry with

```
docker push acme/flint-spark:2.2.0-hadoop2.7-1
```

You will need to customize your Flint server's `docker.conf` for the image repo name you use. Again, assuming `acme/flint-spark`, your `docker.conf` file should look like

```hocon
flint.docker {
  image_repo="acme/flint-spark"
}
```

The Flint server will now be able to find any images pushed to that repo.
