module rabbitmq_client;

private import Log;

private import std.c.string;
private import std.c.stdlib;
private import std.datetime;
private import std.outbuffer;
private import std.uuid;
private import std.conv;

private import core.stdc.stdio;
private import core.thread;

private import Log;
private import mq_client;
private import librabbitmq_headers;

alias void listener_result;

Logger log;

static this()
{
	log = new Logger("rabbitmq", "log", null);
}

class rabbitmq_client: mq_client
{

	private amqp_connection_state_t conn;
	private int sockfd;

	private string fail;
	private bool is_success_status = false;

	bool is_success()
	{
		return is_success_status;
	}

	string get_fail_msg()
	{
		return fail;
	}

	void function(byte* txt, int size, mq_client from_client, ref ubyte[] out_data) message_acceptor;

	int count = 0;
	bool isSend = false;

	this(char[][string] params)
	{
		string[] need_params = ["port", "hostname", "queuename", "vhost", "login", "credentional"];
		if(check_params(need_params, params) == false)
		{
			fail = "не достаточно параметров, необходимо:" ~ text(need_params) ~ ", представлено:" ~ text(params);
		} else
		{
			conn = amqp_new_connection();

			int port = to!(int)(params["port"]);

			die_on_error(sockfd = amqp_open_socket(cast(char*) (params["hostname"] ~ "\0"), port), cast (immutable char*) ("Error on opening socket (AMQP) [" ~ params["hostname"] ~ "]" ));

			amqp_set_sockfd(&conn, sockfd);
			die_on_amqp_error(
					amqp_login(&conn, cast(char*) (params["vhost"] ~ "\0"), 0, 131072, 0, amqp_sasl_method_enum.AMQP_SASL_METHOD_PLAIN,
							cast(char*) (params["login"] ~ "\0"), cast(char*) (params["credentional"] ~ "\0")), "Logging in");
			amqp_channel_open(&conn, 1);
			die_on_amqp_error(amqp_get_rpc_reply(&conn), "Opening channel");

			amqp_bytes_t qq = amqp_cstring_bytes(params["queuename"]);

			amqp_basic_consume(&conn, 1, qq, amqp_empty_bytes, 0, 0, 0, amqp_empty_table);

			die_on_amqp_error(amqp_get_rpc_reply(&conn), "Consuming");
			is_success_status = true;
		}
	}

	~this()
	{
		die_on_amqp_error(amqp_channel_close(&conn, 1, AMQP_REPLY_SUCCESS), "Closing channel");
		die_on_amqp_error(amqp_connection_close(&conn, AMQP_REPLY_SUCCESS), "Closing connection");
		die_on_error(amqp_destroy_connection(&conn), "Ending connection");
	}

	// set callback function for listener ()
	void set_callback(void function(byte* txt, int size, mq_client from_client, ref ubyte[] out_data) _message_acceptor)
	{
		message_acceptor = _message_acceptor;
	}

	void get_count(out int cnt)
	{
		cnt = count;
	}

	// in thread listens to the queue and calls _message_acceptor
	listener_result listener()
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
			//			printf("----\n");

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

				//				printf("DATA:%s\r\n", frame.payload.body_fragment.bytes);

				//        amqp_dump(frame.payload.body_fragment.bytes,
				//                  frame.payload.body_fragment.len);

				try
				{
					count++;

					ubyte[] outbuff;

					message_acceptor((cast(byte*) frame.payload.body_fragment.bytes),
							cast(uint) (frame.payload.body_fragment.len), this, outbuff);

					//					send(soc_rep, cast(char*) outbuff, cast(uint) outbuff.length, false);
				} catch(Exception ex)
				{
					log.trace("ex! user function callback, %s", ex.msg);
				}

			}

			if(body_received != body_target)
			{
				/* Can only happen when amqp_simple_wait_frame returns <= 0 */
				/* We break here to close the connection */
				break;
			}

			amqp_basic_ack(&conn, 1, d.delivery_tag, 0);
		}

		return;
	}

	int send(void* soc_rep, char* messagebody, int message_size, bool send_more)
	{
		return -1;
	}

	void* connect_as_req(string connect_to)
	{
		return null;
	}

	string reciev(void* soc)
	{
		return null;
	}

}