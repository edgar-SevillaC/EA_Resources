option explicit

!INC Local Scripts.EAConstants-VBScript
!INC ARXML_Generation.Constants
!INC ARXML_Generation.ArxmlGeneration

'
' Script Name: 
' Author: Edgar Sevilla
' Purpose: Generate arxml file from a SW Component
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
				Exit sub
			End If
			
			Session.Output "    Target File: " & g_SelectedComponent.Name & ".arxml"
			Session.Output "    Target Path: " & userfilePath
			
			userfilePath = userfilePath & g_SelectedComponent.Name & ".arxml"
			
			'ToDo: Check path exists
			
            Arxml_CreateFile(userfilePath)
            Arxml_GenerationStart
            Arxml_CloseFile
        else
            MsgBox "Not valid SW Component was selected " & Chr(10) & Chr(10) & "Select a valid SW Component in Project Browser and try again", vbCritical, "Error"
			Error_Print("Not valid SW Component was selected")
			Session.Output "Aborted!"
			Exit sub
        end if
    else
        MsgBox "Not valid SW Component was selected " & Chr(10) & Chr(10) & "Select a valid SW Component in Project Browser and try again", vbCritical, "Error"
		Error_Print("Not valid SW Component was selected")
		Session.Output "Aborted!"
		Exit sub
    end if

    Session.Output "Finished: " & Now
    Session.Output "Done!"
	MsgBox "ARXML generation is done"
End Sub

main
