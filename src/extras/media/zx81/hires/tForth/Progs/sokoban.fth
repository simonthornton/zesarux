CR .( SOKOACE )
\ Sokoban game for the Jupiter ACE

\ (c) 2006  by Ricardo Fernandes Lopes
\ under the GNU General Public Licens

CR .( PLAY THE GAME WITH: )
CR .( PLAY )

: TASK ;
\ Set print position to row n1 and column n2
: AT  ( n1 n2 -- )
   SWAP 33 * + 16530 ( screen)
   + 17339 ( cur_pos) ! ;
\ Leave greater of two numbers
: MAX  ( n1 n2 -- n3)
   2DUP <
   IF SWAP
   THEN
   DROP ;
\ Leave lesser of two numbers
: MIN  ( n1 n2 -- n3)
   2DUP >
   IF SWAP
   THEN
   DROP ;
\ Drive the ZON-X81 sound device.
HEX
CODE SND ( n1 n2 -- )            ( Write n1 to AY register n2 )
  79 C,          \ ld a,c
  D3 C, DF C,    \ out ($df),a
  E1 C,          \ pop hl
  7D C,          \ ld a,l
  D3 C, 0F C,    \ out ($0f),a
  C1 C,          \ pop bc
  NEXT           \ jp NEXT
\ Turns off all sound on all channels, A,B and C
: SNDOFF  ( -- )
   FF 7 SND ;
: BEEP ( c n -- )
   SWAP 0 SND
   0 1 SND
   FE 7 SND
   0F 8 SND
   0 DO LOOP SNDOFF ; DECIMAL

( Graphic characters )
CREATE T 64 ALLOT
: GR 8 * T + DUP 8 + SWAP DO I C! LOOP ;
: SETGR 64 0 DO T I + C@ 12288 I + C! LOOP ;
HEX
00 00 00 00 00 00 00 00 00 GR ( Not used      )
00 00 00 18 18 00 00 00 01 GR ( Target        )
3C 42 81 FF 99 99 7E 3C 02 GR ( Soko          )
3C 42 BD FF BD 99 7E 3C 03 GR ( Soko + Target )
00 7E 42 42 42 42 7E 00 04 GR ( Box           )
00 7E 42 5A 5A 42 7E 00 05 GR ( Box + Target  )
FF AB D5 AB D5 AB D5 FF 06 GR ( Wall          )
00 10 00 10 10 10 10 00 07 GR 
DECIMAL

( Screen elements)
01 CONSTANT TARGET  ( 00 0001b )
02 CONSTANT SOKO    ( 00 0010b )
04 CONSTANT BOX     ( 00 0100b )
06 CONSTANT WALL    ( 00 0110b )

: IN? ( -- n , get number from user)
  BEGIN
    TIB @ DUP LBP ! INPUT
    BL WORD COUNT NUMBER
  UNTIL DROP ;

\ : +! ( n adr -- )  SWAP OVER @ + SWAP ! ;
: INC ( a -- )   1 SWAP +! ;
: DEC ( a -- )  -1 SWAP +! ;

0 VARIABLE SOKO>   ( holds SOKO screen address )
0 VARIABLE #BOX    ( number of boxes out of target )
0 VARIABLE #STEP   ( number of steps )
0 VARIABLE #PUSH   ( number of pushes )

( Movement directions)
-33 CONSTANT UP
 33 CONSTANT DOWN
 -1 CONSTANT LEFT
  1 CONSTANT RIGHT

: STEP ( a1 -- , move SOKO one step)
  DUP C@ TARGET AND SOKO OR OVER C! ( place SOKO in new position )
  SOKO> @                           ( previous SOKO position )
  DUP C@ TARGET AND                 ( check previous contents )
  IF TARGET ELSE 0 ( BL) THEN       ( Target or Blank )
  SWAP C!                           ( remove SOKO from old position )
  SOKO> !
  #STEP INC ;

: PUSH ( a1 a2 -- , push a BOX)
  OVER C@ TARGET AND IF #BOX INC THEN     ( Box entered a target region)
  DUP  C@ DUP TARGET AND IF #BOX DEC THEN ( Box exited a target area)
  TARGET AND BOX OR SWAP C!               ( Move Box)
  STEP                                    ( Move Soko)
  #STEP DEC                               ( Inc Pushes but not Steps)
  #PUSH INC ;

: GO ( dir -- , try to move Soko in the specified direction)
  SOKO> @ OVER +         ( next position )
  DUP C@ WALL =
  IF 2DROP               ( if WALL, do nothing )
  ELSE
    DUP C@ DUP ( BL) 0 = SWAP TARGET = OR 
    IF STEP DROP         ( if Blank or Target, do Step)
    ELSE
      SWAP OVER +        ( over next position )
      DUP C@ DUP ( BL) 0 = SWAP TARGET = OR 
      IF   PUSH          ( if Blank or Target, do Push )
      ELSE 2DROP         ( else, do nothing )
      THEN
    THEN
  THEN ;

: WALK ( c -- c, interpret key and move Soko )
  DUP ASCII I = IF UP    GO ELSE
  DUP ASCII K = IF DOWN  GO ELSE
  DUP ASCII J = IF LEFT  GO ELSE
  DUP ASCII L = IF RIGHT GO
  THEN THEN THEN THEN ;

: .#### ( a -- , formated score type)
  @ 0 <# # # # # #> TYPE ;

: .SCORE ( update score )
  3 28 AT #BOX  @ . 
  5 28 AT #STEP .####
  7 28 AT #PUSH .#### ;

: .FRAME ( Draw screen )
  CLS ." ������sokoace������� VERSION 1.0"
   3 22 AT ." BOXES ?"
   5 22 AT ." STEPS"
   7 21 AT ." PUSHES"
  10 21 AT ." i UP"
  11 21 AT ." k DOWN"
  12 21 AT ." j LEFT"
  13 21 AT ." l RIGHT"
  15 21 AT ." n LEVEL + 1"
  16 21 AT ." p LEVEL - 1"
  17 21 AT ." m LEVEL ?"
  18 21 AT ." r RESTART"
  20 21 AT ." q QUIT"
  22  0 AT ." �by�ricardo�f�lopes�   (C) 2006" ;

: SCAN ( Scan screen map for Soko position and count boxes out of target)
  0 #BOX ! ( reset number of boxes)
  17256 16596
  DO
    I C@
    DUP SOKO = IF I SOKO> ! ELSE ( Search for SOKO start position)
    DUP BOX  = IF #BOX INC       ( Count Boxes out of target)
    THEN THEN DROP
  LOOP ;

20 21 * CONSTANT MAPSIZE ( Map size = 20x20 chars + 20 chars for map label line )
CREATE MAPS MAPSIZE 20 * ALLOT ( Room for 20 maps )
: MAP ( level -- a , return a map address)
  MAPSIZE * MAPS + ;

: S-TYPE  ( work only for this proposit, don't check NEWLINE at the end of line)
  OVER + SWAP DO I C@ 17339 @ C!
  1 17339 +! LOOP ;

: MAP>SCR ( level -- , copy level map to screen)
  MAP 22 1
  DO
    I 0 AT DUP 20 S-TYPE CR 20 +
  LOOP DROP ;

0 VARIABLE LEVEL

: INIT ( level -- , Initialyze Level)
  0 #STEP ! ( reset steps count )
  0 #PUSH ! ( reset pushes count )
  .FRAME
  0 MAX 19 MIN DUP LEVEL !
  MAP>SCR
  SCAN ;

: MAP? ( c -- c , Change level)
  DUP ASCII N = IF LEVEL @ 1+  INIT ELSE ( Next level)
  DUP ASCII P = IF LEVEL @ 1-  INIT ELSE ( Previous level)
  DUP ASCII M = IF 23 1 AT IN? INIT ELSE ( Entered level number)
  DUP ASCII R = IF LEVEL @     INIT      ( Re-start same level)
  THEN THEN THEN THEN ;

: PLAY ( Main code, run this to play SokoACE)
  SETGR     ( initialize graphics )
  0 INIT    ( start the first level )
  BEGIN
    .SCORE       ( Update Score)
    KEY          ( Get key pressed )
    WALK         ( Move SOKO )
    MAP?         ( Check for level request)
    1 9 AT
    #BOX @ 0=    ( No boxes left?)
    IF
      ." DONE [" 100 50 BEEP 75 25 BEEP ( Level completed !)
    THEN 
    ASCII Q =    ( Quit?)
  UNTIL
  ." QUIT." ;
 