#!/bin/bash

if [ -f "/.dockerenv" ] || [ -f "/.dockerinit" ]; then
  OTCLIENT_PATH=/otclient
  mkdir -p "$OTCLIENT_PATH/build"
  cd "$OTCLIENT_PATH/build"
  cmake -DVORBISFILE_LIBRARY:FILEPATH=/usr/lib/x86_64-linux-gnu/libvorbisfile.so -DVORBIS_LIBRARY:FILEPATH=/usr/lib/x86_64-linux-gnu/libvorbis.so ..
  make -j$(nproc)
else
  if [ "$(docker inspect -f '{{.State.Running}}' "otb")" = "false" ]; then
    docker start -a otb
  else
    echo "# Building already running on 'otb'"
  fi
fi