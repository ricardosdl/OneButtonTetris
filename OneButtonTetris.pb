EnableExplicit
#Game_Width = 800
#Game_Height = 600
#PlayFieldSize_Width = 10;pieces
#PlayFieldSize_Height = 20;pieces
#Piece_Size = 4
#Piece_Templates = 19
#Initial_Fall_Time = 0.2
;#Falling_Piece_Wheel_Timer = 0.2
#Intial_Falling_Piece_Wheel_Timer = 0.75;seconds
;#Falling_Piece_Position_Timer = 0.2
#Initial_Falling_Piece_Position_Timer = 0.75;seconds
#Max_Difficulty = 7
#Time_Until_Next_Difficulty = 40.0            ;seconds
#Initial_Idle_Timer = #Time_Until_Next_Difficulty / 3
#Time_Up_Warning_Timer = 4;seconds
#Completed_Line_Score = 100
#Max_PlayFields = 4
#FallingPieceWheel_Pieces_Per_Column = 2
#FallingPieceWheel_Pieces_Per_Line = 2
#Max_Particles = 100
#Num_Sparkles_Particles_Sprites = 3

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
;the first two bits o the tpieceinfo are set to the empty or filled status, the seven
;after are used to set the color, with this mask we can extract the color set on the pieceinfo
;which is stored inside the Playfield array inside TPlayfield
#Color_Mask = %111111100

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

Enumeration TGameStates
  #StartMenu
  #Playing
  #Paused
  #SinglePlayerGameOver
  #MultiplayerGameOver
EndEnumeration

Enumeration TActionKey
  #LeftControl
  #Space
  #Backspace
  #DownKey
EndEnumeration

Enumeration TSounds
  #MainMusic
  #PauseSound
  #UnpauseSound
  #GameOverSound
  #WinnerSound
  #TimeUpSound
  #IdleSound
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
  Color.u
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

Structure TPlayfieldsDifficulty
  FallingPieceWheelTimer.f
  FallingPiecePositionTimer.f
  FallTime.f
  TimeUntilNextDifficulty.f
  PlayingTimeUp.a
  CurrentDifficulty.a
  MaxDifficulty.a
  CurrentIdleTimer.f
EndStructure

Structure TPlayfieldRankPosition
  PlayerID.a
  Score.l
  TimeSurvived.f;in seconds
EndStructure

Structure TPlayfieldsRanking
  List RankPositions.TPlayfieldRankPosition()
EndStructure

Structure TGameState
  CurrentGameState.a
  OldGameState.a
  MinTimeGameOver.f
  MultiplayerWinnerPlayerID.a
  PlayfieldsRanking.TPlayfieldsRanking
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
  TimeSurvived.f;in seconds
  IdleTimer.f;in seconds
EndStructure

Structure TStartMenu
  StartMenuTitleSprite.i
  NumPlayers.a
EndStructure

Prototype.a UpdateParticleProc(*Particle, Elapsed.f)
Prototype.a DrawParticleProc(*Particle, Elapsed.f)
Structure TParticle
  x.f;position x
  y.f;postion y
  w.f;width
  h.f;height
  Vx.f;velocity x
  Vy.f;velocity y
  Sprite.i;the sprite that will be displayed
  Transparency.a
  Active.a;#true of active #false if not
  Time.f  ;how much time this particle will be alive in seconds
  CurrentTime.f;if > 0 the particle is active or alive
  Update.UpdateParticleProc
  Draw.UpdateParticleProc
EndStructure

Prototype UpdateEmitterProc(*Emitter, Elapsed.f)
Structure TEmitter
  x.f
  y.f
  AngleX.f;in degrees
  AngleY.f;in degrees
  Active.a
  Time.f
  CurrentTime.f
  Update.UpdateEmitterProc
EndStructure

Global ElapsedTimneInS.f, LastTimeInMs.q
Global Dim PieceTemplates.TPieceTemplate(#Piece_Templates - 1)
;holds the current pieces widht and height (according to the number of players)
Global Piece_Width.w, Piece_Height.w
Global PlayField.TPlayField, FallingPiece.TFallingPiece, FallingPieceWheel.TFallingPieceWheel,
       FallingPiecePosition.TFallingPiecePosition
Global Dim PlayFields.TPlayField(#Max_PlayFields - 1), PlayfieldsDifficulty.TPlayfieldsDifficulty
Global GameState.TGameState, NumPlayers.a = 1
Global Dim PiecesConfiguration.TPieceConfiguration(#Right4)
Global Dim FallingPieceWheelSprites(#Right4), FallingPiecePositionSprite.i = #False
Global PlayfieldOutlineSprite.i
Global Dim PiecesSprites(#Right4);the sprites used to draw the playfield and falling piece
Global StartMenu.TStartMenu, Bitmap_Font_Sprite.i
Global SoundInitiated.a = #False, VolumeMusic.a = 100, VolumeSoundEffects.a = 50
Global ControlReleased, SpaceKeyReleased.i, BackspaceReleased.i, DownKeyReleased.i, PKeyReleased.i = #False
Global Dim SparklesParticles.TParticle(#Max_Particles - 1), Dim SparklesParticlesSprites(#Num_Sparkles_Particles_Sprites - 1)
Global NewList Emitters.TEmitter()


Procedure.i GetEmitter(x.f, y.f, AngleX.f, AngleY.f, Time.f, UpdateProc.UpdateEmitterProc)
  Protected *Emitter.TEmitter = #Null
  ForEach Emitters()
    If Not Emitters()\Active
      *Emitter = @Emitters()
    EndIf
    
  Next
  If *Emitter = #Null
    AddElement(Emitters())
    *Emitter = @Emitters()
  EndIf
  
  *Emitter\x = x
  *Emitter\y = y
  *Emitter\AngleX = AngleX
  *Emitter\AngleY = AngleY
  *Emitter\Active = #True
  *Emitter\Time = Time
  *Emitter\CurrentTime = Time
  *Emitter\Update = UpdateProc
  
  ProcedureReturn *Emitter
EndProcedure

Procedure.i GetSparkleParticle()
  Protected i.a
  For i = 0 To #Max_Particles - 1
    If Not SparklesParticles(i)\Active
      ProcedureReturn @SparklesParticles(i)
    EndIf
  Next
  
  ProcedureReturn #Null
  
EndProcedure

Procedure UpdateQuickSparkleParticle(*Particle.TParticle, Elapsed.f)
  If Not *Particle\Active
    ProcedureReturn
  EndIf
  *Particle\x + *Particle\Vx * Elapsed
  *Particle\y + *Particle\vy * Elapsed
  
  
  *Particle\Vy + 50 * Elapsed;gravity
  
  Protected TimeOverNumSprites.f = *Particle\Time / #Num_Sparkles_Particles_Sprites
  Protected CurrentSpriteIdx.a = *Particle\CurrentTime / TimeOverNumSprites
  If CurrentSpriteIdx > #Num_Sparkles_Particles_Sprites - 1
    CurrentSpriteIdx = #Num_Sparkles_Particles_Sprites - 1
  EndIf
  
  *Particle\Sprite = SparklesParticlesSprites(CurrentSpriteIdx)
  
  *Particle\Transparency = 255 * (*Particle\CurrentTime / *Particle\Time)
  
  Protected NumParticleSizes.a = 3
  Dim ParticleSizes.a(NumParticleSizes - 1)
  ParticleSizes(0) = 8
  ParticleSizes(1) = 6
  ParticleSizes(2) = 4
  
  Protected TimeIntervalPerSize.f = *Particle\Time / NumParticleSizes
  Protected CurrentParticleSizeIdx.a = *Particle\CurrentTime / TimeIntervalPerSize
  If CurrentParticleSizeIdx > NumParticleSizes - 1
    CurrentParticleSizeIdx = NumParticleSizes - 1
  EndIf
  
  *Particle\w = ParticleSizes(CurrentParticleSizeIdx)
  *Particle\h = ParticleSizes(CurrentParticleSizeIdx)
  
  
  *Particle\CurrentTime - Elapsed
  If *Particle\CurrentTime <= 0
    *Particle\Active = #False
  EndIf
  
EndProcedure

Procedure EmitterQuickSparklesUpdate(*Emitter.TEmitter, Elapsed.f)
  Protected NumParticles.a = Random(15, 10), i.a = 0
  Protected StartAngleY.f = *Emitter\AngleY - 45
  Protected FinalAngleY.f = *Emitter\AngleY + 45
  Protected StepAngleY.f = (FinalAngleY - StartAngleY) / NumParticles
  For i = 1 To NumParticles
    Protected *Particle.TParticle = GetSparkleParticle()
    If *Particle = #Null
      Continue
    EndIf
;     x.f;position x
;     y.f;postion y
;     w.f;width
;     h.f;height
;     Vx.f;velocity x
;     Vy.f;velocity y
;     Sprite.i;the sprite that will be displayed
;     Transparency.a
;     Active.a;#true of active #false if not
;     Time.f  ;how much time this particle will be alive in seconds
;     CurrentTime.f;if > 0 the particle is active or alive
;     Update.UpdateParticleProc
;     Draw.UpdateParticleProc
    
    
    
    *Particle\x = *Emitter\x
    *Particle\y = *Emitter\y
    *Particle\w = 4
    *Particle\h = 4
    *Particle\Vx = Random(100, 25) * Cos(Radian(*Emitter\AngleX))
    *Particle\Vy = Random(100, 50) * Sin(Radian(StartAngleY))
    StartAngleY + StepAngleY
    *Particle\Sprite = SparklesParticlesSprites(0)
    *Particle\Transparency = 255
    *Particle\Active = #True
    *Particle\Time = 500 / 1000;in ms
    *Particle\CurrentTime = *Particle\Time
    *Particle\Update = @UpdateQuickSparkleParticle()
  Next
  
  *Emitter\CurrentTime - Elapsed
  If *Emitter\CurrentTime <= 0
    *Emitter\Active = #False
  EndIf
  
  
EndProcedure

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

Procedure DrawBitmapText(x.f, y.f, Text.s, CharWidthPx.a = 16, CharHeightPx.a = 24, Transparency.a = 255)
  ;ClipSprite(Bitmap_Font_Sprite, #PB_Default, #PB_Default, #PB_Default, #PB_Default)
  ;ZoomSprite(Bitmap_Font_Sprite, #PB_Default, #PB_Default)
  Protected i.i
  For i.i = 1 To Len(Text);loop the string Text char by char
    Protected AsciiValue.a = Asc(Mid(Text, i, 1))
    ClipSprite(Bitmap_Font_Sprite, (AsciiValue - 32) % 16 * 8, (AsciiValue - 32) / 16 * 12, 8, 12)
    ZoomSprite(Bitmap_Font_Sprite, CharWidthPx, CharHeightPx)
    DisplayTransparentSprite(Bitmap_Font_Sprite, x + (i - 1) * CharWidthPx, y, Transparency)
  Next
EndProcedure

Procedure LoadBitmapFontSprite()
  Bitmap_Font_Sprite = LoadSprite(#PB_Any, "assets\gfx\font.png", #PB_Sprite_AlphaBlending)
  If IsSprite(Bitmap_Font_Sprite)
    ProcedureReturn #True
  EndIf
  
  ProcedureReturn #False
  
EndProcedure

Procedure LoadSounds()
  If Not SoundInitiated
    ProcedureReturn
  EndIf
  
  LoadSound(#MainMusic, "assets\sfx\twister-tetris.ogg")
  LoadSound(#PauseSound, "assets\sfx\pause.ogg")
  LoadSound(#UnpauseSound, "assets\sfx\unpause.ogg")
  LoadSound(#GameOverSound, "assets\sfx\gameover.ogg")
  LoadSound(#WinnerSound, "assets\sfx\winner.ogg")
  LoadSound(#TimeUpSound, "assets\sfx\timeup.ogg")
  LoadSound(#IdleSound, "assets\sfx\idle.ogg")
  
EndProcedure

Procedure PlaySoundEffect(Sound.a, Music.a = #False)
  If Not SoundInitiated
    ProcedureReturn
  EndIf
  If Music
    PlaySound(Sound, #PB_Sound_Loop, VolumeMusic)
  Else
    PlaySound(Sound, 0, VolumeSoundEffects)
  EndIf;#PB_Sound_MultiChannel is leaking memory
EndProcedure

Procedure StopSoundEffect(Sound.a)
  If Not SoundInitiated
    ProcedureReturn
  EndIf
  
  StopSound(Sound)
  
EndProcedure

Procedure PauseSoundEffect(Sound.a)
  If Not SoundInitiated
    ProcedureReturn
  EndIf
  
  PauseSound(Sound)
  
EndProcedure

Procedure ResumeSoundEffect(Sound.a)
  If Not SoundInitiated
    ProcedureReturn
  EndIf
  
  ResumeSound(Sound)
  
EndProcedure

;HasExecuted will tell if the soundstatus has been executed
;because the sound might not been iniated
Procedure.i SoundEffectStatus(Sound.a, *HasExecuted.Ascii)
  If Not SoundInitiated
    *HasExecuted\a = #False
    ProcedureReturn
  EndIf
  *HasExecuted\a = #True
  ProcedureReturn SoundStatus(Sound)
  
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

Procedure ChangePlayFieldState(*PlayField.TPlayField, NewState.a)
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
  *PlayField\TimeSurvived = 0.0
  *PlayField\IdleTimer = 0.0
  ChangePlayFieldState(*PlayField, #ChoosingFallingPiecePosition)
  
EndProcedure

Macro GetFallingPieceWheelWidth(Width)
  Width = #FallingPieceWheel_Pieces_Per_Column * #Piece_Size * Piece_Width
EndMacro

Procedure SetupFallingPieceWheel(*FallingPieceWheel.TFallingPieceWheel, PosX.f, PosY.f)
  InitFallingPieceWheel(*FallingPieceWheel)
  *FallingPieceWheel\x = PosX
  *FallingPieceWheel\y = PosY
  
  If IsSprite(*FallingPieceWheel\CurrentPieceBackgroundSprite)
    FreeSprite(*FallingPieceWheel\CurrentPieceBackgroundSprite)
  EndIf
  
  *FallingPieceWheel\CurrentPieceBackgroundSprite = CreateSprite(#PB_Any, #Piece_Size * Piece_Width, #Piece_Size * Piece_Height,
                                                                 #PB_Sprite_AlphaBlending)
  
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

Procedure.i GetPieceTypeColorRGB(PieceType.a)
  Select PieceType
    Case #Line
      ProcedureReturn RGB(255, 0, 0)
    Case #Square
      ProcedureReturn RGB(0, 0, 255)
    Case #LeftL
      ProcedureReturn RGB(255, 255, 0)
    Case #RightL
      ProcedureReturn RGB(Red(#Magenta), Green(#Magenta), Blue(#Magenta))
    Case #Left4
      ProcedureReturn RGB(Red(#Cyan), Green(#Cyan), Blue(#Cyan))
    Case #Tee
      ProcedureReturn RGB(0, 255, 0)
    Case #Right4
      ProcedureReturn RGB($FF, $66, $00)
    Default
      ProcedureReturn #Black
  EndSelect
  
EndProcedure

Procedure.i GetPieceTypeColorRGBA(PieceType.a)
  Select PieceType
    Case #Line
      ProcedureReturn RGBA(255, 0, 0, 255)
    Case #Square
      ProcedureReturn RGBA(0, 0, 255, 255)
    Case #LeftL
      ProcedureReturn RGBA(255, 255, 0, 255)
    Case #RightL
      ProcedureReturn RGBA(Red(#Magenta), Green(#Magenta), Blue(#Magenta), 255)
    Case #Left4
      ProcedureReturn RGBA(Red(#Cyan), Green(#Cyan), Blue(#Cyan), 255)
    Case #Tee
      ProcedureReturn RGBA(0, 255, 0, 255)
    Case #Right4
      ProcedureReturn RGBA($FF, $66, $00, 255)
    Default
      ProcedureReturn RGBA(Red(#Black), Green(#Black), Blue(#Black), 255)
  EndSelect
  
EndProcedure

Procedure.i GetPieceSpriteByColor(Color.u)
  Select Color
    Case #RedColor
      ProcedureReturn PiecesSprites(0)
    Case #BlueColor
      ProcedureReturn PiecesSprites(1)
    Case #YellowColor
      ProcedureReturn PiecesSprites(2)
    Case #MagentaColor
      ProcedureReturn PiecesSprites(3)
    Case #CyanColor
      ProcedureReturn PiecesSprites(4)
    Case #GreenColor
      ProcedureReturn PiecesSprites(5)
    Case #OrangeColor
      ProcedureReturn PiecesSprites(6)
    Default
      ProcedureReturn #False
  EndSelect
  
EndProcedure

Procedure CreateSparklesParticlesSprites()
  Protected i.a
  Protected Dim SpritesColors.q(#Num_Sparkles_Particles_Sprites - 1)
  SpritesColors(2) = RGBA($CC, $FF, $FF, $FF);almost white
  SpritesColors(1) = RGBA($FF, $FF, $66, $FF);light yellow
  SpritesColors(0) = RGBA($FF, $FF, $00, $FF);heavy yellow
  For i = 0 To #Num_Sparkles_Particles_Sprites - 1
    If IsSprite(SparklesParticlesSprites(i))
      FreeSprite(SparklesParticlesSprites(i))
    EndIf
    
    SparklesParticlesSprites(i) = CreateSprite(#PB_Any, 1, 1, #PB_Sprite_AlphaBlending)
    If SparklesParticlesSprites(i) <> 0
      StartDrawing(SpriteOutput(SparklesParticlesSprites(i)))
      Box(0, 0, 1, 1, SpritesColors(i))
      StopDrawing()
    EndIf
    
    
  Next i
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
            Protected Color.q = GetPieceTypeColorRGBA(PieceType)
            Box(x * Piece_Width, y * Piece_Height, Piece_Width - 1, Piece_Height - 1, Color)
          EndIf
        Next y
      Next x
      
      StopDrawing()
      FallingPieceWheelSprites(PieceType) = Sprite
    EndIf
    
  Next
  
EndProcedure

Procedure CreatePiecesSprites()
  Protected PieceType.a
  For PieceType = #Line To #Right4
    If IsSprite(PiecesSprites(PieceType))
      FreeSprite(PiecesSprites(PieceType))
    EndIf
    
    Protected PieceSprite.i = CreateSprite(#PB_Any, Piece_Width - 1, Piece_Height - 1, #PB_Sprite_AlphaBlending)
    If PieceSprite <> 0
      StartDrawing(SpriteOutput(PieceSprite))
      DrawingMode(#PB_2DDrawing_AllChannels)
      Box(0, 0, Piece_Width, Piece_Height, GetPieceTypeColorRGBA(PieceType))
      StopDrawing()
      PiecesSprites(PieceType) = PieceSprite
    EndIf
    
    
  Next
EndProcedure

Procedure.a CreatePlayfieldOutlineSprite()
  If IsSprite(PlayfieldOutlineSprite)
    FreeSprite(PlayfieldOutlineSprite)
  EndIf
  
  PlayfieldOutlineSprite = CreateSprite(#PB_Any, #PlayFieldSize_Width * Piece_Width, #PlayFieldSize_Height * Piece_Height, #PB_Sprite_AlphaBlending)
  If PlayfieldOutlineSprite <> 0
    StartDrawing(SpriteOutput(PlayfieldOutlineSprite))
    DrawingMode(#PB_2DDrawing_AllChannels)
    Box(0, 0, SpriteWidth(PlayfieldOutlineSprite), SpriteHeight(PlayfieldOutlineSprite), RGBA(0, 0, 0, 0))
    DrawingMode(#PB_2DDrawing_Outlined | #PB_2DDrawing_AllChannels)
    Box(0, 0, SpriteWidth(PlayfieldOutlineSprite), SpriteHeight(PlayfieldOutlineSprite), RGBA($7f, 80, 70, 255))
    StopDrawing()
    ProcedureReturn #True
  EndIf
  
  ProcedureReturn #False
  
  
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
  PiecesConfiguration(#Line)\Color = #RedColor
  
  PiecesConfiguration(#Square)\PieceType = #Square
  PiecesConfiguration(#Square)\NumConfigurations = 1
  StringListToAsciiList("2", PiecesConfiguration(#Square)\PieceTemplates())
  PiecesConfiguration(#Square)\WidthInPieces = 2
  PiecesConfiguration(#Square)\HeightInPieces = 2
  PiecesConfiguration(#Square)\Color = #BlueColor
  
  PiecesConfiguration(#LeftL)\PieceType = #LeftL
  PiecesConfiguration(#LeftL)\NumConfigurations = 4
  StringListToAsciiList("3,4,5,6", PiecesConfiguration(#LeftL)\PieceTemplates())
  PiecesConfiguration(#LeftL)\WidthInPieces = 3
  PiecesConfiguration(#LeftL)\HeightInPieces = 2
  PiecesConfiguration(#LeftL)\Color = #YellowColor
  
  PiecesConfiguration(#RightL)\PieceType = #RightL
  PiecesConfiguration(#RightL)\NumConfigurations = 4
  StringListToAsciiList("7,8,9,10", PiecesConfiguration(#RightL)\PieceTemplates())
  PiecesConfiguration(#RightL)\WidthInPieces = 3
  PiecesConfiguration(#RightL)\HeightInPieces = 2
  PiecesConfiguration(#RightL)\Color = #MagentaColor
  
  PiecesConfiguration(#Left4)\PieceType = #Left4
  PiecesConfiguration(#Left4)\NumConfigurations = 2
  StringListToAsciiList("11,12", PiecesConfiguration(#Left4)\PieceTemplates())
  PiecesConfiguration(#Left4)\WidthInPieces = 3
  PiecesConfiguration(#Left4)\HeightInPieces = 2
  PiecesConfiguration(#Left4)\Color = #CyanColor
  
  PiecesConfiguration(#Tee)\PieceType = #Tee
  PiecesConfiguration(#Tee)\NumConfigurations = 4
  StringListToAsciiList("13,14,15,16", PiecesConfiguration(#Tee)\PieceTemplates())
  PiecesConfiguration(#Tee)\WidthInPieces = 3
  PiecesConfiguration(#Tee)\HeightInPieces = 2
  PiecesConfiguration(#Tee)\Color = #GreenColor
  
  PiecesConfiguration(#Right4)\PieceType = #Right4
  PiecesConfiguration(#Right4)\NumConfigurations = 2
  StringListToAsciiList("17,18", PiecesConfiguration(#Right4)\PieceTemplates())
  PiecesConfiguration(#Right4)\WidthInPieces = 3
  PiecesConfiguration(#Right4)\HeightInPieces = 2
  PiecesConfiguration(#Right4)\Color = #OrangeColor
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
    ProcedureReturn RGB($FF, $66, $00)
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
        DisplayTransparentSprite(PiecesSprites(PieceType), *PlayField\x + x * Piece_Width + i * Piece_Width, *PlayField\y + y * Piece_Height + j * Piece_Height)
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
  DisplayTransparentSprite(PlayfieldOutlineSprite, *Playfield\x, *Playfield\y)
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

Procedure DrawTimeUp(*Playfield.TPlayfield, *PlayfieldsDifficulty.TPlayfieldsDifficulty)
  If *Playfield\State = #GameOver
    ProcedureReturn
  EndIf
  
  If *PlayfieldsDifficulty\TimeUntilNextDifficulty <= #Time_Up_Warning_Timer
    Protected TimeUpText.s = "FASTER!"
    Protected TimeTextNumChars.u = Len(TimeUpText)
    Protected TimeUpX.f, TimeUpY.f
    TimeUpX = *Playfield\x + (*Playfield\Width - TimeTextNumChars * 16) / 2
    TimeUpY = *Playfield\y + 5
    Protected Timer.u = (*PlayfieldsDifficulty\TimeUntilNextDifficulty * 1000) / 200
    Protected Transparency.a = 255 * (Timer % 2)
    DrawBitmapText(TimeUpX, TimeUpY, TimeUpText, 16, 24, Transparency)
  EndIf
  
EndProcedure

Procedure DrawIdleWarning(*PlayField.TPlayfield)
  If *PlayField\IdleTimer >= PlayfieldsDifficulty\CurrentIdleTimer
    Protected IdleText.s = "IDLE!"
    Protected IdleTextNumChars.u = Len(IdleText)
    Protected IdleTextX.f, IdleTextY.u
    IdleTextX = *PlayField\x + (*PlayField\Width - IdleTextNumChars * 16) / 2
    IdleTextY = *PlayField\y + 10
    Protected Timer.u = (*PlayField\IdleTimer * 1000) / 200
    Protected Transparency.a = 255 * (Timer % 2)
    DrawBitmapText(IdleTextX, IdleTextY, IdleText, 16, 24, Transparency)
    
  EndIf
EndProcedure

Procedure DrawPlayfield(*PLayField.TPlayField)
  DrawFallingPiecePosition(*PLayField)
  
  Protected x.u, y.u
  For x = 0 To #PlayFieldSize_Width - 1
    For y = 0 To #PlayFieldSize_Height - 1
      If (*PlayField\PlayField(x, y) & #Empty)
        Continue
      EndIf
      
      Protected PieceInfo.u = *PlayField\PlayField(x, y)
      Protected PieceColor.u = PieceInfo & #Color_Mask
      DisplayTransparentSprite(GetPieceSpriteByColor(PieceColor), *PlayField\x + x * Piece_Width, *PlayField\y + y * Piece_Height)
    Next y
  Next x
  
  DrawTimeUp(*PLayField, @PlayfieldsDifficulty)
  
  DrawIdleWarning(*PLayField)
  
  DrawFallingPiece(*PLayField)
  
  DrawPlayFieldOutline(*PLayField)
  
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

Procedure DrawPauseMenu()
  Protected PausedText.s = "PAUSED"
  Protected PausedTextNumChars.u = Len(PausedText)
  Protected PausedX.f, PausedY.f
  PausedX = (ScreenWidth() - (PausedTextNumChars * 16)) / 2
  PausedY = 200
  DrawBitmapText(PausedX, PausedY, PausedText)
EndProcedure

Procedure DrawSinglePlayerGameOver()
  Protected GameOverCharWidth.a = 32
  Protected GameOverCharHeight.a = 48
  
  Protected GameOverText.s = "GAME OVER"
  Protected GameOverTextNumChars.u = Len(GameOverText)
  Protected GameOverX.f, GameOverY.f
  GameOverX = (ScreenWidth() - (GameOverTextNumChars * GameOverCharWidth)) / 2
  GameOverY = 100
  DrawBitmapText(GameOverX, GameOverY, GameOverText, GameOverCharWidth, GameOverCharHeight)
  
  Protected ScoreText.s = "Your score:" + Str(PlayFields(0)\Score)
  Protected ScoreTextNumChars.u = Len(ScoreText)
  Protected ScoreTextX.f, ScoreTextY.f
  ScoreTextX = (ScreenWidth() - (ScoreTextNumChars * 16)) / 2
  ScoreTextY = GameOverY + GameOverCharHeight + 10
  DrawBitmapText(ScoreTextX, ScoreTextY, ScoreText)
  
  Protected SurvivedText.s = "Time Survived:" + StrF(PlayFields(0)\TimeSurvived, 2)
  Protected SurvivedTextNumChars.u = Len(SurvivedText)
  Protected SurvivedTextX.f, SurvivedTextY.f
  SurvivedTextX = (ScreenWidth() - (SurvivedTextNumChars * 16)) / 2
  SurvivedTextY = ScoreTextY + GameOverCharHeight + 10
  DrawBitmapText(SurvivedTextX, SurvivedTextY, SurvivedText)
  
  Protected KeyText.s = "Left Control to go back"
  Protected KeyTextNumChars.u = Len(KeyText)
  Protected KeyTextX.f, KeyTextY.f
  KeyTextX = (ScreenWidth() - (KeyTextNumChars * 16)) / 2
  KeyTextY = SurvivedTextY + 24 + 10
  DrawBitmapText(KeyTextX, KeyTextY, KeyText)
EndProcedure

Procedure DrawMultiplayerGameOver()
  Protected WinnerCharWidth.a = 32
  Protected WinnerCharHeight.a = 48
  
  Protected WinnerText.s = "RANKING"
  Protected WinnerTextNumChars.u = Len(WinnerText)
  Protected WinnerTextX.f, WinnerTextY.f
  WinnerTextX = (ScreenWidth() - (WinnerTextNumChars * WinnerCharWidth)) / 2
  WinnerTextY = 100
  DrawBitmapText(WinnerTextX, WinnerTextY, WinnerText, WinnerCharWidth, WinnerCharHeight)
  
  
  Protected PlayerCharWidth.a = 16
  Protected PlayerCharHeight.a = 24
  Protected i.a = 1
  ForEach GameState\PlayfieldsRanking\RankPositions()
    Protected PlayerID.s = "Player " + Str(GameState\PlayfieldsRanking\RankPositions()\PlayerID)
    Protected Score.s = "Score:" + GameState\PlayfieldsRanking\RankPositions()\Score
    Protected Survived.s = "Survived:" + StrF(GameState\PlayfieldsRanking\RankPositions()\TimeSurvived, 2)
    
    Protected RankText.s = PlayerID + "|" + Score + "|" + Survived
    Protected RankTextNumChars.u = Len(RankText)
    Protected RankTextX.f, RankTextY.f
    RankTextX = (ScreenWidth() - (RankTextNumChars * PlayerCharWidth)) / 2
    RankTextY = (WinnerTextY + WinnerCharHeight + 10) + ((i - 1) * (PlayerCharHeight + 10))
    DrawBitmapText(RankTextX, RankTextY, RankText, PlayerCharWidth, PlayerCharHeight)
    
    i + 1
  Next
  
  
  
  
  Protected KeyText.s = "Left Control to go back"
  Protected KeyTextNumChars.u = Len(KeyText)
  Protected KeyTextX.f, KeyTextY.f
  KeyTextX = (ScreenWidth() - (KeyTextNumChars * 16)) / 2
  KeyTextY = RankTextY + PlayerCharHeight + 10
  DrawBitmapText(KeyTextX, KeyTextY, KeyText)
  
EndProcedure

Procedure DrawParticles()
  Protected i.a
  For i = 0 To #Max_Particles - 1
    If Not SparklesParticles(i)\Active
      Continue
    EndIf
    
    ZoomSprite(SparklesParticles(i)\Sprite, SparklesParticles(i)\w, SparklesParticles(i)\h)
    DisplayTransparentSprite(SparklesParticles(i)\Sprite, SparklesParticles(i)\x, SparklesParticles(i)\y, SparklesParticles(i)\Transparency)
    
  Next
  
EndProcedure

Procedure Draw()
  If GameState\CurrentGameState = #Playing
    DrawPlayFields()
  ElseIf GameState\CurrentGameState = #StartMenu
    DrawStartMenu()
  ElseIf GameState\CurrentGameState = #Paused
    DrawPlayFields()
    DrawPauseMenu()
    
  ElseIf GameState\CurrentGameState = #SinglePlayerGameOver
    DrawPlayFields()
    DrawSinglePlayerGameOver()
    
  ElseIf GameState\CurrentGameState = #MultiplayerGameOver
    DrawPlayFields()
    DrawMultiplayerGameOver()
  EndIf
  
  DrawParticles()
  
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
          *PlayField\State = #GameOver
          ProcedureReturn
        EndIf
        
        
        If Not IsCellWithinPlayField(XCell, YCell)
          Continue
        EndIf
        
        *PlayField\PlayField(XCell, YCell) = #Filled | PiecesConfiguration(FallingPiece\Type)\Color
      EndIf
      
    Next j
    
  Next i
  
  ClearPlayFieldCompletedLines(*PlayField)
  If CheckCompletedLines(*PlayField)
    ChangePlayFieldState(*PlayField, #ScoringCompletedLines)
  Else
    ChangePlayFieldState(*PlayField, #ChoosingFallingPiecePosition)
  EndIf
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
  
  ;the template for the current configuration
  If IsActionKeyActivated(*PlayField\ActionKey)
    *FallingPiece\Configuration = (*FallingPiece\Configuration + 1) % NumConfigurations
  EndIf
  
  ;gets the current template used by the falling piece
  Protected PieceTemplateIdx.a = GetPieceTemplateIdx(*FallingPiece\Type, *FallingPiece\Configuration)
  
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
    If *FallingPiece\FallingTimer >= PlayfieldsDifficulty\FallTime
      ;fall down one line
      *FallingPiece\PosY + 1
      *FallingPiece\FallingTimer = 0.0
    EndIf
  EndIf
  
EndProcedure

Procedure ChooseCurrentPiece(*Playfield.TPlayField)
  If *Playfield\State <> #ChoosingFallingPiece
    ProcedureReturn
  EndIf
  
  *Playfield\FallingPieceWheel\ChoosedPiece = #True
  *Playfield\FallingPieceWheel\ChoosedPieceTimer = 0.5
  
EndProcedure

Procedure UpdateFallingPieceWheel(*PlayField.TPlayField, Elapsed.f)
  If *PlayField\State <> #ChoosingFallingPiece
    ProcedureReturn
  EndIf
  
  Protected *FallingPieceWheel.TFallingPieceWheel = @*PlayField\FallingPieceWheel
  
  *FallingPieceWheel\CurrentTimer + Elapsed
  If *FallingPieceWheel\CurrentTimer >= PlayfieldsDifficulty\FallingPieceWheelTimer And (Not *FallingPieceWheel\ChoosedPiece)
    ;just cycle through the pieces
    *FallingPieceWheel\CurrentTimer  = 0
    *FallingPieceWheel\PieceType = (*FallingPieceWheel\PieceType + 1) % #Num_Piece_Types
  EndIf
  
  If IsActionKeyActivated(*PlayField\ActionKey) And (Not *FallingPieceWheel\ChoosedPiece)
    ;the player chose the current piece
    ChooseCurrentPiece(*PlayField)
    ;TODO: emit some particles
    ;GetEmitter(PosX, PosY, 45, 0, 1 / 1000, @EmitterQuickSparklesUpdate())
    Protected Column.a = *FallingPieceWheel\PieceType % #FallingPieceWheel_Pieces_Per_Column
    Protected Line.a = *FallingPieceWheel\PieceType / #FallingPieceWheel_Pieces_Per_Line
    Protected PosX.f = *PlayField\x + *PlayField\Width + 10 + Column * (#Piece_Size * Piece_Width + 10)
    Protected PosY.f = *PlayField\y + 30 + Line * (#Piece_Size * Piece_Height + 10)
    GetEmitter(PosX, PosY, 0, 0, 500 / 1000, @EmitterQuickSparklesUpdate())
  EndIf
  
  If *FallingPieceWheel\ChoosedPiece And *FallingPieceWheel\ChoosedPieceTimer >=0
    ;we use this timer to flash the chosen piece
    *FallingPieceWheel\ChoosedPieceTimer - Elapsed
  EndIf
  
  If *FallingPieceWheel\ChoosedPiece And *FallingPieceWheel\ChoosedPieceTimer < 0
    ChangePlayFieldState(*PlayField, #WaitingFallingPiece)
  EndIf
EndProcedure

Procedure CheckKeys()
  ControlReleased = KeyboardReleased(#PB_Key_LeftControl)
  SpaceKeyReleased = KeyboardReleased(#PB_Key_Space)
  BackspaceReleased = KeyboardReleased(#PB_Key_Back)
  DownKeyReleased = KeyboardReleased(#PB_Key_Down)
  PKeyReleased = KeyboardReleased(#PB_Key_P)
EndProcedure

Procedure ChooseCurrentPosition(*PlayField.TPlayField)
  If *PlayField\State <> #ChoosingFallingPiecePosition
    ProcedureReturn
  EndIf
  
  *PlayField\FallingPiecePosition\ChoosedPosition = #True
  *PlayField\FallingPiecePosition\ChoosedPositionTimer = 0.5
  
EndProcedure

Procedure UpdateFallingPiecePosition(*PlayField.TPlayField, Elapsed.f)
  If *PlayField\State <> #ChoosingFallingPiecePosition
    ProcedureReturn
  EndIf
  
  Protected *FallingPiecePosition.TFallingPiecePosition = @*PlayField\FallingPiecePosition
  
  If IsActionKeyActivated(*PlayField\ActionKey) And Not *FallingPiecePosition\ChoosedPosition
    ChooseCurrentPosition(*PlayField)
    ;TODO:emit some particles
    Protected PosX.f = *PLayField\x + *FallingPiecePosition\Column * Piece_Width
    Protected PosY.f = *PlayField\y
    GetEmitter(PosX, PosY, 45, 0, 1 / 1000, @EmitterQuickSparklesUpdate())
  EndIf
  
  If Not *FallingPiecePosition\ChoosedPosition
    *FallingPiecePosition\CurrentTimer + Elapsed
  EndIf
  
  If *FallingPiecePosition\CurrentTimer >= PlayfieldsDifficulty\FallingPiecePositionTimer
    *FallingPiecePosition\Column = (*FallingPiecePosition\Column + 1) % #PlayFieldSize_Width
    *FallingPiecePosition\CurrentTimer = 0
  EndIf
  
  If *FallingPiecePosition\ChoosedPositionTimer > 0
    *FallingPiecePosition\ChoosedPositionTimer - Elapsed
  EndIf
  
  If *FallingPiecePosition\ChoosedPosition And *FallingPiecePosition\ChoosedPositionTimer <= 0
    ChangePlayFieldState(*PlayField, #ChoosingFallingPiece)
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

Procedure BringPlayFieldOneLineUp(*Playfield.TPlayfield, StartLine.b)
  If *Playfield\State = #GameOver
    ProcedureReturn
  EndIf
  Protected CurrentLine.b, CurrentColumn.a
  For CurrentLine = 1 To #PlayFieldSize_Height - 1
    For CurrentColumn = 0 To #PlayFieldSize_Width - 1
      *Playfield\PlayField(CurrentColumn, CurrentLine - 1) = *Playfield\PlayField(CurrentColumn, CurrentLine)
    Next CurrentColumn
    
  Next CurrentLine
  
EndProcedure

Procedure.u RandomColor()
  Dim Colors.u(6)
  
  Colors(0) = #RedColor
  Colors(1) = #BlueColor
  Colors(2) = #YellowColor
  Colors(3) = #MagentaColor
  Colors(4) = #CyanColor
  Colors(5) = #GreenColor
  Colors(6) = #OrangeColor
  
  ProcedureReturn Colors(Random(6))
  
  
EndProcedure

Procedure.a FillPlayfieldLine(*Playfield.TPlayField, Line.a)
  If *Playfield\State = #GameOver
    ProcedureReturn
  EndIf
  If Not IsCellWithinPlayField(0, Line)
    ProcedureReturn #False
  EndIf
  
  Protected CurrentColumn.a
  Protected EmptyColumn.a = Random(#PlayFieldSize_Width - 1)
  For CurrentColumn = 0 To #PlayFieldSize_Width - 1
    If CurrentColumn = EmptyColumn
      ;a random column will be always empty
      *Playfield\PlayField(CurrentColumn, Line) = #Empty
      Continue
    EndIf
    
    ;all other columns have a 50% chance of being empty
    If Random(1)
      Protected Color.u = RandomColor()
      ;we fill and put a color
      *Playfield\PlayField(CurrentColumn, Line) = #Filled | Color
    Else
      ;if it is even, it will be empty
      *Playfield\PlayField(CurrentColumn, Line) = #Empty
    EndIf
  Next
  
  
EndProcedure

Procedure MultiplayerAttack(AttackerPlayfieldID.a, CompletedLines.a)
  Protected i.a
  While CompletedLines > 0
    For i = 1 To NumPlayers
      If AttackerPlayfieldID = PlayFields(i - 1)\PlayerID
        ;can't attack itself
        Continue
      EndIf
      
      BringPlayFieldOneLineUp(@PlayFields(i - 1), #PlayFieldSize_Height - 1)
      FillPlayfieldLine(@PlayFields(i - 1), #PlayFieldSize_Height - 1)
      
    Next i
    CompletedLines - 1
  Wend
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
      *PLayField\Score + *PLayField\CompletedLines\SequentialCompletedLines * #Completed_Line_Score
      If *PLayField\CompletedLines\SequentialCompletedLines > 1
        ;bonus score
        *PLayField\Score + (*PLayField\CompletedLines\SequentialCompletedLines - 1) * (#Completed_Line_Score / 4)
      EndIf
      MultiplayerAttack(*PLayField\PlayerID, *PLayField\CompletedLines\SequentialCompletedLines)
      ClearPlayFieldCompletedLines(*PLayField)
      ChangePlayFieldState(*PLayField, #ChoosingFallingPiecePosition)
    EndIf
  EndIf
EndProcedure

Procedure ChangeGameState(*GameState.TGameState, NewGameState.a)
  *GameState\OldGameState = *GameState\CurrentGameState
  *GameState\CurrentGameState = NewGameState
  Select NewGameState
    Case #StartMenu
      StopSoundEffect(#MainMusic)
      
    Case #Playing
      If *GameState\OldGameState = #StartMenu
        ;starting a new game, play the music from the beginning
        PlaySoundEffect(#MainMusic, #True)
      ElseIf *GameState\OldGameState = #Paused
        PlaySoundEffect(#UnpauseSound)
        ;was paused just resume the  main music
        ResumeSoundEffect(#MainMusic)
      EndIf
      
    Case #Paused
      PauseSoundEffect(#MainMusic)
      PauseSoundEffect(#TimeUpSound)
      PauseSoundEffect(#IdleSound)
      PlaySoundEffect(#PauseSound)
      
    Case #SinglePlayerGameOver
      StopSoundEffect(#MainMusic)
      StopSoundEffect(#TimeUpSound)
      StopSoundEffect(#IdleSound)
      PlaySoundEffect(#GameOverSound)
      *GameState\MinTimeGameOver = 2.0
      
    Case #MultiplayerGameOver
      StopSoundEffect(#MainMusic)
      StopSoundEffect(#TimeUpSound)
      StopSoundEffect(#IdleSound)
      PlaySoundEffect(#WinnerSound)
      *GameState\MinTimeGameOver = 3.0
      
  EndSelect
EndProcedure

Procedure InitPlayfieldsDifficulty(*PlayfieldsDifficulty.TPlayfieldsDifficulty)
  *PlayfieldsDifficulty\FallingPiecePositionTimer = #Initial_Falling_Piece_Position_Timer
  *PlayfieldsDifficulty\FallingPieceWheelTimer = #Initial_Falling_Piece_Position_Timer
  *PlayfieldsDifficulty\FallTime = #Initial_Fall_Time
  *PlayfieldsDifficulty\TimeUntilNextDifficulty = #Time_Until_Next_Difficulty
  *PlayfieldsDifficulty\PlayingTimeUp = #False
  *PlayfieldsDifficulty\CurrentDifficulty = 0;first difficulty
  *PlayfieldsDifficulty\MaxDifficulty = #Max_Difficulty
  *PlayfieldsDifficulty\CurrentIdleTimer = #Initial_Idle_Timer
EndProcedure

Procedure StartNewGame(NumberOfPlayers.a)
  NumPlayers = NumberOfPlayers
  InitPlayFields(NumPlayers, PlayFields())
  InitPlayfieldsDifficulty(@PlayfieldsDifficulty)
  CreateFallingPieceWheelSprites()
  CreateFallingPiecePositionSprite()
  CreatePiecesSprites()
  CreatePlayfieldOutlineSprite()
  ChangeGameState(@GameState, #Playing)
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

Procedure GetPlayfieldsRanking(*PlayfieldsRanking.TPlayfieldsRanking)
  Protected i.a
  
  ClearList(*PlayfieldsRanking\RankPositions())
  
  
  For i = 1 To NumPlayers
    AddElement(*PlayfieldsRanking\RankPositions())
    *PlayfieldsRanking\RankPositions()\PlayerID = PlayFields(i - 1)\PlayerID
    *PlayfieldsRanking\RankPositions()\Score = PlayFields(i - 1)\Score
    *PlayfieldsRanking\RankPositions()\TimeSurvived = PlayFields(i - 1)\TimeSurvived
  Next
  
  ;first we sort by time survived
  SortStructuredList(*PlayfieldsRanking\RankPositions(), #PB_Sort_Descending, OffsetOf(TPlayfieldRankPosition\TimeSurvived), TypeOf(TPlayfieldRankPosition\TimeSurvived))
  ;and then by score making the score the main attribute to win
  SortStructuredList(*PlayfieldsRanking\RankPositions(), #PB_Sort_Descending, OffsetOf(TPlayfieldRankPosition\Score), TypeOf(TPlayfieldRankPosition\Score))
  
  
  
EndProcedure

Procedure UpdateGameOverPlayFields(Elapsed.f)
  If NumPlayers = 1
    If PlayFields(0)\State = #GameOver
      ChangeGameState(@GameState, #SinglePlayerGameOver)
    EndIf
    ProcedureReturn
  EndIf
  
  Protected i.a
  Protected AlivePlayers.a = 0
  For i = 1 To NumPlayers
    If PlayFields(i - 1)\State <> #GameOver
      AlivePlayers + 1
    EndIf
  Next
  
  If AlivePlayers = 0
    GetPlayfieldsRanking(@GameState\PlayfieldsRanking)
    ChangeGameState(@GameState, #MultiplayerGameOver)
  EndIf
  

EndProcedure

Procedure UpdatePauseMenu(Elapsed.f)
  If PKeyReleased
    ChangeGameState(@GameState, #Playing)
  EndIf
EndProcedure

Procedure PausePlayingGame()
  ;paused the game
  ChangeGameState(@GameState, #Paused)
EndProcedure

Procedure UpdateSinglePlayerGameOver(Elapsed.f)
  GameState\MinTimeGameOver - Elapsed
  If ControlReleased And GameState\MinTimeGameOver <= 0
    ChangeGameState(@GameState, #StartMenu)
  EndIf
EndProcedure

Procedure UpdateMultiplayerGameOver(Elapsed.f)
  GameState\MinTimeGameOver - Elapsed
  Protected AnyActionKeyReleased.a = Bool(ControlReleased Or SpaceKeyReleased Or BackspaceReleased Or DownKeyReleased)
  If AnyActionKeyReleased And GameState\MinTimeGameOver <= 0
    ChangeGameState(@GameState, #StartMenu)
  EndIf
EndProcedure

Procedure IncreasePlayfieldsDifficulty(*PlayfieldsDifficulty.TPlayfieldsDifficulty)
  *PlayfieldsDifficulty\CurrentDifficulty + 1
  If *PlayfieldsDifficulty\CurrentDifficulty > *PlayfieldsDifficulty\MaxDifficulty
    ;won't increase past maxdifficulty
    ProcedureReturn
  EndIf
  Select *PlayfieldsDifficulty\CurrentDifficulty
    Case 1 To 4:
      ;starts at #Initial_Falling_Piece_Position_Timer and #Intial_Falling_Piece_Wheel_Timer
      *PlayfieldsDifficulty\FallingPiecePositionTimer - 0.15;less 150 ms
      *PlayfieldsDifficulty\FallingPieceWheelTimer - 0.15;less 150 ms
      *PlayfieldsDifficulty\FallTime - 0.015             ;less 15 ms
      *PlayfieldsDifficulty\CurrentIdleTimer - 2;less 2 seconds
    Case 5:
      *PlayfieldsDifficulty\FallTime - 0.015
      *PlayfieldsDifficulty\CurrentIdleTimer - 2
    Case 6 To 7:
      *PlayfieldsDifficulty\FallTime - 0.015             ;less 15 ms
    Default
      
  EndSelect
EndProcedure

Procedure UpdatePlayfieldsDifficulty(*PlayfieldsDifficulty.TPlayfieldsDifficulty, Elapsed.f)
  *PlayfieldsDifficulty\TimeUntilNextDifficulty - Elapsed
  If *PlayfieldsDifficulty\TimeUntilNextDifficulty <= 0
    *PlayfieldsDifficulty\TimeUntilNextDifficulty = #Time_Until_Next_Difficulty
    IncreasePlayfieldsDifficulty(*PlayfieldsDifficulty)
    
    *PlayfieldsDifficulty\PlayingTimeUp = #False
    StopSoundEffect(#TimeUpSound)
    
  EndIf
  
  If Not *PlayfieldsDifficulty\PlayingTimeUp And *PlayfieldsDifficulty\TimeUntilNextDifficulty <= #Time_Up_Warning_Timer
    *PlayfieldsDifficulty\PlayingTimeUp = #True
    PlaySoundEffect(#TimeUpSound, #True)
  EndIf
  
EndProcedure

Procedure UpdateTimeSurvived(*Playfield.TPlayField, Elapsed.f)
  If *Playfield\State <> #GameOver
    *Playfield\TimeSurvived + Elapsed
  EndIf
EndProcedure

Procedure UpdateIdleTimer(*Playfield.TPlayField, Elapsed.f)
  ;#ChoosingFallingPiece
  ;#ChoosingFallingPiecePosition
  Protected State.a = *Playfield\State
  Protected ShouldUpdate.a = Bool((State = #ChoosingFallingPiece) Or (State = #ChoosingFallingPiecePosition))
  If ShouldUpdate
    *Playfield\IdleTimer + Elapsed
  EndIf
  
  If IsActionKeyActivated(*PlayField\ActionKey)
    *Playfield\IdleTimer = 0
  EndIf
  
  
  
  If *Playfield\IdleTimer >= (PlayfieldsDifficulty\CurrentIdleTimer + 3)
    Select *Playfield\State
      Case #ChoosingFallingPiece
        ChooseCurrentPiece(*Playfield)
      Case #ChoosingFallingPiecePosition
        ChooseCurrentPosition(*Playfield)
    EndSelect
    
    *Playfield\IdleTimer = 0
    
  EndIf
  
  If *Playfield\IdleTimer >= PlayfieldsDifficulty\CurrentIdleTimer
    Protected HasExecuted.Ascii\a = #False
    Protected Status = SoundEffectStatus(#IdleSound, @HasExecuted)
    If HasExecuted\a
      If Status <> #PB_Sound_Playing
        ;
        PlaySoundEffect(#IdleSound)
      EndIf      
    EndIf
  EndIf
  
  
EndProcedure

Procedure UpdateParticles(Elapsed.f)
  ForEach Emitters()
    If Emitters()\Active
      Emitters()\Update(@Emitters(), Elapsed)
    EndIf
  Next
  
  Protected i.a
  For i = 0 To #Max_Particles - 1
    If SparklesParticles(i)\Active
      SparklesParticles(i)\Update(@SparklesParticles(i), Elapsed)
    EndIf
  Next
  
  
  
EndProcedure

Procedure Update(Elapsed.f)
  If #PB_Compiler_Debugger
    If KeyboardReleased(#PB_Key_G)
      ChangeGameState(@GameState, #SinglePlayerGameOver)
      ProcedureReturn
    EndIf
    
    If KeyboardReleased(#PB_Key_H)
      ;randomly sets one of the playfields as the last survivor
      Protected RandomWinner.a = Random(NumPlayers, 1), PlayerID.a
      For PlayerID = 1 To NumPlayers
        If PlayFields(PlayerID - 1)\PlayerID = RandomWinner
          ;this will be the last survivor
          Continue
        EndIf
        PlayFields(PlayerID - 1)\State = #GameOver
      Next
    EndIf
    
    If KeyboardReleased(#PB_Key_J)
      ;sets all playfields to game over
      For PlayerID = 1 To NumPlayers
        PlayFields(PlayerID - 1)\State = #GameOver
      Next
    EndIf
    
    
  EndIf
  
  If GameState\CurrentGameState = #Playing
    CheckKeys()
    If PKeyReleased
      PausePlayingGame()
      ProcedureReturn
    EndIf
    
    Protected i.a
    For i = 1 To NumPlayers
      UpdateFallingPiece(@PlayFields(i - 1), Elapsed)
      UpdateFallingPieceWheel(@PlayFields(i - 1), Elapsed)
      UpdateFallingPiecePosition(@PlayFields(i - 1), Elapsed)
      UpdateScoringCompletedLines(@PlayFields(i - 1), Elapsed)
      UpdateTimeSurvived(@PlayFields(i - 1), Elapsed)
      UpdateIdleTimer(@PlayFields(i - 1), Elapsed)
    Next i
    UpdateGameOverPlayFields(Elapsed)
    UpdatePlayfieldsDifficulty(@PlayfieldsDifficulty, Elapsed)
  ElseIf GameState\CurrentGameState = #StartMenu
    UpdateStartMenu(Elapsed)
  ElseIf GameState\CurrentGameState = #Paused
    CheckKeys()
    UpdatePauseMenu(Elapsed)
  ElseIf GameState\CurrentGameState = #SinglePlayerGameOver
    CheckKeys()
    UpdateSinglePlayerGameOver(Elapsed)
  ElseIf GameState\CurrentGameState = #MultiplayerGameOver
    CheckKeys()
    UpdateMultiplayerGameOver(Elapsed)
  EndIf
  
  UpdateParticles(Elapsed)

EndProcedure

;===================main program starts here================
InitSprite()
InitKeyboard()
SoundInitiated = Bool(InitSound() <> 0)
UseOGGSoundDecoder()
LoadSounds()
OpenWindow(1, 0,0, #Game_Width, #Game_Height,"One-Button Tetris", #PB_Window_ScreenCentered | #PB_Window_SystemMenu)
OpenWindowedScreen(WindowID(1),0,0, #Game_Width, #Game_Height , 0, 0, 0)
UsePNGImageDecoder()
LoadBitmapFontSprite()
SetupStartMenu()
LoadPiecesTemplate()
LoadPiecesConfigurations()
CreateSparklesParticlesSprites()
ChangeGameState(@GameState, #StartMenu)

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