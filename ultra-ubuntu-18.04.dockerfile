FROM ubuntu:18.04

ARG VERSION

WORKDIR /workspace

LABEL maintainer="dfuse Team"
LABEL description="Image containing the EOSIO binaries for Ultra Blockchains" \
    version="${VERSION}" \
    packageName="ultra"

# Copy the package file from the context to our working directory
COPY ./*.deb .

# Copy some compile dependencies to our location
COPY ./librdkafka.so.1 .

RUN cp librdkafka.so.1 /usr/lib/x86_64-linux-gnu/librdkafka.so.1 \
    && cd /usr/lib/x86_64-linux-gnu/ \
    && ln -s librdkafka.so.1 librdkafka.so

RUN apt-get update \
    && apt-get install -y openssl ca-certificates ./*.deb \
    && rm -rf *.deb \
    && apt-get clean
