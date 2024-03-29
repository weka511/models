# Models
Netlogo models inspired by Scott Page's course [Model Thinking](https://www.coursera.org/course/modelthinking) and by Bill Rand's [Introduction to Agent-Based Modeling](https://www.complexityexplorer.org/courses/23-introduction-to-agent-based-modeling).

File|Description
----------------|------------------------------------------------------------------
El Farol.nlogo|El Farol bar problem
Immigration.nlogo|This is an extension of Uri Wilensky’s Segregation Model, which was based on Thomas Schelling’s Model of Segregation.
params.txt|Sample parameter file for schelling.py
schelling.py|[Agent Based model for Dynamic Models of Segregation, Thomas Schelling](https://search.iczhiku.com/paper/xfVfSs6TUWsnl2Kl.pdf),
implemented in mesa --  https://mesa.readthedocs.io/en/stable/tutorials/intro_tutorial.html
skins.nlogo|Model the rules that some Aboriginal groups have created to preserve animals.

## skins

Model the rules that some Aboriginal groups have created to preserve animals.

Several years agoo I was struck by a description of the rules for conserving totem animals, which show evidence of having been designed very carefully. This model is intended as a respectful exploration of the rules, to verify my belief that they ensure stability of the population.

There are two types of rules.

 * Who may eat which types of animal
 * Who may marry whom, and the *subsection* (also known as a *skin*) associated with the offspring.

### Who may eat which types of animal

Each person has a "subsection". They may not eat the animal associated with that subsection, and they must protect the breeding ground associated with that animal by any means at all.

### Who may marry whom, and the *subsection* associated with the offspring.

 * Everyone belongs to a *subsection*
 * The husband and wife must be from different subsection; a male can marry a female from one specified subsection, only, and vice versa.
 * The child belongs to a different subsection again, which is determined by the subsection of the father and of the mother.

Some examples of rules may be found at [the Wikipedia page on Aboriginal Kinship](http://en.wikipedia.org/wiki/Australian_Aboriginal_kinship). Here is an example from the Martuthunira language of the Western Pilbara.


|Section name (female)|Marries (male)|Children|
|---------------------|--------------|--------|
|Karimarra|Panaka|Pal.yarri|
|Panaka|Karimarra|Purungu|
|Pal.yarri|Purungu|Karimarra|
|Purungu|Pal.yarri|Panaka|

### Research Question

Is this system stable? If we start with a group of people from a "reasonable" mix of subsection, plus "enough" animals, will the rules give a fluctuating population in which no people or food anaimals go extinct?
