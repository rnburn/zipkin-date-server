FROM ubuntu:16.04

WORKDIR /app
ADD .  /app
RUN set -x \
# new directory for storing sources and .deb files
	&& tempDir="$(mktemp -d)" \
	&& chmod 777 "$tempDir" \
			\
# save list of currently-installed packages so build dependencies can be cleanly removed later
			&& savedAptMark="$(apt-mark showmanual)" \
			\
# set up go
  && apt-get update \
  && apt-get install --no-install-recommends --no-install-suggests -y \
              git \
              ca-certificates \
              software-properties-common \
              wget \
  && wget https://storage.googleapis.com/golang/go1.8.3.linux-amd64.tar.gz \
  && tar -xvf go1.8.3.linux-amd64.tar.gz \
  && mv go $tempDir \
  && export GOROOT=$tempDir/go \
  && export GOPATH=$tempDir/gopath \
  && export PATH=$GOPATH/bin:$GOROOT/bin:$PATH \
# install glide
  && add-apt-repository ppa:masterminds/glide \
  && apt-get update \
  && apt-get install --no-install-recommends --no-install-suggests -y \
              glide \
# build the date-server demo
  && mkdir -p $GOPATH/src/github.com/rnburn/ \
  && mv /app $GOPATH/src/github.com/rnburn/zipkin-date-server \
  && cd $GOPATH/src/github.com/rnburn/zipkin-date-server \
  && glide install \
  && go build -o date-server \
  && mkdir /app \
  && mv date-server /app/date-server \
# reset apt-mark's "manual" list so that "purge --auto-remove" will remove all build dependencies
# (which is done after we install the built packages so we don't have to redownload any overlapping dependencies)
			&& apt-mark showmanual | xargs apt-mark auto > /dev/null \
			&& { [ -z "$savedAptMark" ] || apt-mark manual $savedAptMark; } \
			\
# purge leftovers from building them (including extra, unnecessary build deps)
  && apt-get purge -y --auto-remove \
	&& rm -rf "$tempDir"

EXPOSE 8080

STOPSIGNAL SIGTERM

CMD ["/app/date-server", "all"]
