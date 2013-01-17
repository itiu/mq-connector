module test_recieve;

private import Log;
private import std.c.string;
private import std.c.stdlib;
private import core.thread;

private import std.stdio;

private import mq_client;
private import rabbitmq_client;

void main(char[][] args)
{
	mq_client client = null;

	char[][string] params;

	params["hostname"] = cast(char[]) "192.168.0.101";
	params["port"] = cast(char[]) "5672";
	params["queuename"] = cast(char[]) "new-search";
	params["vhost"] = cast(char[]) "bigarchive";
	params["login"] = cast(char[]) "ba";
	params["credentional"] = cast(char[]) "123456";

	client = new rabbitmq_client(params);

	if(client.is_success() == true)
	{
		client.set_callback(&get_message);

		Thread thread = new Thread(&client.listener);

		log.trace("start new Thread %X", &thread);
		thread.start();
	} else
	{
		writeln(client.get_fail_msg);
	}
	//        while(true)
	//            Thread.getThis().sleep(100_000_000);
}

int count = 0;

void get_message(byte* message, int message_size, mq_client from_client, ref ubyte[])
{
	count++;
	printf("[%i] data: %s\n", count, cast(char*) message);

	//	from_client.send("", "test message", false);
	return;
}
