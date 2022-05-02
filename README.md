# Chinese Checkers Bot
## Overview
This project is to build an AI to play Chinese checkers.
## Game Utilites
Game utilities contains functions to determine:
 - Next Posible Turns
 - Winning Positions

## Game Model
The Game model contains the following stages:
 - Naive Training Model
    - Brute force the game state space to determine a naive set of game solutions.
 - Train the First-Order Model 
 - Iterate

 # Testing 

 `
   using Pkg
   Pkg.test("ChineseCheckers")
`