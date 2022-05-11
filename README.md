# Chinese Checkers Game
## Package Contents
### Overview
Julia package that provides:
 - A **rule engine** for Chinese Checkers 
 - A **game model** with different bots to play Chinese Checkers.

### **Rule Engine**
The rule engine contains functions to determine:
 - Next Posible Turns
 - Winning Positions

### **Game Model**
The game model contains functions to model the game and train bots.

---

## Testing 

Under Package mode enter:

`
activate .
`

Then in the Julia REPL enter the following:

```
   using Pkg
   Pkg.test("ChineseCheckers")
```