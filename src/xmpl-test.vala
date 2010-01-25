using GLib;
using Xmpl;

static int main (string[] args)
{
	int num_files = args.length - 3;
	string command = args[1];
	string key = args[2];
	string value = "";

	if (command == "set")
	{
		value = args[3];
		num_files -= 1;
	}

	for (int i = args.length - num_files; i < args.length; i++)
	{
		string file = args[i];

		switch (command)
		{
			case "get":
				value = Xmpl.get_property (file, key);
				debug ("'%s': %s => %s", file, key, value);
				break;
			case "set":
				if (Xmpl.set_property (file, key, value))
				{
					debug ("successfully set '%s': %s => %s", file, key, value);
				}

				else
				{
					debug ("error setting '%s': %s => %s", file, key, value);
				}
				break;
			case "del":
				if (Xmpl.delete_property (file, key))
				{
					debug ("successfully deleted '%s': %s", file, key);
				}

				else
				{
					debug ("could not delete '%s': %s", file, key);
				}
				break;
			default:
				debug ("I have no idea what you're trying to say. Speak up, please.");
				break;
		}
	}

	return 0;
}
