/* exempi-lite.c
 *
 * <insert your silly legalese here, puhleez!>
 *
 * If you've come here looking for documentation, you're in the wrong place.
 * I'd love to tell you that all of this stuff is self-explanatory and all
 * that, but there's nothing intuitive about writing code and I'm in need of
 * more explaining than most. Your best bet, if you haven't been driven off
 * just yet, is to mosey on over to exempi-lite.h for a less implementation-
 * specific rendition of the how-tos and what-fors.
 */

#include "exempi-lite.h"

char* xmpl_get_property (char* file, char* key)
{
	if (xmp_init ())
	{
		XmpFilePtr f;
		XmpPtr x;
		XmpStringPtr s;
		XmpPropsBits p;
		char* value = NULL;

		f = xmp_files_open_new (file, XMP_OPEN_READ | XMP_OPEN_ONLYXMP);
		x = xmp_files_get_new_xmp (f);

		if (xmp_has_property (x, NS_DC, key))
		{
			s = xmp_string_new ();

			/* This property is a string. */
			if (xmp_get_property (x, NS_DC, key, s, &p) && strcmp ("", xmp_string_cstr (s)) != 0)/* && XMP_IS_PROP_SIMPLE (p))*/
			{
				value = strdup (xmp_string_cstr (s));
			}

			/* Nope... it's an array. */
			else if (xmp_get_array_item (x, NS_DC, key, 1, s, &p))/* && XMP_IS_PROP_ARRAY (p))*/
			{
				int i = 2;
				value = strdup (xmp_string_cstr (s));

				for (; xmp_get_array_item (x, NS_DC, key, i, s, NULL); i++)
				{
					/* Allocate enough space for both strings, plus one more character for the
					   comma that will separate the array items. */
					value = (char*) realloc (value,
						(strlen (value) + 1 + strlen (xmp_string_cstr (s))) * sizeof (char));
					value = strcat (value, ",");
					value = strcat (value, xmp_string_cstr (s));
				}
			}

			else
			{
				printf ("Error: Unrecognized property type '%x'\n", p);
			}

			xmp_string_free (s);
		}

		xmp_files_free (f);
		xmp_free (x);
		xmp_terminate ();

		return value;
	}
}

bool xmpl_set_property (char* file, char* key, char* value)
{
	if (xmp_init ())
	{
		XmpFilePtr f;
		XmpPtr x;
		XmpStringPtr s;
		XmpPropsBits p = 0;
		bool success = false;

		f = xmp_files_open_new (file, XMP_OPEN_FORUPDATE | XMP_OPEN_ONLYXMP);
		x = xmp_files_get_new_xmp (f);
		s = xmp_string_new ();

		/* This property is a string. */
		if (xmp_set_property (x, NS_DC, key, value, p))
		{
			success = true;
		}

		/* Nope... it's an array. */
		else if (xmp_set_array_item (x, NS_DC, key, 1, value, p))
		{
			int i;
			char* temp = strdup (value);
			temp = strtok (temp, ",");

			for (i = 1; temp && xmp_set_array_item (x, NS_DC, key, i, temp, p); i++)
			{
				temp = strtok (NULL, ",");
				success = true;
			}

			free (temp);
		}

		/* Flush the changes to disk. */
		if (!xmp_files_put_xmp (f, x) || !xmp_files_close (f, XMP_CLOSE_SAFEUPDATE))
		{
			printf ("Error writing to or closing '%s': %d\n", file, xmp_get_error ());
			success = false;
		}

		xmp_files_free (f);
		xmp_free (x);
		xmp_string_free (s);

		xmp_terminate ();

		return success;
	}
}

bool xmpl_delete_property (char* file, char* key)
{
	if (xmp_init ())
	{
		XmpFilePtr f;
		XmpPtr x;
		XmpStringPtr s;
		bool success = false;

		f = xmp_files_open_new (file, XMP_OPEN_FORUPDATE | XMP_OPEN_ONLYXMP);
		x = xmp_files_get_new_xmp (f);

		if (xmp_has_property (x, NS_DC, key) && xmp_delete_property (x, NS_DC, key))
		{
			success = true;
		}

		/* Flush the changes to disk. */
		if (!xmp_files_close (f, XMP_CLOSE_SAFEUPDATE))
		{
			printf ("Error closing '%s': %d\n", file, xmp_get_error ());
			success = false;
		}

		xmp_files_free (f);
		xmp_free (x);

		xmp_terminate ();

		return success;
	}
}
