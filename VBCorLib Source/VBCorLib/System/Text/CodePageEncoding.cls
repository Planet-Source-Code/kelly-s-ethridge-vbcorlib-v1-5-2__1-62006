VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "CodePageEncoding"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
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
'    Module: CodePageEncoding
'

''
' An encoding class that uses the underlying encoding support of Windows.
'

Option Explicit
Implements IObject
Implements Encoding

Private Declare Function GetCPInfo Lib "kernel32.dll" (ByVal CodePage As Long, ByRef lpCPInfo As CPINFO) As Long
Private Declare Function WideCharToMultiByte Lib "kernel32.dll" (ByVal CodePage As Long, ByVal dwFlags As Long, ByRef lpWideCharStr As Integer, ByVal cchWideChar As Long, ByRef lpMultiByteStr As Byte, ByVal cchMultiByte As Long, ByVal lpDefaultChar As String, ByVal lpUsedDefaultChar As Long) As Long
Private Declare Function MultiByteToWideChar Lib "kernel32.dll" (ByVal CodePage As Long, ByVal dwFlags As Long, ByRef lpMultiByteStr As Byte, ByVal cchMultiByte As Long, ByRef lpWideCharStr As Integer, ByVal cchWideChar As Long) As Long

Private Const MAX_DEFAULTCHAR   As Long = 2
Private Const MAX_LEADBYTES     As Long = 12

Private Type CPINFO
    MaxCharSize                     As Long
    DefaultChar(MAX_DEFAULTCHAR)    As Byte
    LeadByte(MAX_LEADBYTES)         As Byte
End Type


Private mCodePage       As Long
Private mMaxCharSize    As Long
Private mChars()        As Integer
Private mCharsSA        As SafeArray1d



'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'   Friend Interface
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
Friend Sub Init(ByVal CodePage As Long)
    Dim Info As CPINFO
    
    If GetCPInfo(CodePage, Info) = BOOL_FALSE Then _
        Throw Cor.NewNotSupportedException("Either the Code Page is invalid or the Encoding is not installed.")
    
    mCodePage = CodePage
    mMaxCharSize = Info.MaxCharSize
End Sub


'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'   Private Helpers
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
Private Property Get Table() As EncodingTable
    Set Table = modStaticClasses.Encoding.EncodingTable
End Property


'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'   Class Events
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
Private Sub Class_Terminate()
    SAPtr(mChars) = 0
End Sub


'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'   IObject Interface
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
Private Function IObject_Equals(Value As Variant) As Boolean
    If IsObject(Value) Then
        If TypeOf Value Is Encoding Then
            Dim ec As Encoding
            Set ec = Value
            IObject_Equals = (ec.CodePage = mCodePage)
        End If
    End If
End Function

Private Function IObject_GetHashcode() As Long
    IObject_GetHashcode = mCodePage
End Function

Private Function IObject_ToString() As String
    IObject_ToString = "VBCorLib.Encoding"
End Function


'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'   Encoding Interface
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
Private Property Get Encoding_BodyName() As String
    Encoding_BodyName = Table.BodyName(mCodePage)
End Property

Private Property Get Encoding_CodePage() As Long
    Encoding_CodePage = mCodePage
End Property

Private Property Get Encoding_EncodingName() As String
    Encoding_EncodingName = Table.EncodingName(mCodePage)
End Property

Private Function Encoding_Equals(Value As Variant) As Boolean
    Encoding_Equals = IObject_Equals(Value)
End Function

Private Function Encoding_GetByteCount(Chars As Variant, Optional Index As Variant, Optional Count As Variant) As Long
    Call AttachChars(Chars, mChars, mCharsSA)
    
    Dim ElemIndex   As Long
    Dim ElemCount   As Long
    Dim result      As Long
    result = GetOptionalArrayRange(SAPtr(mChars), Index, ElemIndex, Count, ElemCount)
    If result <> NO_ERROR Then Call ThrowArrayRangeException(result, "Chars", ElemIndex, "Index", ElemCount, "Count", IsMissing(Index))
    
    If mMaxCharSize = 1 Or ElemCount = 0 Then
        Encoding_GetByteCount = ElemCount
    Else
        Encoding_GetByteCount = WideCharToMultiByte(mCodePage, 0, mChars(ElemIndex), ElemCount, vbNullString, 0, vbNullString, 0)
    End If
    SAPtr(mChars) = 0
End Function

Private Function Encoding_GetBytes(Chars As Variant, Optional Index As Variant, Optional Count As Variant) As Byte()
    Call AttachChars(Chars, mChars, mCharsSA)
    
    Dim ElemIndex   As Long
    Dim ElemCount   As Long
    Dim result      As Long
    result = GetOptionalArrayRange(SAPtr(mChars), Index, ElemIndex, Count, ElemCount)
    If result <> NO_ERROR Then Call ThrowArrayRangeException(result, "Chars", ElemIndex, "Index", ElemCount, "Count", IsMissing(Index))
    
    Dim Size As Long
    Size = Encoding_GetMaxByteCount(ElemCount)
    
    Dim ret() As Byte
    If Size > 0 Then
        ReDim ret(0 To Size - 1)
        
        Dim ByteCount As Long
        ByteCount = WideCharToMultiByte(mCodePage, 0, mChars(ElemIndex), ElemCount, ret(0), Size, vbNullString, 0)
        If ByteCount <> Size Then ReDim Preserve ret(0 To ByteCount - 1)
    Else
        ret = cArray.CreateInstance(ciByte)
    End If
    
    SAPtr(mChars) = 0
    Encoding_GetBytes = ret
End Function

Private Function Encoding_GetBytesEx(Chars As Variant, ByVal CharIndex As Long, ByVal CharCount As Long, Bytes() As Byte, ByVal ByteIndex As Long) As Long
    Call AttachChars(Chars, mChars, mCharsSA)
    
    Dim result As Long
    result = VerifyArrayRange(SAPtr(mChars), CharIndex, CharCount)
    If result <> NO_ERROR Then Call ThrowArrayRangeException(result, "Chars", CharIndex, "CharIndex", CharCount, "CharCount")
    
    If CharCount > 0 Then
        Dim RequiredSize As Long
        RequiredSize = WideCharToMultiByte(mCodePage, 0, mChars(CharIndex), CharCount, 0, 0, vbNullString, 0)
        
        result = VerifyArrayRange(SAPtr(Bytes), ByteIndex, RequiredSize)
        Select Case result
            Case Argument_InvalidCountOffset:   Throw Cor.NewArgumentException(Environment.GetResourceString(Argument_SmallConversionBuffer), "Bytes")
            Case Is <> NO_ERROR:                Call ThrowArrayRangeException(result, "Bytes", ByteIndex, "ByteIndex", 0, vbNullString)
        End Select
        
        Encoding_GetBytesEx = WideCharToMultiByte(mCodePage, 0, mChars(CharIndex), CharCount, Bytes(ByteIndex), cArray.GetLength(Bytes), vbNullString, 0)
    End If
    SAPtr(mChars) = 0
End Function

Private Function Encoding_GetCharCount(Bytes() As Byte, Optional Index As Variant, Optional Count As Variant) As Long
    Dim ElemIndex   As Long
    Dim ElemCount   As Long
    Dim result      As Long
    
    result = GetOptionalArrayRange(SAPtr(Bytes), Index, ElemIndex, Count, ElemCount)
    If result <> NO_ERROR Then Call ThrowArrayRangeException(result, "Byte", ElemIndex, "Index", ElemCount, "Count", IsMissing(Index))
    
    If ElemCount = 0 Then Exit Function
    Encoding_GetCharCount = MultiByteToWideChar(mCodePage, 0, Bytes(ElemIndex), ElemCount, 0, 0)
End Function

Private Function Encoding_GetChars(Bytes() As Byte, Optional Index As Variant, Optional Count As Variant) As Integer()
    Dim ElemIndex As Long
    Dim ElemCount As Long
    
    Dim result As Long
    result = GetOptionalArrayRange(SAPtr(Bytes), Index, ElemIndex, Count, ElemCount)
    If result <> NO_ERROR Then Call ThrowArrayRangeException(result, "Bytes", ElemIndex, "Index", ElemCount, "Count", IsMissing(Index))
    
    Dim Size As Long
    Size = Encoding_GetMaxCharCount(ElemCount)
    
    Dim ret() As Integer
    If Size > 0 Then
        ReDim ret(0 To Size - 1)
        Size = Encoding_GetCharsEx(Bytes, Index, Count, ret, 0)
        ReDim Preserve ret(0 To Size - 1)
    Else
        ret = cArray.CreateInstance(ciInteger)
    End If
    
    SAPtr(mChars) = 0
    Encoding_GetChars = ret
End Function

Private Function Encoding_GetCharsEx(Bytes() As Byte, ByVal ByteIndex As Long, ByVal ByteCount As Long, Chars() As Integer, ByVal CharIndex As Long) As Long
    Dim result As Long
    result = VerifyArrayRange(SAPtr(Bytes), ByteIndex, ByteCount)
    If result <> NO_ERROR Then Call ThrowArrayRangeException(result, "Bytes", ByteIndex, "ByteIndex", ByteCount, "ByteCount")
    
    If ByteCount > 0 Then
        Dim RequiredSize As Long
        RequiredSize = MultiByteToWideChar(mCodePage, 0, Bytes(ByteIndex), ByteCount, 0, 0)
        
        result = VerifyArrayRange(SAPtr(Chars), CharIndex, RequiredSize)
        Select Case result
            Case Argument_InvalidCountOffset:   Throw Cor.NewArgumentException(Environment.GetResourceString(Argument_SmallConversionBuffer), "Chars")
            Case Is <> NO_ERROR:                Call ThrowArrayRangeException(result, "Chars", CharIndex, "CharIndex", 0, vbNullString)
        End Select
        
        Encoding_GetCharsEx = MultiByteToWideChar(mCodePage, 0, Bytes(ByteIndex), ByteCount, Chars(CharIndex), cArray.GetLength(Chars))
    End If
    SAPtr(mChars) = 0
End Function

Private Function Encoding_GetDecoder() As Decoder
    Dim ret As New CodePageDecoder
    Call ret.Init(mMaxCharSize, mCodePage)
    Set Encoding_GetDecoder = ret
End Function

Private Function Encoding_GetEncoder() As Encoder
    Dim ret As New DefaultEncoder
    Call ret.Init(Me)
    Set Encoding_GetEncoder = ret
End Function

Private Function Encoding_GetHashCode() As Long
    Encoding_GetHashCode = mCodePage
End Function

Private Function Encoding_GetMaxByteCount(ByVal CharCount As Long) As Long
    If CharCount < 0 Then _
        Throw Cor.NewArgumentOutOfRangeException(Environment.GetResourceString(ArgumentOutOfRange_NeedNonNegNum), "CharCount", CharCount)
        
    Encoding_GetMaxByteCount = CharCount * mMaxCharSize
End Function

Private Function Encoding_GetMaxCharCount(ByVal ByteCount As Long) As Long
    If ByteCount < 0 Then _
        Throw Cor.NewArgumentOutOfRangeException(Environment.GetResourceString(ArgumentOutOfRange_NeedNonNegNum), "ByteCount", ByteCount)
    
    Encoding_GetMaxCharCount = ByteCount
End Function

Private Function Encoding_GetPreamble() As Byte()
    Encoding_GetPreamble = cArray.CreateInstance(ciByte, 0)
End Function

Private Function Encoding_GetString(Bytes() As Byte, Optional Index As Variant, Optional Count As Variant) As String
    Dim ElemIndex   As Long
    Dim ElemCount   As Long
    Dim result      As Long
    
    result = GetOptionalArrayRange(SAPtr(Bytes), Index, ElemIndex, Count, ElemCount)
    If result <> NO_ERROR Then Call ThrowArrayRangeException(result, "Bytes", ElemIndex, "Index", ElemCount, "Count", IsMissing(Index))
    
    Dim Size As Long
    Size = Encoding_GetMaxCharCount(Count)
    
    Dim ret As String
    ret = SysAllocStringLen(0, Size)
    With mCharsSA
        .pvData = StrPtr(ret)
        .lLbound = 0
        .cElements = Size
    End With
    SAPtr(mChars) = VarPtr(mCharsSA)
    Size = Encoding_GetCharsEx(Bytes, ElemIndex, ElemCount, mChars, 0)
    SAPtr(mChars) = 0
    Encoding_GetString = Left$(ret, Size)
End Function

Private Property Get Encoding_HeaderName() As String
    Encoding_HeaderName = Table.HeaderName(mCodePage)
End Property

Private Property Get Encoding_IsBrowserDisplay() As Boolean
    Encoding_IsBrowserDisplay = Table.IsBrowserDisplay(mCodePage)
End Property

Private Property Get Encoding_IsBrowserSave() As Boolean
    Encoding_IsBrowserSave = Table.IsBrowserSave(mCodePage)
End Property

Private Property Get Encoding_IsMailNewsDisplay() As Boolean
    Encoding_IsMailNewsDisplay = Table.IsMailNewsDisplay(mCodePage)
End Property

Private Property Get Encoding_IsMailNewsSave() As Boolean
    Encoding_IsMailNewsSave = Table.IsMailNewsSave(mCodePage)
End Property

Private Function Encoding_ToString() As String
    Encoding_ToString = "VBCorLib.Encoding"
End Function

Private Property Get Encoding_WebName() As String
    Encoding_WebName = Table.WebName(mCodePage)
End Property

Private Property Get Encoding_WindowsCodePage() As Long
    Encoding_WindowsCodePage = Table.WindowsCodePage(mCodePage)
End Property
