EnableExplicit

#Game_Width = 800
#Game_Height = 600
#PlayFieldSize_Width = 10;pieces
#PlayFieldSize_Height = 20;pieces
#Piece_Width = (#Game_Height / 2) / #PlayFieldSize_Width
#Piece_Height = #Piece_Width
#Piece_Size = 4
#Piece_Templates = 19

EnumerationBinary TPieceInfo
  #Empty
  #Filled
  #RedColor
  #BlueColor
  #YellowColor
  #MagentaColor
  #CyanColor
  #GreenColor
  #OrangeColor
EndEnumeration

Enumeration TPieceType
  #Line
  #Square
  #LeftL
  #RightL
  #Left4
  #Tee
  #Right4
EndEnumeration

Structure TPieceTemplate
  Array PieceTemplate.u(#Piece_Size - 1, #Piece_Size - 1)
EndStructure

Structure TPieceConfiguration
  PieceType.a
  NumConfigurations.a
  List PieceTemplates.a()
EndStructure




Structure TFallingPiece
  PosX.w
  PosY.w
  Type.a
  Configuration.a
  Array Pieces.u(#Piece_Size - 1, #Piece_Size - 1)
  
EndStructure


Structure TPlayField
  ;stores the tpieceinfo
  Array PlayField.u(#PlayFieldSize_Width - 1, #PlayFieldSize_Height - 1)
EndStructure

Global ElapsedTimneInS.f, LastTimeInMs.q
Global Dim PieceTemplates.TPieceTemplate(#Piece_Templates - 1)
Global PlayField.TPlayField, FallingPiece.TFallingPiece
Global NewMap PiecesConfiguration.TPieceConfiguration()

;Reads a list of integers separated by Separator and put them on IntegerList()
;no check is performed for valid integers in StringList
Procedure StringListToAsciiList(StringList.s, List AsciiList.a(), Separator.s = ",")
  ;our input AsciiList is cleaned, then we read the values on StringList
  ;one by one using Separator to find them, and put them in IntegerList
  ClearList(AsciiList())
  Protected NumItemsList.i =  CountString(StringList, Separator) + 1
  Protected i.i
  For i = 1 To NumItemsList
    AddElement(AsciiList())
    AsciiList() = Val(StringField(StringList, i, Separator))
  Next i
EndProcedure

Procedure SavePieceTemplate(List PieceLines.s(), CurrentPieceTemplate.a)
  Protected PieceTemplateLine.a = 0
  ForEach PieceLines()
    Protected PieceLine.s = PieceLines()
    Protected PieceLineSize = Len(PieceLine)
    Protected i.a
    For i = 1 To PieceLineSize
      Protected Value.a = Val(Mid(PieceLine, i, 1))
      Protected PieceTemplateColumn.a = i - 1
      PieceTemplates(CurrentPieceTemplate)\PieceTemplate(PieceTemplateColumn, PieceTemplateLine) = Value
    Next i
    PieceTemplateLine + 1
  Next
  
EndProcedure

Procedure LoadPiecesTemplate()
  NewList PiecesLines.s()
  Protected CurrentPieceTemplate.a = 0
  ReadFile(0, "pieces.txt")
  While Eof(0) = 0
    Protected Line.s = ReadString(0)
    If Left(Line, 1) = "-"
      ;finished reading one pices template
      SavePieceTemplate(PiecesLines(), CurrentPieceTemplate)
      ClearList(PiecesLines())
      CurrentPieceTemplate + 1
      Continue
    EndIf
    
    AddElement(PiecesLines())
    PiecesLines() = Line
  Wend
  
EndProcedure

Procedure LoadPiecesConfigurations()
  PiecesConfiguration(Str(#Line))\PieceType = #Line
  PiecesConfiguration(Str(#Line))\NumConfigurations = 2
  StringListToAsciiList("0,1", PiecesConfiguration(Str(#Line))\PieceTemplates())
  
  PiecesConfiguration(Str(#Square))\PieceType = #Square
  PiecesConfiguration(Str(#Square))\NumConfigurations = 1
  StringListToAsciiList("2", PiecesConfiguration(Str(#Square))\PieceTemplates())
  
  PiecesConfiguration(Str(#LeftL))\PieceType = #LeftL
  PiecesConfiguration(Str(#LeftL))\NumConfigurations = 4
  StringListToAsciiList("3,4,5,6", PiecesConfiguration(Str(#LeftL))\PieceTemplates())
  
  PiecesConfiguration(Str(#RightL))\PieceType = #RightL
  PiecesConfiguration(Str(#RightL))\NumConfigurations = 4
  StringListToAsciiList("7,8,9,10", PiecesConfiguration(Str(#RightL))\PieceTemplates())
  
  PiecesConfiguration(Str(#Left4))\PieceType = #Left4
  PiecesConfiguration(Str(#Left4))\NumConfigurations = 2
  StringListToAsciiList("11,12", PiecesConfiguration(Str(#Left4))\PieceTemplates())
  
  PiecesConfiguration(Str(#Tee))\PieceType = #Tee
  PiecesConfiguration(Str(#Tee))\NumConfigurations = 4
  StringListToAsciiList("13,14,15,16", PiecesConfiguration(Str(#Tee))\PieceTemplates())
  
  PiecesConfiguration(Str(#Right4))\PieceType = #Right4
  PiecesConfiguration(Str(#Right4))\NumConfigurations = 2
  StringListToAsciiList("17,18", PiecesConfiguration(Str(#Right4))\PieceTemplates())
  
  
  
EndProcedure



Procedure.q GetPieceColor(PieceInfo.u)
  If PieceInfo & #RedColor
    ProcedureReturn #Red
  ElseIf PieceInfo & #BlueColor
    ProcedureReturn #Blue
  ElseIf PieceInfo & #YellowColor
    ProcedureReturn #Yellow
  ElseIf PieceInfo & #MagentaColor
    ProcedureReturn #Magenta
  ElseIf PieceInfo & #CyanColor
    ProcedureReturn #Cyan
  ElseIf PieceInfo & #GreenColor
    ProcedureReturn #Green
  ElseIf PieceInfo & #OrangeColor
    ProcedureReturn RGBA($FF, $66, $00, 255)
  EndIf
  
  ProcedureReturn #Black
  
EndProcedure

Procedure DrawFallingPiece()
  Protected x.w = FallingPiece\PosX
  Protected y.w = FallingPiece\PosY
  Protected PieceType.a = FallingPiece\Type
  Protected PiecesConfiguration.a = FallingPiece\Configuration
  
  Protected NumConfigurations.a = PiecesConfiguration(Str(PieceType))\NumConfigurations
  
  Static Timer = 0
  Timer + 16
  If Timer > 500
    FallingPiece\Configuration = (FallingPiece\Configuration + 1) % NumConfigurations
    Timer = 0
  EndIf
  
  
  FirstElement(PiecesConfiguration(Str(PieceType))\PieceTemplates())
  
  Protected FirstConfiguration.a = PiecesConfiguration(Str(PieceType))\PieceTemplates()
  
  Protected PieceTemplateIdx.a = FirstConfiguration + (FallingPiece\Configuration % NumConfigurations)
  
  Protected i.u, j.u
  For i = 0 To #Piece_Size - 1
    For j = 0 To #Piece_Size - 1
      If PieceTemplates(PieceTemplateIdx)\PieceTemplate(i, j)
        Box(x * #Piece_Width + i * #Piece_Width, y * #Piece_Height + j * #Piece_Height, #Piece_Width - 1, #Piece_Height - 1, RGB($7f, 0, 0))
        ;Box(100, 100, #Piece_Width - 1, #Piece_Height - 1, RGB($7f, 0, 0))
      EndIf
      
    Next j
    
  Next i
  
  
EndProcedure


Procedure Draw()
  Protected x.u, y.u
  StartDrawing(ScreenOutput())
  For x = 0 To #PlayFieldSize_Width - 1
    For y = 0 To #PlayFieldSize_Height - 1
      Protected PieceInfo.u = PlayField\PlayField(x, y)
      Protected PieceColor = GetPieceColor(PieceInfo)
      Box(x * #Piece_Width, y * #Piece_Height, #Piece_Width - 1, #Piece_Height - 1, PieceColor)
    Next y
  Next x
  
  DrawFallingPiece()
  
  StopDrawing()
EndProcedure




InitSprite()
InitKeyboard()

LoadPiecesTemplate()
LoadPiecesConfigurations()

OpenWindow(1, 0,0, #Game_Width, #Game_Height,"One Button Tetris", #PB_Window_ScreenCentered)
OpenWindowedScreen(WindowID(1),0,0, #Game_Width, #Game_Height , 0, 0, 0)

FallingPiece\PosX = 9
FallingPiece\PosY = 15
FallingPiece\Type = #Right4
FallingPiece\Configuration = 1

LastTimeInMs = ElapsedMilliseconds()

Repeat
  ElapsedTimneInS = (ElapsedMilliseconds() - LastTimeInMs) / 1000.0
  LastTimeInMs = ElapsedMilliseconds()
  ExamineKeyboard()
  Global event = WindowEvent()
  
  ;Update
  
  ;Draw
  ClearScreen(#Black)
  Draw()
  
  
  FlipBuffers()
Until event = #PB_Event_CloseWindow Or KeyboardPushed(#PB_Key_Escape)
End