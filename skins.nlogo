; Copyright 2015 Simon Crase
; See Info tab for full copyright and license.

patches-own [
  countdown      ;; controls regrowth
]

turtles-own [
  energy        ;; need this to live, and a higher level to reproduce
  skin          ;; controls marriage and who can eat what
]

breed [people person]

people-own [
  gender
  age
]

breed [animals animal]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to setup
  clear-all
  setup-food-for-animals
  setup-animals
  setup-people
  reset-ticks
end

;; create animals and distribute them uniformly

to setup-animals
  set-default-shape animals "cow"
  create-animals number-of-animals [
     setxy random-xcor random-ycor
     set skin random get-number-skins
     set color get-color skin
     set energy animal-energy-start
    ]
end

;; create people in centre, so nobody will be too close to a breeding ground

to setup-people
  set-default-shape people "person"
  create-people number-of-people [
    setxy 0 0
    set gender random 2
    set skin random 4
    set color get-color skin
    set energy person-energy-start
    set age 0
    ]
end

;; setup patches with and without food

to setup-food-for-animals
  ask patches [
    set pcolor one-of [green brown]
    if-else pcolor = green
      [ set countdown grass-regrowth-time ]
      [ set countdown random grass-regrowth-time ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to go
    ask people [
      move-people
      catch-animal
      death person-life-expentancy
      reproduce-people
      set age age + 1
    ]
    ask animals [
      move-animal
      set energy energy - 1
      eat-grass
      death animal-life-expentancy
      reproduce-animal
  ]
  ask patches [ grow-grass ]
  tick
end

;; If energy low enough, try to catch and eat an animal.
;; Don't eat animal if its skin matches ours!

to catch-animal
  if energy < satiation-energy [
    let my-skin  skin
    let prey one-of animals-here
    if prey != nobody [
      let food-energy 0
      ask prey [
        let skin-for-breed get-skin-for-breeding-ground xcor ycor
        if  skin != my-skin [
          set food-energy energy
          die
        ]
      ]
      set energy energy + human-gain-from-food * food-energy / 100
    ]
  ]
end

to move-animal
  rt random 45
  fd random animal-speed
end

;; move person - but stay put if this would place us in someelse's breeding ground

to move-people
  let x0  xcor
  let y0  ycor
  rt random 45
  fd random 10
  let breeding-skin get-skin-for-breeding-ground xcor ycor
  if-else  breeding-skin = -1 or breeding-skin = skin
    [set energy energy - person-cost-move]
    [set xcor x0
     set ycor y0]
end

to-report get-color [skin-number]
  report 10 * skin-number + 5
end

to-report get-number-skins
  report 4
end

to  reproduce-people
  if age > age-at-puberty and energy > 1.5 * person-energy-start [
      let my-gender gender
      let my-skin skin
      let  found-partner FALSE
      ask other people-here [
        if my-gender = 0 and gender = 1 and energy > 1.5 * person-energy-start and age > age-at-puberty  [
          let new-skin get-child my-skin skin
          if new-skin > -1 [
            set  found-partner TRUE
            hatch 1 [
              set gender random 2
                set skin new-skin
                set color get-color skin
                set energy person-energy-start
                set age 0
            ]
            set energy energy - female-cost-reproduction * person-energy-start / 100.0
          ] ;; if new skin
        ] ;; if my-gender
      ] ;;ask
      if found-partner[
        set energy energy - male-cost-reproduction * person-energy-start / 100.0
      ]
  ] ;;age
end



to death [life-expectancy]
  if energy < 0 or random life-expectancy = 0 [ die ]
end

to grow-grass  ;; patch procedure
  ;; countdown on brown patches: if reach 0, grow some grass
  if pcolor = brown [
    ifelse countdown <= 0
      [ set pcolor green
        set countdown grass-regrowth-time ]
      [ set countdown countdown - 1 ]
  ]
end

to eat-grass  ;; sheep procedure
  ;; sheep eat grass, turn the patch brown
  if pcolor = green [
    set pcolor brown
    set energy energy + animal-gain-from-food  ;; sheep gain energy by eating
  ]
end

to reproduce-animal  ;; sheep procedure
  let skin-for-breed get-skin-for-breeding-ground xcor ycor
  if skin = skin-for-breed and random-float 100 < animal-reproduce [  ;; throw "dice" to see if you will reproduce
    set energy (energy / 2)                ;; divide energy between parent and offspring
    hatch 1 [
       set color get-color skin
       rt random-float 360
       fd 1
       ]   ;; hatch an offspring and move it forward 1 step
  ]
end



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Section name (female)  Marries (male)  Children
; 0 Karimarra  1 Panaka  2 Pal.yarri
; 1 Panaka  0 Karimarra  3 Purungu
; 2 Pal.yarri  3 Purungu  0 Karimarra
; 3 Purungu  2 Pal.yarri  1 Panaka
to-report get-child[father mother]
  if father = 0 and mother = 1 [report 2]
  if father = 1 and mother = 0 [report 3]
  if father = 2 and mother = 3 [report 0]
  if father = 3 and mother = 2 [report 1]
  report -1
end

to-report get-skin-for-breeding-ground [x y]
  if min-pxcor <= x and min-pxcor + width-breeding-ground >= x and max-pycor >= y and max-pycor - width-breeding-ground <= y [report 0]
  if max-pxcor >= x and max-pxcor - width-breeding-ground <= x and max-pycor >= y and max-pycor - width-breeding-ground <= y [report 1]
  if min-pxcor <= x and min-pxcor + width-breeding-ground >= x and min-pycor <= y and min-pycor + width-breeding-ground >= y [report 2]
  if max-pxcor >= x and max-pxcor - width-breeding-ground <= x and min-pycor <= y and min-pycor + width-breeding-ground >= y  [report 3]
  report -1
end
@#$#@#$#@
GRAPHICS-WINDOW
930
10
1549
650
16
16
18.455
1
10
1
1
1
0
1
1
1
-16
16
-16
16
0
0
1
ticks
30.0

BUTTON
840
15
904
48
Setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
200
10
372
43
number-of-people
number-of-people
0
100
98
1
1
NIL
HORIZONTAL

CHOOSER
775
105
912
150
skin-system
skin-system
"Martuthunira (4)"
0

SLIDER
390
10
562
43
number-of-animals
number-of-animals
0
1000
306
1
1
NIL
HORIZONTAL

PLOT
15
490
895
645
People
NIL
NIL
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count people with [skin = 0]"
"pen-1" 1.0 0 -7500403 true "" "plot count people with [skin = 1]"
"pen-2" 1.0 0 -2674135 true "" "plot count people with [skin = 2]"
"pen-3" 1.0 0 -955883 true "" "plot count people with [skin = 3]"

SLIDER
200
45
372
78
person-energy-start
person-energy-start
0
200
100
1
1
NIL
HORIZONTAL

SLIDER
200
80
372
113
person-cost-move
person-cost-move
0
10
1
0.5
1
NIL
HORIZONTAL

SLIDER
200
115
382
148
person-life-expentancy
person-life-expentancy
0
1000
478
1
1
NIL
HORIZONTAL

PLOT
15
320
895
485
Animals
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count animals with [skin = 0]"
"pen-1" 1.0 0 -7500403 true "" "plot count animals with [skin = 1]"
"pen-2" 1.0 0 -2674135 true "" "plot count animals with [skin = 2]"
"pen-3" 1.0 0 -955883 true "" "plot count animals with [skin = 3]"

PLOT
15
655
890
805
Plants
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count patches with [pcolor = green]"

SLIDER
570
10
742
43
grass-regrowth-time
grass-regrowth-time
0
30
6
1
1
NIL
HORIZONTAL

SLIDER
390
50
562
83
animal-gain-from-food
animal-gain-from-food
0
50
25
0.5
1
NIL
HORIZONTAL

SLIDER
390
90
562
123
animal-reproduce
animal-reproduce
1
50
50
1
1
%
HORIZONTAL

SLIDER
575
50
752
83
width-breeding-ground
width-breeding-ground
1
16
12
1
1
NIL
HORIZONTAL

BUTTON
840
55
903
88
go
Go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
200
150
387
183
human-gain-from-food
human-gain-from-food
0
100
64
1
1
%
HORIZONTAL

SLIDER
395
125
567
158
animal-speed
animal-speed
0
10
4.5
0.5
1
NIL
HORIZONTAL

SLIDER
200
185
372
218
satiation-energy
satiation-energy
0
250
156
1
1
NIL
HORIZONTAL

SLIDER
390
160
567
193
animal-life-expentancy
animal-life-expentancy
0
500
56
1
1
NIL
HORIZONTAL

PLOT
925
660
1540
810
Energy
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot sum [energy] of animals"
"pen-1" 1.0 0 -7500403 true "" "plot sum [energy] of people"
"pen-2" 1.0 0 -2674135 true "" "plot sum [energy] of turtles"

SLIDER
400
205
572
238
animal-energy-start
animal-energy-start
0
200
100
1
1
NIL
HORIZONTAL

SLIDER
200
220
392
253
male-cost-reproduction
male-cost-reproduction
0
100
17
1
1
%
HORIZONTAL

SLIDER
200
255
387
288
female-cost-reproduction
female-cost-reproduction
0
100
89
1
1
NIL
HORIZONTAL

SLIDER
210
290
382
323
age-at-puberty
age-at-puberty
0
100
25
1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

Model the rules that some Aboriginal groups have created to preserve animals.

Several years agoo I was struck by a description of the rules for conserving totem animals, which show evidence of having been designed very carefully. This model is intended as a respectful exploration of the rules, to verify my belief that they ensure stability of the population. I've created this model in the hope it will answer two questions.

  * Do the marriage rules keep the kin system stable (e.g., what happens if there is a gross imbalance in ratios?
  * Do the food rules ensure that the mix of species remains stable?

## HOW IT WORKS

The model has three interacting types of agent:

  * Food (patches)     Food grows, and it is eaten by animals. Some pathces are assigned to be breeding areas).
  * Animals (turtles)  Animals gain energy from Food. If an animal has enough energy, it may reproduce, but only in a Breeding Area.
  * People (turtles)   People gain energy by eating animals whose skin is different from their own. If people have enough energy they can reproduce, provided they find a partner (of the correct gender) whose skin is the correct one also. The offspring have the approriate skin, depending on the parents. Reproduction costs energy,

People and animals both die:

 * if they run out of energy, or;
 * namdomly (the life expectancy is used to set a proabaility of death).

Animals also die if they are eaten!

Assumptions:

 * we do not need to assume monogamy, as the extra book-keeping isn't expected to change to outcome.
 * we can assume asexuial reproduction on the part of animals.
 * all animals depend on a homogeneous food source.
 * we assume that nobody evey violates the breeding grounds.

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

 * Allow kinship rules to be varied, say by loading from a CSV file.
 * Allow kinship restrictions to be turned off to see how influential they are.

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

I have borrowed code from Wolf Sheep Predation

## CREDITS AND REFERENCES


  * The model is distributed under the [GNU LESSER GENERAL PUBLIC LICENSE, Version 3, 29 June 2007](https://github.com/weka511/models/blob/master/LICENSE)

  * [Link to model](https://github.com/weka511/models)

  * [Description of kinship system](http://en.wikipedia.org/wiki/Australian_Aboriginal_kinship)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.2.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
1
@#$#@#$#@
