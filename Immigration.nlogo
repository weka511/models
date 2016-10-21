globals [
  injected-others-1?  ;; Used in conjunction with inject-others-1
                      ;; It ensures that we inject the first group
                      ;; of new people only once
  injected-others-2?  ;; Used in conjunction with inject-others-2
                      ;; It ensures that we inject the second group
                      ;; of new people only once
  history             ;; A record of all sadness ratings. Used to judge that
                      ;; we are unlikely to converge
]

turtles-own [
  happy?         ;; A turtle is happy if the propertion of neighbours
                 ;; sharing the same colour at least %-similar-wanted
                 ;; Sometimes we say a turtle is "sad" as a shorthand for "not happy?"
]

;; Create initial population of turtles

to setup
  clear-all
   ;; Perform a consistencey check.
   ;; If we don't intende to inject a first
   ;; group of immigrants, it doesn't make
   ;; sense to inject a second

  if n-inject-1 = 0 [set n-inject-2 0]

  ;; Initializion - there are two flags that are used to ensure that ensure that we inject each
  ;; group immigrants only once (if at all). Initialize them so we know we havevn;t done any yet

  set injected-others-1? false
  set injected-others-2? false

  ;; Initialize history - we will record the rsults of each step here

  set history []

  ;; Set all patches to a uniform background colour, and insert as many turtles as we
  ;; need to provide tht epected poulation density

  ask patches[
    set pcolor gray
    if random 100 < density [ populate-patch number-of-groups]
  ]

  ;; Find out which turtles are happy

  ask turtles [update-happiness]

  reset-ticks
end

;; Go - try to make turtles happier by moving those who aren't happy
;; It is possible to inject one or two waves of immigrants. This will
;; only be done if the state is stable - everyone is happy.

to go

  ;; Store a list of turtles who aren't happy

  let sad-turtles turtles with [not happy?]

  ;; If everyone is happy, check to see whether we should allow some new types of turtles to
  ;; join the party. We allow for up to 2 waves of immigration

  if count sad-turtles = 0 and should-stop? [stop]

  ;; We need to see whether we are going nowhere, i.e. we can't achieve happiness by
  ;; going on. The rule is that if we have done a lot of moves, and people are just as
  ;; sad as (or sadder than) the average for a numb er of ticks, we assume that stability
  ;; cannot be achieved.

  if not we-are-improving? sad-turtles [stop]

  ;; If we get here we are still running - we feel that there is some prospect of improving
  ;; happiness. Let's try moving all the sda turtles, then recalculate happiness

  ask sad-turtles [pursue-happiness]
  ask turtles [update-happiness]

  tick
end

;; Allow a certain number of immigrants to settle on vacant patches
;;    Parameters
;;      n-immigrants    Number of immigrants
;;      goup            The group that they all belong to

to-report injected-others? [n-immigrants group]
  ifelse n-immigrants < count get-vacancies
  [
    ask n-of n-immigrants get-vacancies [
      sprout 1 [
        colour-turtle group
      ]
    ]
    report true
  ]
  [
    show "The Country is full"
    report false
    ]
end

;; Add one new person to a patch, and assign them to a group at random

to populate-patch [ maximum-groups ]
  sprout 1 [
    colour-turtle random maximum-groups
  ]
end

;; Assign a colour to turtle. Each group has a differnt colour
to colour-turtle [ group ]
    if group = 0 [set color red]
    if group = 1 [set color blue]
    if group = 2 [set color green]
    if group = 3 [set color yellow]
    if group = 4 [set color cyan]
    if group = 6 [set color magenta]
    if group = 7 [set color violet]
    if group = 8 [set color pink]
end

;; Update the turtle's happiness indicator,
;; and display happy or sad face

to update-happiness
  set happy? is-happy?
  ifelse happy?[set shape "face happy"][set shape "face sad"]
end

;; Determine whther or not this turtle is happy
;; A happy turtle is one that has plenty of neighbours

to-report is-happy?
  let similar-nearby count (turtles-on neighbors)  with [ color = [ color ] of myself ]
  let other-nearby count (turtles-on neighbors) with [ color != [ color ] of myself ]
  report similar-nearby >= (%-similar-wanted * (similar-nearby + other-nearby) / 100)
end

;; Find patches that aren't occupied

to-report get-vacancies
  report patches with [count turtles-here = 0]
end

;; Move to a vacant patch, in the hope that turtle will be happier there


to pursue-happiness
  move-to one-of get-vacancies
end

;; This reporter is used when the city is stable, i.e. everyone is happy.
;; It checks to see whether we need to inject immigrants. If so it tells the
;; model to continue (by returning false), otherwise it returns true - i.e.
;; it is timne tio stop

to-report should-stop?
  ifelse n-inject-1 > 0 and not injected-others-1?  ;; This is the case where we have
                                                    ;; to do a first wave of immigration
    [
      set injected-others-1? true
      if not injected-others? n-inject-1 (number-of-groups + 1) [report true]
      ask turtles [update-happiness]
      set history []]                                 ;; Reset history, as we want the population to
    [ifelse n-inject-2 > 0 and not injected-others-2? ;; This is the case where we have
                                                      ;; to do a 2nd wave of immigration
      [
        set injected-others-2? true
        if not injected-others? n-inject-2 (number-of-groups + 2) [report true]
        ask turtles [update-happiness]
        set history []]
      [report true]]
    report false
end

;; We need to see whether we are going nowhere, i.e. we can't achieve happiness by
;; going on. The rule is that if we have done a lot of moves, and people are just as
;; sad as (or sadder than) the average for a numb er of ticks, we assume that stability
;; cannot be achieved.'

to-report we-are-improving? [sad-turtles]
  set history lput (count sad-turtles) history

  if length history > n-history-stop and  mean history <= count sad-turtles [
    show (word "Failed to improve after " n-history-stop " trials")
    report false
  ]

  report true
end
@#$#@#$#@
GRAPHICS-WINDOW
370
10
809
470
16
16
13.0
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

SLIDER
4
10
176
43
density
density
0
100
73
1
1
NIL
HORIZONTAL

SLIDER
5
47
178
80
number-of-groups
number-of-groups
2
6
5
1
1
NIL
HORIZONTAL

BUTTON
10
195
73
228
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

BUTTON
78
195
137
230
Go Once
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

BUTTON
146
195
209
230
Go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

SLIDER
10
230
193
263
%-similar-wanted
%-similar-wanted
0
100
36
1
1
NIL
HORIZONTAL

PLOT
6
319
274
469
Happiness
NIL
NIL
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"Happy" 1.0 0 -13345367 true "" "plot (count turtles with [happy?])/(count turtles)"
"Sad" 1.0 0 -2674135 true "" "plot (count turtles with [not happy?])/(count turtles)"

MONITOR
290
325
347
370
Happy
count turtles with [happy?]
17
1
11

MONITOR
293
393
350
438
Sad
count turtles with [not happy?]
17
1
11

SLIDER
8
82
180
115
n-inject-1
n-inject-1
0
100
0
1
1
NIL
HORIZONTAL

SLIDER
8
121
180
154
n-inject-2
n-inject-2
0
100
0
1
1
NIL
HORIZONTAL

SLIDER
10
155
182
188
n-history-stop
n-history-stop
0
10000
10000
100
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

### Scope of Model

This is an extension of [Uri Wilensky's Segregation Model](http://ccl.northwestern.edu/netlogo/models/Segregation), which was based on [Thomas Schelling's Model of Segregation](http://isites.harvard.edu/fs/docs/icb.topic185351.files/shelling1.pdf). Schelling' model is very fertile: it gaives rise to further questions, including the ones that follow.

  * If we add more colours, does it become more difficult to achieve _happiness_? For example, if we have more colours:
    * does it take longer to achieve stability?
    * do we get a more fragmented neighbourhood, with more segregation?

  * What is the tradeoff between _population density_ and the time to achieve happiness?
  * What happens if we inject another colour into a configuration that has stabilized? Does a small injection of "foreigners" cause a small change, or is it disruptive?
  * Does it make any difference if the numbers of people of each colour are different?

### Background

Schelling stated: "My ultimate concern of course is segregation by color in the United States". My interest is different, as I lived Melbourne, Australia, for 25 years. Melbourne, unlike Sydney, was a free settlment from the outset. It presented a number of analogies to the dichotomy between white and black in the United States: English versus Irish, free settlers versus former convicts & their children, Protestant versus Catholics,  Anglo-Irish versus the minority of indigenous Kooris.

Some Chinese had settled in the 19<sup>th</sup> century, during the Victorian Goldrush, before the adoption of the [White Australia Policy](https://en.wikipedia.org/wiki/White_Australia_policy). As this policy was eroded and abolished during the 20th century, various groups of [New Australians](http://slwa.wa.gov.au/wepon/settlement/html/new_australians.html) were welcomed: [Greeks and Italians after the 2nd World War](https://en.wikipedia.org/wiki/Snowy_Mountains_Scheme), Vietnamese following the fall of Saigon, Lebanese, and, more recently, Somalis and other Africans. Each group tended to occupy its own areas at first. When I arrived in Melbourne in 1990, the suburb where I first lived, Flemington, was changing from largely Italian to Vietnamese. The Vietnamese are now generally accepted: their children & grandchildren speak with Aussie accents, and the Somalis and other Muslims are the newcomers.

I am fascinated by the patchwork of communities in Melbourne: the Orthodox Jewish neighbourhoods, which allow people to walk to the Synagogue without breaking the ban on working on the Sabbath; the [Jewish cakeshops of Acland Street](https://www.timeout.com/melbourne/restaurants/acland-street-cake-crawl) (to the South), and the popular [Italian restaurants of Lygon Street](http://www.goodfood.com.au/eat-out/melbournes-little-italy-a-guide-to-lygon-street-20140418-36x10), in the inner North; [Melbourne's Chinatown](http://www.thatsmelbourne.com.au/Placestogo/Precincts_Neighbourhoods/Chinatown/Pages/Chinatown.aspx) in the central City; the big Vietnamese communities to the East & West of the City; the grouping of Indian familes, which makes it practicable to have Indian Supermarkets, and for the children to study classical dance and music. This led me to wonder how well the model works for more than two groups, and what happens to later immigrants.

## HOW IT WORKS

###Agent Selection


  * There is only one type of active agent, a _turtle_ representing a person
  * _Patches_ are essentially passive; a patch is either occupied by one person, or it is vacant.


###Agent Properties

  * Turtles

    * _color_ - a built in property, which denotes the group (e.g. ethnicity) that this turtle belongs to.

    * _happy?_ - a turtle is happy if "enough" of its neighbours are of the same group. "Enough" means that the percentage of neighbours belonging to the same group is at least _%-similar-wanted_ (see list if inputs below).


  * Patches

    * Patches have an implicit property, as each patch is either a host to a turtle, or it isn't. This is managed by NetLogo, so the model only has to query the patch for the presence of turtles.


###Agent Actions

  * Ordinarily turtles who are not happy (not enough neighbours from their group) move to an unoccupied patch selected at random. I experimented with deterministc strategies (e.g. nearest unoccupied), but these tended to trap a turtle in a cycle of repeated failure, so I discarded them.
  * There can be up to two waves of immigration once all turtles are happy (this is selected by the user). If immigration is has been specified, patches sprout additional turtles. Each wave of immigrants is from a separate group, which cannot match a group that is already in place. I have established that immigrants tend to form ghettoes.

###Envionment

Just a 2D area, representing a city: since it is a square patch, maybe the city started as a [Roman castra](https://en.wikipedia.org/wiki/Castra)!

## HOW TO USE IT

### Inputs
  * _density_ of people living in the City
  * _number-of-groups_ of people living in the City
  * _n-inject-1_ Once the population stabilizes (i.e. everybody is happy), inject this many immigrants to the existing population.
    * The immigrants will form a separate group
    * The immigrants are not counted in the _density_
  * _n-inject-2_ This works similarly to _n-inject-1_. It injects a 2nd wave of immigrnats after the first has stabilized.
  * _n-history-stop_ This is used to terminate a run if happness is not improving.
    * If there has been no immigration, and the number of ticks exceeds _n-history-stop_, terminate the run if current happiness falls below the average of since the simulation started.
    * If there has been any immigration events, the "history" is reset. The models now looks at happiness since the latest immigration event.
  * _%-similar-wanted_ A turtle is happy if "enough" of its neighbours are the same colour. "Enough" means that the percentage of similar neighbours to total numbers is at least _%-similar-wanted_. E.g., if a turtle has the full number of neighbours, 8, _%-similar-wanted_ of 25 means that two or more nighbouts are similar.

### Outputs

  * Plot showing overall happiness, and sadness, as a fraction of all turtles. So if everybody is happy, happiness = 1.0 and sadness = 0.0.
  * Total number of happy turtles
  * Total number of sad turtles

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

  * [Uri Wilensky's Segregation Model](http://ccl.northwestern.edu/netlogo/models/Segregation)

## CREDITS AND REFERENCES

  * Latest version of [this model](https://github.com/weka511/models/blob/master/Immigration.nlogo)
  * [Uri Wilensky's Segregation Model](http://ccl.northwestern.edu/netlogo/models/Segregation)
  * [Models of Segregation Thomas Schelling](http://isites.harvard.edu/fs/docs/icb.topic185351.files/shelling1.pdf)
  * [Dynamic Models of Segregation Thomas Schelling] (http://wayback.archive.org/web/20140801170215/http://www.stat.berkeley.edu/~aldous/157/Papers/Schelling_Seg_Models.pdf)

## COPYRIGHT AND LICENSE

Copyright 2016 Simon Crase

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.
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
NetLogo 5.3.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="5" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [happy?]</metric>
    <metric>count turtles with [not happy?]</metric>
    <enumeratedValueSet variable="house-search-strategy">
      <value value="&quot;Random Jump&quot;"/>
      <value value="&quot;Nearest&quot;"/>
      <value value="&quot;Furthest&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-groups">
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
      <value value="5"/>
      <value value="6"/>
    </enumeratedValueSet>
    <steppedValueSet variable="density" first="30" step="5" last="95"/>
    <steppedValueSet variable="%-similar-wanted" first="13" step="13" last="78"/>
    <enumeratedValueSet variable="n-inject-2">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-inject-1">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
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
