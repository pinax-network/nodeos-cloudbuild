#!/bin/bash

export CLOUDSDK_CORE_PROJECT=${CLOUDSDK_CORE_PROJECT:-"eoscanada-shared-services"}

main() {
    VERSION=${1}
    if [[ ${VERSION} == "" ]]; then
        echo "ERROR: Missing version"
        echo ""

        usage
        exit 1
    fi

    MODIFIER=${2}
    if [[ ${MODIFIER} == "" ]]; then
        echo "ERROR: Missing modifier"
        echo ""

        usage
        exit 1
    fi

    TAG=${VERSION}
    if [[ ${3} != "" ]]; then
        TAG=${3}
    fi

    gcloud builds submit . \
    --async \
    --config cloudbuild-cdt.yaml \
    --disk-size 120 \
    --timeout 8h \
    --substitutions "_TAG=${TAG},_EOSIO_CDT_VERSION=${VERSION},_EOSIO_CDT_MODIFIER=${MODIFIER}" \
    --machine-type=n1-highcpu-32
}

usage() {
    echo "usage: $0 version modifier [docker-tag]"
    echo "  version     The version release to use, this is 1.4.1, 1.5.0, etc."
    echo "  modifier    The release archive modifier to download, for example '-1.amd64' or '.x86_64'"
    echo "  docker-tag  The tag to use when tagging the docker image, optional, defaults to 'version'"
    echo ""
}

main $@
