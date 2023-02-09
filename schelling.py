# https://mesa.readthedocs.io/en/stable/tutorials/intro_tutorial.html

from mesa      import Agent, Model
from mesa.time import RandomActivation

class Person(Agent):
    def __init__(self, unique_id, model):
        super().__init__(unique_id, model)(self)
    def step(self):
        pass

class SchellingModel(Model):

    def __init__(self, N):
        self.schedule = RandomActivation(self)
        for i in range(N):
            self.schedule.add(Person(i, self))

    def step(self):
        self.schedule.step()

if __name__ == '__main__':
    schelling_model = SchellingModel(10)
    model.step()
