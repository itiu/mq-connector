module test_rabbitmq_listenq;

private import Log;
private import std.c.string;
private import std.c.stdlib;
private import core.thread;
private import core.stdc.stdio;

private import mq_client;
private import librabbitmq_headers;

void main(char[][] args)
{
	printf("test_amqp_listenq \r\n");
	mq_client client = null;

	string hostname = "192.168.0.101";
	int port = 5672;
	string queuename = "for-client-doc-notif";

	amqp_connection_state_t conn;

	conn = amqp_new_connection();

	int sockfd;

	die_on_error(sockfd = amqp_open_socket(hostname.ptr, port), "Opening socket");

	amqp_set_sockfd(&conn, sockfd);
	die_on_amqp_error(amqp_login(&conn, "bigarchive".ptr, 0, 131072, 0, amqp_sasl_method_enum.AMQP_SASL_METHOD_PLAIN, "ba".ptr,
			"123456".ptr), "Logging in");
	amqp_channel_open(&conn, 1);
	die_on_amqp_error(amqp_get_rpc_reply(&conn), "Opening channel");

	amqp_bytes_t qq = amqp_cstring_bytes(queuename);

	amqp_basic_consume(&conn, 1, qq, amqp_empty_bytes, 0, 0, 0, amqp_empty_table);

	die_on_amqp_error(amqp_get_rpc_reply(&conn), "Consuming");

	{
		amqp_frame_t frame;
		int result;

		amqp_basic_deliver_t* d;
		amqp_basic_properties_t* p;
		size_t body_target;
		size_t body_received;

		while(1)
		{
			amqp_maybe_release_buffers(&conn);
			result = amqp_simple_wait_frame(&conn, &frame);
			printf("Result %d\n", result);
			if(result < 0)
				break;

			printf("Frame type %d, channel %d\n", frame.frame_type, frame.channel);
			if(frame.frame_type != AMQP_FRAME_METHOD)
				continue;

			printf("Method %s\n", amqp_method_name(frame.payload.method.id));
			if(frame.payload.method.id != AMQP_BASIC_DELIVER_METHOD)
				continue;

			d = cast(amqp_basic_deliver_t*) frame.payload.method.decoded;
			printf("Delivery %u, exchange %.*s routingkey %.*s\n", d.delivery_tag, cast(int) d.exchange.len,
					cast(char*) d.exchange.bytes, cast(int) d.routing_key.len, cast(char*) d.routing_key.bytes);

			result = amqp_simple_wait_frame(&conn, &frame);
			if(result < 0)
				break;

			if(frame.frame_type != AMQP_FRAME_HEADER)
			{
				fprintf(stderr, "Expected header!");
				abort();
			}
			p = cast(amqp_basic_properties_t*) frame.payload.properties.decoded;
			if(p._flags & AMQP_BASIC_CONTENT_TYPE_FLAG)
			{
				printf("Content-type: %.*s\n", cast(int) p.content_type.len, cast(char*) p.content_type.bytes);
			}
			printf("----\n");

			body_target = frame.payload.properties.body_size;
			body_received = 0;

			while(body_received < body_target)
			{
				result = amqp_simple_wait_frame(&conn, &frame);
				if(result < 0)
					break;

				if(frame.frame_type != AMQP_FRAME_BODY)
				{
					fprintf(stderr, "Expected body!");
					abort();
				}

				body_received += frame.payload.body_fragment.len;
				assert(body_received <= body_target);

				printf("DATA:%s\r\n", frame.payload.body_fragment.bytes);

				//        amqp_dump(frame.payload.body_fragment.bytes,
				//                  frame.payload.body_fragment.len);
			}

			if(body_received != body_target)
			{
				/* Can only happen when amqp_simple_wait_frame returns <= 0 */
				/* We break here to close the connection */
				break;
			}

			amqp_basic_ack(&conn, 1, d.delivery_tag, 0);
		}
	}

	die_on_amqp_error(amqp_channel_close(&conn, 1, AMQP_REPLY_SUCCESS), "Closing channel");
	die_on_amqp_error(amqp_connection_close(&conn, AMQP_REPLY_SUCCESS), "Closing connection");
	die_on_error(amqp_destroy_connection(&conn), "Ending connection");
}

int count = 0;

void get_message(byte* message, int message_size, mq_client from_client, ref ubyte[])
{
	count++;
	printf("[%i] data: %s\n", count, cast(char*) message);

	//	from_client.send("", "test message", false);
	return;
}
