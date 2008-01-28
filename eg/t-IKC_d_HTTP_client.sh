#!/bin/sh

./bin/poikc -I ./t
./bin/poikc -I

### spawn
./bin/poikc -o d -s m -D IKC_d_HTTP_client spawn

### (More safe)
./bin/poikc -o d -s e -D IKC_d_HTTP enqueue http://search.cpan.org/~suzuki/
echo "********************************************************************";
sleep 1;
date;
./bin/poikc -o d -s e -D IKC_d_HTTP dequeue


### (Direct access)
./bin/poikc -o d -s m -D POEIKCdaemon::Utility publish_IKC IKC_d_HTTP IKC_d_HTTP_client
./bin/poikc -o d -a=IKC_d_HTTP -s=enqueue_respond http://search.cpan.org/~suzuki/
echo "********************************************************************";
sleep 1;
date;
./bin/poikc -o d -D -a=IKC_d_HTTP -s=dequeue_respond

