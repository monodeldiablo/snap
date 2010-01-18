<?xml version="1.0"?>
<api version="1.0">
	<namespace name="Exempi">
		<function name="xmp_append_array_item" symbol="xmp_append_array_item">
			<return-type type="bool"/>
			<parameters>
				<parameter name="xmp" type="XmpPtr"/>
				<parameter name="schema" type="char*"/>
				<parameter name="name" type="char*"/>
				<parameter name="arrayOptions" type="uint32_t"/>
				<parameter name="value" type="char*"/>
				<parameter name="optionBits" type="uint32_t"/>
			</parameters>
		</function>
		<function name="xmp_copy" symbol="xmp_copy">
			<return-type type="XmpPtr"/>
			<parameters>
				<parameter name="xmp" type="XmpPtr"/>
			</parameters>
		</function>
		<function name="xmp_delete_localized_text" symbol="xmp_delete_localized_text">
			<return-type type="bool"/>
			<parameters>
				<parameter name="xmp" type="XmpPtr"/>
				<parameter name="schema" type="char*"/>
				<parameter name="name" type="char*"/>
				<parameter name="genericLang" type="char*"/>
				<parameter name="specificLang" type="char*"/>
			</parameters>
		</function>
		<function name="xmp_delete_property" symbol="xmp_delete_property">
			<return-type type="bool"/>
			<parameters>
				<parameter name="xmp" type="XmpPtr"/>
				<parameter name="schema" type="char*"/>
				<parameter name="name" type="char*"/>
			</parameters>
		</function>
		<function name="xmp_files_can_put_xmp" symbol="xmp_files_can_put_xmp">
			<return-type type="bool"/>
			<parameters>
				<parameter name="xf" type="XmpFilePtr"/>
				<parameter name="xmp" type="XmpPtr"/>
			</parameters>
		</function>
		<function name="xmp_files_close" symbol="xmp_files_close">
			<return-type type="bool"/>
			<parameters>
				<parameter name="xf" type="XmpFilePtr"/>
				<parameter name="options" type="XmpCloseFileOptions"/>
			</parameters>
		</function>
		<function name="xmp_files_free" symbol="xmp_files_free">
			<return-type type="bool"/>
			<parameters>
				<parameter name="xf" type="XmpFilePtr"/>
			</parameters>
		</function>
		<function name="xmp_files_get_new_xmp" symbol="xmp_files_get_new_xmp">
			<return-type type="XmpPtr"/>
			<parameters>
				<parameter name="xf" type="XmpFilePtr"/>
			</parameters>
		</function>
		<function name="xmp_files_get_xmp" symbol="xmp_files_get_xmp">
			<return-type type="bool"/>
			<parameters>
				<parameter name="xf" type="XmpFilePtr"/>
				<parameter name="xmp" type="XmpPtr"/>
			</parameters>
		</function>
		<function name="xmp_files_new" symbol="xmp_files_new">
			<return-type type="XmpFilePtr"/>
		</function>
		<function name="xmp_files_open" symbol="xmp_files_open">
			<return-type type="bool"/>
			<parameters>
				<parameter name="xf" type="XmpFilePtr"/>
				<parameter name="p2" type="char*"/>
				<parameter name="options" type="XmpOpenFileOptions"/>
			</parameters>
		</function>
		<function name="xmp_files_open_new" symbol="xmp_files_open_new">
			<return-type type="XmpFilePtr"/>
			<parameters>
				<parameter name="p1" type="char*"/>
				<parameter name="options" type="XmpOpenFileOptions"/>
			</parameters>
		</function>
		<function name="xmp_files_put_xmp" symbol="xmp_files_put_xmp">
			<return-type type="bool"/>
			<parameters>
				<parameter name="xf" type="XmpFilePtr"/>
				<parameter name="xmp" type="XmpPtr"/>
			</parameters>
		</function>
		<function name="xmp_free" symbol="xmp_free">
			<return-type type="bool"/>
			<parameters>
				<parameter name="xmp" type="XmpPtr"/>
			</parameters>
		</function>
		<function name="xmp_get_array_item" symbol="xmp_get_array_item">
			<return-type type="bool"/>
			<parameters>
				<parameter name="xmp" type="XmpPtr"/>
				<parameter name="schema" type="char*"/>
				<parameter name="name" type="char*"/>
				<parameter name="index" type="int32_t"/>
				<parameter name="property" type="XmpStringPtr"/>
				<parameter name="propsBits" type="uint32_t*"/>
			</parameters>
		</function>
		<function name="xmp_get_error" symbol="xmp_get_error">
			<return-type type="int"/>
		</function>
		<function name="xmp_get_localized_text" symbol="xmp_get_localized_text">
			<return-type type="bool"/>
			<parameters>
				<parameter name="xmp" type="XmpPtr"/>
				<parameter name="schema" type="char*"/>
				<parameter name="name" type="char*"/>
				<parameter name="genericLang" type="char*"/>
				<parameter name="specificLang" type="char*"/>
				<parameter name="actualLang" type="XmpStringPtr"/>
				<parameter name="itemValue" type="XmpStringPtr"/>
				<parameter name="propBits" type="uint32_t*"/>
			</parameters>
		</function>
		<function name="xmp_get_property" symbol="xmp_get_property">
			<return-type type="bool"/>
			<parameters>
				<parameter name="xmp" type="XmpPtr"/>
				<parameter name="schema" type="char*"/>
				<parameter name="name" type="char*"/>
				<parameter name="property" type="XmpStringPtr"/>
				<parameter name="propsBits" type="uint32_t*"/>
			</parameters>
		</function>
		<function name="xmp_get_property_bool" symbol="xmp_get_property_bool">
			<return-type type="bool"/>
			<parameters>
				<parameter name="xmp" type="XmpPtr"/>
				<parameter name="schema" type="char*"/>
				<parameter name="name" type="char*"/>
				<parameter name="property" type="bool*"/>
				<parameter name="propsBits" type="uint32_t*"/>
			</parameters>
		</function>
		<function name="xmp_get_property_date" symbol="xmp_get_property_date">
			<return-type type="bool"/>
			<parameters>
				<parameter name="xmp" type="XmpPtr"/>
				<parameter name="schema" type="char*"/>
				<parameter name="name" type="char*"/>
				<parameter name="property" type="XmpDateTime*"/>
				<parameter name="propsBits" type="uint32_t*"/>
			</parameters>
		</function>
		<function name="xmp_get_property_float" symbol="xmp_get_property_float">
			<return-type type="bool"/>
			<parameters>
				<parameter name="xmp" type="XmpPtr"/>
				<parameter name="schema" type="char*"/>
				<parameter name="name" type="char*"/>
				<parameter name="property" type="double*"/>
				<parameter name="propsBits" type="uint32_t*"/>
			</parameters>
		</function>
		<function name="xmp_get_property_int32" symbol="xmp_get_property_int32">
			<return-type type="bool"/>
			<parameters>
				<parameter name="xmp" type="XmpPtr"/>
				<parameter name="schema" type="char*"/>
				<parameter name="name" type="char*"/>
				<parameter name="property" type="int32_t*"/>
				<parameter name="propsBits" type="uint32_t*"/>
			</parameters>
		</function>
		<function name="xmp_has_property" symbol="xmp_has_property">
			<return-type type="bool"/>
			<parameters>
				<parameter name="xmp" type="XmpPtr"/>
				<parameter name="schema" type="char*"/>
				<parameter name="name" type="char*"/>
			</parameters>
		</function>
		<function name="xmp_init" symbol="xmp_init">
			<return-type type="bool"/>
		</function>
		<function name="xmp_iterator_free" symbol="xmp_iterator_free">
			<return-type type="bool"/>
			<parameters>
				<parameter name="iter" type="XmpIteratorPtr"/>
			</parameters>
		</function>
		<function name="xmp_iterator_new" symbol="xmp_iterator_new">
			<return-type type="XmpIteratorPtr"/>
			<parameters>
				<parameter name="xmp" type="XmpPtr"/>
				<parameter name="schema" type="char*"/>
				<parameter name="propName" type="char*"/>
				<parameter name="options" type="XmpIterOptions"/>
			</parameters>
		</function>
		<function name="xmp_iterator_next" symbol="xmp_iterator_next">
			<return-type type="bool"/>
			<parameters>
				<parameter name="iter" type="XmpIteratorPtr"/>
				<parameter name="schema" type="XmpStringPtr"/>
				<parameter name="propName" type="XmpStringPtr"/>
				<parameter name="propValue" type="XmpStringPtr"/>
				<parameter name="options" type="uint32_t*"/>
			</parameters>
		</function>
		<function name="xmp_iterator_skip" symbol="xmp_iterator_skip">
			<return-type type="bool"/>
			<parameters>
				<parameter name="iter" type="XmpIteratorPtr"/>
				<parameter name="options" type="XmpIterSkipOptions"/>
			</parameters>
		</function>
		<function name="xmp_namespace_prefix" symbol="xmp_namespace_prefix">
			<return-type type="bool"/>
			<parameters>
				<parameter name="ns" type="char*"/>
				<parameter name="prefix" type="XmpStringPtr"/>
			</parameters>
		</function>
		<function name="xmp_new" symbol="xmp_new">
			<return-type type="XmpPtr"/>
			<parameters>
				<parameter name="buffer" type="char*"/>
				<parameter name="len" type="size_t"/>
			</parameters>
		</function>
		<function name="xmp_new_empty" symbol="xmp_new_empty">
			<return-type type="XmpPtr"/>
		</function>
		<function name="xmp_parse" symbol="xmp_parse">
			<return-type type="bool"/>
			<parameters>
				<parameter name="xmp" type="XmpPtr"/>
				<parameter name="buffer" type="char*"/>
				<parameter name="len" type="size_t"/>
			</parameters>
		</function>
		<function name="xmp_prefix_namespace_uri" symbol="xmp_prefix_namespace_uri">
			<return-type type="bool"/>
			<parameters>
				<parameter name="prefix" type="char*"/>
				<parameter name="ns" type="XmpStringPtr"/>
			</parameters>
		</function>
		<function name="xmp_register_namespace" symbol="xmp_register_namespace">
			<return-type type="bool"/>
			<parameters>
				<parameter name="namespaceURI" type="char*"/>
				<parameter name="suggestedPrefix" type="char*"/>
				<parameter name="registeredPrefix" type="XmpStringPtr"/>
			</parameters>
		</function>
		<function name="xmp_serialize" symbol="xmp_serialize">
			<return-type type="bool"/>
			<parameters>
				<parameter name="xmp" type="XmpPtr"/>
				<parameter name="buffer" type="XmpStringPtr"/>
				<parameter name="options" type="uint32_t"/>
				<parameter name="padding" type="uint32_t"/>
			</parameters>
		</function>
		<function name="xmp_serialize_and_format" symbol="xmp_serialize_and_format">
			<return-type type="bool"/>
			<parameters>
				<parameter name="xmp" type="XmpPtr"/>
				<parameter name="buffer" type="XmpStringPtr"/>
				<parameter name="options" type="uint32_t"/>
				<parameter name="padding" type="uint32_t"/>
				<parameter name="newline" type="char*"/>
				<parameter name="tab" type="char*"/>
				<parameter name="indent" type="int32_t"/>
			</parameters>
		</function>
		<function name="xmp_set_array_item" symbol="xmp_set_array_item">
			<return-type type="bool"/>
			<parameters>
				<parameter name="xmp" type="XmpPtr"/>
				<parameter name="schema" type="char*"/>
				<parameter name="name" type="char*"/>
				<parameter name="index" type="int32_t"/>
				<parameter name="value" type="char*"/>
				<parameter name="optionBits" type="uint32_t"/>
			</parameters>
		</function>
		<function name="xmp_set_localized_text" symbol="xmp_set_localized_text">
			<return-type type="bool"/>
			<parameters>
				<parameter name="xmp" type="XmpPtr"/>
				<parameter name="schema" type="char*"/>
				<parameter name="name" type="char*"/>
				<parameter name="genericLang" type="char*"/>
				<parameter name="specificLang" type="char*"/>
				<parameter name="value" type="char*"/>
				<parameter name="optionBits" type="uint32_t"/>
			</parameters>
		</function>
		<function name="xmp_set_property" symbol="xmp_set_property">
			<return-type type="bool"/>
			<parameters>
				<parameter name="xmp" type="XmpPtr"/>
				<parameter name="schema" type="char*"/>
				<parameter name="name" type="char*"/>
				<parameter name="value" type="char*"/>
				<parameter name="optionBits" type="uint32_t"/>
			</parameters>
		</function>
		<function name="xmp_set_property_bool" symbol="xmp_set_property_bool">
			<return-type type="bool"/>
			<parameters>
				<parameter name="xmp" type="XmpPtr"/>
				<parameter name="schema" type="char*"/>
				<parameter name="name" type="char*"/>
				<parameter name="value" type="bool"/>
				<parameter name="optionBits" type="uint32_t"/>
			</parameters>
		</function>
		<function name="xmp_set_property_date" symbol="xmp_set_property_date">
			<return-type type="bool"/>
			<parameters>
				<parameter name="xmp" type="XmpPtr"/>
				<parameter name="schema" type="char*"/>
				<parameter name="name" type="char*"/>
				<parameter name="value" type="XmpDateTime*"/>
				<parameter name="optionBits" type="uint32_t"/>
			</parameters>
		</function>
		<function name="xmp_set_property_float" symbol="xmp_set_property_float">
			<return-type type="bool"/>
			<parameters>
				<parameter name="xmp" type="XmpPtr"/>
				<parameter name="schema" type="char*"/>
				<parameter name="name" type="char*"/>
				<parameter name="value" type="double"/>
				<parameter name="optionBits" type="uint32_t"/>
			</parameters>
		</function>
		<function name="xmp_set_property_int32" symbol="xmp_set_property_int32">
			<return-type type="bool"/>
			<parameters>
				<parameter name="xmp" type="XmpPtr"/>
				<parameter name="schema" type="char*"/>
				<parameter name="name" type="char*"/>
				<parameter name="value" type="int32_t"/>
				<parameter name="optionBits" type="uint32_t"/>
			</parameters>
		</function>
		<function name="xmp_string_cstr" symbol="xmp_string_cstr">
			<return-type type="char*"/>
			<parameters>
				<parameter name="s" type="XmpStringPtr"/>
			</parameters>
		</function>
		<function name="xmp_string_free" symbol="xmp_string_free">
			<return-type type="void"/>
			<parameters>
				<parameter name="s" type="XmpStringPtr"/>
			</parameters>
		</function>
		<function name="xmp_string_new" symbol="xmp_string_new">
			<return-type type="XmpStringPtr"/>
		</function>
		<function name="xmp_terminate" symbol="xmp_terminate">
			<return-type type="void"/>
		</function>
		<struct name="XmpDateTime">
			<field name="year" type="int32_t"/>
			<field name="month" type="int32_t"/>
			<field name="day" type="int32_t"/>
			<field name="hour" type="int32_t"/>
			<field name="minute" type="int32_t"/>
			<field name="second" type="int32_t"/>
			<field name="tzSign" type="int32_t"/>
			<field name="tzHour" type="int32_t"/>
			<field name="tzMinute" type="int32_t"/>
			<field name="nanoSecond" type="int32_t"/>
		</struct>
		<struct name="XmpFilePtr">
		</struct>
		<struct name="XmpIteratorPtr">
		</struct>
		<struct name="XmpPtr">
		</struct>
		<struct name="XmpStringPtr">
		</struct>
		<enum name="XmpCloseFileOptions">
			<member name="XMP_CLOSE_NOOPTION" value="0"/>
			<member name="XMP_CLOSE_SAFEUPDATE" value="1"/>
		</enum>
		<enum name="XmpFileType">
			<member name="XMP_FT_PDF" value="1346651680"/>
			<member name="XMP_FT_PS" value="1347624992"/>
			<member name="XMP_FT_EPS" value="1162892064"/>
			<member name="XMP_FT_JPEG" value="1246774599"/>
			<member name="XMP_FT_JPEG2K" value="1246779424"/>
			<member name="XMP_FT_TIFF" value="1414088262"/>
			<member name="XMP_FT_GIF" value="1195984416"/>
			<member name="XMP_FT_PNG" value="1347307296"/>
			<member name="XMP_FT_SWF" value="1398228512"/>
			<member name="XMP_FT_FLA" value="1179402528"/>
			<member name="XMP_FT_FLV" value="1179407904"/>
			<member name="XMP_FT_MOV" value="1297045024"/>
			<member name="XMP_FT_AVI" value="1096173856"/>
			<member name="XMP_FT_CIN" value="1128877600"/>
			<member name="XMP_FT_WAV" value="1463899680"/>
			<member name="XMP_FT_MP3" value="1297101600"/>
			<member name="XMP_FT_SES" value="1397052192"/>
			<member name="XMP_FT_CEL" value="1128614944"/>
			<member name="XMP_FT_MPEG" value="1297106247"/>
			<member name="XMP_FT_MPEG2" value="1297101344"/>
			<member name="XMP_FT_MPEG4" value="1297101856"/>
			<member name="XMP_FT_WMAV" value="1464680790"/>
			<member name="XMP_FT_AIFF" value="1095321158"/>
			<member name="XMP_FT_HTML" value="1213484364"/>
			<member name="XMP_FT_XML" value="1481460768"/>
			<member name="XMP_FT_TEXT" value="1952807028"/>
			<member name="XMP_FT_PHOTOSHOP" value="1347634208"/>
			<member name="XMP_FT_ILLUSTRATOR" value="1095311392"/>
			<member name="XMP_FT_INDESIGN" value="1229866052"/>
			<member name="XMP_FT_AEPROJECT" value="1095061536"/>
			<member name="XMP_FT_AEPROJTEMPLATE" value="1095062560"/>
			<member name="XMP_FT_AEFILTERPRESET" value="1179015200"/>
			<member name="XMP_FT_ENCOREPROJECT" value="1313034066"/>
			<member name="XMP_FT_PREMIEREPROJECT" value="1347571786"/>
			<member name="XMP_FT_PREMIERETITLE" value="1347572812"/>
			<member name="XMP_FT_UNKNOWN" value="538976288"/>
		</enum>
		<enum name="XmpIterOptions">
			<member name="XMP_ITER_CLASSMASK" value="255"/>
			<member name="XMP_ITER_PROPERTIES" value="0"/>
			<member name="XMP_ITER_ALIASES" value="1"/>
			<member name="XMP_ITER_NAMESPACES" value="2"/>
			<member name="XMP_ITER_JUSTCHILDREN" value="256"/>
			<member name="XMP_ITER_JUSTLEAFNODES" value="512"/>
			<member name="XMP_ITER_JUSTLEAFNAME" value="1024"/>
			<member name="XMP_ITER_INCLUDEALIASES" value="2048"/>
			<member name="XMP_ITER_OMITQUALIFIERS" value="4096"/>
		</enum>
		<enum name="XmpIterSkipOptions">
			<member name="XMP_ITER_SKIPSUBTREE" value="1"/>
			<member name="XMP_ITER_SKIPSIBLINGS" value="2"/>
		</enum>
		<enum name="XmpOpenFileOptions">
			<member name="XMP_OPEN_NOOPTION" value="0"/>
			<member name="XMP_OPEN_READ" value="1"/>
			<member name="XMP_OPEN_FORUPDATE" value="2"/>
			<member name="XMP_OPEN_ONLYXMP" value="4"/>
			<member name="XMP_OPEN_CACHETNAIL" value="8"/>
			<member name="XMP_OPEN_STRICTLY" value="16"/>
			<member name="XMP_OPEN_USESMARTHANDLER" value="32"/>
			<member name="XMP_OPEN_USEPACKETSCANNING" value="64"/>
			<member name="XMP_OPEN_LIMITSCANNING" value="128"/>
			<member name="XMP_OPEN_INBACKGROUND" value="268435456"/>
		</enum>
		<enum name="XmpPropsBits">
			<member name="XMP_PROP_VALUE_IS_URI" value="2"/>
			<member name="XMP_PROP_HAS_QUALIFIERS" value="16"/>
			<member name="XMP_PROP_IS_QUALIFIER" value="32"/>
			<member name="XMP_PROP_HAS_LANG" value="64"/>
			<member name="XMP_PROP_HAS_TYPE" value="128"/>
			<member name="XMP_PROP_VALUE_IS_STRUCT" value="256"/>
			<member name="XMP_PROP_VALUE_IS_ARRAY" value="512"/>
			<member name="XMP_PROP_ARRAY_IS_UNORDERED" value="512"/>
			<member name="XMP_PROP_ARRAY_IS_ORDERED" value="1024"/>
			<member name="XMP_PROP_ARRAY_IS_ALT" value="2048"/>
			<member name="XMP_PROP_ARRAY_IS_ALTTEXT" value="4096"/>
			<member name="XMP_PROP_IS_ALIAS" value="65536"/>
			<member name="XMP_PROP_HAS_ALIASES" value="131072"/>
			<member name="XMP_PROP_IS_INTERNAL" value="262144"/>
			<member name="XMP_PROP_IS_STABLE" value="1048576"/>
			<member name="XMP_PROP_IS_DERIVED" value="2097152"/>
			<member name="XMP_PROP_ARRAY_FORM_MASK" value="7680"/>
			<member name="XMP_PROP_COMPOSITE_MASK" value="7936"/>
			<member name="XMP_IMPL_RESERVED_MASK" value="1879048192"/>
		</enum>
	</namespace>
</api>
