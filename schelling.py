#!/usr/bin/env python

# https://mesa.readthedocs.io/en/stable/tutorials/intro_tutorial.html

'''
Schelling Segregation model in mesa
'''

from abc               import abstractmethod
from matplotlib.pyplot import colorbar, figure, imshow, show
from mesa              import Agent, Model
from mesa.space        import MultiGrid
from mesa.time         import RandomActivation
from numpy             import zeros

class Person(Agent):

    def __init__(self, unique_id, model):
        super().__init__(unique_id, model)

    @abstractmethod
    def step(self):
        ...

    @abstractmethod
    def get_indicator(self):
        ...

    def step(self):
        n_like_me, n_different = self.count_neighbours()
        if n_like_me==0 or n_like_me/(n_like_me+n_different)<self.model.limit:
            self.model.move(self)

    def count_neighbours(self):
        return self.model.count_neighbours(self,self.pos)

    def __str__(self):
        return f'{self.unique_id} {self.get_indicator()} {self.pos}'

class Red(Person):
    def __init__(self, unique_id, model):
        super().__init__(unique_id, model)

    def get_indicator(self):
        return 1

class Blue(Person):
    def __init__(self, unique_id, model):
        super().__init__(unique_id, model)

    def get_indicator(self):
        return 2

class SchellingModel(Model):

    def __init__(self,
                 width  = 10,
                 height = 10,
                 nRed   = 75,
                 nBlue  = 10,
                 limit  = 0.25):
        self.schedule = RandomActivation(self)
        self.grid     = MultiGrid(width, height, True)
        self.limit    = limit
        for i in range(nRed):
            self.place(Red(i, self))
        for i in range(nBlue):
            self.place(Blue(i+nRed, self))
        self.empty = [(x,y) for x in range(width) for y in range(height) if len(self.grid.get_cell_list_contents((x,y)))==0]

    def place(self,person):
        x = self.random.randrange(self.grid.width)
        y = self.random.randrange(self.grid.height)
        while len(self.grid.get_cell_list_contents((x,y)))>0:
            x = self.random.randrange(self.grid.width)
            y = self.random.randrange(self.grid.height)
        self.grid.place_agent(person, (x, y))
        self.schedule.add(person)

    def step(self):
        self.schedule.step()

    def get_counts(self):
        agent_counts = zeros((self.grid.width, self.grid.height))
        for cell in self.grid.coord_iter():
            cell_content, x, y = cell
            for person in cell_content:
                agent_counts[x][y] = person.get_indicator()
        return agent_counts

    def move(self,person):
        pos = self.find_candidate(person)
        print (f'Move {person} to {pos}')
        if pos!=None:
            self.empty.remove(pos)
            self.empty.append(person.pos)
            self.grid.move_agent(person, pos)

    def find_candidate(self,person):
        for pos in self.empty:
            n_like_me, n_different = self.count_neighbours(person,pos)
            if n_like_me>self.limit *(n_like_me+n_different):
                return pos

    def count_neighbours(self,person,pos):
        n_like_me   = 0
        n_different = 0
        for neighbour in self.grid.iter_neighbors(pos, False):
            if neighbour.get_indicator()==person.get_indicator():
                n_like_me += 1
            else:
                n_different += 1

        return n_like_me, n_different

if __name__ == '__main__':
    model = SchellingModel()

    figure()
    imshow(model.get_counts(), interpolation="nearest")
    colorbar()

    for i in range(25):
        model.step()
    figure()
    imshow(model.get_counts(), interpolation="nearest")
    colorbar()

    show()
