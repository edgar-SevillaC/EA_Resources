!INC Local Scripts.EAConstants-VBScript
!INC ARXML_Generation.Constants
'
' Script Name: 
' Author: 
' Purpose: 
' Date: 
'
' ================================
' Helper Functions
' ================================

Private Function Debug_Print(line, level)
    If DBG_PRINT_ENABLED And level <= DBG_LEVEL Then
        Session.Output(line)
    End If
End Function

Private Function AskUserConfirmation(msg)
    Dim result
    result = MsgBox(msg, vbYesNo + vbQuestion, "Confirm Action")
    AskUserConfirmation = (result = vbYes)
End Function

