Attribute VB_Name = "modExceptionMethods"
'    CopyRight (c) 2004 Kelly Ethridge
'
'    This file is part of VBCorLib.
'
'    VBCorLib is free software; you can redistribute it and/or modify
'    it under the terms of the GNU Library General Public License as published by
'    the Free Software Foundation; either version 2.1 of the License, or
'    (at your option) any later version.
'
'    VBCorLib is distributed in the hope that it will be useful,
'    but WITHOUT ANY WARRANTY; without even the implied warranty of
'    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
'    GNU Library General Public License for more details.
'
'    You should have received a copy of the GNU Library General Public License
'    along with Foobar; if not, write to the Free Software
'    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
'
'    Module: modExceptionMethods
'

''
' Provides the mechanisms to Throw and Catch exceptions in the system.
'
Option Explicit

Private mException As Exception


''
' Catches an exception, if one has been thrown. Otherwise, it may create
' a new exception if the Err object contains an error.
'
' @param ex The variable used to retrieve the exception that has been thrown.
' @param Err An object used to determine if an error has been raised and
' if an exception object should be created and returned if no exception
' currently has been thrown.
' @return Returns True if an exception was indeed caught, otherwise False.
'
Public Function Catch(ByRef ex As Exception, Optional ByVal Err As ErrObject) As Boolean
    If Not mException Is Nothing Then
        Set ex = mException
        Set mException = Nothing
        Catch = True
    ElseIf Not Err Is Nothing Then
        If Err.Number Then
            Set ex = Cor.NewException(Err.Description)
            ex.HResult = Err.Number
            ex.Source = Err.Source
            Err.Clear
            Catch = True
        End If
    End If
    VBA.Err.Clear
End Function

''
' Stores the exception locally and raises an error to notify the application
' that an exception is ready to be caught.
'
' @param ex The exception to cache to be caught.
'
Public Sub Throw(ByVal ex As Exception)
    Set mException = ex
    Err.Raise ex.HResult, ex.Source, ex.Message
End Sub

''
' Clears a cached exception if one exists.
'
Public Sub ClearException()
    Set mException = Nothing
End Sub

''
' Gets a formatted message from a system error code.
'
' @param MessageID The error code to retrieve the message for.
' @return A system message representing the code, or "Unknown Error." if the code was not found.
'
Public Function GetErrorMessage(ByVal MessageID As Long) As String
    Dim buf As String
    Dim Size As Long
    
    buf = String$(1024, vbNullChar)
    Size = FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM, ByVal 0&, MessageID, 0, buf, Len(buf), ByVal 0&)
    If Size > 0 Then
        GetErrorMessage = Left$(buf, Size - 2)
    Else
        GetErrorMessage = "Unknown Error."
    End If
End Function
