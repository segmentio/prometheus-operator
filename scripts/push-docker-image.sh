#!/usr/bin/env bash
# exit immediately when a command fails
set -e
# only exit with zero if all commands of the pipeline exit successfully
set -o pipefail
# error on unset variables
set -u

# docker run -it --rm -v $(pwd):/workdir -w /workdir 528451384384.dkr.ecr.us-west-2.amazonaws.com/buildkite-agent-golang1.14 make operator

CPU_ARCHS="amd64 arm64"
TAG="colin-proxy-url"
REPO="528451384384.dkr.ecr.us-west-2.amazonaws.com/prometheus-operator"

for arch in $(echo "$CPU_ARCHS"); do
	docker build --build-arg ARCH=${arch} --build-arg OS=linux -t ${REPO}:${TAG}-${arch} .
	aws-okta exec ops-write -- docker push "${REPO}:${TAG}-${arch}"
done

export DOCKER_CLI_EXPERIMENTAL=enabled
docker manifest create -a "${REPO}:${TAG}" \
  "${REPO}:${TAG}-amd64" \
  "${REPO}:${TAG}-arm64"

for arch in $(echo "$CPU_ARCHS"); do
	docker manifest annotate --arch "${arch}" "${REPO}:${TAG}" "${REPO}:${TAG}-${arch}"
done

aws-okta exec ops-write -- docker manifest push "${REPO}:${TAG}"
