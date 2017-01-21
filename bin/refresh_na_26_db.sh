#!/bin/bash

set -e
set -u

if [ $# -ne 1 ]; then
  echo "Usage: $(basename $0) <geo_dir>"
  exit 1
fi

GEO_DIR=$1

if [ ! -d $GEO_DIR ]; then
  echo "No such dir: $GEO_DIR"
  exit 1
fi

rm -rf $GEO_DIR/tmp*

DB_NUMBER=26
DB_NAME=na_${DB_NUMBER}
DB_BASENAME=${DB_NAME}_db

LOCAL_VERSION=$(ls $GEO_DIR | sed -n -e "s/^$DB_BASENAME-//p" | sort -n | tail -n 1)
S3_VERSION=$(aws s3 ls s3://vamp-artifacts/geo/$DB_BASENAME- | fgrep .tgz.md5 | sed -r "s/.*$DB_BASENAME-(\d+)\.tgz\.md5/\1/" | sort -n | tail -n 1)

if [ -z $LOCAL_VERSION ] || [ $LOCAL_VERSION -ne $S3_VERSION ]; then
  echo "We have version $LOCAL_VERSION"
  echo "Version $S3_VERSION is available"
  echo "Updating $DB_NAME to version $S3_VERSION"

  TEMP_DIR=$(mktemp -d -p $GEO_DIR)
  cd $TEMP_DIR

  NEW_BASENAME=$DB_BASENAME-$S3_VERSION
  TARBALL=$NEW_BASENAME.tgz
  echo "Downloading $TARBALL to $TEMP_DIR"
  aws s3 cp s3://vamp-artifacts/geo/$TARBALL $TEMP_DIR

  echo "Untarring $TARBALL"
  tar xzf $TARBALL

  echo "Moving $NEW_BASENAME to $GEO_DIR"
  mv $NEW_BASENAME $GEO_DIR

  echo "Removing $TEMP_DIR"
  rm -r $TEMP_DIR

  if [ -n "$LOCAL_VERSION" ]; then
    PREV_DB_DIR=$GEO_DIR/$DB_BASENAME-$LOCAL_VERSION
    echo "Removing previous db dir $PREV_DB_DIR"
    rm -r $PREV_DB_DIR
  fi

  echo "Done!"
else
  echo "Already have latest version"
fi
