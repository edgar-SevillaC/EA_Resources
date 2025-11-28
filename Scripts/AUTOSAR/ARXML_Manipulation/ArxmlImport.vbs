
!INC Local Scripts.EAConstants-VBScript
!INC ARXML_Generation.Constants
!INC ARXML_Generation.Helpers
!INC ARXML_Generation.Xml
!INC ARXML_Generation.Debug
'
' Script Name: 
' Author: 
' Purpose: 
' Date: 
'
' ================================
' ARXML Import Logic
' ================================

Dim g_XmlDoc

'Software Component under analysis
dim g_SwComponent as EA.Element

Function ImportArxml(filePath)
	Debug_Print "ImportArxml", 1

	Debug_Print "Arxml file: " & filePath, 2
	
	'------------------------
	dim xmlString
	xmlString = XML_Readfile2String(filePath)
	
	xmlString = replace(xmlString,"xmlns=" & chr(34) & "http://autosar.org/schema/r4.0" & Chr(34),"")
	Session.Output xmlString

	' Load ARXML using string
	set g_XmlDoc = XML_LoadXmlFromString(xmlString)
	'------------------------

    ' Load ARXML using file
'	set g_XmlDoc = XML_LoadXmlFromFile(filePath)
	
	
	
    If g_XmlDoc Is Nothing Then
        Error_Print "Failed to load ARXML file."
        Exit Function
	else
		Debug_Print "file correctly loaded", 2
    End If
	

	' Enable XPath selection
	g_XmlDoc.setProperty "SelectionLanguage", "XPath"

	' Declare namespaces for XPath queries
	g_XmlDoc.setProperty "SelectionNamespaces", _
		"xmlns:ea='https://sparxsystems.com/schema/ea'"

    ' Process SW Components
    SearchForSwComponents("APPLICATION-SW-COMPONENT-TYPE")
    SearchForSwComponents("COMPLEX-DEVICE-DRIVER-SW-COMPONENT-TYPE")
	
End Function


Function SearchForSwComponents(componentTypeNode)
	
	' "APPLICATION-SW-COMPONENT-TYPE"
	' "COMPLEX-DEVICE-DRIVER-SW-COMPONENT-TYPE"
	Debug_Print "SearchForSwComponents: ", 1

    Dim swComponents
	Dim swcType
	Set swComponents = g_XmlDoc.selectNodes("//" & componentTypeNode)
	
	if componentTypeNode = "APPLICATION-SW-COMPONENT-TYPE" then
		swcType = "APP-SWC"
	elseif componentTypeNode = "COMPLEX-DEVICE-DRIVER-SW-COMPONENT-TYPE" then
		swcType = "CDD-SWC"
	else
		swcType = "Unknown"
	end if
	
	'Session.Output "swComponents.Count: " & swComponents.Count
    Dim swc
    For Each swc In swComponents

        Dim swcName, guidValue
        swcName = swc.SelectSingleNode("SHORT-NAME").Text
        guidValue = swc.SelectSingleNode("ea:GUID").Text
		'node.getAttribute("id")
		Debug_Print "swcName: " & swcName, 1
		Debug_Print "guidValue: " & guidValue, 1
        Dim swcElement
        If guidValue <> "" Then
            On Error Resume Next
            Set g_SwComponent = Repository.GetElementByGuid(guidValue)
							
            On Error GoTo 0
            If g_SwComponent Is Nothing Then
                If AskUserConfirmation("GUID not found. Create new SW Component '" & swcName & "'?") Then
					CreateSwComponent swcName,swcType
                End If
            Else
				Session.Output "SWC already exists"
                UpdateSwComponent swcName, swcType
            End If
        Else
            Set swcElement = CreateSwComponent(swcName)
        End If

        ' Process Ports for this SW Component
        If Not g_SwComponent Is Nothing Then
            ImportPPorts swc
			ImportRPorts swc
        End If
    Next
end function

Function UpdateSwComponent(swcName, swcType)
	Debug_Print "UpdateSwComponent", 1
	
	if swcName <> g_SwComponent.Name then
		g_SwComponent.Name = swcName
		g_SwComponent.Update
		Debug_Print "Component Name was updated: " & g_SwComponent.Name, 1
	end if
	
	dim tag As EA.TaggedValue
	
	Set tag = g_SwComponent.TaggedValues.GetByName(COMPONENT_TYPE_TAG)
    If Not tag Is Nothing Then
		
		Debug_Print "swcType: " & swcType, 1
		
		If swcType = "APP-SWC" and swcType <> "Unknown" then
			if tag.Value <> "APP (AUTOSAR)" then
				tag.Value = "APP (AUTOSAR)"
				tag.Update
				g_SwComponent.Update
				Debug_Print "Component type was updated: " & tag.Value, 1
			end if
		elseif swcType = "CDD-SWC" and swcType <> "Unknown" then
			if tag.Value <> "CDD (AUTOSAR)" and swcType <> "Unknown" then
				tag.Value = "CDD (AUTOSAR)"
				tag.Update
				g_SwComponent.Update
				Debug_Print "Component type was updated: " & tag.Value, 1
			end if
		else
			
			Warning_Print "Unknown Type: " & swcType, 1
			
		end if
	else
        'ToDo: Create missing Tag value
    End If
	
end function

Function CreateSwComponent(swcName, swcType)
	Debug_Print "UpdateSwComponent", 1
	
    Dim rootPkg
	Set rootPkg = Repository.Models.GetAt(0)
	
	Dim newPkg
    Set newPkg = rootPkg.Packages.AddNew("NewPackage_" & swcName, "Package")
    newPkg.Update
    rootPkg.Packages.Refresh
	
    Set g_SwComponent = newPkg.Elements.AddNew(swcName, "Component")
    g_SwComponent.Stereotype = SWC_STEREOTYPE
    g_SwComponent.Update
	newPkg.Update
	
	
	'Repository.RefreshModelView newPkg.PackageID
	Set g_SwComponent = Repository.GetElementByID(g_SwComponent.ElementID)

	dim tag As EA.TaggedValue
	
	Set tag = g_SwComponent.TaggedValues.GetByName(COMPONENT_TYPE_TAG)
    If Not tag Is Nothing Then
		If swcType = "APP-SWC" then
			tag.Value = "APP (AUTOSAR)"
		elseif swcType = "CDD-SWC" then
			tag.Value = "CDD (AUTOSAR)"
		else
			tag.Value = "APP (AUTOSAR)"
		end if
		tag.Update
		Debug_Print tag.Name & ":" & tag.Value, 1
		g_SwComponent.Update
	end if
	
    Debug_Print "Created SW Component: " & swcName, 1
	Debug_Print "Path : /" & rootPkg.Name & "/" & newPkg.Name, 1
	
End Function


Function ImportPPorts(swcNode)
	Debug_Print "ImportPPorts", 1
    Dim ports
    Set ports = swcNode.selectNodes(".//P-PORT-PROTOTYPE")
    Dim portNode
    For Each portNode In ports
        Dim portName
		Dim guidValue
		
        portName = portNode.SelectSingleNode("SHORT-NAME").Text
        guidValue = portNode.SelectSingleNode("ea:GUID").Text
		
		Debug_Print "portName " & portName, 2
		Debug_Print "guidValue " & guidValue, 2

        Dim portElement
        If guidValue <> "" Then
            
            Set portElement = Repository.GetElementByGuid(guidValue)
            
            If portElement Is Nothing Then
                If AskUserConfirmation("Create new Port '" & portName & "'?") Then
					
					Dim portTypeNode
					Set portTypeNode = portNode.selectNodes("//SERVER-COM-SPEC")
					if Not portTypeNode is Nothing then
						Set portElement = CreatePort(g_SwComponent, portName, PPORT_SERVER)
					end if
				
'					Set portTypeNode = portNode.selectNodes(".//NONQUEUED-SENDER-COM-SPEC")
'					if Not portTypeNode is Nothing then
'						Set portElement = CreatePort(g_SwComponent, portName, PPORT_SENDER)
'					end if
'					
'					Set portTypeNode = portNode.selectNodes(".//MODE-SWITCH-SENDER-COM-SPEC")
'					if Not portTypeNode is Nothing then
'						Set portElement = CreatePort(g_SwComponent, portName, PPORT_SENDER)
'					end if
                    
                End If
            Else
				Debug_Print "portElement.Name " & portElement.Name, 2
				if portElement.Name <> portName then
					portElement.Name = portName
					portElement.Update
					g_SwComponent.Update
					Debug_Print "Component portName was updated: " & portName, 1
				end if
			End If
        Else
            Set portElement = CreatePort(g_SwComponent, portName, PPORT_SERVER)
        End If

        ' If Client-Server interface, import operations
        If Not portElement Is Nothing Then
            ImportClientServerOperations portNode, portElement
        End If
    Next
End Function

Function ImportRPorts(swcNode)
	Debug_Print "ImportRPorts", 1
    Dim ports
    Set ports = swcNode.selectNodes(".//R-PORT-PROTOTYPE")
    Dim portNode
    For Each portNode In ports
        Dim portName
		Dim guidValue
		
        portName = portNode.SelectSingleNode("SHORT-NAME").Text
        guidValue = portNode.SelectSingleNode("ea:GUID").Text
		
		Debug_Print "portName " & portName, 2
		Debug_Print "guidValue " & guidValue, 2

        Dim portElement
        If guidValue <> "" Then
            
            Set portElement = Repository.GetElementByGuid(guidValue)
            
            If portElement Is Nothing Then
                If AskUserConfirmation("Create new Port '" & portName & "'?") Then
					
					Dim portTypeNode
					Set portTypeNode = portNode.selectNodes("//CLIENT-COM-SPEC")
					if Not portTypeNode is Nothing then
						Set portElement = CreatePort(g_SwComponent, portName, RPORT_CLIENT)
					end if
				
'					Set portTypeNode = portNode.selectNodes(".//NONQUEUED-RECEIVER-COM-SPEC")
'					if Not portTypeNode is Nothing then
'						Set portElement = CreatePort(g_SwComponent, portName, PPORT_SENDER)
'					end if
'					
'					Set portTypeNode = portNode.selectNodes(".//MODE-SWITCH-RECEIVER-COM-SPEC")
'					if Not portTypeNode is Nothing then
'						Set portElement = CreatePort(g_SwComponent, portName, PPORT_SENDER)
'					end if
                    
                End If
            Else
				Debug_Print "portElement.Name " & portElement.Name, 2
				if portElement.Name <> portName then
					portElement.Name = portName
					portElement.Update
					g_SwComponent.Update
					Debug_Print "Component portName was updated: " & portName, 1
				end if
			End If
        Else
            Set portElement = CreatePort(g_SwComponent, portName, RPORT_CLIENT)
        End If

        ' If Client-Server interface, import operations
        If Not portElement Is Nothing Then
            ImportClientServerOperations portNode, portElement
        End If
    Next
End Function

Function CreatePort(parentElement, name, stereotype)
	Debug_Print "CreatePort", 1
    Dim newPort
    Set newPort = parentElement.Elements.AddNew(name, "Port")
    newPort.Stereotype = stereotype
    newPort.Update
    Session.Output "Created Port: " & name
    Set CreatePort = newPort
End Function

Function ImportClientServerOperations(portNode, portElement)
	Debug_Print "ImportClientServerOperations", 1
    Dim operations
    Set operations = portNode.selectNodes(".//CLIENT-SERVER-OPERATION")
    Dim opNode
    For Each opNode In operations
        Dim opName
        opName = XMLGetNodeText(g_XmlDoc, opNode.selectSingleNode("SHORT-NAME").xpath)
        Dim newOp
        Set newOp = portElement.Methods.AddNew(opName, "")
        newOp.Update
        Session.Output "Added Operation: " & opName
    Next
End Function

Function ImportSenderReceiverPortInterface(portNode, portElement)
	Debug_Print "ImportClientServerOperations", 1
    Dim operations
    Set operations = portNode.selectNodes(".//CLIENT-SERVER-OPERATION")
    Dim opNode
    For Each opNode In operations
        Dim opName
        opName = XMLGetNodeText(g_XmlDoc, opNode.selectSingleNode("SHORT-NAME").xpath)
        Dim newOp
        Set newOp = portElement.Methods.AddNew(opName, "")
        newOp.Update
        Session.Output "Added Operation: " & opName
    Next
End Function