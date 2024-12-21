;*****************************************************************
; Defines
;*****************************************************************
; enable / disable pal mode
PAL_MODE = 1
; enable / disable debug mode
DEBUG_MODE = 0

; PPU Registers
PPU_CONTROL = $2000 ; PPU Control Register 1 (Write)
PPU_MASK = $2001 ; PPU Control Register 2 (Write)
PPU_STATUS = $2002; PPU Status Register (Read)
PPU_SPRRAM_ADDRESS = $2003 ; PPU SPR-RAM Address Register (Write)
PPU_SPRRAM_IO = $2004 ; PPU SPR-RAM I/O Register (Write)
PPU_VRAM_ADDRESS1 = $2005 ; PPU VRAM Address Register 1 (Write)
PPU_VRAM_ADDRESS2 = $2006 ; PPU VRAM Address Register 2 (Write)
PPU_VRAM_IO = $2007 ; VRAM I/O Register (Read/Write)
SPRITE_DMA = $4014 ; Sprite DMA Register

; PPU control register masks
NT_2000 = $00 ; nametable location
NT_2400 = $01
NT_2800 = $02
NT_2C00 = $03

; Useful PPU memory addresses
NAME_TABLE_0_ADDRESS		= $2000
ATTRIBUTE_TABLE_0_ADDRESS	= $23C0
NAME_TABLE_1_ADDRESS		= $2400
ATTRIBUTE_TABLE_1_ADDRESS	= $27C0

VRAM_DOWN = $04 ; increment VRAM pointer by row

OBJ_0000 = $00 
OBJ_1000 = $08
OBJ_8X16 = $20

BG_0000 = $00 ; 
BG_1000 = $10

VBLANK_NMI = $80 ; enable NMI

BG_OFF = $00 ; turn background off
BG_CLIP = $08 ; clip background
BG_ON = $0A ; turn background on

OBJ_OFF = $00 ; turn objects off
OBJ_CLIP = $10 ; clip objects
OBJ_ON = $14 ; turn objects on

; APU Registers
APU_DM_CONTROL = $4010 ; APU Delta Modulation Control Register (Write)
APU_CLOCK = $4015 ; APU Sound/Vertical Clock Signal Register (Read/Write)

; INPUT
; Joystick/Controller values
JOYPAD1 = $4016 ; Joypad 1 (Read/Write)
JOYPAD2 = $4017 ; Joypad 2 (Read/Write)

; Gamepad bit values
PAD_A      = $01
PAD_B      = $02
PAD_SELECT = $04
PAD_START  = $08
PAD_U      = $10
PAD_D      = $20
PAD_L      = $40
PAD_R      = $80

; DURING TITLE SCREEN
; 3 offset for size variables
START_SCREEN_BUFFER_1 = $0320 + 3
START_SCREEN_BUFFER_2 = $41F + 3
START_SCREEN_BUFFER_3 = $51E + 3

; MAP BUFFER
MAZE_BUFFER = $0320
MAP_BUFFER_SIZE = 120
MAP_COLUMNS = 32 ;32 bits
MAP_ROWS = 30

; FRONTIER LIST
FRONTIER_LISTQ1 = MAZE_BUFFER + MAP_BUFFER_SIZE
FRONTIER_LIST_CAPACITY = 120 ; capacity is more than enough, can be reduced if necessary

; VISITED CELLS BUFFER
; 120 byte buffer same as maze buffer but this stores if a cell is visited (1) or not (0)
VISISTED_ADDRESS = FRONTIER_LISTQ1
VISITED_BUFFER_SIZE = 120 

; DIRECTIONS BUFFER
DIRECTIONS_ADDRESS = VISISTED_ADDRESS + VISITED_BUFFER_SIZE
DIRECTIONS_BUFFER_SIZE = 240

; Queue data structure constants
QUEUE_START = $05B4 + 3; start address for the queue | right after start screen buffer_3 (never fully filled)
QUEUE_CAPACITY = 209 - 3; the maximum capacity of the queue - actual  available size is capacity - 1

; player directions
LEFT = 0
BOTTOM = 1 
RIGHT = 2
TOP = 3

; Neighbor util - directions
TOP_N = 0
RIGHT_N = 1 
BOTTOM_N = 2
LEFT_N = 3

; directions for solving
TOP_D = 0
RIGHT_D = 1
BOTTOM_D = 2
LEFT_D = 3

;changed tiles buffer
CHANGED_TILES_BUFFER_SIZE = 40

;SETUP
GENERATION_ANIMATION_DELAY = 40
PLAYER_MOVEMENT_DELAY = 5 ;sets the delay for player movement (==  movement speed)
MAZE_GENERATION_SPEED = 1 ;how much is maze generation slowed down
SCORE_DIGIT_OFFSET = 8

; Gamemode masks
; 000G HSSS
GAME_MODE_MASK  = %00010000 ; playing or solving
HARD_MODE_MASK  = %00001000 ; hardmode or not 
SOLVE_MODE_MASK = %00000111 ; which solving algorithm

CLEAR_SOLVING_MODE_MASK     = %11111000
BFS_MODE_MASK               = %00000000
LHR_MODE_MASK               = %00000001

GAMEMODE_TITLE_SCREEN = 0
GAMEMODE_GENERATING = 1
GAMEMODE_PLAYING = 2
GAMEMODE_SOLVING = 3
GAMEMODE_PAUSED = 4

; Tiles
WALL_TILE = 0
FRONTIER_WALL_TILE = 1
BLACK_TILE = 16
BROKEN_WALL_TILE = 17

PATH_TILES_AMOUNT = 3
PATH_TILE_1 = 2
PATH_TILE_2 = 3
PATH_TILE_3 = 4
PATH_TILE_END_L = 5
PATH_TILE_END_R = 6
;*****************************************************************