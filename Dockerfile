FROM ruby:2.1.5
MAINTAINER Tom Rothe <info@tomrothe.de>

# disable documentation generation for gems/bundler
RUN echo "gem: --no-rdoc --no-ri" > ~/.gemrc
RUN apt-get update && apt-get install -y python-pip && pip install awscli && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /opt
RUN mkdir -p /opt/monews
COPY . /opt/monews/
WORKDIR /opt/monews
RUN bundle install

CMD "/opt/monews/s3_wrapper.rb"