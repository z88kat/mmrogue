REM
Rem Roguelike Game in MMBASIC for the Raspberry Pi Pico
Rem This is a simple roguelike game written in MMBASIC for the Raspberry Pi Pico
Rem It features a basic map generation, player movement, and monster interaction
REM This was written during the roguelike tutorial series 2025
REM
REM This code was written directly on the Raspberry Pi Pico using the MMBASIC editor
REM
REM The game uses ANSI escape codes for cursor movement and color to diplay using telnet or serial
REM
hp = 10
max_hp = 30
level = 1
mana = 20
max_mana = 20
pos_x = 15
pos_y = 10
max_x = 50
max_y = 20
min_y = 2
min_x = 1

REM ========= MONSTERS =========
Const MAX_MONSTERS = 10
Rem 0 = x, 1 = 1
Dim monsters(MAX_MONSTERS - 1, 1)
Rem position our monster at  5,10
Monsters(0,0) = 10
Monsters(0,1) = 5

REM ========= MAP SETUP =========
Const MAP_START_Y = 3
Const MAP_START_X = 5
Const MAP_WIDTH = 40
Const MAP_HEIGHT = 16
Dim map$(MAP_WIDTH, MAP_HEIGHT)
Dim explored(MAP_WIDTH, MAP_HEIGHT)
Const MAX_ROOMS = 12
Const MIN_ROOM_SIZE = 3
Const MAX_ROOM_SIZE = 6
Const FOV_RADIUS = 8
Rem To track rooms' centers for corridor connection
Dim roomX(MAX_ROOMS)
Dim roomY(MAX_ROOMS)
roomCount = 0
Randomize Timer


Rem ======= START GAME ==========
StartGame

Rem Initalize the map
InitMap
DrawMap

Rem Draw the player for the first time
MovePlayer 99

Dim lastkey$
Rem Game Loop
Do
  b$ = Inkey$
  c = Asc(b$)
  If b$ <> "" And b$ <> lastkey$ Then
    Rem Move Right
    If c = 131 Then MovePlayer 1
    Rem Move Left
    If c = 130 Then MovePlayer 0
    Rem Move Up
    If c = 128 Then MovePlayer 2
    Rem Move Down
    If c = 129 Then MovePlayer 3
    Rem Display Stats
    If c = 115 Then DisplayStats
    Rem Rebuild the map
    If b$="r" Then
      InitMap
      DrawMap
    EndIf
  End If
  Rem Use INKEY$ with key state tracking to prevent auto move
  lastkey$=b$

  Rem If c > 100 Then Print "pressed key is ";c
Loop Until b$="q"

Rem Show the cursor
Print Chr$(27)+"[?25h"
Rem Main loop has ended
End

Sub RollStats
  hp = Int(Rnd * 10) + 20
  mana = Int(Rnd * 10) + 10
  InitStats
End Sub

Rem Move the player around the screen
Sub MovePlayer arg1

  Rem Clear the player
  Rem Render pos_y, pos_x, "."
  Local c_pos_x = pos_x
  Local c_pos_y = pos_y

  If arg1 = 1 Then pos_x = pos_x +1
  If arg1 = 0 Then pos_x = pos_x -1
  If arg1 = 2 Then pos_y = pos_y -1
  If arg1 = 3 Then pos_y = pos_y +1

  Rem Let's check what at this map position, is the player
  Rem Allowed to move to this position
  map_c$ = map$(pos_x - MAP_START_X, pos_y - MAP_START_Y)

  If map_c$="#" Then Message "You walk into the wall!" Else Message " "
  If map_c$="#" And arg1 = 1 Then pos_x = pos_x - 1
  If map_c$="#" And arg1 = 0 Then pos_x = pos_x + 1
  If map_c$="#" And arg1 = 2 Then pos_y = pos_y + 1
  If map_c$="#" And arg1 = 3 Then pos_y = pos_y - 1

  If pos_x < min_x Then pos_x = min_x
  If pos_x > max_x Then pos_x = max_x
  If pos_y < min_y Then pos_y = min_y
  If pos_y > max_y Then pos_y = max_y

  Render c_pos_y, c_pos_x, "."
  Render pos_y, pos_x, "@", "green"

  Rem LOS This can be a performance hit
  For y = pos_y - FOV_RADIUS - MAP_START_Y To pos_y + FOV_RADIUS - MAP_START_Y
    For x = pos_x - FOV_RADIUS - MAP_START_X To pos_x + FOV_RADIUS - MAP_START_X
      If x >= 0 And x < MAP_WIDTH And y >= 0 And y < MAP_HEIGHT Then
        If explored(x,y) = 0 Then
          If  IsVisible(pos_x - MAP_START_X, pos_y - MAP_START_Y, x, y) Then
            explored(x, y) = 1
            map_c$ = map$(x,y)
            Render MAP_START_Y + y, MAP_START_X + x, map_c$, "white"
          End If
        EndIf
      EndIf
    Next x
  Next y

  Rem draw the player after drawing the map
  Render c_pos_y, c_pos_x, "."
  Render pos_y, pos_x, "@", "green"

  Rem When the player moves the monsters move!
  MoveMonsters
End Sub

Sub MoveMonsters

   m_y = Monsters(0,1)
   m_x = Monsters(0,0)

   Render m_y, m_x, "T", "yellow"

End Sub

Rem draw an entity on the screen
Rem @py position on the vertical
Rem @px position on the horizontal
Rem @char the character to print
Rem @color default is white. "green", "black", "red", "yellow", "blue",
Rem "megenta", "cyan"
Sub Render py, px, char$, color$

  Rem Position the cursor at the given location and draw the character
  Rem set te cursor color, default is white
  co$ ="[37m"
  Select Case color$
    Case "green":   co$ = "[32m"
    Case "black":   co$ = "[30m"
    Case "red":     co$ = "[31m"
    Case "yellow":  co$ = "[33m"
    Case "blue":    co$ = "[34m"
    Case "magenta": co$ = "[35m"
    Case "cyan":    co$ = "[36m"
    Case Else:      co$ = "[37m"
  End Select

  Rem Enable the color
  Print Chr$(27)+co$

  Rem draw the character
  Print Chr$(27)+"["+Str$(py)+";"+Str$(px)+"f"+char$

End Sub

Sub Message msg$

  Rem handle empty string overwrite
  If msg$=" " Then msg$="                                     "

  Rem Enable The color cyan
  Print Chr$(27)+"[36m"
  ms_y = START_MAP_Y + MAP_HEIGHT + 4
  Print Chr$(27)+"["+Str$(ms_y)+";5f"+msg$

End Sub

Sub DisplayStats

  m$ = "HP: "+Str$(hp)+"/"+Str$(max_hp)
  m$ = m$+"    MANA: "+Str$(mana)+"/"+Str$(max_mana)
  m$ = m$+"   LEVEL: "+Str$(level)

  ms_y = 2
  Print Chr$(27)+"[35m"
  Print Chr$(27)+"["+Str$(ms_y)+";5f"+m$

End Sub

Sub InitStats
  Print "HP: ";hp;"/";max_hp;"   MANA: ";mana;"/";max_mana;"   LEVEL: ";level
End Sub

Rem MAP GENERATION

Rem # is a wall, cannot move
Rem . walkable: floor
Rem " " cannot see yet
Sub InitMap

  roomcount = 0
  playerPlaced = 0
  Rem means at least 2 tiles of wall between rooms.
  Const roomBuffer = 2


For y = 0 To MAP_HEIGHT - 1
  For x = 0 To MAP_WIDTH - 1
      map$(x, y) = "#"
      explored(x, y) = 0
  Next x
Next y

For i = 1 To MAX_ROOMS
  roomW = Int(Rnd * (MAX_ROOM_SIZE - MIN_ROOM_SIZE + 1)) + MIN_ROOM_SIZE
  roomH = Int(Rnd * (MAX_ROOM_SIZE - MIN_ROOM_SIZE + 1)) + MIN_ROOM_SIZE

  Rem Ensure at least 1-tile margin around map edges
  roomX1 = Int(Rnd * (MAP_WIDTH - roomW - 2)) + 1
  roomY1 = Int(Rnd * (MAP_HEIGHT - roomH - 2)) + 1

  roomX2 = roomX1 + roomW - 1
  roomY2 = roomY1 + roomH - 1

  Rem ' Check for overlap inc buffer
  overlap = 0
  For y = roomY1 - roomBuffer To roomY2 + roomBuffer
    For x = roomX1 - roomBuffer To roomX2 + roomBuffer
      If x >= 0 And x < MAP_WIDTH And y >= 0 And y < MAP_HEIGHT Then
        If map$(x, y) = "." Then overlap = 1
      EndIf
    Next x
  Next y


  If overlap = 0 Then
    Rem Carve Room
    For y = roomY1 To roomY2
      For x = roomX1 To roomX2
        map$(x, y) = "."
      Next x
    Next y

    Rem Save center of room
    roomX(roomCount) = (roomX1 + roomX2) \ 2
    roomY(roomCount) = (roomY1 + roomY2) \ 2

    Rem Place player in the first valid room
    If playerPlaced = 0 Then
      pos_x = roomX(roomCount) + MAP_START_X
      pos_y = roomY(roomCount) + MAP_START_Y
      playerPlaced = 1
    EndIf

    roomCount = roomCount + 1
  EndIf

Next i

Rem Simple L-shaped corridors connecting room centers.
  For i = 1 To roomCount - 1
    x1 = roomX(i - 1)
    y1 = roomY(i - 1)
    x2 = roomX(i)
    y2 = roomY(i)

    Rem Randomly choose to go horizontal then vertical, or vice versa
    If Rnd < 0.5 Then
      HorizontalCorridor
      VerticalCorridor
    Else
      VerticalCorridor
      HorizontalCorridor
    EndIf
  Next i
End Sub

Rem Horizontal Corridor Subroutine
Sub HorizontalCorridor
  For x = Min(x1, x2) To Max(x1, x2)
    map$(x, y1) = "."
  Next x
End Sub

Rem Vertical Corridor Subroutine
Sub VerticalCorridor
  For y = Min(y1, y2) To Max(y1, y2)
    map$(x2, y) = "."
  Next y
End Sub

Rem Draw the map on the screen
Sub DrawMap

  map_h = MAP_HEIGHT + MAP_START_Y -1
  For y = 0 To MAP_HEIGHT - 1
    For x = 0 To MAP_WIDTH - 1
      If explored(x, y) Then
        map_c$ = map$(x,y)
        Render MAP_START_Y + y, MAP_START_X + x, map_c$, "white"
      EndIf
    Next x
  Next y

  Rem Position the player on the map
  Print Chr$(27)+"["+Str$(pos_y)+";"+Str$(pos_x)+"f"+"@"
  Print Chr$(27)+"[?25l"

End Sub

Rem LOS Function (simple raycast)
Function IsVisible(x1, y1, x2, y2)
  Local dx, dy, steps, x, y, i
  Local fx, fy

  dx = x2 - x1
  dy = y2 - y1

  steps = Max(Abs(dx), Abs(dy))
  If steps = 0 Then
    IsVisible = 1
    Exit Function
  EndIf

  fx = x1
  fy = y1

  dx = dx / steps
  dy = dy / steps

  For i = 1 To steps
    fx = fx + dx
    fy = fy + dy
    x = Int(fx + 0.5)
    y = Int(fy + 0.5)

    If x < 0 Or x >= MAP_WIDTH Or y < 0 Or y >= MAP_HEIGHT Then
      IsVisible = 0
      Exit Function
    EndIf

    Rem Stop ray if wall is hit (except the target tile)
    If map$(x, y) = "#" Then
      If x = x2 And y = y2 Then
        IsVisible = 1
      Else
        IsVisible = 0
      EndIf
      Exit Function
    EndIf
  Next i

  IsVisible = 1
End Function


Rem Start the game
Sub StartGame

  Rem Clear Screen
  Print Chr$(27)+"[2J"

  Print ""
  Print "Darkness has fallen over the kingdom."
  Print ""
  Print "The evil wizard Malgareth has kidnapped the princess Elira."
  Print "and taken her to his tower."
  Print ""
  Print "Will you brave the darkness and rescue the princess before it's too late"
  Print ""
  Rem 36 lines per screen
  Print Chr$(27)+"[?91"
  Print Chr$(27)+"[35m"
  Print " ----- press (s) to start (r) to re-roll (q) to quit ----- "
  Print ""

  Rem Initialize the player stats for the first time
  RollStats
  Print ""

  Do
    b$ = Inkey$
    If b$ ="r" Then RollStats
    If b$ ="q" Then End
  Loop Until b$="s"

  Rem Clear Screen
  Print Chr$(27)+"[2J"
  Rem Make the Character Green
  Print Chr$(27)+"[32m"

End Sub