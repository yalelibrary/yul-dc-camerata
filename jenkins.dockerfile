FROM ruby:3.2.0

RUN apt update && apt upgrade -y && \
    apt install python3-pip -y

RUN python3 -m pip install awscli
