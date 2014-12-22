#!/bin/bash

# load authentication info into environment
source aws_keys_export.sh

# download from s3
rm -rf tmp rss
aws s3 cp --recursive s3://monews/tmp tmp
aws s3 cp --recursive s3://monews/rss rss

# run monews
ruby monews.rb

# upload to s3
aws s3 cp --recursive tmp s3://monews/tmp
aws s3 cp --recursive rss s3://monews/rss
