DMD=dmd

date
rm *.a

git log -1 --pretty=format:"module myversion; public static char[] author=cast(char[])\"%an\"; public static char[] date=cast(char[])\"%ad\"; public static char[] hash=cast(char[])\"%h\";">myversion.d

#~/dmd/linux/bin/dmd -version=D1 myversion.d src/Log.d src/zmq_pp_broker_client.d src/zmq_point_to_poin_client.d src/libzmq_headers.d src/mq_client.d lib/libzmq.a lib/libstdc++.a lib/libuuid.a -oflibzmq-D1.a -lib

$DMD -version=D2 -m64 myversion.d \
src/Log.d src/dzmq.d src/zmq_pp_broker_client.d src/zmq_point_to_poin_client.d src/libzmq_headers.d src/mq_client.d \
src/rabbitmq_client.d src/librabbitmq_headers.d \
lib64/libzmq.a lib64/libstdc++.a lib64/libuuid.a lib64/librabbitmq.a -oflib-zeromq-connector-64.a -lib

echo 'build examples'

rm test_librabbitmq_listenq
$DMD -version=D2 -m64  src/Log.d src/librabbitmq_headers.d src/mq_client.d examples/test_librabbitmq_listenq.d \
lib-zeromq-connector-64.a -oftest_librabbitmq_listenq

rm test_rabbitmq_recieve
$DMD -version=D2 -m64  src/Log.d src/librabbitmq_headers.d src/mq_client.d src/rabbitmq_client.d examples/test_rabbitmq_recieve.d \
lib-zeromq-connector-64.a -oftest_rabbitmq_recieve


#lib64/libstdc++.a lib64/libuuid.a lib64/librabbitmq.a

#$DMD -version=D2 src/test_send.d src/Log.d src/zmq_point_to_poin_client.d src/libzmq_headers.d src/mq_client.d \
#lib/libzmq.a lib/libstdc++.a lib/libuuid.a 

rm *.o
date
