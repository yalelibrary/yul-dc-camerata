FROM ruby:2.7.8

RUN apt update && apt upgrade -y && \
    apt install -y --no-install-recommends \
        jq \
        python3-pip \
    && rm -rf /var/lib/apt/lists/*

RUN python3 -m pip install awscli

# RUN gem update --system && gem install bundler
RUN gem install bundler -v '2.4.22'

# COPY . ./

# RUN bundle install && rake install