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
#Falling_Piece_Wheel_Timer = 0.2

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
#Num_Piece_Types = #Right4 + 1

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
  CurrentPieceBackgroundSprite.i
  ChoosedPiece.a
  ChoosedPieceTimer.f
EndStructure

Structure TFallingPiecePosition
  Column.a
  CurrentTimer.f
  ChoosedPosition.a
  ChoosedPositionTimer.f
EndStructure



Global ElapsedTimneInS.f, LastTimeInMs.q
Global Dim PieceTemplates.TPieceTemplate(#Piece_Templates - 1)
Global PlayField.TPlayField, FallingPiece.TFallingPiece, FallingPieceWheel.TFallingPieceWheel,
       FallingPiecePosition.TFallingPiecePosition
Global GameState.a
Global Dim PiecesConfiguration.TPieceConfiguration(#Right4)
Global Dim FallingPieceWheelSprites(#Right4), FallingPiecePositionSprite.i = #False
Global SpaceKeyReleased.i = #False

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

Procedure CreateFallingPiecePositionSprite()
  Protected Sprite = CreateSprite(#PB_Any, #Piece_Width, #PlayFieldSize_Height * #Piece_Height, #PB_Sprite_AlphaBlending)
  If Sprite = 0
    ;error creating
    ProcedureReturn #False
  EndIf
  
  StartDrawing(SpriteOutput(Sprite))
  DrawingMode(#PB_2DDrawing_AllChannels)
  ;Box(0, 0, SpriteWidth(Sprite), SpriteHeight(Sprite), RGBA($ff, $33, $33, 45))
  Box(0, 0, SpriteWidth(Sprite), SpriteHeight(Sprite), RGBA($cc, $ff, $ff, 100))
  StopDrawing()
  
  FallingPiecePositionSprite = Sprite
  
  
EndProcedure


Procedure CreateFallingPieceWheelSprites()
  Protected PieceType.a
  For PieceType = #Line To #Right4
    Protected Sprite = CreateSprite(#PB_Any, #Piece_Size * #Piece_Width,
                                    #Piece_Size * #Piece_Height, #PB_Sprite_AlphaBlending)
    If Sprite <> 0
      StartDrawing(SpriteOutput(Sprite))
      DrawingMode(#PB_2DDrawing_AllChannels)
      Box(0, 0, SpriteWidth(Sprite), SpriteHeight(Sprite), RGBA(0, 0, 0, 0))
      Protected FirstConfiguraton.a
      GetPieceFirstConfiguration(PieceType, FirstConfiguraton)
      Protected PieceTemplateIdx.a = GetPieceTemplateIdx(PieceType, FirstConfiguraton)
      
      Protected x.u, y.u
      For x = 0 To #Piece_Size - 1
        For y = 0 To #Piece_Size - 1
          If PieceTemplates(PieceTemplateIdx)\PieceTemplate(x, y)
            Box(x * #Piece_Width, y * #Piece_Height, #Piece_Width - 1, #Piece_Height - 1, RGBA($7f, 0, 0, $ff))
          EndIf
        Next y
      Next x
      
      StopDrawing()
      FallingPieceWheelSprites(PieceType) = Sprite
    EndIf
    
  Next
  
EndProcedure

Procedure InitFallingPieceWheel()
  FallingPieceWheel\CurrentTimer = 0
  FallingPieceWheel\PieceType = Random(#Right4, #Line)
  FallingPieceWheel\ChoosedPiece = #False
  FallingPieceWheel\ChoosedPieceTimer = 0.0
EndProcedure


Procedure SetupFallingPieceWheel()
  InitFallingPieceWheel()
  FallingPieceWheel\x = PlayField\x + PlayField\Width + 10
  FallingPieceWheel\y = PlayField\y + PlayField\Height / 2 - (#Piece_Size * #Piece_Height) / 2
  FallingPieceWheel\CurrentPieceBackgroundSprite = CreateSprite(#PB_Any, 120, 120, #PB_Sprite_AlphaBlending)
  If FallingPieceWheel\CurrentPieceBackgroundSprite <> 0
    StartDrawing(SpriteOutput(FallingPieceWheel\CurrentPieceBackgroundSprite))
    Box(0, 0, 120, 120, RGB(255, 255, 255))
    StopDrawing()
  EndIf
  
EndProcedure

Procedure InitFallingPiecePosition()
  FallingPiecePosition\Column = 0
  FallingPiecePosition\CurrentTimer = 0
  FallingPiecePosition\ChoosedPosition = #False
  FallingPiecePosition\ChoosedPositionTimer = 0
  
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

Procedure LaunchFallingPiece(Type.a, PosX.w = 0, PosY.w = -3)
  FallingPiece\PosX = PosX
  FallingPiece\PosY = PosY
  FallingPiece\Type = Type
  FallingPiece\Configuration = 0
  FallingPiece\IsFalling = #True
EndProcedure

Procedure ChangeGameState(NewState.a)
  Protected OldGameState.a = GameState
  Select NewState
    Case #ChoosingFallingPiecePosition
      InitFallingPiecePosition()
      InitFallingPieceWheel()
      GameState = NewState
      
    Case #WaitingFallingPiece
      LaunchFallingPiece(FallingPieceWheel\PieceType, FallingPiecePosition\Column)
      GameState = NewState
      
    Case #ChoosingFallingPiece
      GameState = #ChoosingFallingPiece
  EndSelect
  
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
  
  Protected i.a, x.f, y.f
  For i = #Line To #Right4
    Protected Column.a = i % 3
    Protected Line.a = i / 3
    x = PlayField\x + PlayField\Width + 10 + Column * (#Piece_Size * #Piece_Width + 10)
    y = 0 + 10 + Line * (#Piece_Size * #Piece_Height + 10)
    If i = FallingPieceWheel\PieceType
      If Not FallingPieceWheel\ChoosedPiece
        ;just show the background behind the current piece
        DisplayTransparentSprite(FallingPieceWheel\CurrentPieceBackgroundSprite, x, y)
      ElseIf FallingPieceWheel\ChoosedPieceTimer > 0
        Protected Timer.l = (FallingPieceWheel\ChoosedPieceTimer * 1000) / 50
        Protected Intensity = 255 * (Timer % 2)
        DisplayTransparentSprite(FallingPieceWheel\CurrentPieceBackgroundSprite, x, y, Intensity)
      ElseIf FallingPieceWheel\ChoosedPieceTimer <= 0
        DisplayTransparentSprite(FallingPieceWheel\CurrentPieceBackgroundSprite, x, y)
        
      EndIf
      
    EndIf
    
    DisplayTransparentSprite(FallingPieceWheelSprites(i), x, y)
  Next
  
  
EndProcedure


Procedure DrawPlayFieldOutline()
  ;LineXY(PlayField\x + 1, PlayField\y + 1, #PlayFieldSize_Width * #Piece_Width, PlayField\y, RGB($7f, 80, 70))
  Line(PlayField\x + 1, PlayField\y + 1, #PlayFieldSize_Width * #Piece_Width, 1, RGB($7f, 80, 70))
  Line(PlayField\x + #PlayFieldSize_Width * #Piece_Width, 1, 1, #PlayFieldSize_Height * #Piece_Height, RGB($7f, 80, 70))
EndProcedure

Procedure DrawFallingPiecePosition()
  If Not FallingPiecePosition\ChoosedPosition
    DisplayTransparentSprite(FallingPiecePositionSprite, FallingPiecePosition\Column * #Piece_Width, 0)
  ElseIf FallingPiecePosition\ChoosedPositionTimer > 0
    Protected Timer.l = (FallingPiecePosition\ChoosedPositionTimer * 1000) / 50
    Protected Intensity = 255 * (Timer % 2)
    DisplayTransparentSprite(FallingPiecePositionSprite, FallingPiecePosition\Column * #Piece_Width, 0, Intensity)
  ElseIf FallingPiecePosition\ChoosedPositionTimer <= 0
    DisplayTransparentSprite(FallingPiecePositionSprite, FallingPiecePosition\Column * #Piece_Width, 0)
  EndIf
  
EndProcedure

Procedure Draw()
  DrawFallingPiecePosition()
  
  
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
  
  StopDrawing()
  
  DrawFallingPieceWheel()
  
  
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
  ChangeGameState(#ChoosingFallingPiecePosition)
EndProcedure

Procedure LaunchRandomFallingPiece()
  LaunchFallingPiece(Random(#Right4, #Line))
EndProcedure




Procedure UpdateFallingPiece(Elapsed.f)
  ;gets the number of configuration this piecetype has
  Protected NumConfigurations.a = PiecesConfiguration(FallingPiece\Type)\NumConfigurations
  
  ;gets the current template used by the falling piece
  Protected PieceTemplateIdx.a = GetPieceTemplateIdx(FallingPiece\Type, FallingPiece\Configuration)
  
  If SpaceKeyReleased
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

Procedure UpdateFallingPieceWheel(Elapsed.f)
  If GameState <> #ChoosingFallingPiece
    ProcedureReturn
  EndIf
  
  FallingPieceWheel\CurrentTimer + Elapsed
  If FallingPieceWheel\CurrentTimer > #Falling_Piece_Wheel_Timer And (Not FallingPieceWheel\ChoosedPiece)
    ;just cycle through the pieces
    FallingPieceWheel\CurrentTimer  = 0
    FallingPieceWheel\PieceType = (FallingPieceWheel\PieceType + 1) % #Num_Piece_Types
  EndIf
  
  If SpaceKeyReleased And (Not FallingPieceWheel\ChoosedPiece)
    ;the player chose the current piece
    FallingPieceWheel\ChoosedPiece = #True
    FallingPieceWheel\ChoosedPieceTimer = 0.5
  EndIf
  
  If FallingPieceWheel\ChoosedPiece And FallingPieceWheel\ChoosedPieceTimer >=0
    ;we use this timer to flash the chosen piece
    FallingPieceWheel\ChoosedPieceTimer - Elapsed
  EndIf
  
  If FallingPieceWheel\ChoosedPiece And FallingPieceWheel\ChoosedPieceTimer < 0
    ChangeGameState(#WaitingFallingPiece)
  EndIf
  
  
EndProcedure

Procedure CheckKeys()
  ExamineKeyboard()
  SpaceKeyReleased = KeyboardReleased(#PB_Key_Space)
EndProcedure

Procedure UpdateFallingPiecePosition(Elapsed.f)
  If GameState <> #ChoosingFallingPiecePosition
    ProcedureReturn
  EndIf
  
  If SpaceKeyReleased And Not FallingPiecePosition\ChoosedPosition
    FallingPiecePosition\ChoosedPosition = #True
    FallingPiecePosition\ChoosedPositionTimer = 0.5
  EndIf
  
  
  If Not FallingPiecePosition\ChoosedPosition
    FallingPiecePosition\CurrentTimer + Elapsed
  EndIf
  
  If FallingPiecePosition\CurrentTimer > 0.2
    FallingPiecePosition\Column = (FallingPiecePosition\Column + 1) % #PlayFieldSize_Width
    FallingPiecePosition\CurrentTimer = 0
  EndIf
  
  If FallingPiecePosition\ChoosedPositionTimer > 0
    FallingPiecePosition\ChoosedPositionTimer - Elapsed
  EndIf
  
  If FallingPiecePosition\ChoosedPosition And FallingPiecePosition\ChoosedPositionTimer <= 0
    ChangeGameState(#ChoosingFallingPiece)
  EndIf
  
  
  
EndProcedure



Procedure Update(Elapsed.f)
  CheckKeys()
  UpdateFallingPiece(Elapsed)
  UpdateFallingPieceWheel(Elapsed)
  UpdateFallingPiecePosition(Elapsed)
EndProcedure



InitSprite()
InitKeyboard()

OpenWindow(1, 0,0, #Game_Width, #Game_Height,"One Button Tetris", #PB_Window_ScreenCentered)
OpenWindowedScreen(WindowID(1),0,0, #Game_Width, #Game_Height , 0, 0, 0)

LoadPiecesTemplate()
LoadPiecesConfigurations()
InitPlayField()
SetupFallingPieceWheel()
CreateFallingPieceWheelSprites()
CreateFallingPiecePositionSprite()

ChangeGameState(#ChoosingFallingPiecePosition)

LastTimeInMs = ElapsedMilliseconds()
;LaunchRandomFallingPiece()

Repeat
  ElapsedTimneInS = (ElapsedMilliseconds() - LastTimeInMs) / 1000.0
  LastTimeInMs = ElapsedMilliseconds()
  
  Global event = WindowEvent()
  
  ;Update
  Update(ElapsedTimneInS)
  
  ;Draw
  ClearScreen(#Black)
  Draw()
  
  
  FlipBuffers()
Until event = #PB_Event_CloseWindow Or KeyboardPushed(#PB_Key_Escape)
End