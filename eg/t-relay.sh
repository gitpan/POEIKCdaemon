#!/bin/sh

./bin/poikc -I ./t
./bin/poikc -I

./bin/poikc  -U=get_VERSION

./bin/poikc -D -U relay Demo::Demo::relay_start Start_relay ccc ddd

cat test-poeikcd.txt

sleep 0.3;

cat test-poeikcd.txt

./bin/poikc  -U=get_VERSION
