!INC Local Scripts.EAConstants-VBScript
!INC ARXML_Generation.Debug

'
' Script Name: 
' Author: 
' Purpose: 
' Date: 
'
Function XML_LoadXmlFromFile(filePath)
	Debug_Print "XML_LoadXmlFromFile", 1
    Dim xmlDoc
    Set xmlDoc = CreateObject("MSXML2.DOMDocument.6.0")
    
	xmlDoc.async = False
    xmlDoc.validateOnParse = False
    
    If Not xmlDoc.Load(filePath) Then
        Session.Output "XML File Load Error: " & xmlDoc.parseError.reason
        Set xmlDoc = Nothing
    End If
    
    Set XML_LoadXmlFromFile = xmlDoc
End Function

Function XML_LoadXmlFromString(xmlString)
	Debug_Print "XML_LoadXmlFromString", 1
    Dim xmlDoc
    Set xmlDoc = CreateObject("MSXML2.DOMDocument.6.0")
    
	xmlDoc.async = False
    xmlDoc.validateOnParse = False
	xmlDoc.resolveExternals = False
    
    If Not xmlDoc.loadXML(xmlString) Then
        Session.Output "XML File Load Error: " & xmlDoc.parseError.reason
        Set xmlDoc = Nothing
    End If
    
    Set XML_LoadXmlFromString = xmlDoc
End Function


Function XML_Readfile2String(filePath)
	Debug_Print "XML_Readfile2String", 1
	Dim fso, file
	dim xmlContent
	
	xmlContent = ""
	Set fso = CreateObject("Scripting.FileSystemObject")

	If fso.FileExists(filePath) Then
		Set file = fso.OpenTextFile(filePath, 1) ' 1 = ForReading
		' Read entire file into a string
		xmlContent = file.ReadAll
		file.Close
	else
		MsgBox "File do not exist" & chr(10) & filePath
		Session.Output "File do not exist"
	end if

    XML_Readfile2String = xmlContent
	
End Function