FROM ruby:2.6.6

RUN apt update && apt upgrade -y && \
    apt install -y --no-install-recommends \
        jq \
        python3-pip \
    && rm -rf /var/lib/apt/lists/*

RUN python3 -m pip install awscli

# RUN gem update --system && gem install bundler
RUN gem install bundler

# COPY . ./

# RUN bundle install && rake install