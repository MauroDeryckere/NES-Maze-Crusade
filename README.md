# NES Maze Game

## Intro

The NES Maze Game is a maze navigation game inspired by classic titles from the golden era of gaming. Designed for the Nintendo Entertainment System (NES), it offers players the chance to navigate through intricate mazes in different modes.

Players can enjoy the game on original NES hardware or through a compatible NES emulator, making it accessible to a wider audience of retro gaming enthusiasts.

## Table of Contents
1. [Intro](#intro)
2. [How To Play](#how-to-play)
   - [Gamemodes](#gamemodes) 
   - [Title Screen Controls](#title-screen-controls)
   - [In-Game Controls](#in-game-controls)  
   - [Objective](#objective)  
3. [Technical Information](#technical-information)
   - [Building Project](#building-project)
   - [Graphics](#graphics)
   - [Data Structures](#data-structures)
   - [Maze Generation](#maze-generation)
   - [Maze Solving](#maze-solving)
4. [Used Software](#used-software)
5. [References](#references)  
   - [Sources](#sources)  
   - [Initial Project](#initial-project)  

## How To Play

To play the game if you don't have a NES, you need an emulator, we have tested the game in Mesen and FCEUX but other emulators may also work when they support PAL mode. If you do have a NES you will need a way to upload the NES file to a cartridge (Everdrive, ...)

### Gamemodes

- **Hard**: Hard mode stops displaying the maze once it's been generated and has has the player looking for their way out using a classic "Fog of War" system.
- **Auto**: The auto gamemode disables player input (in hardmode) and uses solving algorithms to solve the maze. This allows you to sit back and enjoy the satisfying animation. Starting in auto mode with the hard flag enabled uses the Left Hand Rule solving algorithm, without it uses a Breadth First Search.

### Title Screen Controls

- **DPAD UP**: Move selection up
- **DPAD DOWN**: Move selection down
- **SELECT**: Select a menu item
- **START**: Start the game with the current selections

### In-Game Controls

- **START**: Pause the game
- **DPAD**: Move up, right, down, or left
- **A**: Open chest

### Objective

Navigate through the maze and reach the end to complete the level.

## Technical information
In this section we will cover a lot of the technical details for the project.

### Building project
To build the project (I am using a VS Code terminal in this case, but any terminal will work) run the folliwng command in a terminal: 
```bash
Setup\build.bat Maze
```

Having a 6502 compiler installed is a requirement for this to work, we used [CC65](https://cc65.github.io/).

### Graphics
split scrolling "hack" for HUD
score
animations

uses changed tiles buffer -> more specifics there

### Data structures

#### Buffers
Buffers (arrays) are the most commonly used data structure throughout the project, a few different ones are defined:
- Changed Tile
- Chest
- Direction
- Map
- StartScreen
- Torch
- Visited

#### Queue
The queue is a circular queue to avoid the moving of memory (limited possibility to do this in 6502). Make sure the queue capacity that is reserved is sufficient when using this for certain algorithms that require you to maintain all items in the queue.

*Note: the queue uses one extra byte at the end to be able to distinguish between full and empty without storing additonal flags / adding extra loggic (N-1 usable slots)*

Example of how the queue data structure works: 
```text
Initial state - empty: 
queue_head = 0
queue_tail = 0

Enqueue 42
queue_head = 0
queue_tail = 1
[ 42 ][ ?? ][ ?? ]

Enqueue 43
queue_head = 0
queue_tail = 2
[ 42 ][ 43 ][ ?? ]

Dequeue 
queue_head = 1
queue_tail = 2
[ ?? ][ 43 ][ ?? ]

Example of what happens when we need to wrap around in the circular queue: 
initial state: 
queue_head = 1
queue_tail = 4
[ ?? ][ 43 ][ 50 ][ 60 ][ ?? ] 

Enqueue 70 
queue_head = 1 
queue_tail = 0 - wrapped around to 0
[ 70 ][ 43 ][ 50 ][ 60 ][ ?? ]  ; note: last slot remains [??] - reserve one to distinguish between empty and full
```

### Maze generation
Prims

### Maze solving
LHR
BFS

## Used Software
**Graphics:**
- [YY-CHR](https://wiki.vg-resource.com/YY-CHR)
- [NEXXT Studio 3](https://frankengraphics.itch.io/nexxt)

**Audio:**
- [FamiStudio](https://famistudio.org/)

**Coding & Debugging:**
- [Visual Studio Code](https://code.visualstudio.com/)
- [Mesen](https://www.mesen.ca/) and [MesenX](https://github.com/NovaSquirrel/Mesen-X) (debugging and emulating)
- [FCEUX](https://fceux.com/web/home.html) (debugging and emulating)

## References

### Sources

For the controller input on the NES there are some things to consider if you use DPCM samples, to ensure this won't be an issue I used the following [source](https://www.nesdev.org/wiki/Controller_reading_code).

The split scrolling for the HUD is done using the old trick from Super Mario Bros 3 since I was not using a mapper that supports scanline interrupts at the time and the HUD is at the top row [source](https://retrocomputing.stackexchange.com/questions/1898/how-can-i-create-a-split-scroll-effect-in-an-nes-game).

### Initial Project

The initial project was made during a class in a [DAE](https://www.digitalartsandentertainment.be/page/31/Game+Development) course (Retro Console & Emulator Programming) given by Tom Tesch.

**We used the following book in that class to setup the project:** </br>
Cruise, Tony. (2024). </br>
Classic Programming on the NES. </br>
Manning Publications Co.</br>
ISBN: 9781633438019.

For more information, or to view the original project, please visit the project repository [here](https://github.com/thegamingnobody/AssemblyMaze).
ZZ