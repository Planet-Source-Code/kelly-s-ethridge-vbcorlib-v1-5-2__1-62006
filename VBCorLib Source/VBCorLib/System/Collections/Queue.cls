VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 1  'Persistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "Queue"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
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
'    Module: Queue
'

''
' Provides a collections that maintains a list of items in a First-in-First-Out
' sequence.
'
' @see Constructors
' @see ICollection
' @see IEnumerable
' @see ICloneable
'
Option Explicit
Implements IObject
Implements ICloneable
Implements ICollection
Implements IEnumerable

Private Const DEF_CAPACITY As Long = 16

Private mItems()    As Variant
Private mHead       As Long
Private mTail       As Long
Private mCapacity   As Long
Private mCount      As Long
Private mVersion    As Long


''
' Clears the contents of the queue
'
' @remarks Event though the contents are cleared, the capacity
' of the queue is unchanged.
'
Public Sub Clear()
    mCount = 0
    mHead = 0
    mTail = 0
    ReDim mItems(0 To mCapacity - 1)
    mVersion = mVersion + 1
End Sub

''
' Returns a clone of the queue.
'
' @remarks Returns a second queue with the same contents as the original.
'
Public Function Clone() As Object
    Dim ret As New Queue
    Call ret.CloneHelper(mItems, mCount, mHead, mTail)
    Set Clone = ret
End Function

''
' Determines if the queue contains a specific value.
'
' @param value The value to search for in the queue.
' @param comparer A user supplied comparer for custom comparisons.
' @return Value indicating if the value was found.
' @remarks If more than one instance of the same value exists in the
' queue, this will stop once it finds the first instance.
'
Public Function Contains(ByRef Value As Variant, Optional ByVal comparer As IComparer) As Boolean
    Dim i As Long
    Dim j As Long
    
    j = mHead
    If comparer Is Nothing Then
        For i = 1 To mCount
            If EqualsVariants(mItems(j), Value) Then
                Contains = True
                Exit Function
            End If
            j = (j + 1) Mod mCapacity
        Next i
    Else
        For i = 1 To mCount
            If comparer.Compare(mItems(j), Value) = 0 Then
                Contains = True
                Exit Function
            End If
            j = (j + 1) Mod mCapacity
        Next i
    End If
End Function

''
' Copy the contents of the queue to an array.
'
' @param dstArray The array to copy the contents to.
' @param index The starting index in the dstArray to copy the contents to.
' @remarks The values in the queue will be cast to the array datatype if possible.
'
Public Sub CopyTo(ByRef DstArray As Variant, ByVal Index As Long)
    If mHead < mTail Then
        Call cArray.CopyEx(mItems, mHead, DstArray, Index, mCount)
    Else
        Call cArray.CopyEx(mItems, mHead, DstArray, Index, mCapacity - mHead)
        Call cArray.CopyEx(mItems, 0, DstArray, (mCapacity - mHead) + Index, mTail)
    End If
End Sub

''
' Returns the number of items in the queue.
'
' @return The number of items in the queue.
'
Public Property Get Count() As Long
    Count = mCount
End Property

''
' Returns the item at the head of the queue and removes that item from the queue.
'
' @return The item at the head of the queue.
'
Public Function Dequeue() As Variant
    If mCount = 0 Then _
        Throw Cor.NewInvalidOperationException(Environment.GetResourceString(InvalidOperation_EmptyQueue))
    
    Call Helper.MoveVariant(Dequeue, mItems(mHead))
    mHead = (mHead + 1) Mod mCapacity
    mCount = mCount - 1
    mVersion = mVersion + 1
End Function

''
' Adds an item to the tail of the queue, expanding the queue as necessary.
'
' @param value The item to be placed at the tail of the queue.
'
Public Sub Enqueue(ByRef Value As Variant)
    Call EnsureCapacity(mCount + 1)
    Call VariantCopyInd(mItems(mTail), Value)
    mTail = (mTail + 1) Mod mCapacity
    mCount = mCount + 1
    mVersion = mVersion + 1
End Sub

''
' Returns a boolean indicating if the value and this object
' instance are the same instance.
'
' @param value The value to compare equality to.
' @return Boolean indicating equality.
'
Public Function Equals(ByRef Value As Variant) As Boolean
    Equals = Object.Equals(Me, Value)
End Function

''
' Returns an enumerator for the queue.
'
' @return Enumerator to allow iterating over the queue.
'
Public Function GetEnumerator() As IEnumerator
    Dim ret As New QueueEnumerator
    Call ret.Init(Me, mHead, SAPtr(mItems))
    Set GetEnumerator = ret
End Function

''
' Returns a pseudo-unique number identifying this instance.
'
' @return Pseudo-unique number identifying this instance.
'
Public Function GetHashCode() As Long
    GetHashCode = ObjPtr(CUnk(Me))
End Function

''
' Returns an enumerator compatible with For..Each convention.
'
' @return The enumerator object.
'
Public Function NewEnum() As IUnknown
Attribute NewEnum.VB_UserMemId = -4
Attribute NewEnum.VB_MemberFlags = "40"
    Set NewEnum = CreateEnumerator(GetEnumerator)
End Function

''
' Returns the next value to be removed from the queue without
' removing the value from the queue.
'
' @return The next value in the queue.
'
Public Function Peek() As Variant
    If mCount = 0 Then _
        Throw Cor.NewInvalidOperationException(Environment.GetResourceString(InvalidOperation_EmptyQueue))
    
    Call VariantCopy(Peek, mItems(mHead))
End Function

''
' Returns the contents of the queue in a variant array.
'
' @return An array of variants containing the queue contents.
'
Public Function ToArray() As Variant()
    Dim ret() As Variant
    ret = cArray.CreateInstance(ciVariant, mCount)
    If mCount > 0 Then Call CopyTo(ret, 0)
    ToArray = ret
End Function

''
' Returns a string representation of this object instance.
'
' @return String representing this instance.
'
Public Function ToString() As String
    ToString = Object.ToString(Me, App)
End Function

''
' Resizes the internal capacity to match the number of items in the queue.
'
Public Sub TrimToSize()
    If mCount = 0 Then
        ReDim mItems(0 To DEF_CAPACITY - 1)
        mCapacity = DEF_CAPACITY
    Else
        Call NormalizeArray(mCount)
        mCapacity = mCount
    End If
    mVersion = mVersion + 1
End Sub


'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'   Friend Interface
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
Friend Sub CloneHelper(ByRef Items() As Variant, ByVal Count As Long, ByVal head As Long, ByVal tail As Long)
    mItems = Items
    mCount = Count
    mHead = head
    mTail = tail
    mCapacity = UBound(Items) + 1
End Sub

Friend Property Get Version() As Long
    Version = mVersion
End Property

Friend Sub Init(ByRef c As Variant)
    Call WriteRange(c)
End Sub


'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'   Private Helpers
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
Private Sub NormalizeArray(ByVal NewCapacity As Long)
    Dim NewItems() As Variant
    
    If mHead = 0 Then
        If NewCapacity <> mCapacity Then
            ReDim Preserve mItems(0 To NewCapacity - 1)
        End If
    Else
        ReDim NewItems(0 To NewCapacity - 1)
        If mHead < mTail Then
            Call CopyMemory(NewItems(0), mItems(mHead), (mTail - mHead) * 16)
            Call ZeroMemory(mItems(mHead), (mTail - mHead) * 16)
        Else
            Call CopyMemory(NewItems(0), mItems(mHead), (mCapacity - mHead) * 16)
            Call CopyMemory(NewItems(mCapacity - mHead), mItems(0), mHead * 16)
            Call ZeroMemory(mItems(0), (mCapacity - 1) * 16)
        End If
        Call Helper.Swap4(ByVal ArrPtr(mItems), ByVal ArrPtr(NewItems))
    End If
    mTail = mCount
    mHead = 0
End Sub

Private Sub EnsureCapacity(ByVal RequiredCapacity As Long)
    Dim NewCapacity As Long
    
    If RequiredCapacity <= mCapacity Then Exit Sub
    NewCapacity = mCapacity * 2
    If RequiredCapacity > NewCapacity Then NewCapacity = RequiredCapacity
    Call NormalizeArray(NewCapacity)
    mCapacity = NewCapacity
End Sub

Private Sub WriteRange(ByRef c As Variant)
    If IsArray(c) Then
        Call WriteArray(c)
    ElseIf IsObject(c) Then
        If c Is Nothing Then _
            Throw Cor.NewArgumentNullException(Environment.GetResourceString(ArgumentNull_Collection), "c")
        
        If TypeOf c Is Collection Then
            Call WriteVBCollection(c)
        ElseIf TypeOf c Is ICollection Then
            Call WriteICollection(c)
        Else
            Throw Cor.NewInvalidCastException("An ICollection or VBA.Collection object is required.")
        End If
    Else
        Throw Cor.NewInvalidCastException("An Array, ICollection, or VBA.Collection object is required.")
    End If

End Sub

Private Sub WriteArray(ByRef Arr As Variant)
    If cArray.IsNull(Arr) Then _
        Throw Cor.NewArgumentNullException(Environment.GetResourceString(ArgumentNull_Array), "c")
    
    ' Get the number of elements in the array
    Dim SizeOfArray As Long
    SizeOfArray = UBound(Arr) - LBound(Arr) + 1
    
    Call WriteCollection(SizeOfArray, Arr)
End Sub

Private Sub WriteVBCollection(ByVal CollectionToInsert As Collection)
    Call WriteCollection(CollectionToInsert.Count, CollectionToInsert)
End Sub

Private Sub WriteICollection(ByVal CollectionToInsert As ICollection)
    Call WriteCollection(CollectionToInsert.Count, CollectionToInsert)
End Sub

Private Sub WriteCollection(ByVal SizeOfCollection As Long, ByRef CollectionToWrite As Variant)
    Call EnsureCapacity(SizeOfCollection)
        
    Dim Value As Variant
    Dim Index As Long
    For Each Value In CollectionToWrite
        Call Helper.MoveVariant(mItems(Index), Value)
        Index = Index + 1
    Next Value
    mCount = SizeOfCollection
End Sub


'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'   Class Events
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
Private Sub Class_InitProperties()
    ReDim mItems(0 To DEF_CAPACITY - 1)
    mCapacity = DEF_CAPACITY
End Sub

Private Sub Class_ReadProperties(PropBag As PropertyBag)
    With PropBag
        mCount = .ReadProperty("Count", 0)
        mHead = .ReadProperty("Head", 0)
        mTail = .ReadProperty("Tail", 0)
        Call EnsureCapacity(.ReadProperty("Capacity", DEF_CAPACITY))
        ReDim mItems(0 To mCapacity - 1)
        
        Dim i As Long
        For i = 0 To mCount - 1
            Call Helper.MoveVariant(mItems(i), .ReadProperty("Item" & i, Empty))
        Next i
    End With
End Sub

Private Sub Class_WriteProperties(PropBag As PropertyBag)
    With PropBag
        Call .WriteProperty("Count", mCount)
        Call .WriteProperty("Head", mHead)
        Call .WriteProperty("Tail", mTail)
        Call .WriteProperty("Capacity", mCapacity)
        
        Call NormalizeArray(mCapacity)
        
        Dim i As Long
        For i = 0 To mCount - 1
            Call .WriteProperty("Item" & i, mItems(i))
        Next i
    End With
End Sub


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


'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'   ICloneable Interface
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
Private Function ICloneable_Clone() As Object
    Set ICloneable_Clone = Clone
End Function


'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'   ICollection Interface
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
Private Sub ICollection_CopyTo(Arr As Variant, ByVal Index As Long)
    Call CopyTo(Arr, Index)
End Sub

Private Property Get ICollection_Count() As Long
    ICollection_Count = Count
End Property

Private Function ICollection_GetEnumerator() As IEnumerator
    Set ICollection_GetEnumerator = GetEnumerator
End Function

Private Function ICollection_NewEnum() As stdole.IUnknown
    Set ICollection_NewEnum = NewEnum
End Function


'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'   IEnumerable Interface
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
Private Function IEnumerable_GetEnumerator() As IEnumerator
    Set IEnumerable_GetEnumerator = GetEnumerator
End Function

Private Function IEnumerable_NewEnum() As stdole.IUnknown
    Set IEnumerable_NewEnum = NewEnum
End Function
