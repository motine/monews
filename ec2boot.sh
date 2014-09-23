#!/bin/bash

# setup
sudo yum -y groupinstall development
sudo yum -y install git ruby-devel curl-devel # openssl openssl-devel
gem install bundler
git clone https://github.com/motine/monews.git
cd monews
cp config.yaml.example config.yaml
bundle install

# download data from s3
rm -rf tmp rss
aws s3 cp --recursive s3://monews/tmp tmp
aws s3 cp --recursive s3://monews/rss rss

# run monews
ruby monews.rb

# upload to s3
aws s3 cp --recursive tmp s3://monews/tmp
aws s3 cp --recursive rss s3://monews/rss

# wait...
sleep 60

# kill instance
sudo shutdown -h 0
