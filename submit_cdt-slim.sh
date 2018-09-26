#!/bin/bash

export CLOUDSDK_CORE_PROJECT=${CLOUDSDK_CORE_PROJECT:-"eoscanada-public"}

main() {
    VERSION=${1}
    if [[ ${VERSION} == "" ]]; then
        echo "ERROR: Missing branch / tag name"
        echo ""

        usage
        exit 1
    fi

    TAG=${VERSION}
    if [[ ${2} != "" ]]; then
        TAG=${2}
    fi

    gcloud builds submit . \
    --async \
    --config cloudbuild-cdt-slim.yaml \
    --disk-size 120 \
    --timeout 8h \
    --substitutions "_TAG=${TAG},_EOSIO_CDT_VERSION=${VERSION}" \
    --machine-type=n1-highcpu-32
}

usage() {
    echo "usage: $0 git-ref [docker-tag]"
    echo "  git-ref     The git reference (branch/tag/sha1) to build"
    echo "  docker-tag  The tag to use when tagging the docker image, optional, defaults to 'git-ref'"
    echo ""
}

main $@
