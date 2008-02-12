#!/bin/sh

./bin/poikc -I ./t
./bin/poikc -I

./bin/poikc  -U=get_VERSION

./bin/poikc -D -U loop 10  Demo::Demo::loop_test Start_Loop aaa bbb

cat test-poeikcd.txt

./bin/poikc -D -U relay Demo::Demo::relay_start Start_relay ccc ddd

cat test-poeikcd.txt

./bin/poikc -D -U loop  Demo::Demo::loop_test Start_Loop AAA BBB

sleep 0.3;

cat test-poeikcd.txt

./bin/poikc -D -U stop Demo::Demo::loop_test end_loop End_loop 1111 2222

./bin/poikc  -U=get_VERSION
