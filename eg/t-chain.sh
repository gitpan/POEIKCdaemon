#!/bin/sh

./bin/poikc -I ./t
./bin/poikc -I

./bin/poikc  -U=get_VERSION

./bin/poikc -D -U chain  Demo::Demo::chain_start chain_1,chain_2,chain_3 abcdefg

cat test-poeikcd.txt

sleep 0.3;

cat test-poeikcd.txt

./bin/poikc  -U=get_VERSION
