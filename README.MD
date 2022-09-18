This project contains multiple Docker images to **run Apache Zeppelin on kuberneters**.

We strongly recommand to use datatok helm charts.

Zeppelin interpreters will run on separate Docker containers.

## Content

### server

Lite image (less than 300MB) based on alpine to run zeppelin without interpreters.

Deps:
- alpine
- java openjdk8
- bash

### interpreter-spark

Image based on ubuntu to run Spark zeppelin interpreter. 
The SPARK_HOME folder must be provided at runtime.

Interpreters:
- spark
- md
- sh

Deps:
- java openjdk-8-jre-headless

### interpreter-r-full

Heavy image (2 GB) based on ubuntu to run interpreters:
- spark
- md
- sh
- python
- r
- jdbc

Deps:
- java openjdk-8-jre-headless

### r-packer

Use this image to build conda env pack for dev purposes.

### interpreter-r

Only interpreters

## Usage

See ./dev/docker-compose.yaml

Build:

```
docker build --build-arg=zeppelin_version=0.10.1 -t zep .
```

Sources:
* https://github.com/apache/zeppelin/blob/v0.10.1/scripts/docker/zeppelin-server/Dockerfile