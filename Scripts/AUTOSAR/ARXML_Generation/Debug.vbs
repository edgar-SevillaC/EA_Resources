!INC Local Scripts.EAConstants-VBScript
!INC ARXML_Generation.Constants

'
' Script Name: 
' Author: Edgar Sevilla
' Purpose: Debug interfaces are defined here
' Date: 12.11.2025
'

Const DBG_PRINT_ENABLED = True
Const DBG_LEVEL = 1      ' Level of details [1 - 3]

' Debug Print
Private Function Debug_Print(line, level)
    If DBG_PRINT_ENABLED And level <= DBG_LEVEL Then
        Session.Output(line)
    End If
End Function

' Error Print
Dim g_ErrorCnt
Private Function Error_Print(line)
    g_ErrorCnt = g_ErrorCnt + 1
    Session.Output("#ERROR# (" & g_ErrorCnt & "): " & line)
End Function

' Warning Print
Dim g_WarningCnt
Private Function Warning_Print(line)
    g_WarningCnt = g_WarningCnt + 1
    Session.Output("#WARNING# (" & g_WarningCnt & "): " & line)
End Function
