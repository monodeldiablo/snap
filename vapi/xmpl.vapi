/* xmpl.vala
 *
 * Copyright (C) 2010  Brian Davis
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.

 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.

 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 * Author:
 *	Brian Davis <brian.william.davis@gmail.com>
 */

[CCode (cheader_filename = "xmpl.h", lower_case_cprefix = "xmpl_")]
namespace Xmpl {
	public const string DC;
	public const string CC;
	public const string EXIF;
	public const string EXIF_AUX;
	public const string TIFF;
	public const string RDF;
	public const string XMP;
	public const string XAP;
	public const string XAP_RIGHTS;

	[CCode (cname = "xmpl_get_property")]
	public static string get_property (string file, string namespace, string key);

	[CCode (cname = "xmpl_set_property")]
	public static bool set_property (string file, string namespace, string key, string value);

	[CCode (cname = "xmpl_delete_property")]
	public static bool delete_property (string file, string namespace, string key);
}
