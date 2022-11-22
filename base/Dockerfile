FROM phusion/passenger-ruby27:2.3.1

RUN curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
  curl -sL   https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && \
  echo "deb https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list && \
  sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' && \
  curl -sL https://deb.nodesource.com/setup_16.x | bash - > /dev/null && \
  DEBIAN_FRONTEND=noninteractive apt-get -qq install -y --no-install-recommends \
    build-essential \
    libsasl2-dev \
    nodejs \
    rsync \
    yarn \
    postgresql-client-12 && \
    apt-get autoremove -y && \
    apt-get clean


RUN yarn && \
  yarn config set no-progress && \
  yarn config set silent

RUN rm /etc/nginx/sites-enabled/default

ENV APP_HOME /home/app/webapp
RUN mkdir $APP_HOME && chown -R app $APP_HOME

COPY ops/boot.sh /etc/rc.local
WORKDIR $APP_HOME
