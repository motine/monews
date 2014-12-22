FROM ruby:2.1.5
MAINTAINER Tom Rothe <info@tomrothe.de>

# disable documentation generation for gems/bundler
RUN echo "gem: --no-rdoc --no-ri" > ~/.gemrc
RUN apt-get update && \
         apt-get install -y python-pip && \
         pip install awscli && \
		 apt-get clean && \
		 rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /opt
RUN git clone https://github.com/motine/monews.git
WORKDIR /opt/monews
RUN bundle install

COPY aws_keys_export.sh /opt/monews
COPY config.yaml /opt/monews
CMD "./s3_wrapper.rb"