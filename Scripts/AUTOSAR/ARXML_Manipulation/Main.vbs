option explicit

!INC Local Scripts.EAConstants-VBScript
!INC ARXML_Generation.Constants
!INC ARXML_Generation.ArxmlGeneration
!INC ARXML_Generation.ArxmlImport

'
' Script Name: 
' Author: Edgar Sevilla
' Purpose: The script is used for Manipulate arxml files
'          Export -> Generate Arxml from SW Component
'          Import -> Generate/Update SW Component from Arxml
'          Update -> Update selected Arxml with details from SWC Component
' Date: 14.04.2025
'
' Requisites:
'    Requires a Model with valid UML profile with valid tags
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
' (v2.0) [15.11.2025] : @Edgar Sevilla : User interface for selecting Path to store arxml file
'                                        Refactoring and split for separation of concerns (, minor fixes, readability improved
' (v2.1) [17.11.2025] : @Edgar Sevilla : minor Fixes, Procession of R-Ports, Reference to interfaces
'                                        in other packages
' (v2.2) [29.11.2025] : @Edgar Sevilla : Import functionality added, so model can be updated using ARXML file
'

'Software Component under analysis
dim g_SelectedComponent as EA.Element


sub main
	
	' Show the script output window
    Repository.EnsureOutputVisible "Script"
    Repository.ClearOutput( "Script" )
    Session.Output( "GenerateSwComponentArxml" )
    Session.Output( "   Author: " & SCRIPT_AUTHOR )
    Session.Output( "   version: " & SCRIPT_VERSION )
    Session.Output("start: " & Now )
    Session.Output("")


	dim optionSelected
	
	optionSelected = RequestUserSelection()
	
	if optionSelected = "E" then
		main_ArxmlExport
	elseif optionSelected = "I" then
		main_ArxmlImport
	elseif optionSelected = "U" then
		main_ArxmlUpdate
	else
		MsgBox "User pressed Cancel button or left the input empty"
		Session.Output "Aborted!"
		Exit sub
	end if

    Session.Output "Finished: " & Now
    Session.Output "Done!"
End Sub

Private Function RequestUserSelection()

			dim userInput
			userInput = InputBox( "Select [E]xport or [I]mport or [U]pdate", "Option", "E" )
			
			Session.Output( "User selection" )
			
			if userInput = "E" then
				Session.Output( "    Export" )
			elseif userInput = "I" then
				Session.Output( "    Import" )
			elseif userInput = "U" then
				Session.Output( "    Update" )
			elseif userInput = "" then
				Session.Output( "    User pressed Cancel button or left the input empty" )
			else
				userInput = "E"
				Session.Output( "    Export (Default)")
			end if
		
		RequestUserSelection = userInput

End Function

Private Function main_ArxmlExport()

    dim treeSelectedType
    treeSelectedType = Repository.GetTreeSelectedItemType()

    if treeSelectedType = otElement then
        set g_SelectedComponent = Repository.GetTreeSelectedObject()
        if g_SelectedComponent.Stereotype = SWC_STEREOTYPE then
		
			dim userfilePath
			dim CurrentDirectory
			dim filePath
			CurrentDirectory = Left(Repository.ConnectionString, InStrRev(Repository.ConnectionString, "\"))
			filePath = CurrentDirectory
			
			userfilePath = InputBox("Enter ARXML file path:", _
                                    "ARXML Generation (" & g_SelectedComponent.Name  & ".arxml)", _
									filePath)
			If userfilePath = "" Then
				MsgBox "User pressed Cancel button or left the input empty"
				Session.Output "User pressed Cancel button or left the input empty"
				Session.Output "Aborted!"
				Exit function
			End If
			
			Session.Output "    Target File: " & g_SelectedComponent.Name & ".arxml"
			Session.Output "    Target Path: " & userfilePath
			
			userfilePath = userfilePath & g_SelectedComponent.Name & ".arxml"
			
			'ToDo: Check path exists
			
            Arxml_CreateFile(userfilePath)
            Arxml_GenerationStart
            Arxml_CloseFile
			MsgBox "ARXML generation is done"
        else
            MsgBox "Not valid SW Component was selected " & Chr(10) & Chr(10) & "Select a valid SW Component in Project Browser and try again", vbCritical, "Error"
			Error_Print("Not valid SW Component was selected")
			Session.Output "Aborted!"
			Exit function
        end if
    else
        MsgBox "Not valid SW Component was selected " & Chr(10) & Chr(10) & "Select a valid SW Component in Project Browser and try again", vbCritical, "Error"
		Error_Print("Not valid SW Component was selected")
		Session.Output "Aborted!"
		Exit function
    end if

end Function


Private Function main_ArxmlImport()

	dim userfilePath
	dim CurrentDirectory
	dim filePath
	CurrentDirectory = Left(Repository.ConnectionString, InStrRev(Repository.ConnectionString, "\"))
	filePath = CurrentDirectory & DEFAULT_FILE_NAME
	
	userfilePath = InputBox("Enter ARXML file path:", _
							"ARXML Import", _
							filePath)
	If userfilePath = "" Then
		MsgBox "User pressed Cancel button or left the input empty"
		Session.Output "User pressed Cancel button or left the input empty"
		Session.Output "Aborted!"
		Exit Function
	End If
	
	Session.Output "    Input File: " & userfilePath
	'userfilePath = replace(userfilePath,"\","\\")

	
	'--------------------
    ImportArxml userfilePath
	MsgBox "ARXML import is done"

end Function

Private Function main_ArxmlUpdate()

end Function

main
