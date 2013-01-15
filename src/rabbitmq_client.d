module rabbitmq_client;

private import std.c.string;
private import std.stdio;
private import core.stdc.stdlib;
private import core.thread;
private import std.datetime;
private import std.outbuffer;
private import core.stdc.stdio;
private import std.uuid;

private import Log;
private import mq_client;

alias void listener_result;

class amqp_broker_client: mq_client
{
	void function(byte* txt, int size, mq_client from_client, ref ubyte[] out_data) message_acceptor;

	int count = 0;
	bool isSend = false;

	this(string _bind_to, string _behavior)
	{
	}

	~this()
	{
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
		while(1)
		{
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