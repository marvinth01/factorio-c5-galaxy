#/usr/bin/env bash

VERSION=$(jq -r ".version" c5-galaxy/info.json)
zip -r "c5-galaxy_${VERSION}.zip" c5-galaxy
