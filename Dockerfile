FROM ruby:2.1.5
MAINTAINER Tom Rothe <info@tomrothe.de>

# disable documentation generation for gems/bundler
RUN echo "gem: --no-rdoc --no-ri" > ~/.gemrc
# install aws
RUN apt-get update && apt-get install -y python3 python3-pip && pip3 install awscli && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /opt
RUN mkdir -p /opt/monews
COPY . /opt/monews/
WORKDIR /opt/monews
RUN bundle install

CMD "./s3_wrapper.sh"