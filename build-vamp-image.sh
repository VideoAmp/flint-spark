#!/bin/bash

set -e
set -u

function usage() {
  echo "Usage: $(basename $0) [-p] <spark-distfile> <image-number>"
  echo "  -p  Push image"
  exit 1
}

if [ $# -eq 3 ]; then
  if [ $1 = "-p" ]; then
    PUSH=true
    shift
  else
    usage
  fi
elif [ $# -ne 2 ]; then
  usage
else
  PUSH=false
fi

DISTFILE=$1
IMAGE_NUMBER=$2

if [ ! -f $DISTFILE ]; then
  echo "No such file: $DISTFILE"
  exit 1
fi

REPO_NAME=videoamp/spark

DIST_NAME_PAT="spark-([.\d]+(?:-SNAPSHOT)?)-bin-([.\d]+-cdh([.\d]+))([-.\w]+)?-vamp_b(.*)"

DISTFILE_BASENAME=$(basename $DISTFILE .tgz)
SPARK_VERSION=$(echo $DISTFILE_BASENAME | perl -pe "s/$DIST_NAME_PAT/\1/")
SPARK_BINARY_VERSION=${SPARK_VERSION:0:3}
HADOOP_VERSION=$(echo $DISTFILE_BASENAME | perl -pe "s/$DIST_NAME_PAT/\2/")
CDH_VERSION=$(echo $DISTFILE_BASENAME | perl -pe "s/$DIST_NAME_PAT/\3/")
BRANCH=$(echo $DISTFILE_BASENAME | perl -pe "s/$DIST_NAME_PAT/\4/")
SPARK_BUILD_TAG=$(echo $DISTFILE_BASENAME | perl -pe "s/$DIST_NAME_PAT/\5/")
NATIVE_LIB_VERSION=cdh$CDH_VERSION
DOCKER_TAG=$SPARK_VERSION-$HADOOP_VERSION$BRANCH-b$SPARK_BUILD_TAG-$IMAGE_NUMBER

echo "Building $REPO_NAME:$DOCKER_TAG"

docker build --build-arg DISTFILE=$DISTFILE --build-arg SPARK_BINARY_VERSION=$SPARK_BINARY_VERSION --build-arg NATIVE_LIB_VERSION=$NATIVE_LIB_VERSION -t videoamp/spark:$DOCKER_TAG $(dirname $0)

if [ $PUSH = "true" ]; then
  docker push $REPO_NAME:$DOCKER_TAG
fi
