VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "IResourceWriter"
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
'    Module: IResourceWriter
'

''
' Provides an interface for resource writers.
'
' @remarks Implement this interface to allow multiple resource writer
' types to be shared for different resources.
'
Option Explicit

''
' Adds a new resource to the collection of resources to be written.
'
' @param Name The identifier of the resource value.
' @param Value The value of the resource.
' @param LanguageID A CultureInfo, Culture Name, or LCID.
' @param ResourceType A number or name of the resource type.
'
Public Sub AddResource(ByRef Value As Variant, ByRef ResourceName As Variant, Optional ByRef ResourceType As Variant, Optional ByRef LanguageID As Variant): End Sub

''
' Creates the resource collection from the set of resources added to the writer.
'
Public Sub Generate(): End Sub

''
' Closes the resource writer.
'
Public Sub CloseWriter(): End Sub

