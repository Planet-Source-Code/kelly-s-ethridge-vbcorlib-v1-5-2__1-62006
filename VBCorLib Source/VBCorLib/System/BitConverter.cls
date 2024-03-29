VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "BitConverter"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = True
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
'    Module: BitConverter
'

''
' Provides a means to convert value datatypes to and from arrays of bytes.
'
' @remarks The <b>BitConverter</b> class cannot be instantiated. The methods
' are available through the class name itself.
' <pre>
' Dim b() As Byte
' b = BitConverter.GetBytes(&H12345678)
' </pre>
'
Option Explicit
Private Const CHAR_HYPHEN   As Long = 45
Private Const ALPHA_OFFSET  As Long = 55

Private mBuffer As WordBuffer


''
' Converts the bit representation of a Double to a Currency.
'
' @param Value The Double bits to convert to Currency bits.
' @return The bit representation from the Double.
' @remarks This does not convert a Double value to that of a
' Currency value (like using CCur). This will copy the 64 bits
' of the Double variable to the 64 bits of the Currency variable.
'
Public Function DoubleToInt64Bits(ByVal Value As Double) As Currency
    DoubleToInt64Bits = AsCurr(Value)
End Function

''
' Converts the bit representation of a Currencty to a Double.
'
' @param Value The Currency bits to conver to Double bits.
' @return The bit representation from a Currency datatype.
' @remarks This does not convert a Currency to that of a
' Double value (like using CDbl). This will copy the 64 bits
' of the Currency variable to the 64 bits of the Double variable.
'
Public Function Int64BitsToDouble(ByVal Value As Currency) As Double
    Int64BitsToDouble = AsDouble(Value)
End Function

''
' Returns a byte array representation of the datatype value.
'
' @param value The datatype to be converted to a byte array.
' @return An array of bytes converted from the bits of the original datatype.
' @remarks <p>A type boolean is converted to one byte. If the boolean
' value is True, then the byte is 1, otherwise, it is 0.</p>
' <p>The byte array contains as many bytes as the length of the
' datatype being converted. A Long returns a 4-byte array, where as
' a Double will return an 8-byte array.</p>
' <p>The Decimal datatype is converted to 16 bytes with the same
' layout as used in .NET. The layout is different than that of VB.<br><br>
' VB Decimal layout<br>
' bytes 0-1: Variant datatype information<br>
' bytes 2: precision<br>
' bytes 3: sign (&h80 is negative)<br>
' bytes 4-7: the 32 highest bits in the 96bit value<br>
' bytes 8-11: the 32 lowest bits in the 96bit value<br>
' bytes 12-15: the 32 middle bits in the 96bit value<br>
' <br>
' .NET Decimal layout<br>
' bytes 0-3: the 32 lowest bits in the 96bit value<br>
' bytes 4-7: the 32 middle bits in the 96bit value<br>
' bytes 8-11: the 32 highest bits in the 96bit value<br>
' bytes 12-13: unused (zero)<br>
' bytes 14: precision<br>
' bytes 15: sign (&h80 is negative)<br>
'
Public Function GetBytes(ByRef Value As Variant) As Byte()
    Dim ret() As Byte

    ' We use SafeArrayCreateVectorEx because the array descriptor
    ' and data are allocated all in one shot, where as using
    ' ReDim will cause two heap memory allocations.
    Select Case VarType(Value)
        Case vbLong
            SAPtr(ret) = SafeArrayCreateVectorEx(vbByte, 0, 4)
            AsLong(ret(0)) = CLng(Value)
        Case vbBoolean
            SAPtr(ret) = SafeArrayCreateVectorEx(vbByte, 0, 1)
            If Value Then ret(0) = 1
        Case vbInteger
            SAPtr(ret) = SafeArrayCreateVectorEx(vbByte, 0, 2)
            AsWord(ret(0)) = CInt(Value)
        Case vbDouble, vbDate
            SAPtr(ret) = SafeArrayCreateVectorEx(vbByte, 0, 8)
            AsDouble(ret(0)) = CDbl(Value)
        Case vbCurrency
            SAPtr(ret) = SafeArrayCreateVectorEx(vbByte, 0, 8)
            AsCurr(ret(0)) = CCur(Value)
        Case vbSingle
            SAPtr(ret) = SafeArrayCreateVectorEx(vbByte, 0, 4)
            AsSingle(ret(0)) = CSng(Value)
        Case vbDecimal
            Dim ptrDec As Long
            Dim ptrRet As Long
            
            SAPtr(ret) = SafeArrayCreateVectorEx(vbByte, 0, 16)
            
            If VariantType(Value) And VT_BYREF Then
                ptrDec = MemLong(VarPtr(Value) + 8)
            Else
                ptrDec = VarPtr(Value)
            End If
            ptrRet = VarPtr(ret(0))
            
            ' VB Decimal layout
            ' bytes 0-1: Variant datatype information
            ' bytes 2-3: precision and sign bytes
            ' bytes 4-7: the 32 highest bits in the 96bit value
            ' bytes 8-11: the 32 lowest bits in the 96bit value
            ' bytes 12-15: the 32 middle bits in the 96bit value
            '
            ' .NET Decimal layout
            ' bytes 0-3: the 32 lowest bits in the 96bit value
            ' bytes 4-7: the 32 middle bits in the 96bit value
            ' bytes 8-11: the 32 highest bits in the 96bit value
            ' bytes 12-13: unused (zero)
            ' bytes 14-15: precision and sign bytes
            MemCurr(ptrRet) = MemCurr(ptrDec + 8)       ' map VB lowest and middle bits to .NET lowest and middle bits
            MemLong(ptrRet + 8) = MemLong(ptrDec + 4)   ' map VB highest bits to .NET highest bits
            ' In .NET the precision and sign bytes are last.
            ' we don't copy the type information from the variant.
            MemWord(ptrRet + 14) = MemWord(ptrDec + 2)
        Case Else
            Throw Cor.NewNotSupportedException("Only intrinsic value types are supported.")
    End Select
    GetBytes = ret
End Function

''
' Converts an array of bytes to a Boolean value.
'
' @param bytes The array of bytes to create a boolean from.
' @param startindex The byte in the array to create the boolean from.
' @return Boolean representation of the byte used in the array.
' @remarks The boolean value is created from one byte. If the byte is
' a non-zero value, True is returned, otherwise, False is returned.
'
Public Function ToBoolean(ByRef Bytes() As Byte, ByVal StartIndex As Long) As Boolean
    Call VerifyArray(Bytes, StartIndex, 1)
    ToBoolean = (Bytes(StartIndex) > 0)
End Function

''
' Converts an array of bytes to a Double value.
'
' @param bytes The array of bytes to create a double from.
' @param startindex The starting byte in the array to create a double from.
' @return Double datatype representation of the 8 bytes used in the array.
'
Public Function ToDouble(ByRef Bytes() As Byte, ByVal StartIndex As Long) As Double
    Call VerifyArray(Bytes, StartIndex, 8)
    ToDouble = AsDouble(Bytes(StartIndex))
End Function

''
' Converts an array of bytes to a Date value.
'
' @param bytes The array of bytes to create a date from.
' @param startindex The starting byte in the array to create a date from.
' @return Date datatype representation of the 8 bytes used in the array.
' @remarks Even though a Date is represented using a Double, it may still
' raise an error due to the 8 bytes used represent an invalid date range.
'
Public Function ToDate(ByRef Bytes() As Byte, ByVal StartIndex As Long) As Date
    Call VerifyArray(Bytes, StartIndex, 8)
    ToDate = AsDouble(Bytes(StartIndex))
End Function

''
' Converts an array of bytes to an Integer value.
'
' @param bytes The array of bytes used to create an integer from.
' @param startindex The starting byte in the array to create an integer from.
' @return Integer datatype representation of the 2 bytes used in the array.
'
Public Function ToInteger(ByRef Bytes() As Byte, ByVal StartIndex As Long) As Integer
    Call VerifyArray(Bytes, StartIndex, 2)
    ToInteger = AsWord(Bytes(StartIndex))
End Function

''
' Converts an array of bytes to a Long value.
'
' @param bytes The array of bytes used to create a Long from.
' @param startindex The starting byte in the array to create a Long from.
' @return Long datatype representation of the 4 bytes used in the array.
'
Public Function ToLong(ByRef Bytes() As Byte, ByVal StartIndex As Long) As Long
    Call VerifyArray(Bytes, StartIndex, 4)
    ToLong = AsLong(Bytes(StartIndex))
End Function

''
' Converts an array of bytes to a Single value.
'
' @param Bytes The array of bytes used to create a Single from.
' @param StartIndex The starting byte in the array to create a Single from.
' @return Single datatype representation of the 4 bytes used in the array.
'
Public Function ToSingle(ByRef Bytes() As Byte, ByVal StartIndex As Long) As Single
    Call VerifyArray(Bytes, StartIndex, 4)
    ToSingle = AsSingle(Bytes(StartIndex))
End Function

''
' Converts an array of bytes to a Currency value.
'
' @param bytes The array of bytes used to create a Currency from.
' @param startindex The starting byte in the array to create a Currency from.
' @return Currency datatype representation of the 8 bytes used in the array.
'
Public Function ToCurrency(ByRef Bytes() As Byte, ByVal StartIndex As Long) As Currency
    Call VerifyArray(Bytes, StartIndex, 8)
    ToCurrency = AsCurr(Bytes(StartIndex))
End Function

''
' Converts an array of bytes do a Variant Decimal value.
'
' @param Bytes The array of bytes used to create a Decimal value. Must be atleast 16 bytes in length.
' @param StartIndex The starting index within the array to be converting to a Decimal value.
' @return The converted Decimal value.
' @remarks <p>The Decimal datatype is created from 16 bytes with the same
' layout as used in .NET. The layout is different than that of VB.<br><br>
' VB Decimal layout<br>
' bytes 0-1: Variant datatype information<br>
' bytes 2: precision<br>
' bytes 3: sign (&h80 is negative)<br>
' bytes 4-7: the 32 highest bits in the 96bit value<br>
' bytes 8-11: the 32 lowest bits in the 96bit value<br>
' bytes 12-15: the 32 middle bits in the 96bit value<br>
' <br>
' .NET Decimal layout<br>
' bytes 0-3: the 32 lowest bits in the 96bit value<br>
' bytes 4-7: the 32 middle bits in the 96bit value<br>
' bytes 8-11: the 32 highest bits in the 96bit value<br>
' bytes 12-13: unused (zero)<br>
' bytes 14: precision<br>
' bytes 15: sign (&h80 is negative)<br><br>
' If the sign byte is non-zero, then the Decimal will be set as negative.<br>
'
Public Function ToDecimal(ByRef Bytes() As Byte, ByVal StartIndex As Long) As Variant
    Call VerifyArray(Bytes, StartIndex, 16)
    VariantType(ToDecimal) = vbDecimal
    
    ' check precision
    If Bytes(14) > 28 Then _
        Throw Cor.NewOverflowException("Decimal precision must be from 0 to 28 places.")
    
    Dim Ptr As Long
    Ptr = VarPtr(ToDecimal)
    
    If Bytes(15) <> 0 Then MemByte(Ptr + 3) = &H80  ' set sign
    
    MemByte(Ptr + 2) = Bytes(14)            ' set precision
    MemLong(Ptr + 4) = AsLong(Bytes(8))     ' set highest 32 bits
    MemCurr(Ptr + 8) = AsCurr(Bytes(0))     ' set lowest and middle 32bits
End Function

''
' Converts an array of bytes to a string of hexidecimal notations.
'
' @param Bytes The array of bytes used to create a string of hexidecimal values.
' @param Index The starting byte to begin creating hexidecimal values from in the array.
' @param Count The number of bytes to be converted to a hexidecimal notation.
' @return String containing hexidecimal notations for each byte, separated by hyphens.
' @remarks Each byte to be converted to string is converted into a hexidecimal representation.
' For example a byte value of 160 would become 'A0' in the return string. Each byte is separated
' by a hyphen when more than one byte is being converted. An example is a Long of &hABCDEF01 would
' become '01-EF-CD-AB'.
'
Public Function ToString(ByRef Bytes() As Byte, Optional ByRef Index As Variant, Optional ByRef Count As Variant) As String
    If cArray.IsNull(Bytes) Then _
        Throw Cor.NewArgumentNullException(Environment.GetResourceString(ArgumentNull_Array), "Bytes")
    
    Dim ElemIndex As Long
    ElemIndex = GetOptionalLong(Index, LBound(Bytes))
    
    Dim ElemCount As Long
    ElemCount = GetOptionalLong(Count, UBound(Bytes) - ElemIndex + 1)
    
    Call VerifyArray(Bytes, ElemIndex, ElemCount)
    
    Dim ret As String
    ret = SysAllocStringLen(0, ElemCount * 3 - 1)
    mBuffer.SA.pvData = StrPtr(ret)
    
    Dim i       As Long
    Dim b       As Long
    Dim pos     As Long
    Dim nibble  As Long
    Dim Offset  As Long
    
    Offset = 1
    Do While i < ElemCount
        If i > 0 Then mBuffer.Data(pos) = CHAR_HYPHEN: pos = pos + 1
        b = Bytes(ElemIndex + i)
        Do
            nibble = b And &HF
            If nibble > 9 Then
                mBuffer.Data(pos + Offset) = nibble + ALPHA_OFFSET
            Else
                mBuffer.Data(pos + Offset) = nibble + CHAR_0
            End If
            b = b \ 16
            Offset = 1 - Offset
        Loop While Offset = 0
        pos = pos + 2
        i = i + 1
    Loop
    
    ToString = ret
End Function


'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'   Private Helpers
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
Private Sub VerifyArray(ByRef Bytes() As Byte, ByVal Index As Long, ByVal Count As Long)
    Dim result As Long
    result = VerifyArrayRange(SAPtr(Bytes), Index, Count)
    If result <> NO_ERROR Then Call ThrowArrayRangeException(result, "Bytes", Index, "Index", Count, "Index")
End Sub


'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'   Class Events
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
Private Sub Class_Initialize()
    Call InitWordBuffer(mBuffer, 0, &H7FFFFFFF)
End Sub

