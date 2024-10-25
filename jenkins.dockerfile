FROM ruby:3.2.0

RUN apt-get update && apt upgrade -y && \
    apt-get install -y --no-install-recommends \
        jq \
        python3-pip \
        wget \
    && rm -rf /var/lib/apt/lists/*

RUN python3 -m pip install awscli selenium

RUN curl -Lo /usr/local/bin/ecs-cli https://amazon-ecs-cli.s3.amazonaws.com/ecs-cli-linux-amd64-latest && \
    chmod 755 /usr/local/bin/ecs-cli

# install google chrome and chromedriver
RUN wget -q -O chrome-linux64.zip https://bit.ly/chrome-linux64-130-0-6723-69 && \
    unzip chrome-linux64.zip && \
    rm chrome-linux64.zip && \
    mv chrome-linux64 /opt/chrome/ && \
    ln -s /opt/chrome/chrome /usr/local/bin/ && \
    wget -q -O chromedriver-linux64.zip https://bit.ly/chromedriver-linux64-130-0-6723-69 && \
    unzip -j chromedriver-linux64.zip chromedriver-linux64/chromedriver && \
    rm chromedriver-linux64.zip && \
    mv chromedriver /usr/local/bin/

RUN gem update --system

COPY . ./

RUN gem install bundler && bundle install && rake install && chown -R 12001:12001 /usr/local/bundle/gems /tmp /usr/bin/google-chrome