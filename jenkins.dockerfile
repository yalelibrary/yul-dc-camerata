FROM ruby:3.2.0

RUN apt-get update && apt upgrade -y && \
    apt-get install -y --no-install-recommends \
        jq \
        python3-pip \
    && rm -rf /var/lib/apt/lists/*

RUN python3 -m pip install awscli

RUN curl -Lo /usr/local/bin/ecs-cli https://amazon-ecs-cli.s3.amazonaws.com/ecs-cli-linux-amd64-latest && \
    chmod 755 /usr/local/bin/ecs-cli

RUN gem update --system

COPY . ./

RUN gem install bundler && bundle install && rake install && chown -R 12001:12001 /usr/local/bundle/gems