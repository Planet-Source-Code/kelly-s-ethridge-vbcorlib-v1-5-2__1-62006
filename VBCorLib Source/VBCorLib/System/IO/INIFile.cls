VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "INIFile"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = True
'    CopyRight (c) 2005 Kelly Ethridge
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
'    Module: INIFile
'

''
' Provides methods for manipulating an INI initialization file.
'
' @remarks An INI file contains sections in a format like<br><br>
' <i>
' [section]<br>
' key=value<br><br>
' </i>
' A new INIFile object can be created using the <b>NewINIFile</b> method.
' <pre>
' Dim ini As INIFile
' Set ini = NewINIFile("c:\settings.ini")
' </pre>
' <p>If the file name does not specify the directory, then the file will
' be created in the Windows directory. In order to specify the current
' directory, preceed the file name with a current directory symbol ".".
' <pre>
' Dim ini As INIFile
' Set ini = NewINIFile(".\local.ini")
' </pre>
' </p>
'
' @see INISectionWriter
'
Option Explicit
Implements IObject

Private Declare Function WritePrivateProfileString Lib "kernel32.dll" Alias "WritePrivateProfileStringA" (ByVal lpApplicationName As String, ByVal lpKeyName As String, ByVal lpString As String, ByVal lpFileName As String) As Long
Private Declare Function GetPrivateProfileString Lib "kernel32.dll" Alias "GetPrivateProfileStringA" (ByVal lpApplicationName As String, ByVal lpKeyName As String, ByVal lpDefault As String, ByVal lpReturnedString As String, ByVal nSize As Long, ByVal lpFileName As String) As Long
Private Declare Function GetPrivateProfileSection Lib "kernel32.dll" Alias "GetPrivateProfileSectionA" (ByVal lpAppName As String, ByVal lpReturnedString As String, ByVal nSize As Long, ByVal lpFileName As String) As Long

Private mFileName As String


''
' Returns the name of the INI file being manipulated.
'
' @return The INI file name.
'
Public Property Get FileName() As String
    FileName = mFileName
End Property

''
' Sets a key-value pair within a section of an INI file.
'
' @param Section The INI section within the file to set the value.
' @param Key The name of the value to be set.
' @param Value The value to be set in the INI file.
' @remarks If an object is passed in, then it must implement the <b>cObject</b>
' interface or an exception will be thrown. All other datatypes will be converted
' to their normal string value.
'
Public Sub SetValue(ByVal Section As String, ByVal Key As String, ByRef Value As Variant)
    If Len(Section) = 0 Then _
        Throw Cor.NewArgumentException("Section cannot be an empty string.", "Section")
    If Len(Key) = 0 Then _
        Throw Cor.NewArgumentException("Key cannot be an empty string.", "Key")
    
    Dim s As String
    s = Convert.ToString(Value)
    
    ' We don't want a null string, since that would
    ' delete the INI entry instead.
    If cString.IsNull(s) Then s = ""
    
    If WritePrivateProfileString(Section, Key, s, mFileName) = BOOL_FALSE Then IOError Err.LastDllError
End Sub

''
' Returns the string value of the specified key in the specified section of an INI file.
'
' @param Section The section within the INI file to search for the key.
' @param Key The key in the section of an INI file to retrieve the value of.
' @param Default The default value to return if the key is not found in the section.
' <p>An empty string is a valid value in an INI file. Testing for an empty string
' does not mean the value was not found.</p>
'
Public Function GetString(ByVal Section As String, ByVal Key As String, Optional ByVal Default As String) As String
    If Len(Section) = 0 Then _
        Throw Cor.NewArgumentException("Section cannot be an empty string.", "Section")
    If Len(Key) = 0 Then _
        Throw Cor.NewArgumentException("Key cannot be an empty string.", "Key")

    ' MSDN says we cannot pass in a null value for the default.
    If cString.IsNull(Default) Then Default = ""
    
    Dim Size As Long
    Dim buf As String
    Size = 512
    Do
        Size = Size * 2
        buf = String$(Size, vbNullChar)
        Size = GetPrivateProfileString(Section, Key, Default, buf, Size, mFileName)
    Loop While Size = Len(buf) - 1
    
    GetString = Left$(buf, Size)
End Function

''
' Returns a Long value from the specified key in the specified section of an INI file.
'
' @param Section The section within the INI file to search for the key.
' @param Key The key in the section of an INI file to retrieve the value of.
' @param Default The default value to return if the key is not found in the section, or
' the value could not be converted to a Long.
' @remarks An INI file contains all values as Strings. The value is converted back
' into a Long using the CLng function. If an error happens, then the default is returned.
'
Public Function GetLong(ByVal Section As String, ByVal Key As String, Optional ByVal Default As Long) As Long
    GetLong = ConvertTo(vbLong, GetString(Section, Key), Default)
End Function

''
' Returns a Integer value from the specified key in the specified section of an INI file.
'
' @param Section The section within the INI file to search for the key.
' @param Key The key in the section of an INI file to retrieve the value of.
' @param Default The default value to return if the key is not found in the section, or
' the value could not be converted to an Integer.
' @remarks An INI file contains all values as Strings. The value is converted back
' into an Integer using the CInt function. If an error happens, then the default is returned.
'
Public Function GetInteger(ByVal Section As String, ByVal Key As String, Optional ByVal Default As Integer) As Integer
    GetInteger = ConvertTo(vbInteger, GetString(Section, Key), Default)
End Function

''
' Returns a Byte value from the specified key in the specified section of an INI file.
'
' @param Section The section within the INI file to search for the key.
' @param Key The key in the section of an INI file to retrieve the value of.
' @param Default The default value to return if the key is not found in the section, or
' the value could not be converted to a Byte.
' @remarks An INI file contains all values as Strings. The value is converted back
' into a Byte using the CByte function. If an error happens, then the default is returned.
'
Public Function GetByte(ByVal Section As String, ByVal Key As String, Optional ByVal Default As Byte) As Byte
    GetByte = ConvertTo(vbByte, GetString(Section, Key), Default)
End Function

''
' Returns a Boolean value from the specified key in the specified section of an INI file.
'
' @param Section The section within the INI file to search for the key.
' @param Key The key in the section of an INI file to retrieve the value of.
' @param Default The default value to return if the key is not found in the section, or
' the value could not be converted to a Boolean.
' @remarks An INI file contains all values as Strings. The value is converted back
' into a Boolean using the CBool function. If an error happens, then the default is returned.
'
Public Function GetBoolean(ByVal Section As String, ByVal Key As String, Optional ByVal Default As Boolean) As Boolean
    GetBoolean = ConvertTo(vbBoolean, GetString(Section, Key), Default)
End Function

''
' Returns a Date value from the specified key in the specified section of an INI file.
'
' @param Section The section within the INI file to search for the key.
' @param Key The key in the section of an INI file to retrieve the value of.
' @param Default The default value to return if the key is not found in the section, or
' the value could not be converted to a Date.
' @remarks An INI file contains all values as Strings. The value is converted back
' into a Date using the CDate function. If an error happens, then the default is returned.
'
Public Function GetDate(ByVal Section As String, ByVal Key As String, Optional ByVal Default As Date) As Date
    GetDate = ConvertTo(vbDate, GetString(Section, Key), Default)
End Function

''
' Returns a Double value from the specified key in the specified section of an INI file.
'
' @param Section The section within the INI file to search for the key.
' @param Key The key in the section of an INI file to retrieve the value of.
' @param Default The default value to return if the key is not found in the section, or
' the value could not be converted to a Double.
' @remarks An INI file contains all values as Strings. The value is converted back
' into a Double using the CDbl function. If an error happens, then the default is returned.
'
Public Function GetDouble(ByVal Section As String, ByVal Key As String, Optional ByVal Default As Double) As Double
    GetDouble = ConvertTo(vbDouble, GetString(Section, Key), Default)
End Function

''
' Returns a Single value from the specified key in the specified section of an INI file.
'
' @param Section The section within the INI file to search for the key.
' @param Key The key in the section of an INI file to retrieve the value of.
' @param Default The default value to return if the key is not found in the section, or
' the value could not be converted to a Single.
' @remarks An INI file contains all values as Strings. The value is converted back
' into a Single using the CSng function. If an error happens, then the default is returned.
'
Public Function GetSingle(ByVal Section As String, ByVal Key As String, Optional ByVal Default As Single) As Single
    GetSingle = ConvertTo(vbSingle, GetString(Section, Key), Default)
End Function

''
' Returns a Currency value from the specified key in the specified section of an INI file.
'
' @param Section The section within the INI file to search for the key.
' @param Key The key in the section of an INI file to retrieve the value of.
' @param Default The default value to return if the key is not found in the section, or
' the value could not be converted to a Currency.
' @remarks An INI file contains all values as Strings. The value is converted back
' into a Currency using the CCur function. If an error happens, then the default is returned.
'
Public Function GetCurrency(ByVal Section As String, ByVal Key As String, Optional ByVal Default As Currency) As Currency
    GetCurrency = ConvertTo(vbCurrency, GetString(Section, Key), Default)
End Function

''
' Returns a Decimal value from the specified key in the specified section of an INI file.
'
' @param Section The section within the INI file to search for the key.
' @param Key The key in the section of an INI file to retrieve the value of.
' @param Default The default value to return if the key is not found in the section, or
' the value could not be converted to a Decimal.
' @remarks An INI file contains all values as Strings. The value is converted back
' into a Decimal using the CDec function. If an error happens, then the default is returned.
'
Public Function GetDecimal(ByVal Section As String, ByVal Key As String, Optional ByVal Default As Variant) As Variant
    GetDecimal = ConvertTo(vbDecimal, GetString(Section, Key), CDec(Default))
End Function

''
' Returns a cDateTime value from the specified key in the specified section of an INI file.
'
' @param Section The section within the INI file to search for the key.
' @param Key The key in the section of an INI file to retrieve the value of.
' @param Default The default value to return if the key is not found in the section, or
' the value could not be converted to a cDateTime.
' @remarks An INI file contains all values as Strings. The value is converted back
' into a cDateTime using the Cor.NewDate function. If an error happens, then the default is returned.
' </p>Passing in Nothing as the default will return a <b>cDateTime</b> of #12:00:00 AM# for the default.</p>
'
Public Function GetDateTime(ByVal Section As String, ByVal Key As String, Optional ByVal Default As cDateTime) As cDateTime
    On Error GoTo errDefault
    
    Dim s As String
    s = GetString(Section, Key)
    If Len(s) > 0 Then
        Set GetDateTime = Cor.NewDate(CDate(s))
        Exit Function
    End If
    
errDefault:
    If Default Is Nothing Then
        Set Default = cDateTime.FromOADate(#12:00:00 AM#)
    Else
        Set GetDateTime = Default
    End If
End Function

''
' Returns a TimeSpan value from the specified key in the specified section of an INI file.
'
' @param Section The section within the INI file to search for the key.
' @param Key The key in the section of an INI file to retrieve the value of.
' @param Default The default value to return if the key is not found in the section, or
' the value could not be converted to a TimeSpan.
' @remarks An INI file contains all values as Strings. The value is converted back
' into a TimeSpan by first testing if the string is a date and taking the Time
' portion, otherwise, the normal TimeSpan.Parse method is used. This expects the
' string to be in the TimeSpan format. If an error happens, then the default is returned.
' <p>Passing in Nothing for the default will return <b>TimeSpan.Zero</b> for the default.</p>
'
Public Function GetTimeSpan(ByVal Section As String, ByVal Key As String, Optional ByVal Default As TimeSpan) As TimeSpan
    On Error GoTo errDefault
    
    Dim s As String
    s = GetString(Section, Key)
    If Len(s) > 0 Then
        If IsDate(s) Then
            Set GetTimeSpan = Cor.NewTime(CDate(s))
        Else
            Set GetTimeSpan = TimeSpan.Parse(s)
        End If
        Exit Function
    End If
    
errDefault:
    If Default Is Nothing Then
        Set GetTimeSpan = TimeSpan.Zero
    Else
        Set GetTimeSpan = Default
    End If
End Function

''
' Returns a list of section names in an INI file.
'
' @return An array of section names, or a zero-length array if no sections exist.
'
Public Function GetSectionNames() As String()
    GetSectionNames = GetList(vbNullString, vbNullString, 512)
End Function

''
' Returns a list of key names in an INI file.
'
' @param Section The section within an INI file to retrieve key names.
' @return An array of key names from a section, or a zero-length array if no keys exist in the section.
'
Public Function GetKeyNames(ByVal Section As String) As String()
    If Len(Section) = 0 Then _
        Throw Cor.NewArgumentException("Section cannot be an empty string.", "Section")

    GetKeyNames = GetList(Section, vbNullString, 512)
End Function

''
' Deletes a key-value pair in a specific section within an INI file.
'
' @param Section The section the key-value pair is to be deleted from.
' @param Key The key of the key-value pair to be deleted.
'
Public Sub DeleteKey(ByVal Section As String, ByVal Key As String)
    If Len(Section) = 0 Then _
        Throw Cor.NewArgumentException("Section cannot be an empty string.", "Section")
    If Len(Key) = 0 Then _
        Throw Cor.NewArgumentException("Key cannot be an empty string.", "Key")
    
    If WritePrivateProfileString(Section, Key, vbNullString, mFileName) = BOOL_FALSE Then IOError Err.LastDllError
End Sub

''
' Deletes an entire section from an INI file, including all key-value pairs.
'
' @param Section The name of the section to be deleted from an INI file.
'
Public Sub DeleteSection(ByVal Section As String)
    If Len(Section) = 0 Then _
        Throw Cor.NewArgumentException("Section cannot be an empty string.", "Section")
    
    If WritePrivateProfileString(Section, vbNullString, vbNullString, mFileName) = BOOL_FALSE Then IOError Err.LastDllError
End Sub

''
' Returns an IDictionary object containing the key-value pairs from a section in an INI file.
'
' @param Section The section to retrieve all the key-value pairs from.
' @return An IDictionary object containing zero or more key-value pairs.
'
Public Function GetValues(ByVal Section As String) As IDictionary
    If Len(Section) = 0 Then _
        Throw Cor.NewArgumentException("Section cannot be an empty string.", "Section")
    
    Dim buf As String
    Dim Size As Long
    Size = 16384
    Do
        Size = Size * 2
        buf = String$(Size, vbNullChar)
        Size = GetPrivateProfileSection(Section, buf, Size, mFileName)
    Loop While Size = Len(buf) - 1
    
    Dim ret As Hashtable
    Set ret = Cor.NewHashtable(hcp:=New CaseInsensitiveHashCodePrvdr, comparer:=New CaseInsensitiveComparer)
    
    If Size > 0 Then
        Dim pairs() As String
        pairs = Split(Left$(buf, Size - 1), vbNullChar)
    
        Dim pair()  As String
        Dim i       As Long
        For i = 0 To UBound(pairs)
            pair = Split(pairs(i), "=", 2)
            If UBound(pair) = 1 Then
                ret(pair(0)) = pair(1)
            Else
                ret(pair(0)) = ""
            End If
        Next i
    End If
    
    Set GetValues = ret
End Function

''
' Returns a SectionWriter used to create entire sections withing an INI file at once.
'
' @param Section The section to create using the writer.
' @return The SectionWriter used to create an entier section.
' @see INISectionWriter
'
Public Function GetSectionWriter(ByVal Section As String) As IResourceWriter
    Dim ret As New INISectionWriter
    Call ret.Init(mFileName, Section)
    Set GetSectionWriter = ret
End Function

''
' Returns a string representation of this object instance.
'
' @return String representing this instance.
Public Function ToString() As String
    ToString = Object.ToString(Me, App)
End Function

''
' Returns a boolean indicating if the value and this object
' instance are the same instance.
'
' @param value The value to compare equalit to.
' @return Boolean indicating equality.
Public Function Equals(ByRef Value As Variant) As Boolean
    Equals = Object.Equals(Me, Value)
End Function

''
' Returns a pseudo-unique number identifying this instance.
'
' @return Pseudo-unique number identifying this instance.
Public Function GetHashCode() As Long
    GetHashCode = ObjPtr(CUnk(Me))
End Function


'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'   Friend Interface
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
Friend Sub Init(ByVal FileName As String)
    If Len(FileName) = 0 Then _
        Throw Cor.NewArgumentException("FileName cannot be empty.", "FileName")
    
    mFileName = FileName
End Sub


'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'   Private Helpers
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
Private Function ConvertTo(ByVal ConvertType As VbVarType, ByRef s As String, ByRef Default As Variant) As Variant
    On Error GoTo errDefault
    Select Case ConvertType
        Case vbInteger:     ConvertTo = CInt(s)
        Case vbLong:        ConvertTo = CLng(s)
        Case vbSingle:      ConvertTo = CSng(s)
        Case vbDouble:      ConvertTo = CDbl(s)
        Case vbCurrency:    ConvertTo = CCur(s)
        Case vbDate:        ConvertTo = CDate(s)
        Case vbBoolean:     ConvertTo = CBool(s)
        Case vbDecimal:     ConvertTo = CDec(s)
        Case vbByte:        ConvertTo = CByte(s)
    End Select
    Exit Function
    
errDefault:
    ConvertTo = Default
End Function

Private Function GetList(ByRef Section As String, ByRef Key As String, ByVal BufferSize As Long) As String()
    Dim buf As String
    
    Do
        BufferSize = BufferSize * 2
        buf = String$(BufferSize, vbNullChar)
        BufferSize = GetPrivateProfileString(Section, Key, "", buf, BufferSize, mFileName)
    Loop While BufferSize = Len(buf) - 1
    
    If BufferSize > 0 Then
        GetList = Split(Left$(buf, BufferSize - 1), vbNullChar)
    Else
        GetList = cArray.CreateInstance(ciString)
    End If
End Function


'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'   IObject Interface
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
Private Function IObject_Equals(Value As Variant) As Boolean
    IObject_Equals = Equals(Value)
End Function

Private Function IObject_GetHashcode() As Long
    IObject_GetHashcode = GetHashCode
End Function

Private Function IObject_ToString() As String
    IObject_ToString = ToString
End Function
