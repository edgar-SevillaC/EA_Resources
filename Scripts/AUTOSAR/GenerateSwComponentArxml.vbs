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
' History


Const SCRIPT_VERSION  = "1.0"

'Debug Enable:
Const DBG_PRINT_SCREEN = True
Const DBG_PRINT_ARXML_OUTPUT = False

'AUTOSAR CONSTANTS
Const AUTOSAR_VERSION = "4.4.0"
Const AUTOSAR_SCHEMA = "http://autosar.org/schema/r4.0"
Const AUTOSAR_SCHEMA_INST = "http://www.w3.org/2001/xmlschema-instance"
Const AUTOSAR_SCHEMA_XSD = "http://autosar.org/schema/r4.0 AUTOSAR_00046.xsd"

'CUSTOM TAG CONSTANTS
Const CUSTOM_ARXML_NAMESPACE="ea"
Const CUSTOM_ARXML_SCHEMA="https://sparxsystems.com/schema/ea"


Const SWC_STEREOTYPE = "SW Component"
Const SWIF_STEREOTYPE = "SW Interface"

Const PPORT_SENDER = "Sender"
Const PPORT_SERVER = "Server"
Const PPORT_MDSW = "ModeSwitch_in"

Const RPORT_CLIENT = "Client"
Const RPORT_RECEIVER = "Receiver"
Const RPORT_MDSW = "ModeSwitch_out"

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
    Session.Output( "   version: " & SCRIPT_VERSION )
	Session.Output("start: " & Now )
    Session.Output("")
	
	dim treeSelectedType
	dim selectedComponent as EA.Element
	
	treeSelectedType = Repository.GetTreeSelectedItemType()
	
	if treeSelectedType = otElement then
	
		set g_SelectedComponent = Repository.GetTreeSelectedObject()
			
		if g_SelectedComponent.Stereotype = SWC_STEREOTYPE then
	
			Debug_Print( "    SW Component: " & g_SelectedComponent.Name )
			Arxml_CreateFile
			Arxml_PopulateAutosarVersionInfo_start
			Arxml_CreateSWComponentPackage_start
			Arxml_CreateSWComponent_start
			
			Arxml_CreateSWComponentPorts_loop
			Arxml_CreateSWComponentInternalBehaviors_loop
			
			Arxml_CreateSWComponent_end
			
			Arxml_CreateSWComponentModeSwitchInterface_loop
			Arxml_CreateSWComponentModeDeclarationGroup_loop
			
			Arxml_CreateSWComponentPackage_end
			Arxml_PopulateAutosarVersionInfo_end
	
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
	
	Debug_Print("Arxml_CreateFile")
	
	CurrentDirectory = Left(Repository.ConnectionString, InStrRev(Repository.ConnectionString, "\"))
	FilePath = CurrentDirectory & g_SelectedComponent.Name & ".arxml"
	Debug_Print("")
	Debug_Print("    Target File: " & g_SelectedComponent.Name & ".arxml")
	Debug_Print("    Target Path: " & CurrentDirectory)

	Set fso = CreateObject("Scripting.FileSystemObject")
	Set g_ArxmlFile = fso.CreateTextFile(FilePath, True)
	
	Arxml_WriteLine("<?xml version=" & Chr(34) & "1.0" & Chr(34) & " encoding="  & Chr(34) & "utf-8"  & Chr(34) & "?>")

end function

Private Function Arxml_CloseFile()

	Debug_Print("Arxml_CloseFile")
	g_ArxmlFile.Close

end function


Private Function Arxml_PopulateAutosarVersionInfo_start()

	Debug_Print("Arxml_PopulateAutosarVersionInfo_start")
	
	Arxml_WriteLine("<AUTOSAR xmlns=" & Chr(34) & AUTOSAR_SCHEMA & Chr(34))
	
	if CUSTOM_ARXML_NAMESPACE <> "" then
		Arxml_WriteLine("         xmlns:" & CUSTOM_ARXML_NAMESPACE & "=" & _
		                                           Chr(34) & CUSTOM_ARXML_SCHEMA & Chr(34))
	end if
	
    Arxml_WriteLine("         xmlns:xsi=" & Chr(34) & AUTOSAR_SCHEMA_INST & Chr(34))
    Arxml_WriteLine("         xsi:schemaLocation=" & Chr(34) & AUTOSAR_SCHEMA_XSD & Chr(34) & ">")


end function

Private Function Arxml_PopulateAutosarVersionInfo_end()
	Debug_Print("Arxml_PopulateAutosarVersionInfo_end")
	Arxml_WriteLine("</AUTOSAR>")
end function

Private Function Arxml_CreateSWComponentPackage_start()
	Debug_Print("Arxml_CreateSWComponentPackage_start")
	Arxml_WriteLine("  <AR-PACKAGES>")
	Arxml_WriteLine("    <AR-PACKAGE>")
	Arxml_WriteLine("      <SHORT-NAME>" & g_SelectedComponent.Name & "_Package</SHORT-NAME>")
	Arxml_WriteLine("      <AR-PACKAGES>")
	Arxml_WriteLine("        <AR-PACKAGE>")
	Arxml_WriteLine("          <SHORT-NAME>ComponentTypes</SHORT-NAME>")
	Arxml_WriteLine("          <ELEMENTS>")

end function

Private Function Arxml_CreateSWComponentPackage_end()
	Debug_Print("Arxml_CreateSWComponentPackage_end")
	Arxml_WriteLine("          </ELEMENTS>")
	Arxml_WriteLine("        </AR-PACKAGE>")
	
	Arxml_CreateSWComponentCompuMethods_loop
	Arxml_CreateSWComponentPortInterfaces_loop
	
	Arxml_WriteLine("      </AR-PACKAGES>")
	Arxml_WriteLine("    </AR-PACKAGE>")
	Arxml_WriteLine("  </AR-PACKAGES>")

end function

Private Function Arxml_CreateSWComponentPortInterfaces_loop()
	Debug_Print("Arxml_CreateSWComponentPortInterfaces_loop")
	Arxml_WriteLine("        <AR-PACKAGE>")
	Arxml_WriteLine("          <SHORT-NAME>PortInterfaces</SHORT-NAME>")
	Arxml_WriteLine("          <ELEMENTS>")
	
	dim port as EA.Element
	dim swInterface as EA.Element
	dim swInterfaceId
	
	'Loop over Interfaces linked to P-Ports
	for each port in g_SelectedComponent.Elements
		Debug_Print("    " & port.Name & ":" & port.Stereotype)
		
		'Search for Linked SW Interfaces
		swInterfaceId = GetLinkedSwInterfaceElementId(port)
		
		if swInterfaceId <> 0 then
			Set swInterface = Repository.GetElementByID(swInterfaceId)
		end if
		
		If Not swInterface Is Nothing Then
		
			if port.Stereotype = PPORT_SERVER             then 
				Arxml_WriteLine("            <CLIENT-SERVER-INTERFACE>")
				Arxml_WriteLine("              <SHORT-NAME>" & swInterface.Name & "</SHORT-NAME>")
				Arxml_WriteLine("              <OPERATIONS>")
				Arxml_WriteLine("                <CLIENT-SERVER-OPERATION>")
				
				Arxml_WriteLine("                </CLIENT-SERVER-OPERATION>")
				Arxml_WriteLine("              </OPERATIONS>")
				Arxml_WriteLine("            </CLIENT-SERVER-INTERFACE>")
			
			elseif port.Stereotype = PPORT_SENDER         then
				Arxml_WriteLine("            <SENDER-RECEIVER-INTERFACE>")
				Arxml_WriteLine("              <SHORT-NAME>" & swInterface.Name & "</SHORT-NAME>")
				Arxml_WriteLine("              <DATA-ELEMENTS>")
				Arxml_WriteLine("                <VARIABLE-DATA-PROTOTYPE>")
				
				Arxml_WriteLine("                </VARIABLE-DATA-PROTOTYPE>")
				Arxml_WriteLine("              </DATA-ELEMENTS>")
				Arxml_WriteLine("            </SENDER-RECEIVER-INTERFACE>")
				
				
			'elseif port.Stereotype = "ModeSwitch_out" then
			'	arxmlPort = "<P-PORT-PROTOTYPE>"
			else
				' ToDo: Add Alert that Unknown Port Interface detected
				Arxml_WriteLine("            <UNKNOWN-INTERFACE>")
				Arxml_WriteLine("              <SHORT-NAME>" & swInterface.Name & "</SHORT-NAME>")
				Arxml_WriteLine("            <UNKNOWN-INTERFACE>")
			end if
		end if
		
	Next
	
	Arxml_WriteLine("          </ELEMENTS>")
	
	Arxml_WriteLine("        </AR-PACKAGE>")

end function

Private Function Arxml_CreateSWComponentCompuMethods_loop()
	Debug_Print("Arxml_CreateSWComponentPackage_end")
	Arxml_WriteLine("        <AR-PACKAGE>")
	Arxml_WriteLine("          <SHORT-NAME>CompuMethods</SHORT-NAME>")
	Arxml_WriteLine("        </AR-PACKAGE>")

end function

Private Function Arxml_CreateSWComponent_start()
	Debug_Print("Arxml_CreateSWComponent_start")
	Arxml_WriteLine("            <APPLICATION-SW-COMPONENT-TYPE>")
	Arxml_WriteLine("              <SHORT-NAME>" & g_SelectedComponent.Name & "</SHORT-NAME>")

	if CUSTOM_ARXML_NAMESPACE <> "" then
		Arxml_WriteLine("              <" & CUSTOM_ARXML_NAMESPACE & ":GUID>" & g_SelectedComponent.ElementGUID & "</" & CUSTOM_ARXML_NAMESPACE & ":GUID>")
	end if
end function

Private Function Arxml_CreateSWComponent_end()
	Debug_Print("Arxml_CreateSWComponent_end")
	Arxml_WriteLine("            </APPLICATION-SW-COMPONENT-TYPE>")
end function

Private Function Arxml_CreateSWComponentPorts_loop()
	Debug_Print("Arxml_CreateSWComponentPorts_loop")
	Arxml_WriteLine("              <PORTS>")
	
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
		
		Debug_Print("    " & port.Name & ":" & port.Stereotype)
		if port.Stereotype = PPORT_SERVER             then 
			Arxml_WriteLine("                <P-PORT-PROTOTYPE>")
			Arxml_WriteLine("                  <SHORT-NAME>" & port.Name & "</SHORT-NAME>")
			if CUSTOM_ARXML_NAMESPACE <> "" then
				Arxml_WriteLine("                  <" & CUSTOM_ARXML_NAMESPACE & ":GUID>" & port.ElementGUID & "</" & CUSTOM_ARXML_NAMESPACE & ":GUID>")
			end if

			Arxml_WriteLine("                  <PROVIDED-COM-SPECS>")
			
		
			If Not swInterface Is Nothing Then
				Arxml_WriteLine("                    <SERVER-COM-SPEC>")
				'Todo Search for Operations
				Arxml_WriteLine("                    </SERVER-COM-SPEC>")
				Arxml_WriteLine("                  </PROVIDED-COM-SPECS>")
				Arxml_WriteLine("                  <PROVIDED-INTERFACE-TREF DEST=" & Chr(34) & "CLIENT-SERVER-INTERFACE" & Chr(34) & ">/" & _
																					g_SelectedComponent.Name & "_Package/PortInterfaces/" & swInterface.Name & _
																					"</PROVIDED-INTERFACE-TREF>")
				Arxml_WriteLine("                </P-PORT-PROTOTYPE>")
			
			end if
		
		elseif port.Stereotype = PPORT_SENDER         then
			
			Arxml_WriteLine("                <P-PORT-PROTOTYPE>")
			Arxml_WriteLine("                  <SHORT-NAME>" & port.Name & "</SHORT-NAME>")
			if CUSTOM_ARXML_NAMESPACE <> "" then
				Arxml_WriteLine("                  <" & CUSTOM_ARXML_NAMESPACE & ":GUID>" & port.ElementGUID & "</" & CUSTOM_ARXML_NAMESPACE & ":GUID>")
			end if

			Arxml_WriteLine("                  <PROVIDED-COM-SPECS>")
			
		
			If Not swInterface Is Nothing Then
				Arxml_WriteLine("                    <NONQUEUED-SENDER-COM-SPEC>")
				'Todo Search for Attributes
				Arxml_WriteLine("                    </NONQUEUED-SENDER-COM-SPEC>")
				Arxml_WriteLine("                  </PROVIDED-COM-SPECS>")
				Arxml_WriteLine("                  <PROVIDED-INTERFACE-TREF DEST=" & Chr(34) & "SENDER-RECEIVER-INTERFACE" & Chr(34) & ">/" & _
																					g_SelectedComponent.Name & "_Package/PortInterfaces/" & swInterface.Name & _
																					"</PROVIDED-INTERFACE-TREF>")
				Arxml_WriteLine("                </P-PORT-PROTOTYPE>")
			
			end if
			
			
		elseif port.Stereotype = PPORT_MDSW then
			arxmlPort = "<P-PORT-PROTOTYPE>"
			arxmlPortType = "<MODE-SWITCH-SENDER-COM-SPEC>"
			
			Arxml_WriteLine("                <P-PORT-PROTOTYPE>")
			Arxml_WriteLine("                  <SHORT-NAME>" & port.Name & "</SHORT-NAME>")
			if CUSTOM_ARXML_NAMESPACE <> "" then
				Arxml_WriteLine("                  <" & CUSTOM_ARXML_NAMESPACE & ":GUID>" & port.ElementGUID & "</" & CUSTOM_ARXML_NAMESPACE & ":GUID>")
			end if

			Arxml_WriteLine("                  <PROVIDED-COM-SPECS>")
			
		
			If Not swInterface Is Nothing Then
				Arxml_WriteLine("                    <MODE-SWITCH-SENDER-COM-SPEC>")
				'Todo Search for group declarations
				Arxml_WriteLine("                    </MODE-SWITCH-SENDER-COM-SPEC>")
				Arxml_WriteLine("                  </PROVIDED-COM-SPECS>")
				Arxml_WriteLine("                  <PROVIDED-INTERFACE-TREF DEST=" & Chr(34) & "MODE-SWITCH-INTERFACE" & Chr(34) & ">/" & _
																					g_SelectedComponent.Name & "_Package/PortInterfaces/" & swInterface.Name & _
																					"</PROVIDED-INTERFACE-TREF>")
				Arxml_WriteLine("                </P-PORT-PROTOTYPE>")
			
			end if
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
			arxmlPort = "<UNKNOWN-PORT-PROTOTYPE>"
			arxmlPortType = "<UNKNOWN-COM-SPEC>"
		end if

		

	
	next

	Arxml_WriteLine("              </PORTS>")

end function

Private Function Arxml_CreateSWComponentInternalBehaviors_loop()
	Debug_Print("Arxml_CreateSWComponentInternalBehaviors_loop")
	Arxml_WriteLine("              <INTERNAL-BEHAVIORS>")
	Arxml_WriteLine("                <SWC-INTERNAL-BEHAVIOR>")
	Arxml_WriteLine("                  <SHORT-NAME>" & g_SelectedComponent.Name & "_InternalBehavior</SHORT-NAME>")
	Arxml_WriteLine("                  <DATA-TYPE-MAPPING-REFS>")
	Arxml_WriteLine("                  </DATA-TYPE-MAPPING-REFS>")
	Arxml_WriteLine("                  <EXCLUSIVE-AREAS>")
	Arxml_WriteLine("                  </EXCLUSIVE-AREAS>")
	Arxml_WriteLine("                  <EVENTS>")
	Arxml_WriteLine("                    <INIT-EVENT>")
	Arxml_WriteLine("                    </INIT-EVENT>")
	Arxml_WriteLine("                  </EVENTS>")
	Arxml_WriteLine("                  <PORT-API-OPTIONS>")
	Arxml_WriteLine("                  </PORT-API-OPTIONS>")
	Arxml_WriteLine("                  <RUNNABLES>")
	Arxml_WriteLine("                  </RUNNABLES>")
	Arxml_WriteLine("                </SWC-INTERNAL-BEHAVIOR>")
	Arxml_WriteLine("              </INTERNAL-BEHAVIORS>")

end function

Private Function Arxml_CreateSWComponentModeSwitchInterface_loop()
	Debug_Print("Arxml_CreateSWComponentModeSwitchInterface_loop")
	Arxml_WriteLine("            <MODE-SWITCH-INTERFACE>")
	Arxml_WriteLine("            </MODE-SWITCH-INTERFACE>")

end function

Private Function Arxml_CreateSWComponentModeDeclarationGroup_loop()
	Debug_Print("Arxml_CreateSWComponentModeDeclarationGroup_loop")
	Arxml_WriteLine("            <MODE-DECLARATION-GROUP>")
	Arxml_WriteLine("            </MODE-DECLARATION-GROUP>")

end function

Private Function GetLinkedSwInterfaceElementId(thePort)

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
		Debug_Print(guid)

		Set eaConnector = Repository.GetConnectorByGuid(guid)
		Set swInterface = Repository.GetElementByID(eaConnector.SupplierID)
		If swInterface.Stereotype = SWIF_STEREOTYPE Then
			GetLinkedSwInterfaceElementId = eaConnector.SupplierID
		end if
	end if
	
	
End function


Private Function Arxml_WriteLine(line)

	if DBG_PRINT_SCREEN = True and DBG_PRINT_ARXML_OUTPUT = True then
		Session.Output(line)
	end if
	g_ArxmlFile.WriteLine line

end function

Private Function Debug_Print(line)

	if DBG_PRINT_SCREEN = True then
		Session.Output(line)
	end if

end function


main
