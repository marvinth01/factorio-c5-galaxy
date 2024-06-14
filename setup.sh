#/usr/bin/env bash

if [ -d factorio ]; then
    :
else
    echo "Error: No factorio directory"
    exit 1
fi

ln -sfT ../../c5-galaxy factorio/mods/c5-galaxy

npm i factoriomod-debug
npm x -- fmtk sumneko-3rd -d factorio/doc-html/runtime-api.json -p factorio/doc-html/prototype-api.json fmtk-out
