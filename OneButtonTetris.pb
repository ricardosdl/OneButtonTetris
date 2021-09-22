EnableExplicit

#Game_Width = 800
#Game_Height = 600
#PlayFieldSize_Width = 10;pieces
#PlayFieldSize_Height = 20;pieces
#Piece_Size = 4
#Piece_Templates = 19
#Fall_Time = 0.2
;#Falling_Piece_Wheel_Timer = 0.2
#Falling_Piece_Wheel_Timer = 0.75
;#Falling_Piece_Position_Timer = 0.2
#Falling_Piece_Position_Timer = 0.75
#Completed_Line_Score = 100
#Max_PlayFields = 4
#FallingPieceWheel_Pieces_Per_Column = 2
#FallingPieceWheel_Pieces_Per_Line = 2

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

Enumeration TPlayfieldState
  #ChoosingFallingPiece
  #ChoosingFallingPiecePosition
  #WaitingFallingPiece
  #ScoringCompletedLines
  #GameOver
EndEnumeration

Enumeration TGameState
  #StartMenu
  #Playing
  #Paused
EndEnumeration

Enumeration TActionKey
  #LeftControl
  #Space
  #Backspace
  #DownKey
EndEnumeration


Structure TPieceTemplate
  Array PieceTemplate.u(#Piece_Size - 1, #Piece_Size - 1)
EndStructure

Structure TPieceConfiguration
  PieceType.a
  NumConfigurations.a
  List PieceTemplates.a()
  WidthInPieces.a
  HeightInPieces.a
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

Structure TFallingPieceWheel
  x.f
  y.f
  PieceType.a
  CurrentTimer.f
  CurrentPieceBackgroundSprite.i
  ChoosedPiece.a
  ChoosedPieceTimer.f
  Width.f
  Height.f
EndStructure

Structure TFallingPiecePosition
  Column.a
  CurrentTimer.f
  ChoosedPosition.a
  ChoosedPositionTimer.f
EndStructure

Structure TCompletedLines
  CompletedLine.b
  CurrentColumn.b
  SequentialCompletedLines.a
EndStructure

Structure TPlayField
  x.f
  y.f
  ;stores the tpieceinfo
  Array PlayField.u(#PlayFieldSize_Width - 1, #PlayFieldSize_Height - 1)
  Width.f
  Height.f
  State.a
  FallingPiecePosition.TFallingPiecePosition
  FallingPieceWheel.TFallingPieceWheel
  FallingPiece.TFallingPiece
  CompletedLines.TCompletedLines
  Score.l
  PlayerID.a
  ActionKey.a
EndStructure

Structure TStartMenu
  StartMenuTitleSprite.i
  NumPlayers.a
EndStructure


Global ElapsedTimneInS.f, LastTimeInMs.q
Global Dim PieceTemplates.TPieceTemplate(#Piece_Templates - 1)
;holds the current pieces widht and height (according to the number of players)
Global Piece_Width.w, Piece_Height.w
Global PlayField.TPlayField, FallingPiece.TFallingPiece, FallingPieceWheel.TFallingPieceWheel,
       FallingPiecePosition.TFallingPiecePosition
Global Dim PlayFields.TPlayField(#Max_PlayFields - 1)
Global GameState.a, NumPlayers.a = 1
Global Dim PiecesConfiguration.TPieceConfiguration(#Right4)
Global Dim FallingPieceWheelSprites(#Right4), FallingPiecePositionSprite.i = #False
Global StartMenu.TStartMenu
Global ControlReleased, SpaceKeyReleased.i, BackspaceReleased.i, DownKeyReleased.i = #False


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

Procedure.a SetupNumPlayers()
  Protected TextNumPlayers.s = InputRequester("Number of Players", "Type the number of players (1-4)", "1")
  TextNumPlayers = Trim(TextNumPlayers)
  NumPlayers = Val(TextNumPlayers)
  If NumPlayers <= 0
    NumPlayers = 1
  EndIf
  
  If NumPlayers > #Max_PlayFields
    NumPlayers = #Max_PlayFields
  EndIf
  
  ProcedureReturn NumPlayers
  
EndProcedure

Procedure.a LoadStartMenuTitleSprite()
  If Not IsSprite(StartMenu\StartMenuTitleSprite)
    StartMenu\StartMenuTitleSprite = LoadSprite(#PB_Any, "assets\gfx\startmenu-title.png", #PB_Sprite_AlphaBlending)
  EndIf
  
  If StartMenu\StartMenuTitleSprite = 0
    ProcedureReturn #False
  EndIf
  
  ProcedureReturn #True
  
  
EndProcedure

Procedure InitStartMenu(NumPlayers.a = 1)
  StartMenu\NumPlayers = NumPlayers
EndProcedure

Procedure SetupStartMenu()
  LoadStartMenuTitleSprite()
  InitStartMenu()
EndProcedure

Procedure InitFallingPiecePosition(*PlayField.TPlayField)
  Protected *FallingPiecePosition.TFallingPiecePosition = *PlayField\FallingPiecePosition
  *FallingPiecePosition\Column = 0
  *FallingPiecePosition\CurrentTimer = 0
  *FallingPiecePosition\ChoosedPosition = #False
  *FallingPiecePosition\ChoosedPositionTimer = 0
  
EndProcedure

Procedure InitFallingPieceWheel(*FallingPieceWheel.TFallingPieceWheel)
  *FallingPieceWheel\CurrentTimer = 0
  *FallingPieceWheel\PieceType = Random(#Right4, #Line)
  *FallingPieceWheel\ChoosedPiece = #False
  *FallingPieceWheel\ChoosedPieceTimer = 0.0
EndProcedure

Procedure LaunchFallingPiece(*PlayField.TPlayField, Type.a, PosX.w = 0, PosY.w = -3)
  *PlayField\FallingPiece\PosX = PosX
  *PlayField\FallingPiece\PosY = PosY
  *PlayField\FallingPiece\Type = Type
  *PlayField\FallingPiece\Configuration = 0
  *PlayField\FallingPiece\IsFalling = #True
EndProcedure

Procedure ClearPlayFieldCompletedLines(*PlayField.TPlayField)
  *PlayField\CompletedLines\CompletedLine = -1
  *PlayField\CompletedLines\CurrentColumn = -1
  *PlayField\CompletedLines\SequentialCompletedLines = 0
EndProcedure

Procedure.a SetupPlayFieldSizes(NumPlayers.a)
  If NumPlayers < 1 Or NumPlayers > 4
    ProcedureReturn #False
  EndIf
  
  Select NumPlayers
    Case 1
      Piece_Width = (#Game_Width / 2) / #PlayFieldSize_Width
      Piece_Height = #Game_Height / #PlayFieldSize_Height
    Case 2
      Piece_Width = (#Game_Width / 4) / #PlayFieldSize_Width
      Piece_Height = #Game_Height / #PlayFieldSize_Height
    Case 3
      Piece_Width = (#Game_Width / 4) / #PlayFieldSize_Width
      Piece_Height = #Game_Height / 2 / #PlayFieldSize_Height
    Case 4
      Piece_Width = (#Game_Width / 4) / #PlayFieldSize_Width
      Piece_Height = #Game_Height / 2 / #PlayFieldSize_Height
      
  EndSelect  
EndProcedure

Procedure ChangeGameState(*PlayField.TPlayField, NewState.a)
  Protected OldGameState.a = *PlayField\State
  Select NewState
    Case #ChoosingFallingPiecePosition
      InitFallingPiecePosition(*PlayField)
      InitFallingPieceWheel(@*PlayField\FallingPieceWheel)
      *PlayField\State = NewState
      
    Case #WaitingFallingPiece
      LaunchFallingPiece(*PlayField, *PlayField\FallingPieceWheel\PieceType, *PlayField\FallingPiecePosition\Column)
      *PlayField\State = NewState
      
    Case #ChoosingFallingPiece
      *PlayField\State = #ChoosingFallingPiece
      
    Case #ScoringCompletedLines
      *PlayField\CompletedLines\CurrentColumn = #PlayFieldSize_Width - 1
      *PlayField\State = #ScoringCompletedLines
  EndSelect
  
EndProcedure

Procedure.i GetPlayfieldActionKey(PlayerID.a)
  Select PlayerID
    Case 1:
      ProcedureReturn #LeftControl
    Case 2:
      ProcedureReturn #Space
    Case 3:
      ProcedureReturn #Backspace
    Case 4:
      ProcedureReturn #DownKey
      
  EndSelect
  
  ProcedureReturn #False
EndProcedure

Procedure InitPlayField(*PlayField.TPlayField, PosX.f, PosY.f, PlayerID.a)
  *PlayField\x = PosX
  *PlayField\y = PosY
  Protected.u x, y
  For x = 0 To #PlayFieldSize_Width - 1
    For y = 0 To #PlayFieldSize_Height - 1
      *PlayField\PlayField(x, y) = #Empty
    Next y
    
  Next x
  *PlayField\Width = #PlayFieldSize_Width * Piece_Width
  *PlayField\Height = #PlayFieldSize_Height * Piece_Height
  ClearPlayFieldCompletedLines(*PlayField)
  *PlayField\Score = 0
  *PlayField\PlayerID = PlayerID
  *PlayField\ActionKey = GetPlayfieldActionKey(PlayerID)
  ;*PlayField\GameState = #ChoosingFallingPiecePosition
  ChangeGameState(*PlayField, #ChoosingFallingPiecePosition)
  
EndProcedure

Macro GetFallingPieceWheelWidth(Width)
  Width = #FallingPieceWheel_Pieces_Per_Column * #Piece_Size * Piece_Width
EndMacro

Procedure SetupFallingPieceWheel(*FallingPieceWheel.TFallingPieceWheel, PosX.f, PosY.f)
  InitFallingPieceWheel(*FallingPieceWheel)
  *FallingPieceWheel\x = PosX
  *FallingPieceWheel\y = PosY
  If IsSprite(*FallingPieceWheel\CurrentPieceBackgroundSprite) = 0
    *FallingPieceWheel\CurrentPieceBackgroundSprite = CreateSprite(#PB_Any, #Piece_Size * Piece_Width, #Piece_Size * Piece_Height,
                                                                 #PB_Sprite_AlphaBlending)
  EndIf
  
  GetFallingPieceWheelWidth(*FallingPieceWheel\Width)
  
  If *FallingPieceWheel\CurrentPieceBackgroundSprite <> 0
    StartDrawing(SpriteOutput(*FallingPieceWheel\CurrentPieceBackgroundSprite))
    Box(0, 0, #Piece_Size * Piece_Width, #Piece_Size * Piece_Height, RGB(255, 255, 255))
    StopDrawing()
  EndIf
  
EndProcedure

Procedure InitPlayFields(NumPlayers.a, Array PlayFields.TPlayField(1))
  SetupPlayFieldSizes(NumPlayers)
  Protected i.a
  For i = 1 To NumPlayers
    Protected PosX.f, PosY
    Protected FallingPieceWheelWidth.f
    GetFallingPieceWheelWidth(FallingPieceWheelWidth)
    Protected Column.a = (i - 1) % 2
    PosX = 0 + Column * ((#PlayFieldSize_Width * Piece_Width) + 25 + FallingPieceWheelWidth )
    
    Protected Line.a = (i - 1) / 2
    PosY = Line * (#PlayFieldSize_Height * Piece_Height)
    InitPlayField(@PlayFields(i - 1), PosX, PosY, i)
    SetupFallingPieceWheel(@PlayFields(i - 1)\FallingPieceWheel, 0, 0)
  Next
  
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
  If IsSprite(FallingPiecePositionSprite)
    FreeSprite(FallingPiecePositionSprite)
  EndIf
  
  Protected Sprite = CreateSprite(#PB_Any, Piece_Width, #PlayFieldSize_Height * Piece_Height, #PB_Sprite_AlphaBlending)
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
    If IsSprite(FallingPieceWheelSprites(PieceType))
      FreeSprite(FallingPieceWheelSprites(PieceType))
    EndIf
    
    Protected Sprite = CreateSprite(#PB_Any, #Piece_Size * Piece_Width,
                                    #Piece_Size * Piece_Height, #PB_Sprite_AlphaBlending)
    If Sprite <> 0
      StartDrawing(SpriteOutput(Sprite))
      DrawingMode(#PB_2DDrawing_AllChannels)
      Box(0, 0, SpriteWidth(Sprite), SpriteHeight(Sprite), RGBA(0, 0, 0, 0))
      ;each of the 19 piece templates is stored sequentially, from 0 to 18
      ;but each piece first configuration is zero (in the list of piece configurations)
      Protected FirstConfiguraton.a = 0
      Protected PieceTemplateIdx.a = GetPieceTemplateIdx(PieceType, FirstConfiguraton)
      
      Protected x.u, y.u
      For x = 0 To #Piece_Size - 1
        For y = 0 To #Piece_Size - 1
          If PieceTemplates(PieceTemplateIdx)\PieceTemplate(x, y)
            Box(x * Piece_Width, y * Piece_Height, Piece_Width - 1, Piece_Height - 1, RGBA($7f, 0, 0, $ff))
          EndIf
        Next y
      Next x
      
      StopDrawing()
      FallingPieceWheelSprites(PieceType) = Sprite
    EndIf
    
  Next
  
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
  PiecesConfiguration(#Line)\WidthInPieces = 4
  PiecesConfiguration(#Line)\HeightInPieces = 1
  
  PiecesConfiguration(#Square)\PieceType = #Square
  PiecesConfiguration(#Square)\NumConfigurations = 1
  StringListToAsciiList("2", PiecesConfiguration(#Square)\PieceTemplates())
  PiecesConfiguration(#Square)\WidthInPieces = 2
  PiecesConfiguration(#Square)\HeightInPieces = 2
  
  PiecesConfiguration(#LeftL)\PieceType = #LeftL
  PiecesConfiguration(#LeftL)\NumConfigurations = 4
  StringListToAsciiList("3,4,5,6", PiecesConfiguration(#LeftL)\PieceTemplates())
  PiecesConfiguration(#LeftL)\WidthInPieces = 3
  PiecesConfiguration(#LeftL)\HeightInPieces = 2
  
  PiecesConfiguration(#RightL)\PieceType = #RightL
  PiecesConfiguration(#RightL)\NumConfigurations = 4
  StringListToAsciiList("7,8,9,10", PiecesConfiguration(#RightL)\PieceTemplates())
  PiecesConfiguration(#RightL)\WidthInPieces = 3
  PiecesConfiguration(#RightL)\HeightInPieces = 2
  
  PiecesConfiguration(#Left4)\PieceType = #Left4
  PiecesConfiguration(#Left4)\NumConfigurations = 2
  StringListToAsciiList("11,12", PiecesConfiguration(#Left4)\PieceTemplates())
  PiecesConfiguration(#Left4)\WidthInPieces = 3
  PiecesConfiguration(#Left4)\HeightInPieces = 2
  
  PiecesConfiguration(#Tee)\PieceType = #Tee
  PiecesConfiguration(#Tee)\NumConfigurations = 4
  StringListToAsciiList("13,14,15,16", PiecesConfiguration(#Tee)\PieceTemplates())
  PiecesConfiguration(#Tee)\WidthInPieces = 3
  PiecesConfiguration(#Tee)\HeightInPieces = 2
  
  PiecesConfiguration(#Right4)\PieceType = #Right4
  PiecesConfiguration(#Right4)\NumConfigurations = 2
  StringListToAsciiList("17,18", PiecesConfiguration(#Right4)\PieceTemplates())
  PiecesConfiguration(#Right4)\WidthInPieces = 3
  PiecesConfiguration(#Right4)\HeightInPieces = 2
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

Procedure.a IsCellWithinPlayField(CellX.w, CellY.w)
  ProcedureReturn Bool((CellX >= 0  And CellX < #PlayFieldSize_Width) And
                       (CellY >= 0 And CellY < #PlayFieldSize_Height))
EndProcedure

Procedure DrawFallingPiece(*PlayField.TPlayField)
  Protected FallingPiece.TFallingPiece = *PlayField\FallingPiece
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
      Protected CellX.w = x + i
      Protected CellY.w = y + j
      If PieceTemplates(PieceTemplateIdx)\PieceTemplate(i, j) And IsCellWithinPlayField(CellX, CellY)
        Box(*PlayField\x + x * Piece_Width + i * Piece_Width, *PlayField\y + y * Piece_Height + j * Piece_Height, Piece_Width - 1, Piece_Height - 1, RGB($7f, 0, 0))
      EndIf
      
    Next j
    
  Next i
EndProcedure

Procedure DrawFallingPieceWheel(*PlayField.TPlayField)
  Protected FallingPieceWheel.TFallingPieceWheel = *PlayField\FallingPieceWheel
  Protected CurrentPieceType.a, x.f, y.f
  For CurrentPieceType = #Line To #Right4
    Protected Column.a = CurrentPieceType % #FallingPieceWheel_Pieces_Per_Column
    Protected Line.a = CurrentPieceType / #FallingPieceWheel_Pieces_Per_Line
    x = *PlayField\x + *PlayField\Width + 10 + Column * (#Piece_Size * Piece_Width + 10)
    y = *PlayField\y + 30 + Line * (#Piece_Size * Piece_Height + 10)
    If CurrentPieceType = FallingPieceWheel\PieceType And *PlayField\State <> #GameOver
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
    
    Protected WidthInPieces.a = PiecesConfiguration(CurrentPieceType)\WidthInPieces
    Protected HeightInPieces.a = PiecesConfiguration(CurrentPieceType)\HeightInPieces
    
    Protected SpriteX = x + (#Piece_Size * Piece_Width / 2) - (WidthInPieces * Piece_Width / 2)
    Protected SpriteY = y + (#Piece_Size * Piece_Height / 2) - (HeightInPieces * Piece_Height / 2)
    DisplayTransparentSprite(FallingPieceWheelSprites(CurrentPieceType), SpriteX, SpriteY)
  Next
EndProcedure

Procedure DrawPlayFieldOutline(*Playfield.TPlayField)
  Line(*PlayField\x + 1, *PlayField\y + 1, #PlayFieldSize_Width * Piece_Width, 1, RGB($7f, 80, 70))
  Line(*PlayField\x + #PlayFieldSize_Width * Piece_Width, *PlayField\y + 1, 1, #PlayFieldSize_Height * Piece_Height, RGB($7f, 80, 70))
EndProcedure

Procedure DrawFallingPiecePosition(*PLayField.TPlayField)
  Protected FallingPiecePosition.TFallingPiecePosition = *PLayField\FallingPiecePosition
  If Not FallingPiecePosition\ChoosedPosition
    DisplayTransparentSprite(FallingPiecePositionSprite, *PlayField\x + FallingPiecePosition\Column * Piece_Width, *PLayField\y)
  ElseIf FallingPiecePosition\ChoosedPositionTimer > 0
    Protected Timer.l = (FallingPiecePosition\ChoosedPositionTimer * 1000) / 50
    Protected Intensity = 255 * (Timer % 2)
    DisplayTransparentSprite(FallingPiecePositionSprite, *PLayField\x + FallingPiecePosition\Column * Piece_Width, *PLayField\y, Intensity)
  ElseIf FallingPiecePosition\ChoosedPositionTimer <= 0
    DisplayTransparentSprite(FallingPiecePositionSprite, *PLayField\x + FallingPiecePosition\Column * Piece_Width, *PLayField\y)
  EndIf
  
EndProcedure

Procedure DrawPlayFieldHUD(*PlayField.TPlayField)
  StartDrawing(ScreenOutput())
  DrawingMode(#PB_2DDrawing_Transparent)
  Protected ScoreText.s = "Player " + *PlayField\PlayerID + " Score:" + Str(*PlayField\Score)
  DrawText(*PlayField\x + *PlayField\Width, *PlayField\y + 5, ScoreText, RGB($FF, $cc, $33))
  If *PlayField\State = #GameOver
    Protected TextHeightOffset = TextHeight(ScoreText)
    DrawText(*PlayField\x + *PlayField\Width, *PlayField\y + 5 + TextHeightOffset, "GAME OVER", RGB(255, 25, 15))
  EndIf
  StopDrawing()
EndProcedure

Procedure DrawPlayfield(*PLayField.TPlayField)
  DrawFallingPiecePosition(*PLayField)
  
  Protected x.u, y.u
  StartDrawing(ScreenOutput())
  For x = 0 To #PlayFieldSize_Width - 1
    For y = 0 To #PlayFieldSize_Height - 1
      If (*PlayField\PlayField(x, y) & #Empty)
        Continue
      EndIf
      
      Protected PieceInfo.u = *PlayField\PlayField(x, y)
      Protected PieceColor = GetPieceColor(PieceInfo)
      Box(*PlayField\x + x * Piece_Width, *PlayField\y + y * Piece_Height, Piece_Width - 1, Piece_Height - 1, PieceColor)
    Next y
  Next x
  
  DrawFallingPiece(*PLayField)
  
  DrawPlayFieldOutline(*PLayField)
  
  StopDrawing()
  
  DrawPlayFieldHUD(*PLayField)
  
  DrawFallingPieceWheel(*PlayField)
EndProcedure

Procedure DrawPlayFields()
  Protected i.a
  For i = 1 To NumPlayers
    DrawPlayfield(@PlayFields(i - 1))
  Next
EndProcedure

Procedure DrawStartMenu()
  Protected MenuTitleX.f = (ScreenWidth() - SpriteWidth(StartMenu\StartMenuTitleSprite)) / 2
  Protected MenuTitleY.f = 50
  DisplayTransparentSprite(StartMenu\StartMenuTitleSprite, MenuTitleX, MenuTitleY)
  StartDrawing(ScreenOutput())
  DrawingMode(#PB_2DDrawing_Transparent)
  Protected NumPlayersText.s = "Number of Players:"
  Protected NumPlayersWidth = TextWidth(NumPlayersText)
  Protected NumPlayersX.f = (ScreenWidth() - NumPlayersWidth) / 2
  Protected NumPlayersY.f = MenuTitleY + SpriteHeight(StartMenu\StartMenuTitleSprite) + 50
  DrawText(NumPlayersX, NumPlayersY, NumPlayersText)
  
  Protected CurrentNumPlayers.s = Str(StartMenu\NumPlayers)
  Protected CurrentNumPlayersWidth = TextWidth(CurrentNumPlayers)
  Protected CurrentNumPlayersX.f = (ScreenWidth() - CurrentNumPlayersWidth) / 2
  Protected CurrentNumPlayersY.f = NumPlayersY + 20
  DrawText(CurrentNumPlayersX - 10, CurrentNumPlayersY, "<")
  DrawText(CurrentNumPlayersX, CurrentNumPlayersY, CurrentNumPlayers, RGB($FF, $cc, $33))
  DrawText(CurrentNumPlayersX + CurrentNumPlayersWidth, CurrentNumPlayersY, ">")
  
  Protected ControlsText.s = "Action Keys:"
  Protected ControlsTextWidth = TextWidth(ControlsText)
  Protected ControlsTextX.f = (ScreenWidth() - ControlsTextWidth) / 2
  Protected ControlsTextY.f = CurrentNumPlayersY + 20
  DrawText(ControlsTextX, ControlsTextY, ControlsText)
  
  Protected PlayersControls.s = "Player 1: Left Control | Player 2: Space | Player 3: BackSpace | Player 4: Down Arrow Key"
  Protected PlayersControlsWidth = TextWidth(PlayersControls)
  Protected PlayersControlsX.f = (ScreenWidth() - PlayersControlsWidth) / 2
  Protected PlayerControlsY.f = ControlsTextY + 20
  DrawText(PlayersControlsX, PlayerControlsY, PlayersControls, RGB($ff, $cc, $33))
  
  StopDrawing()
EndProcedure

Procedure Draw()
  If GameState = #Playing
    DrawPlayFields()
  ElseIf GameState = #StartMenu
    DrawStartMenu()
    
  EndIf
  
EndProcedure



Procedure.a CheckCompletedLines(*PlayField.TPlayField)
  ;we go on each line in the playfield trying to find a completed line
  ;if found we store it on the playfield\completedlines
  Protected x.w, y.w
  For y = #PlayFieldSize_Height - 1 To 0 Step -1
    ;we assume there is a completed line
    Protected IsLineCompleted.a = #True
    For x = 0 To #PlayFieldSize_Width -1
      If (*PlayField\PlayField(x, y) & #Empty)
        IsLineCompleted = #False
        Break
      EndIf
      
    Next x
    If IsLineCompleted
      ;if there is a completed line we store its info and return true
      *PlayField\CompletedLines\CompletedLine = y
      *PlayField\CompletedLines\CurrentColumn = #PlayFieldSize_Width - 1
      *PlayField\CompletedLines\SequentialCompletedLines + 1
      ProcedureReturn IsLineCompleted
    EndIf
    
  Next y
  ;no completed lines found
  ProcedureReturn #False
EndProcedure


Procedure SaveFallingPieceOnPlayField(*PlayField.TPlayField)
  Protected FallingPiece.TFallingPiece = *PlayField\FallingPiece
  Protected PieceTemplateIdx.a = GetPieceTemplateIdx(FallingPiece\Type, FallingPiece\Configuration)
  Protected i.u, j.u
  For i = 0 To #Piece_Size - 1
    For j = 0 To #Piece_Size - 1
      If PieceTemplates(PieceTemplateIdx)\PieceTemplate(i, j)
        Protected XCell.w = FallingPiece\PosX + i
        Protected YCell.w = FallingPiece\PosY + j
        
        Protected IsCellXWithinPlayfield.a = Bool(XCell >= 0 And XCell < #PlayFieldSize_Width)
        Protected IsCellYAbovePlayfield.a = Bool(YCell < 0)
        
        If IsCellXWithinPlayfield And IsCellYAbovePlayfield
          ;game over
          Debug "game over"
          *PlayField\State = #GameOver
          ProcedureReturn
        EndIf
        
        
        If Not IsCellWithinPlayField(XCell, YCell)
          Continue
        EndIf
        
        *PlayField\PlayField(XCell, YCell) = #Filled | #RedColor
      EndIf
      
    Next j
    
  Next i
  
  ClearPlayFieldCompletedLines(*PlayField)
  If CheckCompletedLines(*PlayField)
    ChangeGameState(*PlayField, #ScoringCompletedLines)
  Else
    ChangeGameState(*PlayField, #ChoosingFallingPiecePosition)
  EndIf
EndProcedure

Procedure LaunchRandomFallingPiece()
  ;LaunchFallingPiece(Random(#Right4, #Line))
EndProcedure

Procedure.i IsActionKeyActivated(ActionKey.a)
  Select ActionKey
    Case #LeftControl
      ProcedureReturn ControlReleased
    Case #Space
      ProcedureReturn SpaceKeyReleased
    Case #Backspace
      ProcedureReturn BackspaceReleased
    Case #DownKey
      ProcedureReturn DownKeyReleased
  EndSelect
  
  ProcedureReturn #False
  
EndProcedure

Procedure UpdateFallingPiece(*PlayField.TPlayField, Elapsed.f)
  Protected *FallingPiece.TFallingPiece = @*PlayField\FallingPiece
  ;gets the number of configuration this piecetype has
  Protected NumConfigurations.a = PiecesConfiguration(*FallingPiece\Type)\NumConfigurations
  
  ;gets the current template used by the falling piece
  Protected PieceTemplateIdx.a = GetPieceTemplateIdx(*FallingPiece\Type, *FallingPiece\Configuration)
  
  If IsActionKeyActivated(*PlayField\ActionKey)
    *FallingPiece\Configuration = (*FallingPiece\Configuration + 1) % NumConfigurations
  EndIf
  
  ;check hit with bottom of playfield
  Protected i.u, j.u
  For i = 0 To #Piece_Size - 1
    If Not *FallingPiece\IsFalling
      Break
    EndIf
    For j = 0 To #Piece_Size - 1
      ;each piece is 4x4, if the current piece at the current configuration
      ;is filled at this position, we'll check for collisions
      If PieceTemplates(PieceTemplateIdx)\PieceTemplate(i, j)
        Protected XCell.w = *FallingPiece\PosX + i
        Protected YCell.w = *FallingPiece\PosY + j
        
        Protected IsCellXWithinPlayfield.a = Bool(XCell >= 0 And XCell < #PlayFieldSize_Width)
        If (YCell > #PlayFieldSize_Height - 1) And IsCellXWithinPlayfield
          ;hit bottom of playfield
          *FallingPiece\PosY - 1;put the fallingpiece one line above
          *FallingPiece\IsFalling = #False
          SaveFallingPieceOnPlayField(*PlayField)
          Break
        EndIf
        
        ;if the cell position is outside of the playfield
        ;we ignore it for collisions with filled cells
        If Not IsCellWithinPlayField(XCell, YCell)
          Continue
        EndIf
        
        If *PlayField\PlayField(XCell, YCell) & #Filled
          ;hit with filled cell on playfield
          *FallingPiece\PosY - 1;put the fallingpiece one line above
          *FallingPiece\IsFalling = #False
          SaveFallingPieceOnPlayField(*PlayField)
          Break
        EndIf
        
      EndIf
    Next j
  Next i
  
  If *FallingPiece\IsFalling
    
    *FallingPiece\FallingTimer + Elapsed
    If *FallingPiece\FallingTimer >= #Fall_Time
      ;fall down one line
      *FallingPiece\PosY + 1
      *FallingPiece\FallingTimer = 0.0
    EndIf
  EndIf
  
EndProcedure

Procedure UpdateFallingPieceWheel(*PlayField.TPlayField, Elapsed.f)
  If *PlayField\State <> #ChoosingFallingPiece
    ProcedureReturn
  EndIf
  
  Protected *FallingPieceWheel.TFallingPieceWheel = @*PlayField\FallingPieceWheel
  
  *FallingPieceWheel\CurrentTimer + Elapsed
  If *FallingPieceWheel\CurrentTimer > #Falling_Piece_Wheel_Timer And (Not *FallingPieceWheel\ChoosedPiece)
    ;just cycle through the pieces
    *FallingPieceWheel\CurrentTimer  = 0
    *FallingPieceWheel\PieceType = (*FallingPieceWheel\PieceType + 1) % #Num_Piece_Types
  EndIf
  
  If IsActionKeyActivated(*PlayField\ActionKey) And (Not *FallingPieceWheel\ChoosedPiece)
    ;the player chose the current piece
    *FallingPieceWheel\ChoosedPiece = #True
    *FallingPieceWheel\ChoosedPieceTimer = 0.5
  EndIf
  
  If *FallingPieceWheel\ChoosedPiece And *FallingPieceWheel\ChoosedPieceTimer >=0
    ;we use this timer to flash the chosen piece
    *FallingPieceWheel\ChoosedPieceTimer - Elapsed
  EndIf
  
  If *FallingPieceWheel\ChoosedPiece And *FallingPieceWheel\ChoosedPieceTimer < 0
    ChangeGameState(*PlayField, #WaitingFallingPiece)
  EndIf
EndProcedure

Procedure CheckKeys()
  ControlReleased = KeyboardReleased(#PB_Key_LeftControl)
  SpaceKeyReleased = KeyboardReleased(#PB_Key_Space)
  BackspaceReleased = KeyboardReleased(#PB_Key_Back)
  DownKeyReleased = KeyboardReleased(#PB_Key_Down)
EndProcedure

Procedure UpdateFallingPiecePosition(*PlayField.TPlayField, Elapsed.f)
  If *PlayField\State <> #ChoosingFallingPiecePosition
    ProcedureReturn
  EndIf
  
  Protected *FallingPiecePosition.TFallingPiecePosition = @*PlayField\FallingPiecePosition
  
  If IsActionKeyActivated(*PlayField\ActionKey) And Not *FallingPiecePosition\ChoosedPosition
    *FallingPiecePosition\ChoosedPosition = #True
    *FallingPiecePosition\ChoosedPositionTimer = 0.5
  EndIf
  
  If Not *FallingPiecePosition\ChoosedPosition
    *FallingPiecePosition\CurrentTimer + Elapsed
  EndIf
  
  If *FallingPiecePosition\CurrentTimer > #Falling_Piece_Position_Timer
    *FallingPiecePosition\Column = (*FallingPiecePosition\Column + 1) % #PlayFieldSize_Width
    *FallingPiecePosition\CurrentTimer = 0
  EndIf
  
  If *FallingPiecePosition\ChoosedPositionTimer > 0
    *FallingPiecePosition\ChoosedPositionTimer - Elapsed
  EndIf
  
  If *FallingPiecePosition\ChoosedPosition And *FallingPiecePosition\ChoosedPositionTimer <= 0
    ChangeGameState(*PlayField, #ChoosingFallingPiece)
  EndIf
EndProcedure

Procedure BringPlayFieldOneLineDown(*PlayField.TPLayField, StartLine.b)
  Protected CurrentLine.b, CurrentColumn.a
  For CurrentLine = StartLine To 0 Step -1
    For CurrentColumn = 0 To #PlayFieldSize_Width - 1
      If IsCellWithinPlayField(CurrentColumn, CurrentLine) And IsCellWithinPlayField(CurrentColumn, CurrentLine + 1)
        *PlayField\PlayField(CurrentColumn, CurrentLine + 1) = *PlayField\PlayField(CurrentColumn, CurrentLine)
      EndIf
    Next CurrentColumn
  Next CurrentLine
EndProcedure

Procedure UpdateScoringCompletedLines(*PLayField.TPlayField, Elapsed.f)
  If *PLayField\State <> #ScoringCompletedLines
    ProcedureReturn
  EndIf
  
  Protected CurrentLine.a = *PLayField\CompletedLines\CompletedLine
  
  Protected CurrentColumn.b = *PLayField\CompletedLines\CurrentColumn
  
  If CurrentColumn > -1
    ;we gona clear this column on the playfield this frame
    ;we go from right to left
    *PLayField\PlayField(CurrentColumn, CurrentLine) = #Empty
    CurrentColumn - 1
    *PLayField\CompletedLines\CurrentColumn = CurrentColumn
  Else
    ;finished all columns on the current line
    BringPlayFieldOneLineDown(*PLayField, CurrentLine - 1)
    If Not CheckCompletedLines(*PLayField)
      Debug "sequential completed lines:" + Str(*PLayField\CompletedLines\SequentialCompletedLines)
      *PLayField\Score + *PLayField\CompletedLines\SequentialCompletedLines * #Completed_Line_Score
      If *PLayField\CompletedLines\SequentialCompletedLines > 1
        ;bonus score
        *PLayField\Score + (*PLayField\CompletedLines\SequentialCompletedLines - 1) * (#Completed_Line_Score / 4)
      EndIf
      
      ClearPlayFieldCompletedLines(*PLayField)
      ChangeGameState(*PLayField, #ChoosingFallingPiecePosition)
    EndIf
  EndIf
EndProcedure

Procedure StartNewGame(NumberOfPlayers.a)
  NumPlayers = NumberOfPlayers
  InitPlayFields(NumPlayers, PlayFields())
  CreateFallingPieceWheelSprites()
  CreateFallingPiecePositionSprite()
  GameState = #Playing
EndProcedure

Procedure UpdateStartMenu(Elapsed.f)
  Protected LeftReleased.i = KeyboardReleased(#PB_Key_Left)
  Protected RightReleased.i = KeyboardReleased(#PB_Key_Right)
  If LeftReleased
    StartMenu\NumPlayers - 1
    If StartMenu\NumPlayers < 1
      StartMenu\NumPlayers = #Max_PlayFields
    EndIf
  EndIf
  
  If RightReleased
    StartMenu\NumPlayers + 1
    If StartMenu\NumPlayers > #Max_PlayFields
      StartMenu\NumPlayers = 1
    EndIf
    
  EndIf
  
  If KeyboardReleased(#PB_Key_1)
    StartMenu\NumPlayers = 1
  ElseIf KeyboardReleased(#PB_Key_2)
    StartMenu\NumPlayers = 2
  ElseIf KeyboardReleased(#PB_Key_3)
    StartMenu\NumPlayers = 3
  ElseIf KeyboardReleased(#PB_Key_4)
    StartMenu\NumPlayers = 4
  EndIf
  
  
  Protected ControlReleased.i = KeyboardReleased(#PB_Key_LeftControl)
  Protected SpaceReleased.i = KeyboardReleased(#PB_Key_Space)
  Protected BackspaceReleased.i = KeyboardReleased(#PB_Key_Back)
  Protected DownReleased.i = KeyboardReleased(#PB_Key_Down)
  Protected StartTheGame.a = Bool(ControlReleased Or SpaceReleased Or BackspaceReleased Or DownReleased)
  If StartTheGame
    ;start the game
    StartNewGame(StartMenu\NumPlayers)
    ProcedureReturn
  EndIf
  
  
  
EndProcedure

Procedure Update(Elapsed.f)
  If GameState = #Playing
    CheckKeys()
    Protected i.a
    For i = 1 To NumPlayers
      UpdateFallingPiece(@PlayFields(i - 1), Elapsed)
      UpdateFallingPieceWheel(@PlayFields(i - 1), Elapsed)
      UpdateFallingPiecePosition(@PlayFields(i - 1), Elapsed)
      UpdateScoringCompletedLines(@PlayFields(i - 1), Elapsed)
    Next i
  ElseIf GameState = #StartMenu
    UpdateStartMenu(Elapsed)
  EndIf

EndProcedure

;===================main program starts here================
InitSprite()
InitKeyboard()
OpenWindow(1, 0,0, #Game_Width, #Game_Height,"One-Button Tetris", #PB_Window_ScreenCentered)
OpenWindowedScreen(WindowID(1),0,0, #Game_Width, #Game_Height , 0, 0, 0)
UsePNGImageDecoder()
SetupStartMenu()
LoadPiecesTemplate()
LoadPiecesConfigurations()
GameState = #StartMenu

LastTimeInMs = ElapsedMilliseconds()

Repeat
  ElapsedTimneInS = (ElapsedMilliseconds() - LastTimeInMs) / 1000.0
  LastTimeInMs = ElapsedMilliseconds()
  
  Global event = WindowEvent()
  
  ;Update
  ExamineKeyboard()
  Update(ElapsedTimneInS)
  
  ;Draw
  ClearScreen(#Black)
  Draw()
  
  
  FlipBuffers()
Until event = #PB_Event_CloseWindow Or KeyboardPushed(#PB_Key_Escape)
End