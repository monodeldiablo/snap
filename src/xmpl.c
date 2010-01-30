/* xmpl.c
 *
 * <insert your silly legalese here, puhleez!>
 *
 * If you've come here looking for documentation, you're in the wrong place.
 * I'd love to tell you that all of this stuff is self-explanatory and all
 * that, but there's nothing intuitive about writing code and I'm in need of
 * more explaining than most. Your best bet, if you haven't been driven off
 * just yet, is to mosey on over to xmpl.h for a less implementation-
 * specific rendition of the how-tos and what-fors.
 */

#include "xmpl.h"

char* xmpl_get_property (char* file, char* namespace, char* key)
{
	if (xmp_init ())
	{
		XmpFilePtr f;
		XmpPtr x;
		XmpStringPtr s;
		XmpPropsBits p;
		XmpDateTime d;
		char* value = NULL;

		f = xmp_files_open_new (file, XMP_OPEN_READ | XMP_OPEN_ONLYXMP);
		x = xmp_files_get_new_xmp (f);

		if (xmp_has_property (x, namespace, key))
		{
			s = xmp_string_new ();

			/* This property is a string. */
			if (xmp_get_property (x, namespace, key, s, &p) && strcmp ("", xmp_string_cstr (s)) != 0)/* && XMP_IS_PROP_SIMPLE (p))*/
			{
				value = strdup (xmp_string_cstr (s));
			}

			/* Nope... it's an array. */
			else if (xmp_get_array_item (x, namespace, key, 1, s, &p))/* && XMP_IS_PROP_ARRAY (p))*/
			{
				int i = 2;
				value = strdup (xmp_string_cstr (s));

				for (; xmp_get_array_item (x, namespace, key, i, s, NULL); i++)
				{
					/* Allocate enough space for both strings, plus one more character for the
					   comma that will separate the array items. */
					value = (char*) realloc (value,
						(strlen (value) + 1 + strlen (xmp_string_cstr (s))) * sizeof (char));
					value = strcat (value, ",");
					value = strcat (value, xmp_string_cstr (s));
				}
			}

			/* This property is a DateTime. */
			else if (xmp_get_property_date (x, namespace, key, &d, &p))
			{
				char* tz_format = "-%02d:%02d";
				char* time_format = "%02d-%02d-%02dT%02d:%02d:%02d.%04d";

				/* Fill in the time zone information. */
				char* tzinfo = (char*) malloc (strlen (tz_format) * sizeof (char));
				sprintf (tzinfo, tz_format, d.tzHour, d.tzMinute);

				/* If this represents a timezone east of UTC, change the sign. */
				if (d.tzSign > 0)
				{
					tzinfo[0] = '+';

				}

				/* Now fill in the actual time information. */
				value = (char*) malloc (sizeof (time_format));
				sprintf (value, time_format,
					d.year,
					d.month,
					d.day,
					d.hour,
					d.minute,
					d.second,
					d.nanoSecond);

				/* Glue it all together. */
				value = (char*) realloc (value, (strlen (value) + strlen (tzinfo)) * sizeof (char));
				value = strcat (value, tzinfo);

				free (tzinfo);
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

bool xmpl_set_property (char* file, char* namespace, char* key, char* value)
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
		if (xmp_set_property (x, namespace, key, value, p))
		{
			success = true;
		}

		/* Nope... it's an array. */
		else if (xmp_set_array_item (x, namespace, key, 1, value, p))
		{
			int i;
			char* temp = strdup (value);
			temp = strtok (temp, ",");

			for (i = 1; temp && xmp_set_array_item (x, namespace, key, i, temp, p); i++)
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

bool xmpl_delete_property (char* file, char* namespace, char* key)
{
	if (xmp_init ())
	{
		XmpFilePtr f;
		XmpPtr x;
		XmpStringPtr s;
		bool success = false;

		f = xmp_files_open_new (file, XMP_OPEN_FORUPDATE | XMP_OPEN_ONLYXMP);
		x = xmp_files_get_new_xmp (f);

		if (xmp_has_property (x, namespace, key) && xmp_delete_property (x, namespace, key))
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
