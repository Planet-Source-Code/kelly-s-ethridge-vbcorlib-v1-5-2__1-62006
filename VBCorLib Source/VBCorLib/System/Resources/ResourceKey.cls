VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 1  'Persistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "ResourceKey"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
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
'    Module: ResourceKey
'

''
' This class represents a Resource key by containing the 3 primary
' identifiers for a Windows resource.
'
' @remarks A Windows resource uses up to 3 identifying values that when
' combined are unique within the specific resource set. The <b>LanguageID</b>,
' <b>ResourceName</b>, and <b>ResourceType</b> are combined to create a single
' unique identifier for a Windows resource.
'
Option Explicit
Implements IObject

''
' The type of resources acknowledged by Windows. These are used
' when a resource type is requested in function calls.
'
' @param CursorResource A Windows cursor resource type.
' @param BitmapResource A bitmap resource type.
' @param IconResource An icon resource type.
' @param MenuResource A menu set resource type.
' @param DialogBox A dialog box resource type.
' @param StringResource A String resource type.
' @param FontDirectory A font directory resource type.
' @param FontResource A font resource type.
' @param AcceleratorTable An accelerator table resource type.
' @param UserDefined A user-defined resource type.
' @param GroupCursor A group cursor resource type.
' @param GroupIcon A group icon resource type.
' @param VersionResource A version resource type.
' @param DialogInclude A dialog include resource type.
' @param PlugPlay A plug-n-play resource type.
' @param VXD A VXD resource type.
' @param AniCursor An animated cursor resource type.
' @param AniIcon An animated icon resource type.
' @param HTML An html resource type.
'
Public Enum ResourceTypes
    CursorResource = 1
    BitmapResource = 2
    IconResource = 3
    MenuResource = 4
    DialogBox = 5
    StringResource = 6
    FontDirectory = 7
    FontResource = 8
    AcceleratorTable = 9
    UserDefined = 10
    GroupCursor = 12
    GroupIcon = 14
    VersionResource = 16
    DialogInclude = 17
    PlugPlay = 19
    VXD = 20
    AniCursor = 21
    AniIcon = 22
    HTML = 23
End Enum


Private mResourceName   As Variant
Private mResourceType   As Variant
Private mLanguageID     As Long
Private mHashCode       As Long


''
' Returns the Name or ID of the resource.
'
' @remarks A String or Numeric value.
' @remarks A resource can have an identification as either
' a string name or a numeric value. A string name of "101"
' is not the same as a numeric value of 101.
'
Public Property Get ResourceName() As Variant
    ResourceName = mResourceName
End Property

''
' Returns the Name or ID of the resource type.
'
' @return A String or Numeric value.
' @remarks A resource can be a type that is defined by the
' system. A system type is numeric. A custom resource type
' usually uses a name for the type.
'
Public Property Get ResourceType() As Variant
    ResourceType = mResourceType
End Property

''
' Returns the language this resource is identified with.
'
' @return The LCID or language ID for this resource.
'
Public Property Get LanguageID() As Long
    LanguageID = mLanguageID
End Property

''
' Determines if this object and the value are equal.
'
' @remarks Value The value to compare to this object instance.
' @return Returns True if the value and object are equal, otherwise False.
' @remarks The value is equal if it is a <b>ResourceKey</b> with the
' same <b>LanguageID</b>, <b>ResourceName</b>, and <b>ResourceType</b>.
'
Public Function Equals(ByRef Value As Variant) As Boolean
    If IsObject(Value) Then
        If Value Is Nothing Then Exit Function
        
        If TypeOf Value Is ResourceKey Then
            Dim ResKey As ResourceKey
            Set ResKey = Value
            
            ' If either key is INVARIANT then we
            ' don't bother comparing the language ID's.
            If ResKey.LanguageID <> 0 And mLanguageID <> 0 Then
                If ResKey.LanguageID <> mLanguageID Then Exit Function
            End If
            If Not EqualStringOrInt(ResKey.ResourceName, mResourceName) Then Exit Function
            Equals = EqualStringOrInt(ResKey.ResourceType, mResourceType)
        End If
    End If
End Function

''
' Returns a pseudo-unique hashcode that represents this object.
'
' @return A pseudo-unique hashcode that represents this object.
' @remarks The <b>ResourceName</b>, <b>ResourceType</b>, and <b>LanguageID</b>
' are all used to create the hashcode.
'
Public Function GetHashCode() As Long
    GetHashCode = mHashCode
End Function

''
' Returns a String representation of this object.
'
' @return A String representation of this object.
'
Public Function ToString() As String
    ToString = cString.Format("Name: {0}, Type: {1}, Language: {2}", mResourceName, mResourceType, mLanguageID)
End Function


'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'   Friend Interface
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
Friend Sub Init(ByRef ResourceName As Variant, ByRef ResourceType As Variant, ByVal LanguageID As Long)
    mLanguageID = LanguageID
    
    Call SetStringOrInt(ResourceName, mResourceName)
    Call SetStringOrInt(ResourceType, mResourceType)
    Call SetHashCode
End Sub


'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'   Private Helpers
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
Private Sub SetStringOrInt(ByRef Source As Variant, ByRef Destination As Variant)
    Select Case VarType(Source)
        Case vbString
            Destination = Source
        Case vbLong, vbInteger, vbByte
            Destination = CLng(Source)
        Case Else
            Throw Cor.NewArgumentException("Name and ResourceType must be either a String or a Number.")
    End Select
End Sub

Private Function EqualStringOrInt(ByRef x As Variant, ByRef y As Variant) As Boolean
    If VarType(x) <> VarType(y) Then Exit Function
    If VarType(x) = vbString Then
        EqualStringOrInt = (StrComp(x, y, vbTextCompare) = 0)
    Else
        EqualStringOrInt = (x = y)
    End If
End Function

Private Sub SetHashCode()
    mHashCode = GetHashedValue(mResourceName) Xor GetHashedValue(mResourceType) Xor mLanguageID
End Sub

Private Function GetHashedValue(ByRef Value As Variant) As Long
    If VarType(Value) = vbString Then
        GetHashedValue = Object.GetHashCode(LCase$(Value))
    Else
        GetHashedValue = Object.GetHashCode(Value)
    End If
End Function


'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'   Class Events
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
Private Sub Class_ReadProperties(PropBag As PropertyBag)
    With PropBag
        mResourceName = .ReadProperty("Name")
        mResourceType = .ReadProperty("Type")
        mLanguageID = .ReadProperty("LCID")
    End With
End Sub

Private Sub Class_WriteProperties(PropBag As PropertyBag)
    With PropBag
        Call .WriteProperty("Name", mResourceName)
        Call .WriteProperty("Type", mResourceType)
        Call .WriteProperty("LCID", mLanguageID)
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
