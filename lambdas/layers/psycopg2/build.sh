#!/bin/bash

rm -rf python
mkdir -p python

docker run --rm \
  -v "$PWD":/var/task \
  public.ecr.aws/lambda/python:3.14 \
  pip install -r requirements.txt -t python/

zip -r psycopg2.zip python
