# Update the VARIANT arg in devcontainer.json to pick an Go version
ARG VARIANT=1.15.1-alpine3.12
FROM golang:${VARIANT}

# Options for setup script
ARG UPGRADE_PACKAGES="false"
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

COPY packageList /tmp/packageList
COPY .bashrc /tmp/.bashrc

# Install needed packages and setup non-root user. Use a separate RUN statement to add your own dependencies. Setup non root user
RUN apk update && \
    apk add $(cat /tmp/packageList) && \
    adduser -D -u ${USER_UID} ${USERNAME} && \
    adduser $USERNAME wheel && \
    sed -e 's;^# \(%wheel.*NOPASSWD.*\);\1;g' -i /etc/sudoers && \
    cp /temp/.bashrc /home/$USERNAME/.bashrc && chown $USERNAME /home/$USERNAME/.bashrc

# Install Go tools
ARG GO_TOOLS_WITH_MODULES="\
    golang.org/x/tools/gopls \
    honnef.co/go/tools/... \
    golang.org/x/tools/cmd/gorename \
    golang.org/x/tools/cmd/goimports \
    golang.org/x/tools/cmd/guru \
    golang.org/x/lint/golint \
    github.com/mdempsky/gocode \
    github.com/cweill/gotests/... \
    github.com/haya14busa/goplay/cmd/goplay \
    github.com/sqs/goreturns \
    github.com/josharian/impl \
    github.com/davidrjenni/reftools/cmd/fillstruct \
    github.com/uudashr/gopkgs/v2/cmd/gopkgs \
    github.com/ramya-rao-a/go-outline \
    github.com/acroca/go-symbols \
    github.com/godoctor/godoctor \
    github.com/rogpeppe/godef \
    github.com/zmb3/gogetdoc \
    github.com/fatih/gomodifytags \
    github.com/mgechev/revive \
    github.com/go-delve/delve/cmd/dlv"
RUN mkdir -p /tmp/gotools \
    && cd /tmp/gotools \
    && export GOPATH=/tmp/gotools \
    # Go tools w/module support
    && export GO111MODULE=on \
    && (echo "${GO_TOOLS_WITH_MODULES}" | xargs -n 1 go get -x )2>&1 \
    # gocode-gomod
    && export GO111MODULE=auto \
    && go get -x -d github.com/stamblerre/gocode 2>&1 \
    && go build -o gocode-gomod github.com/stamblerre/gocode \
    # golangci-lint
    #&& curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b /usr/local/bin 2>&1 \
    # Move Go tools into path and clean up
    && mv /tmp/gotools/bin/* /usr/local/bin/ \
    && mv gocode-gomod /usr/local/bin/ \
    && rm -rf /tmp/gotools

ENV GO111MODULE=auto