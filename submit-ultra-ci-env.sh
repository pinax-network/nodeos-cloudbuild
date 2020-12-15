#!/bin/bash

ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

export CLOUDSDK_CORE_PROJECT=eoscanada-shared-services

# We do not use `ultra-ci-env.cb.yaml`, see comment it for future details about why.

# CentOS 7 fails currently when compiling librdkafka so we disable it for now, not like it's a big deal right now
#gcloud builds submit . --config eosio-ci-env.cb.yaml --substitutions _IMAGE_TAG=centos-7.7,_BRANCH=release/ultra/2.0.x-dm --timeout 1h --machine-type=n1-highcpu-32 --async
gcloud builds submit . --config eosio-ci-env.cb.yaml --substitutions _IMAGE_TAG=ubuntu-16.04,_BRANCH=release/ultra/2.0.x-dm --timeout 1h --machine-type=n1-highcpu-32 --async
gcloud builds submit . --config eosio-ci-env.cb.yaml --substitutions _IMAGE_TAG=ubuntu-18.04,_BRANCH=release/ultra/2.0.x-dm --timeout 1h --machine-type=n1-highcpu-32 --async


## CentOS 7 Build Logs
# ...
# Step 13/14 : RUN mkdir -p /usr/local/librdkafka     && { wget -qO- https://github.com/edenhill/librdkafka/archive/v1.4.4.tar.gz | tar -C /usr/local/librdkafka --strip-components=1 -xz ;}     && cd /usr/local/librdkafka     && ./configure --install-deps     && make     && make install
#  ---> Running in d6e8526cb847
# checking for OS or distribution... ok (centos)
# checking for C compiler from CC env... failed
# checking for gcc (by command)... ok
# checking for C++ compiler from CXX env... failed
# checking for C++ compiler (g++)... failed
# checking for C++ compiler (clang++)... ok
# checking executable ld... ok
# checking executable nm... ok
# checking executable objdump... ok
# checking executable strip... ok
# checking executable libtool... ok
# checking for pkgconfig (by command)... ok
# checking for install (by command)... ok
# checking for PIC (by compile)... ok
# checking for GNU-compatible linker options... ok
# checking for GNU linker-script ld flag... ok
# checking for __atomic_32 (by compile)... ok
# checking for __atomic_64 (by compile)... ok
# checking for socket (by compile)... ok
# parsing version '0x010404ff'... ok (1.4.4)
# checking for librt (by pkg-config)... failed
# checking for librt (by compile)... ok
# checking for libpthread (by pkg-config)... failed
# checking for libpthread (by compile)... ok
# checking for c11threads (by pkg-config)... failed
# checking for c11threads (by compile)... failed (disable)
# checking for libdl (by pkg-config)... failed
# checking for libdl (by compile)... ok
# checking for zlib (by pkg-config)... ok
# checking for libcrypto (by pkg-config)... ok
# checking for libssl (by pkg-config)... ok
# checking for libsasl2 (by pkg-config)... failed
# checking for libsasl2 (by compile)... failed
# installing dependencies (yum install -y cyrus-sasl) libsasl2... using yum
# checking for libsasl2 (by pkg-config)... failed
# checking for libsasl2 (by compile)... failed (fail)
# checking for libsasl (by pkg-config)... failed
# checking for libsasl (by compile)... failed (disable)
# checking for libzstd (by pkg-config)... failed
# checking for libzstd (by compile)... failed
# building dependency libzstd... ok (from source)
# checking for libzstd (by pkg-config)... failed
# checking for libzstd (by compile)... ok
# checking for libm (by pkg-config)... failed
# checking for libm (by compile)... ok
# checking for liblz4 (by pkg-config)... failed
# checking for liblz4 (by compile)... failed (disable)
# checking for syslog (by compile)... ok
# checking for rapidjson (by compile)... failed (disable)
# checking for crc32chw (by compile)... ok
# checking for regex (by compile)... ok
# checking for strndup (by compile)... ok
# checking for strlcpy (by compile)... failed (disable)
# checking for strerror_r (by compile)... ok
# checking for pthread_setname_gnu (by compile)... ok
# checking for nm (by env NM)... ok (cached)
# checking for python3 (by command)... failed (disable)
# disabling linker-script since python3 is not available
# checking for getrusage (by compile)... ok



# ###########################################################
# ###                  Configure failed                   ###
# ###########################################################
# ### Accumulated failures:                               ###
# ###########################################################
#  libsasl2 (WITH_SASL_CYRUS)
#     module: self
#     action: fail
#     reason:
# compile check failed:
# CC: CC
# flags: -lsasl2
# gcc  -g -O2 -fPIC -Wall -Wsign-compare -Wfloat-equal -Wpointer-arith -Wcast-align -Wall -Werror _mkltmpIC5Zgk.c -o _mkltmpIC5Zgk.c.o   -lsasl2:
# _mkltmpIC5Zgk.c:1:23: fatal error: sasl/sasl.h: No such file or directory
#  #include <sasl/sasl.h>
#                        ^
# compilation terminated.
# source: #include <sasl/sasl.h>

# ###########################################################
# ### Installing the following packages might help:       ###
# ###########################################################
# sudo yum install -y  cyrus-sasl

# The command '/bin/sh -c mkdir -p /usr/local/librdkafka     && { wget -qO- https://github.com/edenhill/librdkafka/archive/v1.4.4.tar.gz | tar -C /usr/local/librdkafka --strip-components=1 -xz ;}     && cd /usr/local/librdkafka     && ./configure --install-deps     && make     && make install' returned a non-zero code: 1
