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

    PACKAGE_NAME=${2}
    if [[ ${PACKAGE_NAME} == "" ]]; then
        echo "ERROR: Missing package name"
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
    --substitutions "_TAG=${TAG},_EOSIO_CDT_VERSION=${VERSION},_EOSIO_CDT_PACKAGE_NAME=${PACKAGE_NAME}" \
    --machine-type=n1-highcpu-32
}

usage() {
    echo "usage: $0 version package-name [docker-tag]"
    echo "  version       The version release to use, this is 1.6.0, etc."
    echo "  package-name  The release archive package name to download, for example 'eosio.cdt_1.6.0-1_amd64.deb'"
    echo "  docker-tag    The tag to use when tagging the docker image, optional, defaults to 'version'"
    echo ""
}

main $@
