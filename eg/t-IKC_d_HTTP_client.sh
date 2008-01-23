#!/bin/sh

./bin/poikc -I ./t
./bin/poikc -I

### spawn
./bin/poikc -o d -s m  IKC_d_HTTP_client spawn

### (More safe)
./bin/poikc -o d -s e  IKC_d_HTTP enqueue http://search.cpan.org/~suzuki/
echo "********************************************************************";
sleep 1;
date;
./bin/poikc -o d -s e  IKC_d_HTTP dequeue


### (Direct access)
./bin/poikc -o d -s m  POEIKCdaemon::Utility publish_IKC IKC_d_HTTP IKC_d_HTTP_client
./bin/poikc -o d -a=IKC_d_HTTP -s=enqueue_respond http://search.cpan.org/~suzuki/
echo "********************************************************************";
sleep 1;
date;
./bin/poikc -o d -a=IKC_d_HTTP -s=dequeue_respond

