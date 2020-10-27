FROM phusion/passenger-ruby26:1.0.10

RUN echo 'Downloading Packages' && \
  curl -sL https://deb.nodesource.com/setup_12.x | bash - && \
  curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
  echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
  apt-get update -qq && \
  apt-get install -y --no-install-recommends \
    build-essential \
    libsasl2-dev \
    nodejs \
    rsync \
    tzdata \
    yarn \
  && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
  echo 'Packages Downloaded'

# Install Chrome so we can run system specs for Blacklight
RUN apt-get update && apt-get install -y wget && \
  wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - && \
  sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list' && \
  apt-get update && \
  apt-get install -y google-chrome-stable && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
  echo 'Chrome installed'

RUN yarn && \
  yarn config set no-progress && \
  yarn config set silent

RUN rm /etc/nginx/sites-enabled/default

COPY --from=nhd42358.live.dynatrace.com/linux/oneagent-codemodules:all / /
ENV LD_PRELOAD /opt/dynatrace/oneagent/agent/lib64/liboneagentproc.so


ENV APP_HOME /home/app/webapp
RUN mkdir $APP_HOME && chown -R app $APP_HOME
WORKDIR $APP_HOME
