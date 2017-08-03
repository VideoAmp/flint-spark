#!/usr/bin/env bash

set -e
set -u

function usage() {
  echo "Usage: $(basename $0) [-y] <spark-distfile> <image-repo-name> <image-number>"
  echo "  -y  Build image without prompting for confirmation"
  exit 1
}

if [ $# -ne 3 ] && [ $# -ne 4 ]; then
  usage
fi

if [ $1 = "-y" ]; then
  PROMPT=false
  shift
else
  PROMPT=true
fi

DISTFILE=$1
REPO_NAME=$2
IMAGE_NUMBER=$3

if [ ! -f $DISTFILE ]; then
  echo "No such file: $DISTFILE"
  exit 1
fi

set +e

for i in docker perl; do
  type $i &> /dev/null

  if [ $? -ne 0 ]; then
    echo "This script requires $i but cannot find it"
    exit 1
  fi
done

set -e

DIST_NAME_PAT="spark-([.\d]+(?:-SNAPSHOT)?)-bin-(.*)"

DISTFILE_BASENAME=$(basename $DISTFILE .tgz)
SPARK_VERSION=$(echo $DISTFILE_BASENAME | perl -pe "s/$DIST_NAME_PAT/\1/")
HADOOP_VERSION=$(echo $DISTFILE_BASENAME | perl -pe "s/$DIST_NAME_PAT/\2/")
DOCKER_TAG=$SPARK_VERSION-$HADOOP_VERSION-$IMAGE_NUMBER
IMAGE_NAME=$REPO_NAME:$DOCKER_TAG

function confirm_build() {
  echo -n "Will build $IMAGE_NAME. Proceed (y/n)? "
  read CONTINUE

  if [ -z $CONTINUE ] || ([ $CONTINUE != "y" ] && [ $CONTINUE != "n" ]); then
    echo "Enter 'y' or 'n'"
    confirm_build
  fi
}

if [ $PROMPT = "true" ]; then
  confirm_build
else
  CONTINUE=y
fi

if [ $CONTINUE = "y" ]; then
  echo "Building $IMAGE_NAME"
else
  echo "Aborting"
  exit
fi

BASEDIR=$(dirname $0)
DISTDIR=$BASEDIR/dist

if [ ! -d $DISTDIR ]; then
  mkdir $DISTDIR
fi

mv $DISTFILE $DISTDIR

cd $BASEDIR

docker build --squash --no-cache --build-arg DISTFILE=dist/$(basename $DISTFILE) -t $IMAGE_NAME .
