!INC Local Scripts.EAConstants-VBScript
!INC ARXML_Generation.Constants
!INC ARXML_Generation.Debug
!INC ARXML_Generation.HelperUtility

'
' Script Name: ArxmlGeneration
' Author: Edgar Sevilla
' Purpose: ARXML generation based on EA model
' Date: 12.11.2025
'

'File
Dim fso
dim g_ArxmlFile

Private Function Arxml_CreateFile(filePath)
    Debug_Print "Arxml_CreateFile", 1

    Set fso = CreateObject("Scripting.FileSystemObject")
    Set g_ArxmlFile = fso.CreateTextFile(filePath, True)
    
end function

Private Function Arxml_CloseFile()
    Debug_Print "Arxml_CloseFile", 1
    g_ArxmlFile.Close
End Function

Private Function Arxml_GenerationStart()
    Debug_Print "Arxml_GenerationStart", 1
    
    dim customNameSpace
    dim autosarNameSpace
    
    if CUSTOM_ARXML_NAMESPACE <> "" then
        customNameSpace = "xmlns:" & CUSTOM_ARXML_NAMESPACE & "=" & _
                            Chr(34) & CUSTOM_ARXML_SCHEMA & Chr(34) & Chr(10)
    else
        customNameSpace = ""
    end if

    '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    '+              Write ARXML headers                         +
    Arxml_WriteLine("<?xml version=" & Chr(34) & "1.0" & Chr(34) & _
                    " encoding="  & Chr(34) & "utf-8"  & Chr(34) & "?>")
    
    autosarNameSpace = "xmlns=" & Chr(34) & AUTOSAR_SCHEMA & Chr(34) & Chr(10) & _
                       "xmlns:xsi=" & Chr(34) & AUTOSAR_SCHEMA_INST & Chr(34) & Chr(10) & _
                       customNameSpace & _
                       "xsi:schemaLocation=" & Chr(34) & AUTOSAR_SCHEMA_XSD & Chr(34)
                       
    
    autosarNameSpace = XmlOpenTagAndData("AUTOSAR", autosarNameSpace, IDENT_00)
    Arxml_WriteLine autosarNameSpace
    '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


    ' Main Package
    Arxml_CreateMainARPackage

    ' Close AUTOSAR
    '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    '+                    Terminate ARXML Tag                   +
    Arxml_WriteLine XmlCloseTag("AUTOSAR", IDENT_00)
    '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    
End Function

Private Function Arxml_CreateMainARPackage()
    Debug_Print "Arxml_CreateSWComponentPackage", 1
    
    '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    '+                Create AR-Packages  
    Arxml_WriteLine XmlOpenTag("AR-PACKAGES", IDENT_01)
    Arxml_WriteLine XmlOpenTag("AR-PACKAGE", IDENT_02)
    Arxml_WriteLine XmlTag("SHORT-NAME", g_SelectedComponent.Name & PACKAGE_SUFFIX, IDENT_03)
    Arxml_WriteLine XmlOpenTag("AR-PACKAGES", IDENT_03)
    '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    ' Nested packages
    Arxml_CreateComponentTypePackage
    Arxml_CreateCompuMethodsPackage
    Arxml_CreatePortInterfacesPackage

    '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    '+                    Terminate ARXML Tag                   +
    Arxml_WriteLine XmlCloseTag("AR-PACKAGES", IDENT_03)
    Arxml_WriteLine XmlCloseTag("AR-PACKAGE", IDENT_02)
    Arxml_WriteLine XmlCloseTag("AR-PACKAGES", IDENT_01)
    '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
End Function

Private Function Arxml_CreateComponentTypePackage()
    Debug_Print "Arxml_CreateComponentTypePackage", 1
    
    '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    '+                Create SWC-Package                        +
    Arxml_WriteLine XmlOpenTag("AR-PACKAGE", IDENT_04)
    Arxml_WriteLine XmlTag("SHORT-NAME", "ComponentTypes", IDENT_05)
    Arxml_WriteLine XmlOpenTag("ELEMENTS", IDENT_05)

    'Next Envelop
    Arxml_CreateSWComponent
    Arxml_CreateSWComponentModeSwitchInterface_loop
    Arxml_CreateSWComponentModeDeclarationGroup_loop

    '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    '+                    Terminate ARXML Tag                   +
    Arxml_WriteLine XmlCloseTag("ELEMENTS", IDENT_05)
    Arxml_WriteLine XmlCloseTag("AR-PACKAGE", IDENT_04)
    '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    
end function

Private Function Arxml_CreateCompuMethodsPackage()
    Debug_Print "Arxml_CreateCompuMethodsPackage", 1
    
    '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    '+                Create CompuMethods Package               +
    Arxml_WriteLine XmlOpenTag("AR-PACKAGE", IDENT_04)
    Arxml_WriteLine XmlTag("SHORT-NAME", "CompuMethods", IDENT_05)
    '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    
    'Next envelop
    'ToDo: Add Compu Methods
    
    '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    '+                    Terminate ARXML Tag                   +
    Arxml_WriteLine XmlCloseTag("AR-PACKAGE", IDENT_04)
    '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
End Function

Private Function Arxml_CreatePortInterfacesPackage()
    Debug_Print "Arxml_CreatePortInterfacesPackage", 1
    
    '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    '+                Create PortInterfaces Package             +
    Arxml_WriteLine XmlOpenTag("AR-PACKAGE", IDENT_04)
    Arxml_WriteLine XmlTag("SHORT-NAME", "PortInterfaces", IDENT_05)
    Arxml_WriteLine XmlOpenTag("ELEMENTS", IDENT_05)
    '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    
    'Next Envelops
    PortInterfacesExtract
    
    '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    '+                    Terminate ARXML Tag                   +
    Arxml_WriteLine XmlCloseTag("ELEMENTS", IDENT_05)
    Arxml_WriteLine XmlCloseTag("AR-PACKAGE", IDENT_04)
    '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

end function



Private Function Arxml_PortInterfacesPPortServer(swIf)

    Debug_Print "Arxml_PortInterfacesPPortServer", 1
    
    dim swInterface as EA.Element
    set swInterface = swIf
    
    '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    '+                Create Client-Server Interface            +
    Arxml_WriteLine XmlOpenTag("CLIENT-SERVER-INTERFACE", IDENT_06)
    Arxml_WriteLine XmlTag("SHORT-NAME", swInterface.Name, IDENT_07)
    
    if CUSTOM_ARXML_NAMESPACE <> "" then
        Arxml_WriteLine XmlTag(CUSTOM_ARXML_TRACEABILITY_TAG, swInterface.ElementGUID, IDENT_07)
    else
        Arxml_WriteLine XmlTagComment(CUSTOM_ARXML_TRACEABILITY_TAG, swInterface.ElementGUID, IDENT_09)
    end if
    
    Arxml_WriteLine XmlTag("IS-SERVICE", "false", IDENT_07)
    Arxml_WriteLine XmlOpenTag("OPERATIONS", IDENT_07)
    '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    
    'Next Envelop
    PortInterfacesOperationsExtract(swIf)
    
    '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    '+                    Terminate ARXML Tag                   +
    Arxml_WriteLine XmlCloseTag("OPERATIONS", IDENT_07)
    Arxml_WriteLine XmlCloseTag("CLIENT-SERVER-INTERFACE", IDENT_06)
    '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

end function

Private Function Arxml_PortInterfacesPPortSender(swIf)

    Debug_Print "Arxml_PortInterfacesPPortSender", 1
    
    dim swInterface as EA.Element
    set swInterface = swIf

    '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    '+                Create Sender-Receiver Interface          +
    Arxml_WriteLine XmlOpenTag("SENDER-RECEIVER-INTERFACE", IDENT_06)
    Arxml_WriteLine XmlTag("SHORT-NAME", swInterface.Name, IDENT_07)
    
    if CUSTOM_ARXML_NAMESPACE <> "" then
        Arxml_WriteLine XmlTag(CUSTOM_ARXML_TRACEABILITY_TAG, swInterface.ElementGUID, IDENT_07)
    else
        Arxml_WriteLine XmlTagComment(CUSTOM_ARXML_TRACEABILITY_TAG, swInterface.ElementGUID, IDENT_09)
    end if
    
    Arxml_WriteLine XmlTag("IS-SERVICE", "false", IDENT_07)
    Arxml_WriteLine XmlOpenTag("DATA-ELEMENTS", IDENT_07)
    '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    
    'Next Envelop
    PortInterfacesDataElementExtract(swIf)

    '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    '+                    Terminate ARXML Tag                   +
    Arxml_WriteLine XmlCloseTag("DATA-ELEMENTS", IDENT_07)
    Arxml_WriteLine XmlCloseTag("SENDER-RECEIVER-INTERFACE", IDENT_06)
    '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

end function

Private Function Arxml_PortInterfacesPPortModeSwitch(swIf)

    Debug_Print "Arxml_PortInterfacesPPortModeSwitch", 1
    
    dim swInterface as EA.Element
    set swInterface = swIf

    '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    '+                Create Sender-Receiver Interface          +
    Arxml_WriteLine XmlOpenTag("MODE-SWITCH-INTERFACE", IDENT_06)
    Arxml_WriteLine XmlTag("SHORT-NAME", swInterface.Name, IDENT_07)
    
    if CUSTOM_ARXML_NAMESPACE <> "" then
        Arxml_WriteLine XmlTag(CUSTOM_ARXML_TRACEABILITY_TAG, swInterface.ElementGUID, IDENT_07)
    else
        Arxml_WriteLine XmlTagComment(CUSTOM_ARXML_TRACEABILITY_TAG, swInterface.ElementGUID, IDENT_09)
    end if
    
    Arxml_WriteLine XmlTag("IS-SERVICE", "false", IDENT_07)
    Arxml_WriteLine XmlOpenTag("MODE-GROUP", IDENT_07)
    '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    
    'Next Envelop
    'ToDo: Get Mode Groups

    '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    '+                    Terminate ARXML Tag                   +
    Arxml_WriteLine XmlCloseTag("MODE-GROUP", IDENT_07)
    Arxml_WriteLine XmlCloseTag("MODE-SWITCH-INTERFACE", IDENT_06)
    '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

end function


Private Function Arxml_PortInterfaceOperations(Oper)

    Debug_Print "Arxml_PortInterfaceOperations", 1
    
    dim operation as EA.Method
    set operation = Oper
    
    '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    '+                Create Client-Server Operation            +
    Arxml_WriteLine XmlOpenTag("CLIENT-SERVER-OPERATION", IDENT_08)
    Arxml_WriteLine XmlTag("SHORT-NAME", operation.Name, IDENT_09)
    
    if CUSTOM_ARXML_NAMESPACE <> "" then
        Arxml_WriteLine XmlTag(CUSTOM_ARXML_TRACEABILITY_TAG, operation.MethodGUID, IDENT_07)
    else
        Arxml_WriteLine XmlTagComment(CUSTOM_ARXML_TRACEABILITY_TAG, operation.MethodGUID, IDENT_09)
    end if
    
    Arxml_WriteLine XmlOpenTag("ARGUMENTS", IDENT_09)

    '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    'Next Envelop
    PortInterfacesOperationParametersExtract(operation)
    
    
    '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    '+                    Terminate ARXML Tag                   +
    Arxml_WriteLine XmlCloseTag("ARGUMENTS", IDENT_09)
    Arxml_WriteLine XmlCloseTag("CLIENT-SERVER-OPERATION", IDENT_08)
    '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    
end function

Private Function Arxml_PortInterfaceOperationParameter(paramName, paramType, paramDir)
    Debug_Print "Arxml_PortInterfaceOperations", 1
    
    '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    '+                  Create Argumet prototype (Parameters)   +
    Arxml_WriteLine XmlOpenTag("ARGUMENT-DATA-PROTOTYPE", IDENT_09)
    Arxml_WriteLine XmlTag("SHORT-NAME", paramName, IDENT_10)
    
    'ToDo: find reference the the datatype
    Arxml_WriteLine XmlTagAndData("TYPE-TREF",paramType,"DEST=" & Chr(34) & "IMPLEMENTATION-DATA-TYPE" & Chr(34), IDENT_10)

    Arxml_WriteLine XmlTag("DIRECTION", UCase(paramDir), IDENT_10)
    Arxml_WriteLine XmlCloseTag("ARGUMENT-DATA-PROTOTYPE", IDENT_09)
    '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    
end function

Private Function Arxml_PortInterfaceDataElement(Att)

    Debug_Print "Arxml_PortInterfaceDataElement", 1
    
    dim attribute as EA.Attribute
    set attribute = Att
    
    '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    '+                Create VariableData                       +
    Arxml_WriteLine XmlOpenTag("VARIABLE-DATA-PROTOTYPE", IDENT_08)
    Arxml_WriteLine XmlTag("SHORT-NAME", attribute.Name, IDENT_09)
    Arxml_WriteLine XmlTagAndData("TYPE-TREF","ADD REFERENCE (TBD)","DEST=" & Chr(34) & "IMPLEMENTATION-DATA-TYPE" & Chr(34), IDENT_09)
    '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


    
    '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    '+                    Terminate ARXML Tag                   +
    Arxml_WriteLine XmlCloseTag("VARIABLE-DATA-PROTOTYPE", IDENT_08)
    '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    
end function






Private Function Arxml_CreateSWComponent()
    Debug_Print "Arxml_CreateSWComponent", 1
    
    dim componentType
    componentType = IdentifySwComponentType()
    
    '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    '+                Create CompuMethods Package               +
    Arxml_WriteLine XmlOpenTag(componentType, IDENT_06)
    Arxml_WriteLine XmlTag("SHORT-NAME", g_SelectedComponent.Name, IDENT_07)
        
    if CUSTOM_ARXML_NAMESPACE <> "" then
        Arxml_WriteLine XmlTag(CUSTOM_ARXML_TRACEABILITY_TAG, g_SelectedComponent.ElementGUID, IDENT_07)
    else
        Arxml_WriteLine XmlTagComment(CUSTOM_ARXML_TRACEABILITY_TAG, g_SelectedComponent.ElementGUID, IDENT_09)
    end if
    
    Arxml_WriteLine XmlOpenTag("PORTS", IDENT_07)
    '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    
    'Next Evelop
    PortPrototypeExtract
    InternalBehaviorExtract
    
    '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    '+                    Terminate ARXML Tag                   +
    Arxml_WriteLine XmlCloseTag("PORTS", IDENT_07)
    Arxml_WriteLine XmlCloseTag(componentType, IDENT_06)
    '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    
end function




Private Function Arxml_InternalBehavior()
    Debug_Print "Arxml_InternalBehavior", 1
    
    '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    '+              Create Internal Behaviors                   +
    Arxml_WriteLine XmlOpenTag("INTERNAL-BEHAVIORS", IDENT_07)
    Arxml_WriteLine XmlOpenTag("SWC-INTERNAL-BEHAVIOR", IDENT_08)
    Arxml_WriteLine XmlTag("SHORT-NAME", g_SelectedComponent.Name & "_InternalBehavior", IDENT_09)
    Arxml_WriteLine XmlOpenTag("DATA-TYPE-MAPPING-REFS", IDENT_09)
    Arxml_WriteLine XmlCloseTag("DATA-TYPE-MAPPING-REFS", IDENT_09)
    Arxml_WriteLine XmlOpenTag("EXCLUSIVE-AREAS", IDENT_09)
    Arxml_WriteLine XmlCloseTag("EXCLUSIVE-AREAS", IDENT_09)
    '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    
    Arxml_WriteLine XmlOpenTag("EVENTS", IDENT_09)
    
    'Next Envelop
    'ToDo: Extract Events
        Arxml_WriteLine XmlOpenTag("INIT-EVENT", IDENT_10)
        Arxml_WriteLine XmlCloseTag("INIT-EVENT", IDENT_10)
    
    Arxml_WriteLine XmlCloseTag("EVENTS", IDENT_09)
    
    Arxml_WriteLine XmlOpenTag("PORT-API-OPTIONS", IDENT_09)
    Arxml_WriteLine XmlCloseTag("PORT-API-OPTIONS", IDENT_09)
    Arxml_WriteLine XmlOpenTag("RUNNABLES", IDENT_09)
    
    'Next Envelop
    'ToDo: Extract Events
    
    Arxml_WriteLine XmlCloseTag("RUNNABLES", IDENT_09)
    '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    '+                    Terminate ARXML Tag                   +
    Arxml_WriteLine XmlCloseTag("SWC-INTERNAL-BEHAVIOR", IDENT_08)
    Arxml_WriteLine XmlCloseTag("INTERNAL-BEHAVIORS", IDENT_07)
    '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    
end function

Private Function Arxml_CreateSWComponentModeSwitchInterface_loop()
    Debug_Print "Arxml_CreateSWComponentModeSwitchInterface_loop", 1
    
    Arxml_WriteLine XmlOpenTag("MODE-SWITCH-INTERFACE", IDENT_06)
    Arxml_WriteLine XmlCloseTag("MODE-SWITCH-INTERFACE", IDENT_06)

end function

Private Function Arxml_CreateSWComponentModeDeclarationGroup_loop()
    Debug_Print "Arxml_CreateSWComponentModeDeclarationGroup_loop", 1
    
    Arxml_WriteLine XmlOpenTag("MODE-DECLARATION-GROUP", IDENT_06)
    Arxml_WriteLine XmlCloseTag("MODE-DECLARATION-GROUP", IDENT_06)

end function


Private Function Arxml_PortPrototypePPort(swPort, swIf)
    Debug_Print "Arxml_PortPrototypePPortServer", 1
    
    dim port as EA.Element
    dim swInterface as EA.Element
    set port = swPort
    set swInterface = swIf
    
    '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    '+                Create P-Port Prototype                   +
    Arxml_WriteLine XmlOpenTag("P-PORT-PROTOTYPE", IDENT_08)
    Arxml_WriteLine XmlTag("SHORT-NAME", port.Name, IDENT_09)
    
    if CUSTOM_ARXML_NAMESPACE <> "" then
        Arxml_WriteLine XmlTag(CUSTOM_ARXML_TRACEABILITY_TAG, port.ElementGUID, IDENT_09)
    else
        Arxml_WriteLine XmlTagComment(CUSTOM_ARXML_TRACEABILITY_TAG, port.ElementGUID, IDENT_09)
    end if

    Arxml_WriteLine XmlOpenTag("PROVIDED-COM-SPECS", IDENT_09)
    '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    
    'Next Evelops / Operations / Attributes / Modes
    
    dim interfaceType
    dim interfacePath
    
    If Not swInterface Is Nothing Then
        
        if port.Stereotype = PPORT_SERVER then
            
            'Search for Opperations
            PortPrototypeIfOperationsExtract swPort, swInterface
            
            interfaceType = "CLIENT-SERVER-INTERFACE"
            interfacePath = "/" & g_SelectedComponent.Name & PACKAGE_SUFFIX &"/PortInterfaces/" & swInterface.Name

        elseif port.Stereotype = PPORT_SENDER then
        
            'Search for Attributes
            PortPrototypeIfAttributesExtract swPort, swInterface
            
            interfaceType = "SENDER-RECEIVER-INTERFACE"
            interfacePath = "/" & g_SelectedComponent.Name & PACKAGE_SUFFIX &"/PortInterfaces/" & swInterface.Name
        
        elseif port.Stereotype = PPORT_MDSW then
        
            'Todo: Search for Modes
            Arxml_WriteLine XmlOpenTag("MODE-SWITCH-SENDER-COM-SPEC", IDENT_10)
            Arxml_WriteLine XmlTagComment("MODE_SW" , "ToDo in future", IDENT_11)
            Arxml_WriteLine XmlCloseTag("MODE-SWITCH-SENDER-COM-SPEC", IDENT_10)
            
            interfaceType = "MODE-SWITCH-INTERFACE"
            interfacePath = "/" & g_SelectedComponent.Name & PACKAGE_SUFFIX &"/PortInterfaces/" & swInterface.Name
        
        else
            interfaceType = ""
            interfacePath = ""
        end if
        
    end if


    '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    '+                    Terminate ARXML Tag                   +
    Arxml_WriteLine XmlCloseTag("PROVIDED-COM-SPECS", IDENT_09)
    Arxml_WriteLine XmlTagAndData("PROVIDED-INTERFACE-TREF", interfacePath, "DEST=" & Chr(34) & interfaceType & Chr(34), IDENT_09)
    Arxml_WriteLine XmlCloseTag("P-PORT-PROTOTYPE", IDENT_08)
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
                                          "/" & g_SelectedComponent.Name & PACKAGE_SUFFIX & "/PortInterfaces/" & ifName & "/" & _
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
                                          "/" & g_SelectedComponent.Name & PACKAGE_SUFFIX & "/PortInterfaces/" & ifName & "/" & _
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
        Debug_Print "    " & port.Name & ":" & port.Stereotype, 1
        
        'Search for Linked SW Interfaces
        swInterfaceId = GetLinkedSwInterfaceElementId(port)
        Debug_Print "swInterfaceId " & swInterfaceId, 3
        
        
        if swInterfaceId <> 0 then
            Set swInterface = Repository.GetElementByID(swInterfaceId)
        
            If  Not swInterface Is Nothing Then
            
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
        componentType = "APPLICATION-SW-COMPONENT-TYPE"
    elseif componentType = COMPONENT_TYPE_CDD then
        componentType = "COMPLEX-DEVICE-DRIVER-SW-COMPONENT-TYPE"
    else
        Error_Print("No valid SW Component type : '" & componentType & "' : Arxml_CreateSWComponent_start")
        componentType = "UNKNOWN-SW-COMPONENT-TYPE"
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