ARG IMAGE=intersystemsdc/iris-community
FROM $IMAGE

USER root
## add git
RUN apt update && apt-get -y install git

WORKDIR /irisrun/repo

USER ${ISC_PACKAGE_MGRUSER}
RUN --mount=type=bind,src=.,dst=. \
    iris start IRIS && \
	iris session IRIS < iris.script && \
    iris stop IRIS quietly