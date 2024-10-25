FROM ruby:3.2.0

RUN apt-get update && apt upgrade -y && \
    apt-get install -y --no-install-recommends \
        jq \
        python3-pip && \
    apt install -yqq unzip && \
    rm -rf /var/lib/apt/lists/*

RUN python3 -m pip install awscli selenium

RUN curl -Lo /usr/local/bin/ecs-cli https://amazon-ecs-cli.s3.amazonaws.com/ecs-cli-linux-amd64-latest && \
    chmod 755 /usr/local/bin/ecs-cli

# install google chrome
# RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -
# RUN sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list'
# RUN apt-get -y update
# RUN apt-get install -y ./google-chrome-stable_114.0.5735.90-1_amd64.deb
# RUN apt-get install -y google-chrome-stable


# RUN apt install -yqq unzip
# RUN wget -q https://mirror.cs.uchicago.edu/google-chrome/pool/main/g/google-chrome-stable/google-chrome-stable_130.0.6723.69-1_amd64.deb
# RUN sh -c 'echo "zip [arch=linux64] https://storage.googleapis.com/chrome-for-testing-public/130.0.6723.69/linux64/ stable main" >> /etc/apt/sources.list.d/google-chrome.list'
# RUN sh -c 'echo "deb [arch=amd64] https://mirror.cs.uchicago.edu/google-chrome/pool/main/g/google-chrome-stable/ stable main" >> /etc/apt/sources.list.d/google-chrome.list'
# RUN apt-get install -y google-chrome-stable
# RUN cd /opt && \
RUN curl -Lo /opt https://storage.googleapis.com/chrome-for-testing-public/130.0.6723.69/linux64/chrome-linux64.zip && \
    unzip chrome-linux64.zip && \
    apt update && \
    while read pkg ; do apt-get satisfy -y --no-install-recommends "${pkg}" ; done < chrome-linux64/deb.deps  && \
    chown root:root chrome-linux64/chrome_sandbox && \
    chmod 4755 chrome-linux64/chrome_sandbox && \
    export PATH="/opt/chrome-linux64:${PATH}" && \
    export CHROME_DEVEL_SANDBOX="/opt/chrome-linux64/chrome_sandbox"

# install chromedriver
# RUN wget -O /tmp/chromedriver.zip https://googlechromelabs.github.io`curl -sS googlechromelabs.github.io/chrome-for-testing/LATEST_RELEASE_STABLE`/chromedriver_linux64.zip
RUN wget -O /tmp/chromedriver.zip https://storage.googleapis.com/chrome-for-testing-public/130.0.6723.69/linux64/chromedriver-linux64.zip
RUN unzip /tmp/chromedriver.zip chromedriver -d /usr/local/bin/

RUN gem update --system

COPY . ./

RUN gem install bundler && bundle install && rake install && chown -R 12001:12001 /usr/local/bundle/gems /tmp /usr/bin/google-chrome