// TODO переделать на абстрактную модель, отправитель <---> получатель (socket --> uid)

private import std.outbuffer;

interface mq_client
{
	// set callback function for listener ()
	void set_callback(void function(byte* data, int size, mq_client from_client, ref ubyte[]) _message_acceptor);

	void get_count(out int cnt);

	void listener();

	// sends a message to the specified socket
	void* connect_as_req (string connect_to);
	int send(void* soc, char* messagebody, int message_size, bool send_more);
	string reciev(void* soc);	
	
	bool is_success ();
	string get_fail_msg ();
}

public bool check_params (string[] list_need_params, char[][string] params)
{
	foreach (param ; list_need_params)
	{
		if ((param in params) is null)
		{
			return false;
		}
	}
	
	return true;
}
