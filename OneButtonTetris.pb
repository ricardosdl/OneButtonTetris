EnableExplicit

#Game_Width = 800
#Game_Height = 600
#PlayFieldSize_Width = 10;pieces
#PlayFieldSize_Height = 20;pieces
#Piece_Width = (#Game_Height / 2) / #PlayFieldSize_Width
#Piece_Height = #Piece_Width
#Piece_Size = 4
#Piece_Templates = 19
#Fall_Time = 0.2

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

Enumeration TGameState
  #ChoosingFallingPiece
  #ChoosingFallingPiecePosition
  #WaitingFallingPiece
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
  FallingTimer.f
  IsFalling.a
EndStructure


Structure TPlayField
  x.f
  y.f
  ;stores the tpieceinfo
  Array PlayField.u(#PlayFieldSize_Width - 1, #PlayFieldSize_Height - 1)
  Width.f
  Height.f
EndStructure

Structure TFallingPieceWheel
  x.f
  y.f
  PieceType.a
  CurrentTimer.f
EndStructure


Global ElapsedTimneInS.f, LastTimeInMs.q
Global Dim PieceTemplates.TPieceTemplate(#Piece_Templates - 1)
Global PlayField.TPlayField, FallingPiece.TFallingPiece, FallingPieceWheel.TFallingPieceWheel
Global Dim PiecesConfiguration.TPieceConfiguration(#Right4)

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

Procedure InitPlayField()
  PlayField\x = 0
  PlayField\y = 0
  Protected.u x, y
  For x = 0 To #PlayFieldSize_Width - 1
    For y = 0 To #PlayFieldSize_Height - 1
      PlayField\PlayField(x, y) = #Empty
    Next y
    
  Next x
  PlayField\Width = #PlayFieldSize_Width * #Piece_Width
  PlayField\Height = #PlayFieldSize_Height * #Piece_Height
  
EndProcedure

Procedure InitFallingPieceWheel()
  FallingPieceWheel\CurrentTimer = 0
  FallingPieceWheel\PieceType = Random(#Right4, #Line)
  FallingPieceWheel\x = PlayField\x + PlayField\Width + 10
  FallingPieceWheel\y = PlayField\y + PlayField\Height / 2 - (#Piece_Size * #Piece_Height) / 2
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
  CloseFile(0)
EndProcedure

Procedure LoadPiecesConfigurations()
  PiecesConfiguration(#Line)\PieceType = #Line
  PiecesConfiguration(#Line)\NumConfigurations = 2
  StringListToAsciiList("0,1", PiecesConfiguration(#Line)\PieceTemplates())
  
  PiecesConfiguration(#Square)\PieceType = #Square
  PiecesConfiguration(#Square)\NumConfigurations = 1
  StringListToAsciiList("2", PiecesConfiguration(#Square)\PieceTemplates())
  
  PiecesConfiguration(#LeftL)\PieceType = #LeftL
  PiecesConfiguration(#LeftL)\NumConfigurations = 4
  StringListToAsciiList("3,4,5,6", PiecesConfiguration(#LeftL)\PieceTemplates())
  
  PiecesConfiguration(#RightL)\PieceType = #RightL
  PiecesConfiguration(#RightL)\NumConfigurations = 4
  StringListToAsciiList("7,8,9,10", PiecesConfiguration(#RightL)\PieceTemplates())
  
  PiecesConfiguration(#Left4)\PieceType = #Left4
  PiecesConfiguration(#Left4)\NumConfigurations = 2
  StringListToAsciiList("11,12", PiecesConfiguration(#Left4)\PieceTemplates())
  
  PiecesConfiguration(#Tee)\PieceType = #Tee
  PiecesConfiguration(#Tee)\NumConfigurations = 4
  StringListToAsciiList("13,14,15,16", PiecesConfiguration(#Tee)\PieceTemplates())
  
  PiecesConfiguration(#Right4)\PieceType = #Right4
  PiecesConfiguration(#Right4)\NumConfigurations = 2
  StringListToAsciiList("17,18", PiecesConfiguration(#Right4)\PieceTemplates())
  
  
  
EndProcedure

; Procedure.a GetPieceFirstConfiguration(PieceType.a)
;   FirstElement(PiecesConfiguration(PieceType)\PieceTemplates())
;   ProcedureReturn PiecesConfiguration(PieceType)\PieceTemplates()
; EndProcedure

Macro GetPieceFirstConfiguration(PieceType, FirstConfiguration)
  FirstElement(PiecesConfiguration(PieceType)\PieceTemplates())
  FirstConfiguration = PiecesConfiguration(PieceType)\PieceTemplates()
EndMacro

Procedure.a GetPieceTemplateIdx(PieceType.a, Configuration.a)
  Protected FirstConfiguration.a
  GetPieceFirstConfiguration(PieceType, FirstConfiguration)
  
  Protected NumConfigurations.a = PiecesConfiguration(PieceType)\NumConfigurations
  
  ProcedureReturn FirstConfiguration + (Configuration % NumConfigurations)
  
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
  If Not FallingPiece\IsFalling
    ProcedureReturn
  EndIf
  
  Protected x.w = FallingPiece\PosX
  Protected y.w = FallingPiece\PosY
  Protected PieceType.a = FallingPiece\Type
  
  Protected PieceTemplateIdx.a = GetPieceTemplateIdx(PieceType, FallingPiece\Configuration)
  
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

Procedure DrawFallingPieceWheel()
  Protected PieceConfiguration.a
  GetPieceFirstConfiguration(FallingPieceWheel\PieceType, PieceConfiguration)
  
  Protected PieceTemplateIdx.a = GetPieceTemplateIdx(FallingPieceWheel\PieceType, PieceConfiguration)
  
  Protected i.u, j.u
  For i = 0 To #Piece_Size - 1
    For j = 0 To #Piece_Size - 1
      If PieceTemplates(PieceTemplateIdx)\PieceTemplate(i, j)
        Box(FallingPieceWheel\x + i * #Piece_Width, FallingPieceWheel\y + j * #Piece_Height, #Piece_Width - 1, #Piece_Height - 1, RGB($7f, 0, 0))
      EndIf
      
    Next j
    
  Next i
  
  
  
EndProcedure


Procedure DrawPlayFieldOutline()
  ;LineXY(PlayField\x + 1, PlayField\y + 1, #PlayFieldSize_Width * #Piece_Width, PlayField\y, RGB($7f, 80, 70))
  Line(PlayField\x + 1, PlayField\y + 1, #PlayFieldSize_Width * #Piece_Width, 1, RGB($7f, 80, 70))
  Line(PlayField\x + #PlayFieldSize_Width * #Piece_Width, 1, 1, #PlayFieldSize_Height * #Piece_Height, RGB($7f, 80, 70))
EndProcedure



Procedure Draw()
  Protected x.u, y.u
  StartDrawing(ScreenOutput())
  For x = 0 To #PlayFieldSize_Width - 1
    For y = 0 To #PlayFieldSize_Height - 1
      If (PlayField\PlayField(x, y) & #Empty)
        Continue
      EndIf
      
      Protected PieceInfo.u = PlayField\PlayField(x, y)
      Protected PieceColor = GetPieceColor(PieceInfo)
      Box(PlayField\x + x * #Piece_Width, PlayField\y + y * #Piece_Height, #Piece_Width - 1, #Piece_Height - 1, PieceColor)
    Next y
  Next x
  
  DrawFallingPiece()
  
  DrawPlayFieldOutline()
  
  DrawFallingPieceWheel()
  
  StopDrawing()
EndProcedure

Procedure.a IsCellWithinPlayField(CellX.w, CellY.w)
  ProcedureReturn Bool((CellX >= 0  And CellX < #PlayFieldSize_Width) And
                       (CellY >= 0 And CellY < #PlayFieldSize_Height))
EndProcedure

Procedure SaveFallingPieceOnPlayField()
  Protected PieceTemplateIdx.a = GetPieceTemplateIdx(FallingPiece\Type, FallingPiece\Configuration)
  Protected i.u, j.u
  For i = 0 To #Piece_Size - 1
    For j = 0 To #Piece_Size - 1
      If PieceTemplates(PieceTemplateIdx)\PieceTemplate(i, j)
        Protected XCell.w = FallingPiece\PosX + i
        Protected YCell.w = FallingPiece\PosY + j
        If Not IsCellWithinPlayField(XCell, YCell)
          Continue
        EndIf
        
        PlayField\PlayField(XCell, YCell) = #Filled | #RedColor
      EndIf
      
    Next j
    
  Next i
EndProcedure


Procedure LaunchFallingPiece(Type.a, PosX.w = 0, PosY.w = -3)
  FallingPiece\PosX = PosX
  FallingPiece\PosY = PosY
  FallingPiece\Type = Type
  FallingPiece\Configuration = 0
  FallingPiece\IsFalling = #True
EndProcedure

Procedure LaunchRandomFallingPiece()
  LaunchFallingPiece(Random(#Right4, #Line))
EndProcedure




Procedure UpdateFallingPiece(Elapsed.f)
  ;gets the number of configuration this piecetype has
  Protected NumConfigurations.a = PiecesConfiguration(FallingPiece\Type)\NumConfigurations
  
  ;gets the current template used by the falling piece
  Protected PieceTemplateIdx.a = GetPieceTemplateIdx(FallingPiece\Type, FallingPiece\Configuration)
  
  If KeyboardReleased(#PB_Key_Space)
    FallingPiece\Configuration = (FallingPiece\Configuration + 1) % NumConfigurations
  EndIf
  
  ;check hit with bottom of playfield
  Protected i.u, j.u
  For i = 0 To #Piece_Size - 1
    If Not FallingPiece\IsFalling
      Break
    EndIf
    For j = 0 To #Piece_Size - 1
      If PieceTemplates(PieceTemplateIdx)\PieceTemplate(i, j)
        Protected XCell.w = FallingPiece\PosX + i
        Protected YCell.w = FallingPiece\PosY + j
        If YCell > #PlayFieldSize_Height - 1
          ;hit bottom of playfield
          FallingPiece\PosY - 1;put the fallingpiece one line above
          FallingPiece\IsFalling = #False
          SaveFallingPieceOnPlayField()
          Break
        EndIf
        
        If Not IsCellWithinPlayField(XCell, YCell)
          Continue
        EndIf
        
        If PlayField\PlayField(XCell, YCell) & #Filled
          ;hit with filled cell on playfield
          FallingPiece\PosY - 1;put the fallingpiece one line above
          FallingPiece\IsFalling = #False
          SaveFallingPieceOnPlayField()
          Break
        EndIf
        
        
        
        
        
        
        
        
        
      EndIf
    Next j
  Next i
  
  ;check hits with the playfield
  For i = 0 To #PlayFieldSize_Width - 1
    For j = 0 To #PlayFieldSize_Height - 1
      If PlayField\PlayField(i, j) & #Empty
        ;this playfield cell is empty
        Continue
      EndIf
      
      
      
    Next j
  Next i
  
  
  
  If FallingPiece\IsFalling
    
    FallingPiece\FallingTimer + Elapsed
    If FallingPiece\FallingTimer >= #Fall_Time
      ;fall down one line
      FallingPiece\PosY + 1
      FallingPiece\FallingTimer = 0.0
    EndIf
  EndIf
  
  ;check collisions
  
  ;check collisions with the bottom
  ;FallingPiece\
  
EndProcedure


Procedure Update(Elapsed.f)
  UpdateFallingPiece(Elapsed)
EndProcedure



InitSprite()
InitKeyboard()

LoadPiecesTemplate()
LoadPiecesConfigurations()
InitPlayField()
InitFallingPieceWheel()

OpenWindow(1, 0,0, #Game_Width, #Game_Height,"One Button Tetris", #PB_Window_ScreenCentered)
OpenWindowedScreen(WindowID(1),0,0, #Game_Width, #Game_Height , 0, 0, 0)

LastTimeInMs = ElapsedMilliseconds()
;LaunchRandomFallingPiece()

Repeat
  ElapsedTimneInS = (ElapsedMilliseconds() - LastTimeInMs) / 1000.0
  LastTimeInMs = ElapsedMilliseconds()
  ExamineKeyboard()
  Global event = WindowEvent()
  
  ;Update
  Update(ElapsedTimneInS)
  
  ;Draw
  ClearScreen(#Black)
  Draw()
  
  
  FlipBuffers()
Until event = #PB_Event_CloseWindow Or KeyboardPushed(#PB_Key_Escape)
End