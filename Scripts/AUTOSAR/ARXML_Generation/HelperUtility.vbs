!INC Local Scripts.EAConstants-VBScript
!INC ARXML_Generation.Constants
'
' Script Name: 
' Author: Edgar Sevilla
' Purpose: Utility operations
' Date: 12.11.2025
'



' XML Write Line
Private Function Arxml_WriteLine(line)
    If DBG_PRINT_ENABLED And DBG_PRINT_ARXML_OUTPUT Then
        Session.Output(line)
    End If
    g_ArxmlFile.WriteLine line
End Function

' ================================
' XML Helper Utilities
' ================================
Function XmlTag(tagName, content, indent)
    XmlTag = indent & "<" & tagName & ">" & content & "</" & tagName & ">"
End Function

Function XmlTagAndData(tagName, content, extraString, indent)
    XmlTagAndData = indent & "<" & tagName & " " & extraString & ">" & content & "</" & tagName & ">"
End Function

Function XmlOpenTag(tagName, indent)
    XmlOpenTag = indent & "<" & tagName & ">"
End Function

Function XmlOpenTagAndData(tagName, extraString, indent)
    XmlOpenTagAndData = indent & "<" & tagName & " " & extraString & ">"
End Function

Function XmlCloseTag(tagName, indent)
    XmlCloseTag = indent & "</" & tagName & ">"
End Function

Function XmlTagComment(tagName, comment, indent)
    XmlTagComment = indent & "<!--" & tagName & ">" & comment & "</" & tagName & "-->"
End Function
