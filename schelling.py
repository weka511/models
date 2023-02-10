#!/usr/bin/env python

# https://mesa.readthedocs.io/en/stable/tutorials/intro_tutorial.html

'''
Schelling Segregation model in mesa
'''

from abc               import abstractmethod
from matplotlib.pyplot import colorbar, imshow, show
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

class Red(Person):
    def __init__(self, unique_id, model):
        super().__init__(unique_id, model)

    def step(self):
        print (f'{self.unique_id} Red')

    def get_indicator(self):
        return 1

class Blue(Person):
    def __init__(self, unique_id, model):
        super().__init__(unique_id, model)

    def step(self):
        print (f'{self.unique_id} Blue')

    def get_indicator(self):
        return 2

class SchellingModel(Model):

    def __init__(self, width=10, height=10,nRed=75,nBlue=10):
        self.schedule = RandomActivation(self)
        self.grid     = MultiGrid(width, height, True)
        for i in range(nRed):
            self.place(Red(i, self))
        for i in range(nBlue):
            self.place(Blue(i+nRed, self))

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

if __name__ == '__main__':
    model = SchellingModel()
    model.step()

    imshow(model.get_counts(), interpolation="nearest")
    colorbar()
    show()
