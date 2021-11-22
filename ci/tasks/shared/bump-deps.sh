#!/bin/bash

set -eux

git clone input_repo output_repo

cd output_repo/$SOURCE_PATH

#intentionally cause an explicit commit if the underlying go version in our compiled Dockerfile changes.
#assume the go-dep-bumper and bosh-utils are bumping at the same cadence.
NEW_GO_MINOR=$(go version | sed 's/go version go1\.\([0-9]\+\)\..*$/\1/g')
CURRENT_GO_MINOR=$(cat go.mod | grep -E "^go 1.*" | sed "s/^\(go 1.\)\([0-9]\+\)/\2/")

go mod edit -go=1.$NEW_GO_MINOR

go get -u ./...
if [ $CURRENT_GO_MINOR == $NEW_GO_MINOR ]; then
  go mod tidy
else
  go mod tidy -go=1.$CURRENT_GO_MINOR
  go mod tidy -go=1.$NEW_GO_MINOR
fi
go mod vendor

if [ "$(git status --porcelain)" != "" ]; then
  git status
  git add vendor go.sum go.mod
  git config user.name $GIT_USER_NAME
  git config user.email $GIT_USER_EMAIL
  if [ $CURRENT_GO_MINOR == $NEW_GO_MINOR ]; then
    git commit -m "Update vendored dependencies"
  else
    git commit -m "Bump to go version 1.$NEW_GO_MINOR" -m "- (and update vendored dependencies)"
  fi
fi