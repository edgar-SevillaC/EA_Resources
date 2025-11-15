option explicit

!INC Local Scripts.EAConstants-VBScript

'
' Script Name: GenerateSwComponentArxml
' Author: Edgar Sevilla
' Purpose: Generate arxml file from a SW Component
' Date: 14.04.2025
'
' Requisites:
'    Requires an UML profile with valid tags
'
' Configurations
'    None
'
' Instructions:
'    1. Select in SW Component in project Browser
'    2. Run the script
'    3. Arxml File will be generated in same folder where model is stored.
' 
'
' History: (version) [dd.mm.yyyy] : Author : Description
' (v1.0) [14.04.2025] : @Edgar Sevilla : First version of script (functional)
' (v1.1) [10.11.2025] : @Edgar Sevilla : Configuration feature was added. Refactoring. Debuging improved
' (v1.2) [11.11.2025] : @Edgar Sevilla : Refactoring, readability improved
' (v1.3) [15.11.2025] : @Edgar Sevilla : deprecated -> Replaced by "ARXML_Generation"

Const SCRIPT_VERSION  = "1.3"
Const SCRIPT_AUTHOR  = "Edgar Sevilla"

'Debug Enable:
Const DBG_PRINT_ENABLED = True
Const DBG_LEVEL = 1	' Level of details [1 - 3]
Const DBG_PRINT_ARXML_OUTPUT = False

'AUTOSAR CONSTANTS
Const AUTOSAR_VERSION = "4.4.0"
Const AUTOSAR_SCHEMA = "http://autosar.org/schema/r4.0"
Const AUTOSAR_SCHEMA_INST = "http://www.w3.org/2001/xmlschema-instance"
Const AUTOSAR_SCHEMA_XSD = "http://autosar.org/schema/r4.0 AUTOSAR_00046.xsd"

'CUSTOM TAG CONSTANTS
Const CUSTOM_ARXML_NAMESPACE="ea"
Const CUSTOM_ARXML_SCHEMA="https://sparxsystems.com/schema/ea"
'Note: EB tresos do not support TagValues from different namespace


Const PACKAGE_SUFIX = "_Pkg" ' this sufix is used for ARXML package Name


Const SWC_STEREOTYPE = "SW Component" ' Used to identify SW Component element from Model element stereotype
Const SWIF_STEREOTYPE = "SW Interface" ' Used to identify SW Interface element from Model element stereotype

Const PPORT_SENDER = "Sender" ' Used to identify Sender P-Port element from Model element stereotype
Const PPORT_SERVER = "Server" ' Used to identify Sender P-Port element from Model element stereotype
Const PPORT_MDSW = "ModeSwitch_in" ' Used to identify ModeSWitch P-Port element from Model element stereotype

Const RPORT_CLIENT = "Client" ' Used to identify Client R-Port element from Model element stereotype
Const RPORT_RECEIVER = "Receiver" ' Used to identify Receiver R-Port element from Model element stereotype
Const RPORT_MDSW = "ModeSwitch_out" ' Used to identify ModeSWitch R-Port element from Model element stereotype

Const COMPONENT_TYPE_TAG = "Layer" ' Tag Used to identify SW Component Type
Const COMPONENT_TYPE_APP = "APP (AUTOSAR)" ' Used to identify Application SW Component
Const COMPONENT_TYPE_CDD = "CDD (AUTOSAR)" ' Used to identify Complex Device Driver SW Component

'Software Component under 
dim g_SelectedComponent as EA.Element


'File
Dim fso
dim g_ArxmlFile

sub main
	
	' Show the script output window
    Repository.EnsureOutputVisible "Script"
	Repository.ClearOutput( "Script" )
    Session.Output( "GenerateSwComponentArxml" )
	Session.Output( "   Author: " & SCRIPT_AUTHOR )
    Session.Output( "   version: " & SCRIPT_VERSION )
	Session.Output("start: " & Now )
    Session.Output("")
	
	dim treeSelectedType
	dim selectedComponent as EA.Element
	
	g_ErrorCnt = 0
	g_WarningCnt = 0
	treeSelectedType = Repository.GetTreeSelectedItemType()
	
	if treeSelectedType = otElement then
	
		set g_SelectedComponent = Repository.GetTreeSelectedObject()
			
		if g_SelectedComponent.Stereotype = SWC_STEREOTYPE then
	
			Debug_Print "    SW Component: " & g_SelectedComponent.Name , 2
			Arxml_CreateFile
			
			Arxml_GenerationStart
			
			Arxml_CloseFile
		else
			MsgBox "Select a valid SW Component in Project Browser ", _
					vbCritical, _
					"Error: no SW Component was selected"
		end if
		
	else
		MsgBox "Select a valid SW Component in Project Browser ", _
				vbCritical, _
				"Error: no SW Component was selected"
	end if
	
    Session.Output("finished: " & Now)
    Session.Output("Done!" )
end sub


Private Function Arxml_CreateFile()

    dim FilePath
    dim CurrentDirectory
	
	Debug_Print "Arxml_CreateFile", 1
	
	CurrentDirectory = Left(Repository.ConnectionString, InStrRev(Repository.ConnectionString, "\"))
	FilePath = CurrentDirectory & g_SelectedComponent.Name & ".arxml"
	Debug_Print "", 2
	Debug_Print "    Target File: " & g_SelectedComponent.Name & ".arxml", 2
	Debug_Print "    Target Path: " & CurrentDirectory, 2

	Set fso = CreateObject("Scripting.FileSystemObject")
	Set g_ArxmlFile = fso.CreateTextFile(FilePath, True)
	
end function

Private Function Arxml_CloseFile()

	Debug_Print "Arxml_CloseFile", 1
	g_ArxmlFile.Close

end function


Private Function Arxml_GenerationStart()

	Debug_Print "Arxml_GenerationStart", 1
	
	'++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	'+              Write ARXML headers                         +
	Arxml_WriteLine("<?xml version=" & Chr(34) & "1.0" & Chr(34) & _
	                " encoding="  & Chr(34) & "utf-8"  & Chr(34) & "?>")
	Arxml_WriteLine("<AUTOSAR xmlns=" & Chr(34) & AUTOSAR_SCHEMA & Chr(34))
	
	if CUSTOM_ARXML_NAMESPACE <> "" then
		Arxml_WriteLine("         xmlns:" & CUSTOM_ARXML_NAMESPACE & "=" & _
		                                           Chr(34) & CUSTOM_ARXML_SCHEMA & Chr(34))
	end if
	
    Arxml_WriteLine("         xmlns:xsi=" & Chr(34) & AUTOSAR_SCHEMA_INST & Chr(34))
    Arxml_WriteLine("         xsi:schemaLocation=" & Chr(34) & AUTOSAR_SCHEMA_XSD & Chr(34) & ">")
	
	'++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	
	'Next Envelop
	Arxml_CreateMainARPackage

	'++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	'+                    Terminate ARXML Tag                   +
	Arxml_WriteLine("</AUTOSAR>")
	'++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	
end function


Private Function Arxml_CreateMainARPackage()
	Debug_Print "Arxml_CreateSWComponentPackage", 1
	
	'++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	'+                Create AR-Packages                        +
	Arxml_WriteLine("  <AR-PACKAGES>")
	Arxml_WriteLine("    <AR-PACKAGE>")
	Arxml_WriteLine("      <SHORT-NAME>" & g_SelectedComponent.Name & PACKAGE_SUFIX & "</SHORT-NAME>")
	Arxml_WriteLine("      <AR-PACKAGES>")
	'++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

	'Next Envelop
	Arxml_CreateComponentTypePackage
	Arxml_CreateCompuMethodsPackage
	Arxml_CreatePortInterfacesPackage
	
	'++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	'+                    Terminate ARXML Tag                   +
	Arxml_WriteLine("      </AR-PACKAGES>")
	Arxml_WriteLine("    </AR-PACKAGE>")
	Arxml_WriteLine("  </AR-PACKAGES>")
	'++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	
end function

Private Function Arxml_CreateComponentTypePackage()
	Debug_Print "Arxml_CreateComponentTypePackage", 1
	
	'++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	'+                Create SWC-Package                        +
	Arxml_WriteLine("        <AR-PACKAGE>")
	Arxml_WriteLine("          <SHORT-NAME>ComponentTypes</SHORT-NAME>")
	Arxml_WriteLine("          <ELEMENTS>")

	'Next Envelop
	Arxml_CreateSWComponent
	Arxml_CreateSWComponentModeSwitchInterface_loop
	Arxml_CreateSWComponentModeDeclarationGroup_loop

	'++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	'+                    Terminate ARXML Tag                   +
	Arxml_WriteLine("          </ELEMENTS>")
	Arxml_WriteLine("        </AR-PACKAGE>")
	'++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	
end function

Private Function Arxml_CreateCompuMethodsPackage()
	Debug_Print "Arxml_CreateCompuMethodsPackage", 1
	
	'++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	'+                Create CompuMethods Package               +
	Arxml_WriteLine("        <AR-PACKAGE>")
	Arxml_WriteLine("          <SHORT-NAME>CompuMethods</SHORT-NAME>")
	'++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	
	'Next envelop
	'ToDo: Add Compu Methods
	
	'++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	'+                    Terminate ARXML Tag                   +
	Arxml_WriteLine("        </AR-PACKAGE>")
	'++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

end function

Private Function Arxml_CreatePortInterfacesPackage()
	Debug_Print "Arxml_CreatePortInterfacesPackage", 1
	
	'++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	'+                Create PortInterfaces Package             +
	Arxml_WriteLine("        <AR-PACKAGE>")
	Arxml_WriteLine("          <SHORT-NAME>PortInterfaces</SHORT-NAME>")
	Arxml_WriteLine("          <ELEMENTS>")
	'++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	
	'Next Envelops
	PortInterfacesExtract
	
	'++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	'+                    Terminate ARXML Tag                   +
	Arxml_WriteLine("          </ELEMENTS>")
	Arxml_WriteLine("        </AR-PACKAGE>")
	'++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

end function



Private Function Arxml_PortInterfacesPPortServer(swIf)

	Debug_Print "Arxml_PortInterfacesPPortServer", 1
	
	dim swInterface as EA.Element
	set swInterface = swIf
	
	'++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	'+                Create Client-Server Interface            +
	Arxml_WriteLine("            <CLIENT-SERVER-INTERFACE>")
	Arxml_WriteLine("              <SHORT-NAME>" & swInterface.Name & "</SHORT-NAME>")
	
	if CUSTOM_ARXML_NAMESPACE <> "" then
		Arxml_WriteLine("              <" & CUSTOM_ARXML_NAMESPACE & ":GUID>" & swInterface.ElementGUID & "</" & CUSTOM_ARXML_NAMESPACE & ":GUID>")
	end if
	
	Arxml_WriteLine("              <IS-SERVICE>false</IS-SERVICE>")
	Arxml_WriteLine("              <OPERATIONS>")
	'++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	
	'Next Envelop
	PortInterfacesOperationsExtract(swIf)
	
	'++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	'+                    Terminate ARXML Tag                   +
	Arxml_WriteLine("              </OPERATIONS>")
	Arxml_WriteLine("            </CLIENT-SERVER-INTERFACE>")
	'++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

end function

Private Function Arxml_PortInterfacesPPortSender(swIf)

	Debug_Print "Arxml_PortInterfacesPPortSender", 1
	
	dim swInterface as EA.Element
	set swInterface = swIf

	'++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	'+                Create Sender-Receiver Interface          +
	Arxml_WriteLine("            <SENDER-RECEIVER-INTERFACE>")
	Arxml_WriteLine("              <SHORT-NAME>" & swInterface.Name & "</SHORT-NAME>")
	
	if CUSTOM_ARXML_NAMESPACE <> "" then
		Arxml_WriteLine("              <" & CUSTOM_ARXML_NAMESPACE & ":GUID>" & swInterface.ElementGUID & "</" & CUSTOM_ARXML_NAMESPACE & ":GUID>")
	end if
	
	Arxml_WriteLine("              <IS-SERVICE>false</IS-SERVICE>")
	Arxml_WriteLine("              <DATA-ELEMENTS>")
	'++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	
	'Next Envelop
	PortInterfacesDataElementExtract(swIf)

	'++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	'+                    Terminate ARXML Tag                   +
	Arxml_WriteLine("              </DATA-ELEMENTS>")
	Arxml_WriteLine("            </SENDER-RECEIVER-INTERFACE>")
	'++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

end function

Private Function Arxml_PortInterfacesPPortModeSwitch(swIf)

	Debug_Print "Arxml_PortInterfacesPPortModeSwitch", 1
	
	dim swInterface as EA.Element
	set swInterface = swIf

	'++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	'+                Create Sender-Receiver Interface          +
	Arxml_WriteLine("            <MODE-SWITCH-INTERFACE>")
	Arxml_WriteLine("              <SHORT-NAME>" & swInterface.Name & "</SHORT-NAME>")

	if CUSTOM_ARXML_NAMESPACE <> "" then
		Arxml_WriteLine("              <" & CUSTOM_ARXML_NAMESPACE & ":GUID>" & swInterface.ElementGUID & "</" & CUSTOM_ARXML_NAMESPACE & ":GUID>")
	end if
	
	Arxml_WriteLine("              <IS-SERVICE>false</IS-SERVICE>")
	Arxml_WriteLine("              <MODE-GROUP>")
	'++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	
	'Next Envelop
	'ToDo: Get Mode Groups

	'++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	'+                    Terminate ARXML Tag                   +
	Arxml_WriteLine("              </DATA-ELEMENTS>")
	Arxml_WriteLine("            </MODE-SWITCH-INTERFACE>")
	'++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

end function


Private Function Arxml_PortInterfaceOperations(Oper)

	Debug_Print "Arxml_PortInterfaceOperations", 1
	
	dim operation as EA.Method
	set operation = Oper
	
	'++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	'+                Create Client-Server Operation            +
	Arxml_WriteLine("                <CLIENT-SERVER-OPERATION>")
	Arxml_WriteLine("                  <SHORT-NAME>" & operation.Name & "</SHORT-NAME>")
	Arxml_WriteLine("                  <ARGUMENTS>")
	'++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

	'Next Envelop
	PortInterfacesOperationParametersExtract(operation)
	
	
	'++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	'+                    Terminate ARXML Tag                   +
	Arxml_WriteLine("                  </ARGUMENTS>")
	Arxml_WriteLine("                </CLIENT-SERVER-OPERATION>")
	'++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	
end function

Private Function Arxml_PortInterfaceOperationParameter(paramName, paramType, paramDir)
	Debug_Print "Arxml_PortInterfaceOperations", 1
	
	'++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	'+                  Create Argumet prototype (Parameters)   +
	Arxml_WriteLine("                  <ARGUMENT-DATA-PROTOTYPE>")
	Arxml_WriteLine("                    <SHORT-NAME>" & paramName & "</SHORT-NAME>")
	
	'ToDo: find reference the the datatype
	Arxml_WriteLine("                    <TYPE-TREF DEST=" & Chr(34) & "IMPLEMENTATION-DATA-TYPE" & Chr(34) & ">" & _
														paramType & "</TYPE-TREF>")
	Arxml_WriteLine("                    <DIRECTION>" & UCase(paramDir) & "</DIRECTION>")
	Arxml_WriteLine("                  </ARGUMENT-DATA-PROTOTYPE>")
	'++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	
end function

Private Function Arxml_PortInterfaceDataElement(Att)

	Debug_Print "Arxml_PortInterfaceDataElement", 1
	
	dim attribute as EA.Attribute
	set attribute = Att
	
	'++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	'+                Create VariableData                       +
	Arxml_WriteLine("                <VARIABLE-DATA-PROTOTYPE>")
	Arxml_WriteLine("                  <SHORT-NAME>" & attribute.Name & "</SHORT-NAME>")
	Arxml_WriteLine("                  <TYPE-TREF DEST=" & Chr(34) & "IMPLEMENTATION-DATA-TYPE" & Chr(34) & ">" & "ADD REFERENCE (TBD)" & "</TYPE-TREF>")
	'++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


	
	'++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	'+                    Terminate ARXML Tag                   +
	Arxml_WriteLine("                </VARIABLE-DATA-PROTOTYPE>")
	'++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	
end function






Private Function Arxml_CreateSWComponent()
	Debug_Print "Arxml_CreateSWComponent", 1
	
	dim componentType
	componentType = IdentifySwComponentType()
	
	'++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	'+                Create CompuMethods Package               +
	Arxml_WriteLine("            " & componentType)
	Arxml_WriteLine("              <SHORT-NAME>" & g_SelectedComponent.Name & "</SHORT-NAME>")

	if CUSTOM_ARXML_NAMESPACE <> "" then
		Arxml_WriteLine("              <" & CUSTOM_ARXML_NAMESPACE & ":GUID>" & g_SelectedComponent.ElementGUID & "</" & CUSTOM_ARXML_NAMESPACE & ":GUID>")
	end if
	
	Arxml_WriteLine("              <PORTS>")
	'++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	
	'Next Evelop
	PortPrototypeExtract
	InternalBehaviorExtract
	
	'++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	'+                    Terminate ARXML Tag                   +
	Arxml_WriteLine("              </PORTS>")
	Arxml_WriteLine("            </APPLICATION-SW-COMPONENT-TYPE>")
	'++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	
end function




Private Function Arxml_InternalBehavior()
	Debug_Print "Arxml_InternalBehavior", 1
	
	'++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	'+              Create Internal Behaviors                   +
	Arxml_WriteLine("              <INTERNAL-BEHAVIORS>")
	Arxml_WriteLine("                <SWC-INTERNAL-BEHAVIOR>")
	Arxml_WriteLine("                  <SHORT-NAME>" & g_SelectedComponent.Name & "_InternalBehavior</SHORT-NAME>")
	Arxml_WriteLine("                  <DATA-TYPE-MAPPING-REFS>")
	Arxml_WriteLine("                  </DATA-TYPE-MAPPING-REFS>")
	Arxml_WriteLine("                  <EXCLUSIVE-AREAS>")
	Arxml_WriteLine("                  </EXCLUSIVE-AREAS>")
	'++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	
	Arxml_WriteLine("                  <EVENTS>")
	
	'Next Envelop
	'ToDo: Extract Events
		Arxml_WriteLine("                    <INIT-EVENT>")
		Arxml_WriteLine("                    </INIT-EVENT>")
	
	Arxml_WriteLine("                  </EVENTS>")
	
	
	Arxml_WriteLine("                  <PORT-API-OPTIONS>")
	Arxml_WriteLine("                  </PORT-API-OPTIONS>")
	Arxml_WriteLine("                  <RUNNABLES>")
	
	'Next Envelop
	'ToDo: Extract Events
	
	Arxml_WriteLine("                  </RUNNABLES>")
	'++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	'+                    Terminate ARXML Tag                   +
	Arxml_WriteLine("                </SWC-INTERNAL-BEHAVIOR>")
	Arxml_WriteLine("              </INTERNAL-BEHAVIORS>")
	'++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	
end function

Private Function Arxml_CreateSWComponentModeSwitchInterface_loop()
	Debug_Print "Arxml_CreateSWComponentModeSwitchInterface_loop", 1
	Arxml_WriteLine("            <MODE-SWITCH-INTERFACE>")
	Arxml_WriteLine("            </MODE-SWITCH-INTERFACE>")

end function

Private Function Arxml_CreateSWComponentModeDeclarationGroup_loop()
	Debug_Print "Arxml_CreateSWComponentModeDeclarationGroup_loop", 1
	Arxml_WriteLine("            <MODE-DECLARATION-GROUP>")
	Arxml_WriteLine("            </MODE-DECLARATION-GROUP>")

end function


Private Function Arxml_PortPrototypePPort(swPort, swIf)
	Debug_Print "Arxml_PortPrototypePPortServer", 1
	
	dim port as EA.Element
	dim swInterface as EA.Element
	set port = swPort
	set swInterface = swIf
	
	'++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	'+                Create P-Port Prototype                   +
	Arxml_WriteLine("                <P-PORT-PROTOTYPE>")
	Arxml_WriteLine("                  <SHORT-NAME>" & port.Name & "</SHORT-NAME>")
	if CUSTOM_ARXML_NAMESPACE <> "" then
		Arxml_WriteLine("                  <" & CUSTOM_ARXML_NAMESPACE & ":GUID>" & port.ElementGUID & "</" & CUSTOM_ARXML_NAMESPACE & ":GUID>")
	end if

	Arxml_WriteLine("                  <PROVIDED-COM-SPECS>")
	'++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	
	'Next Evelops / Operations / Attributes / Modes
	
	dim interfaceType
	dim interfacePath
	
	If Not swInterface Is Nothing Then
		
		if port.Stereotype = PPORT_SERVER then
			
			'Search for Opperations
			PortPrototypeIfOperationsExtract swPort, swInterface
			
			interfaceType = "CLIENT-SERVER-INTERFACE"
			interfacePath = g_SelectedComponent.Name & PACKAGE_SUFIX &"/PortInterfaces/" & swInterface.Name

		elseif port.Stereotype = PPORT_SENDER then
		
			'Search for Attributes
			PortPrototypeIfAttributesExtract swPort, swInterface
			
			interfaceType = "SENDER-RECEIVER-INTERFACE"
			interfacePath = g_SelectedComponent.Name & PACKAGE_SUFIX &"/PortInterfaces/" & swInterface.Name
		
		elseif port.Stereotype = PPORT_MDSW then
		
			'Todo: Search for Modes
			Arxml_WriteLine("                    <MODE-SWITCH-SENDER-COM-SPEC>")
			Arxml_WriteLine("                    </MODE-SWITCH-SENDER-COM-SPEC>")
			
			interfaceType = "MODE-SWITCH-INTERFACE"
			interfacePath = g_SelectedComponent.Name & PACKAGE_SUFIX &"/PortInterfaces/" & swInterface.Name
		
		else
			interfaceType = ""
			interfacePath = ""
		end if
		
	end if


	'++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	'+                    Terminate ARXML Tag                   +
	Arxml_WriteLine("                  </PROVIDED-COM-SPECS>")
	Arxml_WriteLine("                  <PROVIDED-INTERFACE-TREF DEST=" & Chr(34) & interfaceType & Chr(34) & ">/" & _
											interfacePath & "</PROVIDED-INTERFACE-TREF>")
	Arxml_WriteLine("                </P-PORT-PROTOTYPE>")
	'++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	
end function


Private Function Arxml_PortPrototypeIfOperation(Oper, ifName, portType)

	Debug_Print "Arxml_PortPrototypeIfOperation",1

	dim operation as EA.Method
	Set operation = Oper
	dim spec
	
	if portType = PPORT_SERVER then
		spec = "<SERVER-COM-SPEC>"
	elseif portType = PPORT_CLIENT then
		spec = "<CLIENT-COM-SPEC>"
	else
		spec = "<UNKNOWN-F-COM-SPEC>"
	end if
	
	
	'++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	'+                Create COM-SPEC Prototype                   +
	Arxml_WriteLine("                    " & spec)

	Arxml_WriteLine("                    <OPERATION-REF DEST=" & Chr(34) & "CLIENT-SERVER-OPERATION" & Chr(34) & ">" & _
										  "/" & g_SelectedComponent.Name & PACKAGE_SUFIX & "/PortInterfaces/" & ifName & "/" & _
										  operation.Name & "</OPERATION-REF>")
	Arxml_WriteLine("                      <QUEUE-LENGTH>1</QUEUE-LENGTH>")

	'++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	'+                    Terminate ARXML Tag                   +
	Arxml_WriteLine("                    </" & right(spec,Len(spec)-1))
	'++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

end function

Private Function Arxml_PortPrototypeIfAttributes(attName, ifName, portType)

	Debug_Print "Arxml_PortPrototypeIfAttributes",1

	dim spec
	
	if portType = PPORT_SENDER then
		spec = "<NONQUEUED-SENDER-COM-SPEC>"
	elseif portType = PPORT_RECEIVER then
		spec = "<NONQUEUED-RECEIVER-COM-SPEC>"
	else
		spec = "<UNKNOWN-D-COM-SPEC>"
	end if
	
	
	'++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	'+                Create COM-SPEC Prototype                   +
	Arxml_WriteLine("                    " & spec)

	Arxml_WriteLine("                    <DATA-ELEMENT-REF DEST=" & Chr(34) & "VARIABLE-DATA-PROTOTYPE" & Chr(34) & ">" & _
										  "/" & g_SelectedComponent.Name & PACKAGE_SUFIX & "/PortInterfaces/" & ifName & "/" & _
										  attName & "</DATA-ELEMENT-REF>")
	Arxml_WriteLine("                      <HANDLE-OUT-OF-RANGE>NONE</HANDLE-OUT-OF-RANGE>")
	Arxml_WriteLine("                      <USES-END-TO-END-PROTECTION>0</USES-END-TO-END-PROTECTION>")
	

	'++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	'+                    Terminate ARXML Tag                   +
	Arxml_WriteLine("                    </" & right(spec,Len(spec)-1))
	'++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

end function

Private Function InternalBehaviorExtract()
	Debug_Print "InternalBehaviorExtract",1
	Arxml_InternalBehavior

end function

Private Function PortPrototypeIfOperationsExtract(swPort, swIf)
	Debug_Print "PortPrototypeOperationsExtract", 1
	
	dim swInterface as EA.Element
	dim port as EA.Element
	dim operation as EA.Method
	set swInterface = swIf
	set port = swPort
	
	for each operation in swInterface.Methods
		Debug_Print "OpNmae: " & operation.Name, 3
		
		Arxml_PortPrototypeIfOperation operation, swInterface.Name, port.Stereotype
	Next

end function

Private Function PortPrototypeIfAttributesExtract(swPort, swIf)
	Debug_Print "PortPrototypeIfAttributesExtract", 1
	
	dim swInterface as EA.Element
	dim port as EA.Element
	dim attribute as EA.Attribute
	set  swInterface = swIf
	set port = swPort
	
	for each attribute in swInterface.Attributes
		Debug_Print "OpNmae: " & attribute.Name, 3
		
		Arxml_PortPrototypeIfAttributes attribute.Name, swInterface.Name, port.Stereotype
	Next

end function

Private Function PortPrototypeExtract()
	Debug_Print "PortPrototypeExtract",1
	
	dim port as EA.Element
	dim swInterface as EA.Element
	dim arxmlPortType
	dim arxmlPort
	dim swInterfaceId

	
	'Loop for All Ports (P-Ports and R-Ports)
	for each port in g_SelectedComponent.Elements
		
		swInterfaceId = GetLinkedSwInterfaceElementId(port)
		
		if swInterfaceId <> 0 then
			Set swInterface = Repository.GetElementByID(swInterfaceId)
		end if
		
		Debug_Print "    " & port.Name & ":" & port.Stereotype, 3
		if port.Stereotype = PPORT_SERVER             then 
			Arxml_PortPrototypePPort port, swInterface
		
		elseif port.Stereotype = PPORT_SENDER         then
			Arxml_PortPrototypePPort port, swInterface			
			
		elseif port.Stereotype = PPORT_MDSW then
			Arxml_PortPrototypePPort port, swInterface	
			
		elseif port.Stereotype = RPORT_CLIENT         then
			arxmlPort = "<R-PORT-PROTOTYPE>"
			arxmlPortType = "<CLIENT-COM-SPEC>"
		elseif port.Stereotype = RPORT_RECEIVER       then
			arxmlPort = "<R-PORT-PROTOTYPE>"
			arxmlPortType = "<NONQUEUED-RECEIVER-COM-SPEC>"
		elseif port.Stereotype = RPORT_MDSW  then
			arxmlPort = "<R-PORT-PROTOTYPE>"
			arxmlPortType = "<MODE-SWITCH-RECEIVER-COM-SPEC>"
		else
			Error_Print("No valid Port type : '" & port.Name & ":" & port.Stereotype & "' : Arxml_CreateSWComponent_start")
			arxmlPort = "<UNKNOWN-PORT-PROTOTYPE>"
			arxmlPortType = "</UNKNOWN-COM-SPEC>"
		end if

		

	
	next
end function



Private Function PortInterfacesDataElementExtract(swIf)
	Debug_Print "PortInterfacesDataElementExtract", 1
	
	dim swInterface as EA.Element
	dim attribute as EA.Attribute
	set  swInterface = swIf
	
	for each attribute in swInterface.Attributes
		Debug_Print "AttName: " & attribute.Name, 2
		
		Arxml_PortInterfaceDataElement(attribute)
	Next

end function


Private Function PortInterfacesOperationParametersExtract(oper)
	Debug_Print "PortInterfacesOperationParametersExtract", 1
	
	dim operation as EA.Method
	dim parameter as EA.Parameter
	set  operation = oper
	
	for each parameter in operation.Parameters
		Debug_Print "ParamNmae: " & parameter.Name, 2
		Arxml_PortInterfaceOperationParameter parameter.Name, parameter.Type, parameter.Kind
	Next
	
end function

Private Function PortInterfacesOperationsExtract(swIf)
	Debug_Print "PortInterfacesOperationsExtract", 1
	
	dim swInterface as EA.Element
	dim operation as EA.Method
	set  swInterface = swIf
	
	for each operation in swInterface.Methods
		Debug_Print "OpNmae: " & operation.Name, 3
		
		Arxml_PortInterfaceOperations(operation)
	Next

end function

Private Function PortInterfacesExtract()
	Debug_Print "PortInterfacesExtract", 1

	dim port as EA.Element
	dim swInterface as EA.Element
	dim swInterfaceId
	
	'Loop over Interfaces linked to P-Ports
	for each port in g_SelectedComponent.Elements
		Debug_Print "    " & port.Name & ":" & port.Stereotype, 3
		
		'Search for Linked SW Interfaces
		swInterfaceId = GetLinkedSwInterfaceElementId(port)
		
		if swInterfaceId <> 0 then
			Set swInterface = Repository.GetElementByID(swInterfaceId)
		end if
		
		If Not swInterface Is Nothing Then
		
			if port.Stereotype = PPORT_SERVER             then 
				Arxml_PortInterfacesPPortServer(swInterface)
			
			elseif port.Stereotype = PPORT_SENDER         then
				Arxml_PortInterfacesPPortSender(swInterface)
			
			elseif port.Stereotype = PPORT_MDSW         then
				Arxml_PortInterfacesPPortModeSwitch(swInterface)
				
			else
				' Other ports are not parsed
			end if
		end if
		
	Next

end function

Private Function IdentifySwComponentType()

	Debug_Print "IdentifySwComponentType", 1
	
	dim tag As EA.TaggedValue
	dim componentType
	
	Set tag = g_SelectedComponent.TaggedValues.GetByName(COMPONENT_TYPE_TAG)
    If Not tag Is Nothing Then
        componentType = tag.Value
	else
        componentType = "Invalid"
    End If
	Debug_Print "Tag value: " & componentType, 3
	
	if componentType = COMPONENT_TYPE_APP then
		componentType = "<APPLICATION-SW-COMPONENT-TYPE>"
	elseif componentType = COMPONENT_TYPE_CDD then
		componentType = "<COMPLEX-DEVICE-DRIVER-SW-COMPONENT-TYPE>"
	else
		Error_Print("No valid SW Component type : '" & componentType & "' : Arxml_CreateSWComponent_start")
		componentType = "<UNKNOWN-SW-COMPONENT-TYPE>"
	end if
	
	Debug_Print "Component type Return: " & componentType, 3
	
	IdentifySwComponentType = componentType

end function

Private Function GetLinkedSwInterfaceElementId(thePort)

	Debug_Print "GetLinkedSwInterfaceElementId", 1
	
	dim port as EA.Element
	dim swInterface as EA.Element
	dim eaConnector as EA.Connector
	set port = thePort
	
	GetLinkedSwInterfaceElementId = 0
	
	'Search for Linked SW Interfaces
	dim query
	dim xmlOutput
	dim fileRow
	dim guid
	query = _
			"SELECT t_connector.ea_guid                             " & Chr(10) & _
			"FROM t_connector                                       " & Chr(10) & _
			"WHERE                                                  " & Chr(10) & _
			"      t_connector.Connector_Type = 'Realisation' AND   " & Chr(10) & _
			"      t_connector.Start_Object_ID = " & port.ElementID
	
	xmlOutput = Repository.SQLQuery(query)

	fileRow = Split(xmlOutput, "<Row><ea_guid>")
	if UBound(fileRow) > 0 then
		guid = Left(fileRow(1), InStr(fileRow(1), "}"))
		Debug_Print guid, 2

		Set eaConnector = Repository.GetConnectorByGuid(guid)
		Set swInterface = Repository.GetElementByID(eaConnector.SupplierID)
		If swInterface.Stereotype = SWIF_STEREOTYPE Then
			GetLinkedSwInterfaceElementId = eaConnector.SupplierID
		end if
	end if
	
	Debug_Print GetLinkedSwInterfaceElementId, 2
	
End function


Private Function Arxml_WriteLine(line)

	if DBG_PRINT_ENABLED = True and DBG_PRINT_ARXML_OUTPUT = True then
		Session.Output(line)
	end if
	g_ArxmlFile.WriteLine line

end function

Private Function Debug_Print(line, level)

	if DBG_PRINT_ENABLED = True and level <= DBG_LEVEL then
		Session.Output(line)
	end if

end function

dim g_ErrorCnt

Private Function Error_Print(line)

	g_ErrorCnt = g_ErrorCnt + 1
	Session.Output("#ERROR# (" & g_ErrorCnt &"): " & line)
	
end function

dim g_WarningCnt

Private Function Warning_Print(line)

	g_WarningCnt = g_WarningCnt + 1
	Session.Output("#WARNING# (" & g_WarningCnt &"): " & line)
	
end function

main
