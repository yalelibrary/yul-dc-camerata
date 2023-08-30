FROM ruby:2.6.6

RUN apt-get update && apt upgrade -y && \
    apt-get install -y --no-install-recommends \
      jq \
      sqlite3 \
    && rm -rf /var/lib/apt/lists/*

# install awscli
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscli2.zip" && \
    unzip -d /tmp /tmp/awscli2.zip && /tmp/aws/install && rm -rf /tmp/aws*

RUN gem update --system

COPY . ./

RUN gem install bundler && bundle install && rake install
