' ==========================================================
'  DYNAMIC GUI ENGINE FOR SCREEN 13 (QBX 7.1)
'  Author: JUAN LUIS VILACORTA | Data-Driven Architecture
' ==========================================================

DECLARE SUB FadeOUT ()
DECLARE SUB FadeIN ()
DECLARE SUB ActualizarPaleta (File$)
DECLARE SUB Browse (File$)
DECLARE SUB Edicion (File$)
DECLARE SUB EfectoExit ()
DECLARE SUB EfectoIntro ()
DECLARE SUB EfectoWindows ()
DECLARE SUB Fondo (Tipo$)
DECLARE SUB menu (File$)
DECLARE FUNCTION Pregunta$ (Titulo$, Enunciado$, Tipo$)
'  imgs....file->title,iconfile,picturefile,menufile
'  input...file->title,iconfile,savingfile,menufile

'SCREEN 7
SCREEN 13
COLOR 15
DIM SHARED MODO$
DIM SHARED AppPath$
DIM SHARED MainFile$
DIM SHARED CurrentMenu$
DIM SHARED CurrentBrowse$
DIM SHARED LineasConfig(20)  AS STRING

TYPE PALdata
 Red AS INTEGER
 Grn AS INTEGER
 Blu AS INTEGER
END TYPE

DIM SHARED PAL(255) AS PALdata

 
MODO$ = "splash"
AppPath$ = "DATA\"
MainFile$ = AppPath$ + "main.txt"
CurrentMenu$ = "menu1"

File$ = AppPath$ + "standard"
OUT &H3C7, 0

CALL ActualizarPaleta(File$)

DO
  SELECT CASE LCASE$(MODO$)

    CASE IS = "menu"
      CALL menu(CurrentMenu$)

    CASE IS = "edit"
      CALL Edicion(CurrentBrowse$)

    CASE IS = "browse"
      CALL Browse(CurrentBrowse$)

    CASE IS = "splash"
      EfectoIntro
      CALL Fondo("splash")
      DO: LOOP UNTIL INKEY$ <> ""
      MODO$ = "menu"

    CASE IS = "exit"
      IF Pregunta("Cerrar", "¨Cerrar programa?", "question") = "n" THEN
        CurrentMenu$ = "menu1"
        MODO$ = "menu"
      ELSE
        EfectoExit
        EXIT DO
      END IF
    CASE ELSE
END SELECT
LOOP
CLS
PALETTE
SCREEN 1

SUB ActualizarPaleta (File$)
'EXIT SUB
  bmppal$ = SPACE$(1024)
  OPEN File$ + ".PAL" FOR BINARY AS #1
    GET #1, 1, bmppal$
  CLOSE #1

  FOR bmpc% = 16 TO 255  'FROM 16 AVOIDING DISTORT QBX SYSTEM COLORS
    OUT &H3C8, bmpc%
    OUT &H3C9, FIX(ASC(MID$(bmppal$, bmpc% * 4 + 3, 1)) / 4)'Red
    OUT &H3C9, FIX(ASC(MID$(bmppal$, bmpc% * 4 + 2, 1)) / 4)'Green
    OUT &H3C9, FIX(ASC(MID$(bmppal$, bmpc% * 4 + 1, 1)) / 4)'Blue
  NEXT bmpc%
  'EDITA EL NEGRO A BLANCO
  OUT &H3C8, 0
  OUT &H3C9, FIX(5 / 4)
  OUT &H3C9, FIX(5 / 4)
  OUT &H3C9, FIX(35 / 4)

FOR X = 0 TO 255
 PAL(X).Red = INP(&H3C9)
 PAL(X).Grn = INP(&H3C9)
 PAL(X).Blu = INP(&H3C9)
NEXT

EXIT SUB
  OUT &H3C8, 15
  OUT &H3C9, FIX(0 / 4)
  OUT &H3C9, FIX(0 / 4)
  OUT &H3C9, FIX(0 / 4)
END SUB

SUB Browse (cual$)
DIM Limite%, LinesToDisplay%, X%, y%, i%, LineSize%, LineCount%
DIM originalText$(0 TO 255)

LinesToDisplay% = 19
LineSize% = 32: X% = 8: y% = 5: i% = 0

'browse..file->title,contentfile,menufile
OPEN MainFile$ FOR INPUT AS #1
DO WHILE NOT (EOF(1))
  LINE INPUT #1, l$
    IF LCASE$(l$) = "[" + cual$ + "]" THEN avanzar = 1: EXIT DO
LOOP
IF avanzar = 1 THEN
  LINE INPUT #1, Titulo$
  LINE INPUT #1, ContentFile$
  LINE INPUT #1, CurrentMenu$
END IF
CLOSE #1

CALL Fondo("browse")
COLOR 9
LOCATE 3, X%
PRINT Titulo$
CALL EfectoWindows
c% = 8
'LOAD FILE TEXT
OPEN AppPath$ + ContentFile$ FOR INPUT AS #1
DO WHILE NOT (EOF(1))
  LINE INPUT #1, originalText$(i%)
  DO   'BORRA TABS
    U = INSTR(originalText$(i%), CHR$(9))
    IF U = 0 THEN EXIT DO
    originalText$(i%) = MID$(originalText$(i%), 1, U - 1)
  LOOP
  originalText$(i%) = originalText$(i%) + SPACE$(LineSize%)
  originalText$(i%) = MID$(originalText$(i%), 1, LineSize%)
  i% = i% + 1
LOOP
Limite% = i% - LinesToDisplay%
IF Limite% < 1 THEN Limite% = 0

'DISPLAY FIRST LINES
GOSUB DESPLEGARLISTA

'HANDLE THE KEYBOARD
U$ = CHR$(0) + "H": D$ = CHR$(0) + "P"
l$ = CHR$(0) + "K": r$ = CHR$(0) + "M"
DO
g$ = INKEY$
  SELECT CASE g$
    CASE D$: LineCount% = LineCount% + 1: GOSUB DESPLEGARLISTA
    CASE U$: LineCount% = LineCount% - 1: GOSUB DESPLEGARLISTA
    CASE CHR$(27), "x", "X":  MODO$ = "menu": EXIT DO
  END SELECT
LOOP
CLOSE #1
EXIT SUB

DESPLEGARLISTA:
IF LineCount% > Limite% THEN LineCount% = Limite%: RETURN
IF LineCount% < 0 THEN LineCount% = 0: RETURN
  FOR i% = 0 TO LinesToDisplay% - 1
    TEXT$ = originalText$(LineCount% + i%)
    LOCATE y% + i%, X%
   IF c% = 15 THEN
      c% = 7
    ELSE
      c% = 15
    END IF
    COLOR c%
    PRINT TEXT$
  NEXT i%
RETURN

END SUB

SUB Edicion (cual$)
CONST ESC = 27, DOWN = 80, UP = 72, LEFT = 75, RIGHT = 77
CONST HOME = 71, ENDKEY = 79, PGDN = 81, PGUP = 73
DIM ITEMLENCHAR%(0 TO 9)
DIM ITEMLABEL$(0 TO 9)
DIM ITEMDATA$(0 TO 9)
DIM ColorLabel%(0 TO 9)
DIM CurrItemY%(0 TO 9)
DIM ColorInput%(0 TO 9)
DIM ColorBox%(0 TO 9)
DIM CurrentItem%
DIM Interlineado%

LineSize% = 29: X% = 8:
Interlineado% = 1

OPEN MainFile$ FOR INPUT AS #1
DO WHILE NOT (EOF(1))
  LINE INPUT #1, l$
    IF LCASE$(l$) = "[" + cual$ + "]" THEN avanzar = 1: EXIT DO
LOOP
IF avanzar = 1 THEN
  LINE INPUT #1, Titulo$
  LINE INPUT #1, ContentFile$
  LINE INPUT #1, CurrentMenu$
  LINE INPUT #1, g$: ItemsToDisplay% = VAL(MID$(g$, 11))
  FOR i = 0 TO 4
  LINE INPUT #1, g$
    ITEMLABEL$(i) = MID$(g$, 11)
  LINE INPUT #1, g$
    ITEMLENCHAR%(i) = VAL(MID$(g$, 11))
    ITEMDATA$(i) = ""
  NEXT
END IF
CLOSE #1
g$ = ""
X% = 8
CALL Fondo("edit")
COLOR 9
LOCATE 3, X%
PRINT LEFT$(Titulo$ + SPACE$(25), 25)
CALL EfectoWindows
ColorLabel%(0) = 9
ColorInput%(0) = 7
ColorLabel%(1) = 9
ColorInput%(1) = 7

GOSUB REESCRIBE
COLOR 10: LOCATE 25, 8: PRINT " F2:Guardar ";
COLOR 10: LOCATE 25, 26: PRINT " ESC:Cancelar ";
CurrentItem% = 0
'etiqueta, campo

'HANDLE THE KEYBOARD
U$ = CHR$(0) + "H": D$ = CHR$(0) + "P"
l$ = CHR$(0) + "K": r$ = CHR$(0) + "M"
DO
g$ = INKEY$
IF g$ <> "" THEN
  SELECT CASE g$
   CASE CHR$(0) + "<": GOSUB ALMACENAR: MODO$ = "menu": EXIT DO
    CASE U$:
      CurrentItem% = CurrentItem% - 1
      IF CurrentItem% < 0 THEN CurrentItem% = 0
      g$ = CHR$(0)
      GOSUB REESCRIBE
    CASE D$, CHR$(13), CHR$(9):
      CurrentItem% = CurrentItem% + 1
      IF CurrentItem% > ItemsToDisplay% - 1 THEN CurrentItem% = ItemsToDisplay% - 1
      g$ = CHR$(0)
      GOSUB REESCRIBE
  END SELECT
  SELECT CASE ASC(g$)
    CASE ESC: MODO$ = "menu": EXIT DO
    CASE 8: g$ = "":
      IF LEN(ITEMDATA$(CurrentItem%)) > 0 THEN ITEMDATA$(CurrentItem%) = LEFT$(ITEMDATA$(CurrentItem%), LEN(ITEMDATA$(CurrentItem%)) - 1): GOSUB ESCRIBE: GOSUB ESCRIBE
    CASE IS < 31, 127  'Control code
    CASE 32: GOSUB ESCRIBE
    CASE 48 TO 57: GOSUB ESCRIBE 'Digit
    CASE 65 TO 90: GOSUB ESCRIBE  'Uppercase letter
    CASE 97 TO 122: GOSUB ESCRIBE 'Lowercase letter
    CASE ELSE: GOSUB ESCRIBE      'Punctuation
  END SELECT
END IF
LOOP

EXIT SUB

REESCRIBE:
OLD% = CurrentItem%
y% = 2 - Interlineado%
FOR CurrentItem% = 0 TO ItemsToDisplay% - 1
  ColorLabel%(CurrentItem%) = 7
  ColorInput%(CurrentItem%) = 7
  ColorBox%(CurrentItem%) = 8
  y% = y% + ((3 + Interlineado%))
  CurrItemY%(CurrentItem%) = y%
  IF CurrentItem% <> OLD% THEN GOSUB ESCRIBE
NEXT
CurrentItem% = OLD%
y% = CurrItemY%(CurrentItem%)
ColorBox%(CurrentItem%) = 6
ColorLabel%(CurrentItem%) = 14
ColorInput%(CurrentItem%) = 15
GOSUB ESCRIBE
RETURN


ESCRIBE:
IF LEN(ITEMDATA$(CurrentItem%)) < ITEMLENCHAR%(CurrentItem%) AND g$ <> CHR$(0) THEN ITEMDATA$(CurrentItem%) = ITEMDATA$(CurrentItem%) + g$:
    F% = (X% + LEN(ITEMDATA$(CurrentItem%)) - 1) * 8
    
    IF F% <= 55 + ((ITEMLENCHAR%(CurrentItem%)) * 8) THEN
      LINE (F%, ((y% + Interlineado%) * 8))-(F% + 8, ((y% + Interlineado%) * 8) + 8), ColorBox%(CurrentItem%), BF
      LINE (F% + 8, ((y% + Interlineado%) * 8))-(F% + 16, ((y% + Interlineado%) * 8) + 8), 0, BF
    END IF
    COLOR ColorLabel%(CurrentItem%): LOCATE y%, X%: PRINT ITEMLABEL$(CurrentItem%)
    COLOR ColorInput%(CurrentItem%): LOCATE y% + 1 + Interlineado%, X%: PRINT ITEMDATA$(CurrentItem%)
    LINE (56, ((y% + Interlineado%) * 8))-(56 - ITEMLENCHAR%(CurrentItem%) + ((ITEMLENCHAR%(CurrentItem%)) * 9), ((y% + Interlineado%) * 8) + 8), ColorBox%(CurrentItem%), B
    WAIT &H3DA, 8, 8: WAIT &H3DA, 8, 0
RETURN

ALMACENAR:

OPEN AppPath$ + ContentFile$ FOR APPEND AS #1
  FOR i = 0 TO 4
    PRINT #1, ITEMDATA$(i)
  NEXT
CLOSE #1
a$ = Pregunta("Almacenar", "Datos guardados correctamente", "Information")
RETURN

END SUB

SUB EfectoExit

FOR y = 0 TO 98
LINE (0, y)-(319, y), 0
LINE (0, y + 1)-(319, y + 1), 15
LINE (0, y + 2)-(319, y + 2), 4

LINE (0, 199 - y + 2)-(319, 199 - y + 2), 0
LINE (0, 199 - y + 1)-(319, 199 - y + 1), 15
LINE (0, 199 - y)-(319, 199 - y), 4

FOR W = 0 TO 3000: NEXT
NEXT
  OUT &H3C8, 0
  OUT &H3C9, FIX(0 / 4)
  OUT &H3C9, FIX(0 / 4)
  OUT &H3C9, FIX(0 / 4)

END SUB

SUB EfectoIntro

  FOR y = 99 TO 0 STEP -1
    LINE (0, y)-(319, y), 15
    LINE (0, y)-(49, y), 232
    
    LINE (0, 199 - y)-(319, 199 - y), 15
    LINE (0, 199 - y)-(49, 199 - y), 232
FOR W = 0 TO 3000: NEXT
  NEXT

END SUB

SUB EfectoWindows
X = 53
FOR y = 30 TO 184
  LINE (X, y)-(311, y), 0
  LINE (X, y + 2)-(311, y + 2), 8
  FOR W = 0 TO 500: NEXT
NEXT
LINE (X, 185)-(311, 186), 0, BF
END SUB

SUB FadeIN
c = 0
FOR y = 1 TO 64
 FOR X = 0 TO 255
  OUT &H3C8, X
  r = PAL(c).Red + (y * ((PAL(X).Red - PAL(c).Red) / 64))
  g = PAL(c).Grn + (y * ((PAL(X).Grn - PAL(c).Grn) / 64))
  b = PAL(c).Blu + (y * ((PAL(X).Blu - PAL(c).Blu) / 64))
  OUT &H3C9, r
  OUT &H3C9, g
  OUT &H3C9, b
 NEXT
 t! = TIMER: DO: LOOP UNTIL TIMER > t! + .01
NEXT

END SUB

DEFINT A-Z
SUB FadeOUT
c = 0 'Color of fade.
OUT &H3C8, 0
FOR y = 1 TO 64
 FOR X = 0 TO 15
  r = PAL(X).Red - (y * ((PAL(X).Red - PAL(c).Red) / 64))
  g = PAL(X).Grn - (y * ((PAL(X).Grn - PAL(c).Grn) / 64))
  b = PAL(X).Blu - (y * ((PAL(X).Blu - PAL(c).Blu) / 64))
  OUT &H3C9, r
  OUT &H3C9, g
  OUT &H3C9, b
 NEXT
t! = TIMER: DO: LOOP UNTIL TIMER > t! + .01
NEXT

END SUB

DEFSNG A-Z
SUB Fondo (Tipo$)
          File$ = AppPath$ + "menu.img"
  SELECT CASE LCASE$(Tipo$)
    CASE IS = "splash"
          File$ = AppPath$ + "SPLASH.img"
      iconfile$ = ""
    CASE IS = "browse"
      iconfile$ = AppPath$ + "Icon1.img"
    CASE IS = "edit"
      iconfile$ = AppPath$ + "Icon10.img"
    CASE IS = "menu"
      iconfile$ = AppPath$ + "Icon2.img"
    CASE IS = "question"
      iconfile$ = AppPath$ + "Icon8.img"
    CASE IS = "information"
      iconfile$ = AppPath$ + "Icon7.img"
    CASE ELSE
  END SELECT

IF iconfile$ <> "" THEN
  DIM Icon(90 * 49) AS INTEGER
  DEF SEG = VARSEG(Icon(0))
    BLOAD iconfile$, 0
  DEF SEG
END IF

'WAIT &H3DA, 8, 8: WAIT &H3DA, 8, 0
DEF SEG = &HA000
  BLOAD File$
DEF SEG
IF iconfile$ <> "" THEN PUT (0, 0), Icon, PSET

'PAINT (0, 0), 255, 255
''PAINT (0, 0), 0, 255
'DIM Mask(48 * 48) AS INTEGER
'GET (0, 0)-(47, 47), Mask

'PUT (140, 140), Mask, AND 'black must be in 255
'PUT (140, 140), image, OR 'black will be transparent

END SUB

SUB menu (cual$)
DIM Limite%, LinesToDisplay%, X%, y%, i%, LineSize%, LineCount%
DIM originalText$(0 TO 255)
DIM ITEMCOLOR%(0 TO 9)
DIM ITEMTEXT$(0 TO 9)
DIM ITEMACTION$(0 TO 9)
DIM CurrentM$(0 TO 9)
CALL Fondo("menu")

LineSelected% = 0
LineCount% = 0
LinesToDisplay% = 19
LineSize% = 32: X% = 8: y% = 5: i% = 0

'LOAD FILE TEXT
avanzar = 0
OPEN MainFile$ FOR INPUT AS #1
DO WHILE NOT (EOF(1))
  LINE INPUT #1, l$
    IF LCASE$(l$) = "[" + cual$ + "]" THEN avanzar = 1: EXIT DO
LOOP
IF avanzar = 1 THEN
  DO WHILE NOT (EOF(1))
    LINE INPUT #1, l$
     IF LCASE$(l$) = "end" THEN EXIT DO
      SELECT CASE UCASE$(MID$(l$, 1, 2))
        CASE IS = "T:": Titulo$ = MID$(l$, 3)
        CASE IS = "I:": ITEMTEXT$(i%) = MID$(l$, 3)
        CASE IS = "M:": CurrentM$(i%) = MID$(l$, 3): ITEMACTION$(i%) = "menu": i% = i% + 1
        CASE IS = "B:": CurrentBrowse$ = MID$(l$, 3): ITEMACTION$(i%) = "browse": i% = i% + 1
        CASE IS = "E:": CurrentBrowse$ = MID$(l$, 3): ITEMACTION$(i%) = "edit": i% = i% + 1
        CASE IS = "X:": ITEMACTION$(i%) = "exit": i% = i% + 1
      END SELECT
  LOOP
END IF
Limite% = i% - 1

COLOR 9
LOCATE 3, X%
WAIT &H3DA, 8, 8: WAIT &H3DA, 8, 0
PRINT Titulo$
CALL EfectoWindows

FOR i% = 0 TO Limite%
  ITEMCOLOR%(i%) = 7
NEXT i%

'DISPLAY FIRST LINES
GOSUB DESPLEGARMENU

'HANDLE THE KEYBOARD
U$ = CHR$(0) + "H": D$ = CHR$(0) + "P"
l$ = CHR$(0) + "K": r$ = CHR$(0) + "M"
DO
g$ = INKEY$
  SELECT CASE g$
    CASE D$: LineSelected% = LineSelected% + 1: GOSUB DESPLEGARMENU ': SOUND 640, 1
    CASE U$: LineSelected% = LineSelected% - 1: GOSUB DESPLEGARMENU ': SOUND 640, 1
    CASE CHR$(27), "x", "X": MODO$ = "exit": LineSelected% = -1: EXIT DO
    CASE CHR$(13): EXIT DO

    CASE "1", "2", "3", "4", "5", "6", "7", "8", "9":
    LineSelected% = VAL(g$) - 1: EXIT DO
  END SELECT
LOOP
CLOSE #1
IF LineSelected% > -1 THEN MODO$ = ITEMACTION$(LineSelected%)
IF MODO$ = "menu" THEN CurrentMenu$ = CurrentM$(LineSelected%)
EXIT SUB

DESPLEGARMENU:
COLOR 15
IF LineSelected% > Limite% THEN LineSelected% = Limite%
IF LineSelected% < 0 THEN LineSelected% = 0
  FOR i% = 0 TO Limite%
  l$ = LEFT$(RIGHT$("  " + STR$(i% + 1), 2) + ".- " + ITEMTEXT$(i%), 28)
  WAIT &H3DA, 8, 8: WAIT &H3DA, 8, 0
    LOCATE y% + (i% * 2), X%
    IF LineSelected% = i% THEN COLOR 15 ELSE COLOR 0
    PRINT CHR$(16) + SPACE$(LEN(l$) + 2); CHR$(17)
    LOCATE y% + (i% * 2), X% + 2
    IF LineSelected% = i% THEN COLOR 14 ELSE COLOR ITEMCOLOR%(i%)
    PRINT l$
  NEXT i%
RETURN
END SUB

FUNCTION Pregunta$ (Titulo$, Enunciado$, Tipo$)
y% = 10

  SELECT CASE LCASE$(Tipo$)
    CASE "information": a$ = "(Ok)"
    CASE "question": a$ = "(S/N)"
  END SELECT

CALL Fondo(Tipo$)
COLOR 9: LOCATE 3, 8: PRINT Titulo$
CALL EfectoWindows

COLOR 14
LOCATE y%, 8: PRINT SPACE$((32 - LEN(Enunciado$)) / 2) + Enunciado$
LOCATE y% + 2, 8: PRINT SPACE$((32 - 5) / 2) + a$

'HANDLE THE KEYBOARD
DO
g$ = INKEY$
  SELECT CASE g$
    CASE "n", "N", CHR$(27): Pregunta$ = "n": EXIT DO
    CASE CHR$(13), "s", "S", "y", "Y": Pregunta$ = "s": EXIT DO
  END SELECT
LOOP

END FUNCTION

