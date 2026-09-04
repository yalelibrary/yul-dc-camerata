FROM ruby:3.4.10

RUN apt-get update && apt upgrade -y && \
    apt-get install -y --no-install-recommends \
      jq \
    && rm -rf /var/lib/apt/lists/*

# install awscli
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscli2.zip" && \
    unzip -d /tmp /tmp/awscli2.zip && /tmp/aws/install && rm -rf /tmp/aws*

RUN curl -Lo /usr/local/bin/ecs-cli https://amazon-ecs-cli.s3.amazonaws.com/ecs-cli-linux-amd64-latest && \
    chmod 755 /usr/local/bin/ecs-cli

RUN gem update --system

COPY . ./app

WORKDIR /app

RUN gem install bundler -v 4.0.13 && \
    bundle install && \
    rake install && \
    chown -R 12001:12001 /usr/local/bundle/gems