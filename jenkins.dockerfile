FROM ruby:3.2.0

RUN apt update && apt upgrade -y && \
    apt install -y python3-pip

RUN python3 -m pip install awscli
