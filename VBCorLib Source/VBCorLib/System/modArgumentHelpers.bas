Attribute VB_Name = "modArgumentHelpers"
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
'    Module: modArgumentHelpers
'

''
' This modules contains functions used to help with optional parameters and
' verifying ranges of values.
' <p>All of the functions return an error code except GetOptionalLong. This
' function returns a valid integer value or throws an exception if a the
' supplied optional value is not an integer type.</p>
'
Option Explicit


''
' Retrieves the pointer to an array's SafeArray structure.
'
' @param arr The array to retrieve the pointer to.
' @return A pointer to a SafeArray structure or 0 if the array is null.
'
Public Function GetArrayPointer(ByRef Arr As Variant) As Long
    Const BYREF_ARRAY As Long = VT_BYREF Or vbArray
    
    Dim vt As Long
    
    vt = VariantType(Arr)
    Select Case vt And BYREF_ARRAY
        ' we have to double deref the original array pointer because
        ' the variant held a pointer to the original array variable.
        Case BYREF_ARRAY:   GetArrayPointer = MemLong(MemLong(VarPtr(Arr) + VARIANTDATA_OFFSET))
        ' we won't need to deref again if the original array was dimensioned
        ' as a variant ie:
        '    Dim arr As Variant
        '    ReDim arr(1 To 10) As Long
        '
        ' The passed in variant will be the array variable, not a ByRef
        ' pointer to the array variable.
        Case vbArray:       GetArrayPointer = MemLong(VarPtr(Arr) + VARIANTDATA_OFFSET)
        ' you bad person
        Case Else:          Throw Cor.NewArgumentException(Environment.GetResourceString(Argument_ArrayRequired), "Arr")
    End Select
    
    ' HACK HACK HACK
    '
    ' When an uninitialized array of objects or UDTs is passed into a
    ' function as a ByRef Variant, the array is initialized with just the
    ' SafeArrayDescriptor, at which point, it is a valid array and can
    ' be used by UBound and LBound after the call. So, now we're just
    ' going to assume that any object or UDT array that has just the descriptor
    ' allocated was Null to begin with. That means whenever an Object or UDT
    ' array is passed to any cArray method, it will technically never
    ' be uninitialized, just zero-length.
    Select Case vt And &HFF
        Case vbObject, vbUserDefinedType: If MemLong(GetArrayPointer + PVDATA_OFFSET) = 0 Then GetArrayPointer = 0
    End Select
End Function

''
' This will verify that the array pointer is not Null. If it is null
' then an ArgumentNullException will be thrown.
'
' @param arr The array to retrieve the pointer to.
' @return A pointer to a SafeArray structure.
'
Public Function GetValidArrayPointer(ByRef Arr As Variant) As Long
    GetValidArrayPointer = GetArrayPointer(Arr)
    If GetValidArrayPointer = vbNullPtr Then _
        Throw Cor.NewArgumentNullException(Environment.GetResourceString(ArgumentNull_Array), "Arr")
End Function

''
' Returns an optional value or a default value if the optional value is missing.
'
' @param OptionalValue The optional variant value.
' @param Default The default return value is the optionavalue is missing.
' @return A vbLong value derived from the optional value or default value.
' @remarks The calling function passes in an Optional Variant type from it's function
' parameter list. The value will maintain its Missing status into this call if it was
' not supplied to the caller's function.
' <p>Only vbLong, vbInteger, and vbByte are value OptionalValue datatypes. All others
' will cause an ArgumentException to be thrown.</p>
'
Public Function GetOptionalLong(ByRef OptionalValue As Variant, ByVal DefaultValue As Long) As Long
    Select Case VarType(OptionalValue)
        ' A missing value will be a vbError inside of the Variant.
        Case vbError:                   GetOptionalLong = DefaultValue
        
        ' We only allow optional values to be integer datatypes.
        Case vbLong, vbInteger, vbByte: GetOptionalLong = OptionalValue
        
        ' Throw an exception for an unsupported datatype.
        Case Else
            Throw Cor.NewArgumentException("The Optional value must be an integer type.")
    End Select
End Function

''
' Returns a pair of optional values, requiring both of them to be missing or present.
'
' @param OptionalValue1 First value of the pair.
' @param DefaultValue1 Default value if the first value is missing.
' @param ReturnValue1 The return parameter of the first value.
' @param OptionalValue2 Second value of the pair.
' @param DefaultValue2 Default value if the second value is missing.
' @param ReturnValue2 The return parameter of the second value.
' @return If the function is successful, then NO_ERROR is returned,
' otherwise, an exception error number is returned.
'
Public Function GetOptionalLongPair(ByRef OptionalValue1 As Variant, ByVal DefaultValue1 As Long, ByRef ReturnValue1 As Long, _
                                    ByRef OptionalValue2 As Variant, ByVal DefaultValue2 As Long, ByRef ReturnValue2 As Long) As Long
    Dim im1 As Boolean
    
    im1 = IsMissing(OptionalValue1)
    ' Checks that both optional arguments are either both supplied
    ' or both are missing. Cannot supply only one argument.
    If im1 = IsMissing(OptionalValue2) Then
        ' Sinces 99.99% of the calls will have missing optional
        ' arguments, we optimize for it and return the defaults.
        If im1 Then
            ReturnValue1 = DefaultValue1
            ReturnValue2 = DefaultValue2
        Else
            ' If arguments are supplied, then fallback to the normal
            ' optional argument checking and assignment functions.
            ReturnValue1 = GetOptionalLong(OptionalValue1, DefaultValue1)
            ReturnValue2 = GetOptionalLong(OptionalValue2, DefaultValue2)
        End If
    Else
        ' Only one argument from the pair was supplied.
        GetOptionalLongPair = Argument_ParamRequired
    End If
End Function

''
' Assigns given values or default values, returning any error codes.
'
' @param pSafeArray A pointer to a SafeArray structure.
' @param OptionalIndex The index value supplied by the caller.
' @param ReturnIndex Returns the index of the starting range of the array.
' @param OptionalCount The count value supplied by the caller.
' @param ReturnCount Returns the number of elements to include in the range.
' @return If the function is successful, then NO_ERROR is returned,
' otherwise, an exception error number is returned.
' @remarks <p>Range checking is performed to ensure a Index and Count value pair do not extend outside of the array.</p>
'
Public Function GetOptionalArrayRange(ByVal pSafeArray As Long, _
                                      ByRef OptionalIndex As Variant, ByRef ReturnIndex As Long, _
                                      ByRef OptionalCount As Variant, ByRef ReturnCount As Long) As Long
    Dim LowerBound As Long
    Dim UpperBound As Long
    
    ' This function is optimized by not refactoring
    ' common sections with other helper rountine in
    ' order to cut down on total function calls.
    
    ' Check if the array is a null array.
    If pSafeArray = vbNullPtr Then
        GetOptionalArrayRange = ArgumentNull_Array
        Exit Function
    End If
    
    ' Ensure we only have a 1-Dimension array.
    If SafeArrayGetDim(pSafeArray) <> 1 Then
        GetOptionalArrayRange = Rank_MultiDimension
        Exit Function
    End If
    
    LowerBound = SafeArrayGetLBound(pSafeArray, 1)
    UpperBound = SafeArrayGetUBound(pSafeArray, 1)
    
    ' Get our optional values.
    Dim result As Long
    result = GetOptionalLongPair(OptionalIndex, LowerBound, ReturnIndex, OptionalCount, UpperBound - LowerBound + 1, ReturnCount)
    If result <> NO_ERROR Then
        GetOptionalArrayRange = result
        Exit Function
    End If
    
    ' Can't have an index before the beginning of the array.
    If ReturnIndex < LowerBound Then
        GetOptionalArrayRange = ArgumentOutOfRange_LBound
        Exit Function
    End If
    
    ' Can't have a negative count.
    If ReturnCount < 0 Then
        GetOptionalArrayRange = ArgumentOutOfRange_NeedNonNegNum
        Exit Function
    End If
    
    ' Can't have the range extend past the end of the array.
    If ReturnIndex + ReturnCount - 1 > UpperBound Then
        GetOptionalArrayRange = Argument_InvalidCountOffset
    End If
End Function

''
' Assigns given values or default values and checks the range is valid.
' This version checks that the Index - Count does not extend below the lower bound.
'
' @param pSafeArray A pointer to a SafeArray structure.
' @param OptionalIndex The index value supplied by the caller.
' @param ReturnIndex Returns the index of the starting range of the array.
' @param OptionalCount The count value supplied by the caller.
' @param ReturnCount Returns the number of elements to include in the range.
' @return If the function is successful, then NO_ERROR is returned,
' otherwise, an exception error message is returned.
' @remarks <p>Range checking is performed to ensure a Index and Count value pair do not extend outside of the array.</p>
'
Public Function GetOptionalArrayRangeReverse(ByVal pSafeArray As Long, _
                                             ByRef OptionalIndex As Variant, ByRef ReturnIndex As Long, _
                                             ByRef OptionalCount As Variant, ByRef ReturnCount As Long) As Long
    Dim LowerBound As Long
    Dim UpperBound As Long
    
    ' This function is optimized by not refactoring
    ' common sections with other helper rountine in
    ' order to cut down on total function calls.
    
    ' Check if the array is a null array.
    If pSafeArray = vbNullPtr Then
        GetOptionalArrayRangeReverse = ArgumentNull_Array
        Exit Function
    End If
    
    ' Ensure we only have a 1-Dimension array.
    If SafeArrayGetDim(pSafeArray) <> 1 Then
        GetOptionalArrayRangeReverse = Rank_MultiDimension
        Exit Function
    End If
    
    LowerBound = SafeArrayGetLBound(pSafeArray, 1)
    UpperBound = SafeArrayGetUBound(pSafeArray, 1)
    
    ' Get our optional values.
    Dim result As Long
    result = GetOptionalLongPair(OptionalIndex, UpperBound, ReturnIndex, OptionalCount, UpperBound - LowerBound + 1, ReturnCount)
    If result <> NO_ERROR Then
        GetOptionalArrayRangeReverse = result
        Exit Function
    End If
    
    ' Can't have an index after the end of the array.
    If ReturnIndex > UpperBound Then
        GetOptionalArrayRangeReverse = ArgumentOutOfRange_UBound
        Exit Function
    End If
    
    ' Can't have a negative count.
    If ReturnCount < 0 Then
        GetOptionalArrayRangeReverse = ArgumentOutOfRange_NeedNonNegNum
        Exit Function
    End If
    
    ' Can't have the range extend past the beginning of the array.
    If ReturnIndex - ReturnCount + 1 < LowerBound Then
        GetOptionalArrayRangeReverse = Argument_InvalidCountOffset
    End If
End Function

''
' Verifies the index and count are within the bounds and size of a one-dimensional array.
'
' @param pSA A pointer to a SafeArray structure.
' @param Index The index into the array.
' @param Count The number of elements to include.
' @return If this function succeeds, then NO_ERROR is returned, otherwise
' and error exception code is returned.
'
Public Function VerifyArrayRange(ByVal pSafeArray As Long, ByVal Index As Long, ByVal Count As Long) As Long
    ' This function is optimized by not refactoring
    ' common sections with other helper rountine in
    ' order to cut down on total function calls.

    ' Check if the array is a null array.
    If pSafeArray = vbNullPtr Then
        VerifyArrayRange = ArgumentNull_Array
        Exit Function
    End If
    
    ' Ensure we only have a 1-Dimension array.
    If SafeArrayGetDim(pSafeArray) <> 1 Then
        VerifyArrayRange = Rank_MultiDimension
        Exit Function
    End If
    
    ' Can't have an index before the beginning of the array.
    If Index < SafeArrayGetLBound(pSafeArray, 1) Then
        VerifyArrayRange = ArgumentOutOfRange_LBound
        Exit Function
    End If
    
    ' Can't have a negative count.
    If Count < 0 Then
        VerifyArrayRange = ArgumentOutOfRange_NeedNonNegNum
        Exit Function
    End If
    
    ' Can't have the range extend past the end of the array.
    If Index + Count - 1 > SafeArrayGetUBound(pSafeArray, 1) Then
        VerifyArrayRange = Argument_InvalidCountOffset
    End If
End Function

''
' Verifies the index and count are within the bounds and size of a one-dimensional array.
' This version ensures that Index - Count does not extend below the lower bound.
'
' @param pSA A pointer to a SafeArray structure.
' @param Index The index into the array.
' @param Count The number of elements to include.
' @return If this function succeeds, then NO_ERROR is returned, otherwise
' and error exception code is returned.
'
Public Function VerifyArrayRangeReverse(ByVal pSafeArray As Long, ByVal Index As Long, ByVal Count As Long) As Long
    ' This function is optimized by not refactoring
    ' common sections with other helper rountine in
    ' order to cut down on total function calls.

    ' Check if the array is a null array.
    If pSafeArray = vbNullPtr Then
        VerifyArrayRangeReverse = ArgumentNull_Array
        Exit Function
    End If
    
    ' Ensure we only have a 1-Dimension array.
    If SafeArrayGetDim(pSafeArray) <> 1 Then
        VerifyArrayRangeReverse = Rank_MultiDimension
        Exit Function
    End If
    
    ' Can't have an index after the end of the array.
    If Index > SafeArrayGetUBound(pSafeArray, 1) Then
        VerifyArrayRangeReverse = ArgumentOutOfRange_UBound
        Exit Function
    End If
    
    ' Can't have a negative count.
    If Count < 0 Then
        VerifyArrayRangeReverse = ArgumentOutOfRange_NeedNonNegNum
        Exit Function
    End If
    
    ' Can't have the range extend past the beginning of the array.
    If Index - Count + 1 < SafeArrayGetLBound(pSafeArray, 1) Then
        VerifyArrayRangeReverse = Argument_InvalidCountOffset
    End If
End Function

''
' Throws specific exceptions based on an error code.
'
' @param ErrorCode The code that determines which exception to throw.
' @param ArrayName The name of the array in which the exception occurred.
' @param Index The index into the array at the time of the error.
' @param IndexName The name of the Index parameter to be included in the exception.
' @param Count The number of elements that were included in the verification of the range in the array.
' @param CountName The name of the Count parameter to be included in the exception.
' @param IsIndexMissing Used to help determine which parameter was missing in the original function call.
' @remarks This throws exceptions that are general cases about an Index and Count
' being valid within a given array. Not all exception types are represented here.
'
Public Sub ThrowArrayRangeException(ByVal ErrorCode As Long, ByRef ArrayName As String, ByVal Index As Long, ByRef IndexName As String, ByVal Count As Long, ByRef CountName As String, Optional ByVal IsIndexMissing As Boolean)
    Dim Message As String
    Message = Environment.GetResourceString(ErrorCode)
    Select Case ErrorCode
        Case ArgumentNull_Array:                Throw Cor.NewArgumentNullException(Message, ArrayName)
        Case Rank_MultiDimension:               Throw Cor.NewRankException(Message)
        Case Argument_ParamRequired:            Throw Cor.NewArgumentException(Message, IIf(IsIndexMissing, IndexName, CountName))
        Case ArgumentOutOfRange_LBound:         Throw Cor.NewArgumentOutOfRangeException(Message, IndexName, Index)
        Case ArgumentOutOfRange_UBound:         Throw Cor.NewArgumentOutOfRangeException(Message, IndexName, Index)
        Case ArgumentOutOfRange_NeedNonNegNum:  Throw Cor.NewArgumentOutOfRangeException(Message, CountName, Count)
        Case Argument_InvalidCountOffset:       Throw Cor.NewArgumentException(Message, CountName)
        Case Else:                              Throw Cor.NewArgumentException(Message)
    End Select
End Sub

''
' Verifies the Index and Count range remain inside the bounds of a 0-base list.
'
' @param ListSize The size of the list being checked against.
' @param Index The index into the list, starting at 0.
' @param Count The number of elements in the list to include in the verification.
' @return If success, then 0 is returned, otherwise an error code is returned.
'
Public Function VerifyListRange(ByVal RangeSize As Long, ByVal Index As Long, ByVal Count As Long) As Long
    If Index < 0 Then
        VerifyListRange = ArgumentOutOfRange_LBound ' this should be mapped to ArgumentOutOfRange_NeedNonNegNum
        Exit Function
    End If

    If Count < 0 Then
        VerifyListRange = ArgumentOutOfRange_NeedNonNegNum
        Exit Function
    End If

    If Index + Count > RangeSize Then
        VerifyListRange = Argument_InvalidCountOffset
    End If
End Function

''
' Throws a specific list exception based on the error code, providing the correct argument in the exception.
'
' @param ErrorCode The code of the exception to be thrown.
' @param ListName The name of the list or type of list that was used in verification.
' @param Index The index into the list.
' @param IndexName The name of the variable in the public function.
' @param Count The number of elements verified against the list.
' @param CountName The name of the count variable in the public function.
' @param IsIndexMissing Flag indicating if Index was a missing argument, otherwise Count was missing.
'
Public Sub ThrowListRangeException(ByVal ErrorCode As Long, ByVal Index As Long, ByRef IndexName As String, ByVal Count As Long, ByRef CountName As String, Optional ByVal IsIndexMissing As Boolean)
    Dim Message As String
    
    ' Two of the error codes are of the same type, but we need to distinguish
    ' between them. So we use ArgumentOutOfRange_LBound for one of the codes.
    ' Now get the message for the original error code instead.
    If ErrorCode = ArgumentOutOfRange_LBound Then
        Message = Environment.GetResourceString(ArgumentOutOfRange_NeedNonNegNum)
    Else
        Message = Environment.GetResourceString(ErrorCode)
    End If
    
    Select Case ErrorCode
        Case Argument_ParamRequired:                Throw Cor.NewArgumentException(Message, IIf(IsIndexMissing, IndexName, CountName))
        Case ArgumentOutOfRange_LBound:             Throw Cor.NewArgumentOutOfRangeException(Message, IndexName, Index)
        Case ArgumentOutOfRange_NeedNonNegNum:      Throw Cor.NewArgumentOutOfRangeException(Message, CountName, Count)
        Case Argument_InvalidCountOffset:           Throw Cor.NewArgumentException("The index plus the count extends past the end of the list or string", "Count")
    End Select
End Sub

''
' Assigns values to the missing Index and Count pair, returning any error codes.
'
' @param RangeSize The number of elements in the range to verify against.
' @param OptionalIndex The optional Index variable in the public interface.
' @param ReturnIndex The return value for Index.
' @param OptionalCount The optional Count variable in the public interface.
' @param ReturnCount The return value for Count.
' @return Returns NO_ERROR if successful, otherwise an error code is returned.
' @remarks This has a hardcoded lowerbound of 0 for the start of the list.
'
Public Function GetOptionalListRange(ByVal RangeSize As Long, _
                                     ByRef OptionalIndex As Variant, ByRef ReturnIndex As Long, _
                                     ByRef OptionalCount As Variant, ByRef ReturnCount As Long) As Long
    ' This function is optimized by not refactoring
    ' common sections with other helper rountine in
    ' order to cut down on total function calls.
    
    ' Get our optional values.
    Dim result As Long
    result = GetOptionalLongPair(OptionalIndex, 0, ReturnIndex, OptionalCount, RangeSize, ReturnCount)
    If result <> NO_ERROR Then
        GetOptionalListRange = result
        Exit Function
    End If
    
    ' Can't have an index before the start of the range.
    If ReturnIndex < 0 Then
        GetOptionalListRange = ArgumentOutOfRange_LBound    ' this should be mapped to ArgumentOutOfRange_NeedNonNegNum
        Exit Function
    End If
    
    ' Can't have a negative count.
    If ReturnCount < 0 Then
        GetOptionalListRange = ArgumentOutOfRange_NeedNonNegNum
        Exit Function
    End If
    
    ' Can't have the range extend past the beginning of the array.
    If ReturnIndex + ReturnCount > RangeSize Then
        GetOptionalListRange = Argument_InvalidCountOffset
    End If
End Function

