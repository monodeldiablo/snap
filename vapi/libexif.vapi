/* libexif.vapi generated by vapigen, do not modify. */

[CCode (cprefix = "Exif", lower_case_cprefix = "exif_")]
namespace Exif {
	[Compact]
	[CCode (cheader_filename = "libexif.h")]
	public class Ascii {
	}
	[Compact]
	[CCode (cheader_filename = "libexif.h")]
	public class Byte {
		public static unowned string order_get_name (Exif.ByteOrder order);
	}
	[Compact]
	[CCode (ref_function = "exif_content_ref", ref_function_void = true, unref_function = "exif_content_unref", cheader_filename = "libexif.h")]
	public class Content {
		public uint count;
		public weak Exif.Entry entries;
		public weak Exif.Data parent;
		public weak Exif.ContentPrivate priv;
		[CCode (has_construct_function = false)]
		public Content ();
		public void add_entry (Exif.Entry entry);
		public void dump (uint indent);
		public void fix ();
		public void foreach_entry (Exif.ContentForeachEntryFunc func);
		public unowned Exif.Entry get_entry (Exif.Tag tag);
		public Exif.Ifd get_ifd ();
		public void log (Exif.Log log);
		[CCode (has_construct_function = false)]
		public Content.mem (Exif.Mem p1);
		public void remove_entry (Exif.Entry e);
	}
	[Compact]
	[CCode (cheader_filename = "libexif.h")]
	public class ContentPrivate {
	}
	[Compact]
	[CCode (ref_function = "exif_data_ref", ref_function_void = true, unref_function = "exif_data_unref", cheader_filename = "libexif.h")]
	public class Data {
		public uint data;
		[CCode (array_length = false)]
		public weak Exif.Content[] ifd;
		public weak Exif.DataPrivate priv;
		public uint size;
		[CCode (has_construct_function = false)]
		public Data ();
		public void dump ();
		public void fix ();
		public void foreach_content (Exif.DataForeachContentFunc func);
		[CCode (has_construct_function = false)]
		public Data.from_data (uint data, uint size);
		[CCode (has_construct_function = false)]
		public Data.from_file (string path);
		public Exif.ByteOrder get_byte_order ();
		public Exif.DataType get_data_type ();
		public unowned Exif.MnoteData get_mnote_data ();
		public void load_data (uint d, uint size);
		public void log (Exif.Log log);
		[CCode (has_construct_function = false)]
		public Data.mem (Exif.Mem p1);
		public static unowned string option_get_description (Exif.DataOption o);
		public static unowned string option_get_name (Exif.DataOption o);
		public void save_data (uint d, uint ds);
		public void set_byte_order (Exif.ByteOrder order);
		public void set_data_type (Exif.DataType dt);
		public void set_option (Exif.DataOption o);
		public void unset_option (Exif.DataOption o);
	}
	[Compact]
	[CCode (cheader_filename = "libexif.h")]
	public class DataPrivate {
	}
	[Compact]
	[CCode (ref_function = "exif_entry_ref", ref_function_void = true, unref_function = "exif_entry_unref", cheader_filename = "libexif.h")]
	public class Entry {
		public uint components;
		public uint data;
		public Exif.Format format;
		public weak Exif.Content parent;
		public weak Exif.EntryPrivate priv;
		public uint size;
		public Exif.Tag tag;
		[CCode (has_construct_function = false)]
		public Entry ();
		public void dump (uint indent);
		public void fix ();
		public unowned string get_value (string val, uint maxlen);
		public void initialize (Exif.Tag tag);
		[CCode (has_construct_function = false)]
		public Entry.mem (Exif.Mem p1);
	}
	[Compact]
	[CCode (cheader_filename = "libexif.h")]
	public class EntryPrivate {
	}
	[Compact]
	[CCode (ref_function = "exif_loader_ref", ref_function_void = true, unref_function = "exif_loader_unref", cheader_filename = "libexif.h")]
	public class Loader {
		[CCode (has_construct_function = false)]
		public Loader ();
		public void get_buf (uint buf, uint buf_size);
		public unowned Exif.Data get_data ();
		public void log (Exif.Log log);
		[CCode (has_construct_function = false)]
		public Loader.mem (Exif.Mem mem);
		public void reset ();
		public uint write (uint buf, uint sz);
		public void write_file (string fname);
	}
	[Compact]
	[CCode (ref_function = "exif_log_ref", ref_function_void = true, unref_function = "exif_log_unref", cheader_filename = "libexif.h")]
	public class Log {
		[CCode (has_construct_function = false)]
		public Log ();
		public static unowned string code_get_message (Exif.LogCode code);
		public static unowned string code_get_title (Exif.LogCode code);
		[CCode (has_construct_function = false)]
		public Log.mem (Exif.Mem p1);
		public void set_func (Exif.LogFunc func, void* data);
	}
	[Compact]
	[CCode (cheader_filename = "libexif.h")]
	public class Long {
	}
	[Compact]
	[CCode (ref_function = "exif_mem_ref", ref_function_void = true, unref_function = "exif_mem_unref", cheader_filename = "libexif.h")]
	public class Mem {
		[CCode (has_construct_function = false)]
		public Mem (Exif.MemAllocFunc a, Exif.MemReallocFunc r, Exif.MemFreeFunc f);
		public void* alloc (Exif.Long s);
		[CCode (has_construct_function = false)]
		public Mem.@default ();
		public void* realloc (void* p, Exif.Long s);
	}
	[Compact]
	[CCode (ref_function = "exif_mnote_data_ref", ref_function_void = true, unref_function = "exif_mnote_data_unref", cheader_filename = "libexif.h")]
	public class MnoteData {
		public uint count ();
		public unowned string get_description (uint n);
		public uint get_id (uint n);
		public unowned string get_name (uint n);
		public unowned string get_title (uint n);
		public unowned string get_value (uint n, string val, uint maxlen);
		public void load (uint buf, uint buf_siz);
		public void log (Exif.Log p2);
		public void save (uint buf, uint buf_siz);
	}
	[Compact]
	[CCode (cheader_filename = "libexif.h")]
	public class Rational {
		public weak Exif.Long denominator;
		public weak Exif.Long numerator;
	}
	[Compact]
	[CCode (cheader_filename = "libexif.h")]
	public class SByte {
	}
	[Compact]
	[CCode (cheader_filename = "libexif.h")]
	public class SLong {
	}
	[Compact]
	[CCode (cheader_filename = "libexif.h")]
	public class SRational {
		public weak Exif.SLong denominator;
		public weak Exif.SLong numerator;
	}
	[Compact]
	[CCode (cheader_filename = "libexif.h")]
	public class SShort {
	}
	[Compact]
	[CCode (cheader_filename = "libexif.h")]
	public class Short {
	}
	[Compact]
	[CCode (cheader_filename = "libexif.h")]
	public class Undefined {
	}
	[CCode (cprefix = "EXIF_BYTE_ORDER_", has_type_id = "0", cheader_filename = "libexif.h")]
	public enum ByteOrder {
		MOTOROLA,
		INTEL
	}
	[CCode (cprefix = "EXIF_DATA_OPTION_", has_type_id = "0", cheader_filename = "libexif.h")]
	public enum DataOption {
		IGNORE_UNKNOWN_TAGS,
		FOLLOW_SPECIFICATION,
		DONT_CHANGE_MAKER_NOTE
	}
	[CCode (cprefix = "EXIF_DATA_TYPE_", has_type_id = "0", cheader_filename = "libexif.h")]
	public enum DataType {
		UNCOMPRESSED_CHUNKY,
		UNCOMPRESSED_PLANAR,
		UNCOMPRESSED_YCC,
		COMPRESSED,
		COUNT,
		UNKNOWN
	}
	[CCode (cprefix = "EXIF_FORMAT_", has_type_id = "0", cheader_filename = "libexif.h")]
	public enum Format {
		BYTE,
		ASCII,
		SHORT,
		LONG,
		RATIONAL,
		SBYTE,
		UNDEFINED,
		SSHORT,
		SLONG,
		SRATIONAL,
		FLOAT,
		DOUBLE
	}
	[CCode (cprefix = "EXIF_", has_type_id = "0", cheader_filename = "libexif.h")]
	public enum Ifd {
		IFD_0,
		IFD_1,
		IFD_EXIF,
		IFD_GPS,
		IFD_INTEROPERABILITY,
		IFD_COUNT
	}
	[CCode (cprefix = "EXIF_LOG_CODE_", has_type_id = "0", cheader_filename = "libexif.h")]
	public enum LogCode {
		NONE,
		DEBUG,
		NO_MEMORY,
		CORRUPT_DATA
	}
	[CCode (cprefix = "EXIF_SUPPORT_LEVEL_", has_type_id = "0", cheader_filename = "libexif.h")]
	public enum SupportLevel {
		UNKNOWN,
		NOT_RECORDED,
		MANDATORY,
		OPTIONAL
	}
	[CCode (cprefix = "EXIF_TAG_", has_type_id = "0", cheader_filename = "libexif.h")]
	public enum Tag {
		INTEROPERABILITY_INDEX,
		INTEROPERABILITY_VERSION,
		NEW_SUBFILE_TYPE,
		IMAGE_WIDTH,
		IMAGE_LENGTH,
		BITS_PER_SAMPLE,
		COMPRESSION,
		PHOTOMETRIC_INTERPRETATION,
		FILL_ORDER,
		DOCUMENT_NAME,
		IMAGE_DESCRIPTION,
		MAKE,
		MODEL,
		STRIP_OFFSETS,
		ORIENTATION,
		SAMPLES_PER_PIXEL,
		ROWS_PER_STRIP,
		STRIP_BYTE_COUNTS,
		X_RESOLUTION,
		Y_RESOLUTION,
		PLANAR_CONFIGURATION,
		RESOLUTION_UNIT,
		TRANSFER_FUNCTION,
		SOFTWARE,
		DATE_TIME,
		ARTIST,
		WHITE_POINT,
		PRIMARY_CHROMATICITIES,
		SUB_IFDS,
		TRANSFER_RANGE,
		JPEG_PROC,
		JPEG_INTERCHANGE_FORMAT,
		JPEG_INTERCHANGE_FORMAT_LENGTH,
		YCBCR_COEFFICIENTS,
		YCBCR_SUB_SAMPLING,
		YCBCR_POSITIONING,
		REFERENCE_BLACK_WHITE,
		XML_PACKET,
		RELATED_IMAGE_FILE_FORMAT,
		RELATED_IMAGE_WIDTH,
		RELATED_IMAGE_LENGTH,
		CFA_REPEAT_PATTERN_DIM,
		CFA_PATTERN,
		BATTERY_LEVEL,
		COPYRIGHT,
		EXPOSURE_TIME,
		FNUMBER,
		IPTC_NAA,
		IMAGE_RESOURCES,
		EXIF_IFD_POINTER,
		INTER_COLOR_PROFILE,
		EXPOSURE_PROGRAM,
		SPECTRAL_SENSITIVITY,
		GPS_INFO_IFD_POINTER,
		ISO_SPEED_RATINGS,
		OECF,
		TIME_ZONE_OFFSET,
		EXIF_VERSION,
		DATE_TIME_ORIGINAL,
		DATE_TIME_DIGITIZED,
		COMPONENTS_CONFIGURATION,
		COMPRESSED_BITS_PER_PIXEL,
		SHUTTER_SPEED_VALUE,
		APERTURE_VALUE,
		BRIGHTNESS_VALUE,
		EXPOSURE_BIAS_VALUE,
		MAX_APERTURE_VALUE,
		SUBJECT_DISTANCE,
		METERING_MODE,
		LIGHT_SOURCE,
		FLASH,
		FOCAL_LENGTH,
		SUBJECT_AREA,
		TIFF_EP_STANDARD_ID,
		MAKER_NOTE,
		USER_COMMENT,
		SUB_SEC_TIME,
		SUB_SEC_TIME_ORIGINAL,
		SUB_SEC_TIME_DIGITIZED,
		XP_TITLE,
		XP_COMMENT,
		XP_AUTHOR,
		XP_KEYWORDS,
		XP_SUBJECT,
		FLASH_PIX_VERSION,
		COLOR_SPACE,
		PIXEL_X_DIMENSION,
		PIXEL_Y_DIMENSION,
		RELATED_SOUND_FILE,
		INTEROPERABILITY_IFD_POINTER,
		FLASH_ENERGY,
		SPATIAL_FREQUENCY_RESPONSE,
		FOCAL_PLANE_X_RESOLUTION,
		FOCAL_PLANE_Y_RESOLUTION,
		FOCAL_PLANE_RESOLUTION_UNIT,
		SUBJECT_LOCATION,
		EXPOSURE_INDEX,
		SENSING_METHOD,
		FILE_SOURCE,
		SCENE_TYPE,
		NEW_CFA_PATTERN,
		CUSTOM_RENDERED,
		EXPOSURE_MODE,
		WHITE_BALANCE,
		DIGITAL_ZOOM_RATIO,
		FOCAL_LENGTH_IN_35MM_FILM,
		SCENE_CAPTURE_TYPE,
		GAIN_CONTROL,
		CONTRAST,
		SATURATION,
		SHARPNESS,
		DEVICE_SETTING_DESCRIPTION,
		SUBJECT_DISTANCE_RANGE,
		IMAGE_UNIQUE_ID,
		GAMMA,
		PRINT_IMAGE_MATCHING
	}
	[CCode (cheader_filename = "libexif.h")]
	public delegate void ContentForeachEntryFunc (Exif.Entry p1);
	[CCode (cheader_filename = "libexif.h")]
	public delegate void DataForeachContentFunc (Exif.Content p1);
	[CCode (cheader_filename = "libexif.h")]
	public delegate void LogFunc (Exif.Log log, Exif.LogCode p2, string domain, string format, void* args);
	[CCode (cheader_filename = "libexif.h", has_target = false)]
	public delegate void* MemAllocFunc (Exif.Long s);
	[CCode (cheader_filename = "libexif.h", has_target = false)]
	public delegate void MemFreeFunc (void* p);
	[CCode (cheader_filename = "libexif.h", has_target = false)]
	public delegate void* MemReallocFunc (void* p, Exif.Long s);
	[CCode (cheader_filename = "libexif.h")]
	public const int TAG_GPS_ALTITUDE;
	[CCode (cheader_filename = "libexif.h")]
	public const int TAG_GPS_ALTITUDE_REF;
	[CCode (cheader_filename = "libexif.h")]
	public const int TAG_GPS_AREA_INFORMATION;
	[CCode (cheader_filename = "libexif.h")]
	public const int TAG_GPS_DATE_STAMP;
	[CCode (cheader_filename = "libexif.h")]
	public const int TAG_GPS_DEST_BEARING;
	[CCode (cheader_filename = "libexif.h")]
	public const int TAG_GPS_DEST_BEARING_REF;
	[CCode (cheader_filename = "libexif.h")]
	public const int TAG_GPS_DEST_DISTANCE;
	[CCode (cheader_filename = "libexif.h")]
	public const int TAG_GPS_DEST_DISTANCE_REF;
	[CCode (cheader_filename = "libexif.h")]
	public const int TAG_GPS_DEST_LATITUDE;
	[CCode (cheader_filename = "libexif.h")]
	public const int TAG_GPS_DEST_LATITUDE_REF;
	[CCode (cheader_filename = "libexif.h")]
	public const int TAG_GPS_DEST_LONGITUDE;
	[CCode (cheader_filename = "libexif.h")]
	public const int TAG_GPS_DEST_LONGITUDE_REF;
	[CCode (cheader_filename = "libexif.h")]
	public const int TAG_GPS_DIFFERENTIAL;
	[CCode (cheader_filename = "libexif.h")]
	public const int TAG_GPS_DOP;
	[CCode (cheader_filename = "libexif.h")]
	public const int TAG_GPS_IMG_DIRECTION;
	[CCode (cheader_filename = "libexif.h")]
	public const int TAG_GPS_IMG_DIRECTION_REF;
	[CCode (cheader_filename = "libexif.h")]
	public const int TAG_GPS_LATITUDE;
	[CCode (cheader_filename = "libexif.h")]
	public const int TAG_GPS_LATITUDE_REF;
	[CCode (cheader_filename = "libexif.h")]
	public const int TAG_GPS_LONGITUDE;
	[CCode (cheader_filename = "libexif.h")]
	public const int TAG_GPS_LONGITUDE_REF;
	[CCode (cheader_filename = "libexif.h")]
	public const int TAG_GPS_MAP_DATUM;
	[CCode (cheader_filename = "libexif.h")]
	public const int TAG_GPS_MEASURE_MODE;
	[CCode (cheader_filename = "libexif.h")]
	public const int TAG_GPS_PROCESSING_METHOD;
	[CCode (cheader_filename = "libexif.h")]
	public const int TAG_GPS_SATELLITES;
	[CCode (cheader_filename = "libexif.h")]
	public const int TAG_GPS_SPEED;
	[CCode (cheader_filename = "libexif.h")]
	public const int TAG_GPS_SPEED_REF;
	[CCode (cheader_filename = "libexif.h")]
	public const int TAG_GPS_STATUS;
	[CCode (cheader_filename = "libexif.h")]
	public const int TAG_GPS_TIME_STAMP;
	[CCode (cheader_filename = "libexif.h")]
	public const int TAG_GPS_TRACK;
	[CCode (cheader_filename = "libexif.h")]
	public const int TAG_GPS_TRACK_REF;
	[CCode (cheader_filename = "libexif.h")]
	public const int TAG_GPS_VERSION_ID;
	[CCode (cheader_filename = "libexif.h")]
	public static void array_set_byte_order (Exif.Format p1, uint p2, uint p3, Exif.ByteOrder o_orig, Exif.ByteOrder o_new);
	[CCode (cheader_filename = "libexif.h")]
	public static void convert_utf16_to_utf8 (string @out, uint @in, int maxlen);
	[CCode (cheader_filename = "libexif.h")]
	public static unowned string format_get_name (Exif.Format format);
	[CCode (cheader_filename = "libexif.h")]
	public static uint format_get_size (Exif.Format format);
	[CCode (cheader_filename = "libexif.h")]
	public static unowned Exif.Long get_long (uint b, Exif.ByteOrder order);
	[CCode (cheader_filename = "libexif.h")]
	public static unowned Exif.Rational get_rational (uint b, Exif.ByteOrder order);
	[CCode (cheader_filename = "libexif.h")]
	public static unowned Exif.Short get_short (uint b, Exif.ByteOrder order);
	[CCode (cheader_filename = "libexif.h")]
	public static unowned Exif.SLong get_slong (uint b, Exif.ByteOrder order);
	[CCode (cheader_filename = "libexif.h")]
	public static unowned Exif.SRational get_srational (uint b, Exif.ByteOrder order);
	[CCode (cheader_filename = "libexif.h")]
	public static unowned Exif.SShort get_sshort (uint b, Exif.ByteOrder order);
	[CCode (cheader_filename = "libexif.h")]
	public static unowned string ifd_get_name (Exif.Ifd ifd);
	[CCode (cheader_filename = "libexif.h")]
	public static void log (Exif.Log log, Exif.LogCode p2, string domain, string format);
	[CCode (cheader_filename = "libexif.h")]
	public static void logv (Exif.Log log, Exif.LogCode p2, string domain, string format, void* args);
	[CCode (cheader_filename = "libexif.h")]
	public static void set_long (uint b, Exif.ByteOrder order, Exif.Long value);
	[CCode (cheader_filename = "libexif.h")]
	public static void set_rational (uint b, Exif.ByteOrder order, Exif.Rational value);
	[CCode (cheader_filename = "libexif.h")]
	public static void set_short (uint b, Exif.ByteOrder order, Exif.Short value);
	[CCode (cheader_filename = "libexif.h")]
	public static void set_slong (uint b, Exif.ByteOrder order, Exif.SLong value);
	[CCode (cheader_filename = "libexif.h")]
	public static void set_srational (uint b, Exif.ByteOrder order, Exif.SRational value);
	[CCode (cheader_filename = "libexif.h")]
	public static void set_sshort (uint b, Exif.ByteOrder order, Exif.SShort value);
	[CCode (cheader_filename = "libexif.h")]
	public static Exif.Tag tag_from_name (string name);
	[CCode (cheader_filename = "libexif.h")]
	public static unowned string tag_get_description (Exif.Tag tag);
	[CCode (cheader_filename = "libexif.h")]
	public static unowned string tag_get_description_in_ifd (Exif.Tag tag, Exif.Ifd ifd);
	[CCode (cheader_filename = "libexif.h")]
	public static unowned string tag_get_name (Exif.Tag tag);
	[CCode (cheader_filename = "libexif.h")]
	public static unowned string tag_get_name_in_ifd (Exif.Tag tag, Exif.Ifd ifd);
	[CCode (cheader_filename = "libexif.h")]
	public static Exif.SupportLevel tag_get_support_level_in_ifd (Exif.Tag tag, Exif.Ifd ifd, Exif.DataType t);
	[CCode (cheader_filename = "libexif.h")]
	public static unowned string tag_get_title (Exif.Tag tag);
	[CCode (cheader_filename = "libexif.h")]
	public static unowned string tag_get_title_in_ifd (Exif.Tag tag, Exif.Ifd ifd);
	[CCode (cheader_filename = "libexif.h")]
	public static uint tag_table_count ();
	[CCode (cheader_filename = "libexif.h")]
	public static unowned string tag_table_get_name (uint n);
	[CCode (cheader_filename = "libexif.h")]
	public static Exif.Tag tag_table_get_tag (uint n);
}