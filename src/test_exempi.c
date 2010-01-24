/* test-exempi.c
 */

#include <stdio.h>
#include "exempi-lite.h"

int main (int argc, char* argv[])
{
	int i;
	int num_files = argc - 3;
	char* command = argv[1];
	char* key = argv[2];
	char* value;

	if (strcmp ("set", command) == 0)
	{
		value = argv[3];
		num_files = argc - 4;
	}

	printf ("starting up (operating on %d files)...\n", num_files);

	for (i = argc - num_files; i < argc; i++)
	{
		char* file = argv[i];

		if (strcmp ("get", command) == 0)
		{
			value = xmpl_get_property (file, key);

			if (value)
			{
				printf ("'%s' for '%s': %s\n", key, file, value);
			}
			else
			{
				printf ("'%s' for '%s': <not defined>\n", key, file);
			}

			free (value);
		}

		else if (strcmp ("set", command) == 0)
		{
			if (xmpl_set_property (file, key, value))
			{
				printf ("set '%s' for '%s' to '%s'\n", key, file, value);
			}

			else
			{
				printf ("error setting '%s' for '%s' to '%s'\n", key, file, value);
			}
		}

		else if (strcmp ("del", command) == 0)
		{
			if (xmpl_delete_property (file, key))
			{
				printf ("deleted '%s' from '%s'\n", key, file);
			}

			else
			{
				printf ("error deleting '%s' from '%s'\n", key, file);
			}
		}
	}
}
