#!/usr/bin/env python

# Copyright (c) 2023 Simon Crase

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.


'''
Agent Based model for Dynamic Models of Segregation, Thomas Schelling, https://search.iczhiku.com/paper/xfVfSs6TUWsnl2Kl.pdf,
implemented in mesa --  https://mesa.readthedocs.io/en/stable/tutorials/intro_tutorial.html
'''

from abc               import abstractmethod
from argparse          import ArgumentParser
from matplotlib.pyplot import figure, show
from mesa              import Agent, DataCollector, Model
from mesa.batchrunner  import batch_run
from mesa.space        import SingleGrid
from mesa.time         import RandomActivation
from numpy             import array, count_nonzero, int8, sum, zeros
from os.path           import join
from random            import shuffle



class Person(Agent):
    '''
    Represents a person who occupies a location in the Model
    '''
    def __init__(self, unique_id, model):
        super().__init__(unique_id, model)

    @abstractmethod
    def step(self):
        ...

    @abstractmethod
    def get_indicator(self):
        '''
        Indicates which group person belongs to
        '''
        ...

    def step(self):
        '''
        Each step, move peron if not happy here
        '''
        if not self.is_happy():
            self.model.move(self)

    def is_happy(self):
        '''
        Calculate happiness: a person is happy if the number of neighbors who are like them exceeds a threshold.
        '''
        n_like_me, n_different = self.count_neighbours()
        return self.model.is_happy(n_like_me,n_different)

    def count_neighbours(self):
        '''
        Take census of neighbours: how many are like me?
        '''
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

    '''
    Agent Based model for  Dynamic Models of Segregation, Thomas Schelling, https://search.iczhiku.com/paper/xfVfSs6TUWsnl2Kl.pdf
    '''
    def __init__(self,
                 width     = 100,
                 height    = 100,
                 xRed      = 0.45,
                 xBlue     = 0.45,
                 threshold = 0.25,
                 moore     = True,
                 torus     = True,
                 granularity = [10,10]):
        self.schedule  = RandomActivation(self)
        self.grid      = SingleGrid(width, height, torus = torus)
        self.threshold = threshold
        self.moore     = moore
        self.nRed      = int(xRed*width*height)
        self.nBlue     = int(xBlue*width*height)
        for i in range(self.nRed):
            self.place(Red(i, self))
        for i in range(self.nBlue):
            self.place(Blue(i+self.nRed, self))
        self.running = True
        dissimilarity_calculator = DissimilarityCalculator(granularity[0],granularity[1])

        self.datacollector      = DataCollector(
            model_reporters={
                f'Dissimilarity' : lambda model: dissimilarity_calculator.get_dissimilarity(model),
                'Happiness' : lambda model: model.get_happiness()
            })

    def __str__(self):
        '''
        Used to generate title for plots
        '''
        return f'{self.nRed} Red + {self.nBlue} Blue, '                                                           \
               f'density={(self.nRed + self.nBlue)/(self.grid.width*self.grid.height):.3f}, '                     \
               f'threshold={self.threshold:.3f}, using {"Moore" if self.moore else "von Neumann"} neighbourhoods' \
               f'{" on torus" if self.grid.torus else ""}'

    def place(self,person):
        '''
        Place a person in a randomly selected empty location on the grid
        '''
        x = self.random.randrange(self.grid.width)
        y = self.random.randrange(self.grid.height)
        while not self.grid.is_cell_empty((x,y)):   # This appears faster than find_empty
            x = self.random.randrange(self.grid.width)
            y = self.random.randrange(self.grid.height)
        self.grid.place_agent(person, (x, y))
        self.schedule.add(person)

    def step(self):
        '''
        Take one step of model, and update happiness scores
        '''
        self.datacollector.collect(self)
        self.schedule.step()

    def get_counts(self):
        agent_counts = zeros((self.grid.width, self.grid.height),dtype=int8)
        for cell in self.grid.coord_iter():
            cell_content, x, y = cell
            if cell_content != None:
                agent_counts[x][y] = cell_content.get_indicator()
        return agent_counts

    def move(self,person):
        '''
        Move a person to an empty location
        '''
        self.grid.move_agent(person, self.grid.find_empty())



    def is_happy(self,n_like_me,n_different):
        '''
        Calculate happiness: a person is happy if the number of neighbors who are like them exceeds a threshold.
        '''
        return n_like_me >= self.threshold * (n_like_me+n_different)

    def count_neighbours(self,person,pos):
        '''
        Take census of neighbours to determine how many are like me
        '''
        n_like_me   = 0
        n_different = 0
        for neighbour in self.grid.iter_neighbors(pos, self.moore):
            if neighbour.get_indicator()==person.get_indicator():
                n_like_me += 1
            else:
                n_different += 1

        return n_like_me, n_different

    def get_happiness(self):
        '''
        Calculate average happiness of all people
        '''

        return sum([1 for person,_,_ in self.grid.coord_iter() if person != None and person.is_happy()]) / self.get_area()

    def get_area(self):
        return self.grid.width*self.grid.height



class DissimilarityCalculator(object):
    def __init__(self,m,n):
        self.m      = m
        self.n      = n

    def get_dissimilarity(self,model):
        Counts      = model.get_counts()
        Red_counts  = self.get_count(Counts,1)
        Blue_counts = self.get_count(Counts,2)
        return 0.5 * sum(abs(Red_counts/model.nRed - Blue_counts/model.nBlue))

    def get_count(self,counts,indicator):
        cell_counts = counts * (counts==indicator)/indicator
        m,n         = cell_counts.shape
        return cell_counts.reshape(m//self.m,self.m,n//self.n,self.n).sum(axis=(1, 3))

    def __str__(self):
        return f'({self.m}$\\times${self.n})'

if __name__ == '__main__':
    Palette = array([[255, 255, 255],
                     [255,   0,   0],
                     [  0,   0, 255]])

    parser = ArgumentParser(__doc__)
    parser.add_argument('--size',          type=int,   nargs=2,                default = [100,100])
    parser.add_argument('--granularity',   type = int, nargs=2,                default = [10,10])
    parser.add_argument('--proportions',   type=float, nargs=2,                default = [0.49, 0.49])
    parser.add_argument('--threshold',     type=float,                         default = 1.0/3.0)
    parser.add_argument('--neighbourhood', type=str, choices=['moore', 'von'], default = 'moore')
    parser.add_argument('--N',             type=int,                           default = 25)
    parser.add_argument('--figs',                                              default = './figs')
    parser.add_argument('--name',                                              default = 'schelling')
    parser.add_argument('--show',          action = 'store_true',              default = False)
    parser.add_argument('--torus',         action = 'store_true',              default = False)
    parser.add_argument('--batch',         action = 'store_true',              default = False)
    args = parser.parse_args()

    if args.batch:
        params = {"width": 10, "height": 10, "threshold": [0.25, 0.33]}
        results = batch_run(SchellingModel,
                        parameters             = params,
                        iterations             = 5,
                        max_steps              = 100,
                        number_processes       = 1,
                        data_collection_period = 1,
                        display_progress       = True,
                        )
    else:
        model = SchellingModel(
                    width       = args.size[0],
                    height      = args.size[1],
                    xRed        = args.proportions[0],
                    xBlue       = args.proportions[1],
                    threshold   = args.threshold,
                    moore       = args.neighbourhood=='moore',
                    torus       = args.torus,
                    granularity = args.granularity
        )

        for _ in range(args.N):
            model.step()

        fig = figure(figsize=(10,10))
        fig.suptitle(f'{model}')

        ax1 = fig.add_subplot(2,1,1)
        ax1.imshow(Palette[model.get_counts()], interpolation="nearest")

        ax2 = fig.add_subplot(2,1,2)
        model.datacollector.get_model_vars_dataframe().plot(ax=ax2)

        fig.savefig(join(args.figs,args.name))
        if args.show:
            show()
