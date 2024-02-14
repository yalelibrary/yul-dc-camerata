FROM ruby:3.2.0

RUN apt update && apt upgrade -y && \
    apt install -y python3-pip \
    && rm -rf /var/lib/apt/lists/*

RUN python3 -m pip install awscli

RUN gem update --system && gem install bundler

COPY . ./

RUN bundle install && rake install