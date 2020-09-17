#!/usr/bin/env bash
# exit immediately when a command fails
set -e
# only exit with zero if all commands of the pipeline exit successfully
set -o pipefail
# error on unset variables
set -u

CPU_ARCHS="amd64 arm64"
TAG="colin-proxy-url"
REPO="528451384384.dkr.ecr.us-west-2.amazonaws.com"

docker run -it --rm -v $(pwd):/workdir -w /workdir 528451384384.dkr.ecr.us-west-2.amazonaws.com/buildkite-agent-golang1.14 make operator
docker run -it --rm -v $(pwd):/workdir -w /workdir 528451384384.dkr.ecr.us-west-2.amazonaws.com/buildkite-agent-golang1.14 make prometheus-config-reloader

# prometheus-operator
for arch in $(echo "$CPU_ARCHS"); do
	docker build --build-arg ARCH=${arch} --build-arg OS=linux -t ${REPO}/prometheus-operator:${TAG}-${arch} .
	aws-okta exec ops-write -- docker push "${REPO}/prometheus-operator:${TAG}-${arch}"
done

export DOCKER_CLI_EXPERIMENTAL=enabled
docker manifest create -a "${REPO}/prometheus-operator:${TAG}" \
  "${REPO}/prometheus-operator:${TAG}-amd64" \
  "${REPO}/prometheus-operator:${TAG}-arm64"

for arch in $(echo "$CPU_ARCHS"); do
	docker manifest annotate --arch "${arch}" "${REPO}/prometheus-operator:${TAG}" "${REPO}/prometheus-operator:${TAG}-${arch}"
done

aws-okta exec ops-write -- docker manifest push "${REPO}/prometheus-operator:${TAG}"

# prometheus-config-reloader
for arch in $(echo "$CPU_ARCHS"); do
	docker build --build-arg ARCH=${arch} --build-arg OS=linux -t ${REPO}/prometheus-config-reloader:${TAG}-${arch} .
	aws-okta exec ops-write -- docker push "${REPO}/prometheus-config-reloader:${TAG}-${arch}"
done

export DOCKER_CLI_EXPERIMENTAL=enabled
docker manifest create -a "${REPO}/prometheus-config-reloader:${TAG}" \
  "${REPO}/prometheus-config-reloader:${TAG}-amd64" \
  "${REPO}/prometheus-config-reloader:${TAG}-arm64"

for arch in $(echo "$CPU_ARCHS"); do
	docker manifest annotate --arch "${arch}" "${REPO}/prometheus-config-reloader:${TAG}" "${REPO}/prometheus-config-reloader:${TAG}-${arch}"
done

aws-okta exec ops-write -- docker manifest push "${REPO}/prometheus-config-reloader:${TAG}"
