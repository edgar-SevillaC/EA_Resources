
!INC Local Scripts.EAConstants-VBScript

'
' Script Name: 
' Author: Edgar Sevilla
' Purpose: Constant definitions
' Date: 12.11.2025
'

' ================================
' Constants and Configuration
' ================================

' Script Metadata
Const SCRIPT_VERSION = "2.0"
Const SCRIPT_AUTHOR = "Edgar Sevilla"

' Debug Settings

Const DBG_PRINT_ARXML_OUTPUT = False

' AUTOSAR Constants
Const AUTOSAR_VERSION = "4.4.0"
Const AUTOSAR_SCHEMA = "http://autosar.org/schema/r4.0"
Const AUTOSAR_SCHEMA_INST = "http://www.w3.org/2001/XMLSchema-instance"
Const AUTOSAR_SCHEMA_XSD = "http://autosar.org/schema/r4.0 AUTOSAR_00046.xsd"

' Custom Namespace
Const CUSTOM_ARXML_NAMESPACE = "" '"ea"
Const CUSTOM_ARXML_SCHEMA = "https://sparxsystems.com/schema/ea"
Const CUSTOM_ARXML_TRACEABILITY_TAG ="ea:GUID"

' Stereotypes
Const SWC_STEREOTYPE = "SW Component"
Const SWIF_STEREOTYPE = "SW Interface"
Const PPORT_SERVER = "Server"
Const PPORT_SENDER = "Sender"
Const PPORT_MDSW = "ModeSwitch_in"
Const RPORT_CLIENT = "Client"
Const RPORT_RECEIVER = "Receiver"
Const RPORT_MDSW = "ModeSwitch_out"

' Tags
Const COMPONENT_TYPE_TAG = "Layer"
Const COMPONENT_TYPE_APP = "APP (AUTOSAR)"
Const COMPONENT_TYPE_CDD = "CDD (AUTOSAR)"

' Package suffix
Const PACKAGE_SUFFIX = "_Pkg"

Const IDENT_00 = ""
Const IDENT_01 = "  "
Const IDENT_02 = "    "
Const IDENT_03 = "      "
Const IDENT_04 = "        "
Const IDENT_05 = "          "
Const IDENT_06 = "            "
Const IDENT_07 = "              "
Const IDENT_08 = "                "
Const IDENT_09 = "                  "
Const IDENT_10 = "                    "
Const IDENT_11 = "                      "