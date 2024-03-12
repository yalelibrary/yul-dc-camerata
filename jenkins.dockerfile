FROM ruby:3.2.0

RUN apt update && apt upgrade -y && \
    apt install -y --no-install-recommends \
        jq \
        libxml2 \
        python3-pip \
    && rm -rf /var/lib/apt/lists/*

RUN python3 -m pip install awscli

RUN gem update --system && gem install bundler

RUN groupadd -g 12001 jenkins && useradd jenkins -u 12001 -g 12001

USER jenkins
