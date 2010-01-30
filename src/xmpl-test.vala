using GLib;
using Xmpl;

string expand_namespace (string ns)
{
	switch (ns)
	{
		case "dc": return Xmpl.DC;
		case "cc": return Xmpl.CC;
		case "exif": return Xmpl.EXIF;
		case "exif-aux": return Xmpl.EXIF_AUX;
		case "tiff": return Xmpl.TIFF;
		case "rdf": return Xmpl.RDF;
		case "xmp": return Xmpl.XMP;
		case "xap": return Xmpl.XAP;
		case "xap-rights": return Xmpl.XAP_RIGHTS;
		default:
			critical ("'%s' is not a valid abbreviation for any namespace!", ns);
			return "";
	}
}

static int main (string[] args)
{
	int num_files = args.length - 4;
	string command = args[1];
	string namespace = expand_namespace (args[2]);
	string key = args[3];
	string value = "";

	if (command == "set")
	{
		value = args[4];
		num_files -= 1;
	}

	for (int i = args.length - num_files; i < args.length; i++)
	{
		string file = args[i];

		switch (command)
		{
			case "get":
				value = Xmpl.get_property (file, namespace, key);
				debug ("'%s': %s.%s => %s", file, args[2], key, value);
				break;
			case "set":
				if (Xmpl.set_property (file, namespace, key, value))
				{
					debug ("successfully set '%s': %s.%s => %s", file, args[2], key, value);
				}

				else
				{
					debug ("error setting '%s': %s.%s => %s", file, args[2], key, value);
				}
				break;
			case "del":
				if (Xmpl.delete_property (file, namespace, key))
				{
					debug ("successfully deleted '%s': %s.%s", file, args[2], key);
				}

				else
				{
					debug ("could not delete '%s': %s.%s", file, args[2], key);
				}
				break;
			default:
				debug ("I have no idea what you're trying to say. Speak up, please.");
				break;
		}
	}

	return 0;
}
