FROM ruby:3.2.0

RUN apt-get update && apt upgrade -y && \
    apt-get install -y --no-install-recommends \
        jq \
        python3-pip && \
    # apt install -yqq unzip && \
    rm -rf /var/lib/apt/lists/*

RUN python3 -m pip install awscli selenium

RUN curl -Lo /usr/local/bin/ecs-cli https://amazon-ecs-cli.s3.amazonaws.com/ecs-cli-linux-amd64-latest && \
    chmod 755 /usr/local/bin/ecs-cli

# install google chrome - A
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -
RUN sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list'
RUN apt-get -y update
RUN apt-get install -y google-chrome-stable

# install chromedriver - A
RUN apt-get install -yqq unzip
RUN wget -O /tmp/chromedriver.zip http://chromedriver.storage.googleapis.com/`curl -sS chromedriver.storage.googleapis.com/LATEST_RELEASE`/chromedriver_linux64.zip
RUN unzip /tmp/chromedriver.zip chromedriver -d /usr/local/bin/



# # install google chrome - B
# RUN cd /opt && \
#     curl -L -O https://storage.googleapis.com/chrome-for-testing-public/130.0.6723.69/linux64/chrome-linux64.zip && \
#     unzip chrome-linux64.zip && \
#     apt update && \
#     while read pkg ; do apt-get satisfy -y --no-install-recommends "${pkg}" ; done < chrome-linux64/deb.deps  && \
#     chown root:root chrome-linux64/chrome_sandbox && \
#     chmod 4755 chrome-linux64/chrome_sandbox && \
#     export PATH="/opt/chrome-linux64:${PATH}" && \
#     export CHROME_DEVEL_SANDBOX="/opt/chrome-linux64/chrome_sandbox" && \
#     cd ..

# # install chromedriver - B
# RUN cd /usr/local/bin/ && \
#     curl -L -O https://storage.googleapis.com/chrome-for-testing-public/130.0.6723.69/linux64/chromedriver-linux64.zip && \
#     unzip chromedriver-linux64.zip && \
#     mv chromedriver-linux64 chromedriver && \
#     cd ~ && \
#     chmod 755 /usr/local/bin/chromedriver && \
#     export PATH="/usr/local/bin/chromedriver:${PATH}


RUN gem update --system

COPY . ./

RUN gem install bundler && bundle install && rake install && chown -R 12001:12001 /usr/local/bundle/gems /tmp