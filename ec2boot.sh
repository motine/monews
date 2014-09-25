#!/bin/bash

# run `sudo` sh for testing

# setup
yum -y groupinstall development
yum -y install git ruby-devel curl-devel # openssl openssl-devel
gem install bundler
ln -s /usr/local/share/ruby/gems/2.0/gems/bundler-1.7.3/bin/bundle /usr/bin # put bundle in path
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
shutdown -h 0 &
