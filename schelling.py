#!/usr/bin/env python


'''
Agent Based model for Dynamic Models of Segregation, Thomas Schelling, https://search.iczhiku.com/paper/xfVfSs6TUWsnl2Kl.pdf,
implemented in mesa --  https://mesa.readthedocs.io/en/stable/tutorials/intro_tutorial.html
'''

from abc               import abstractmethod
from argparse          import ArgumentParser
from matplotlib.pyplot import figure, show
from mesa              import Agent, Model
from mesa.space        import MultiGrid
from mesa.time         import RandomActivation
from numpy             import array, count_nonzero, int8, zeros
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
        # return n_like_me >= self.model.threshold * (n_like_me+n_different)

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
                 nRed      = 7400,
                 nBlue     = 2400,
                 threshold = 0.25,
                 moore     = True):
        self.schedule  = RandomActivation(self)
        self.grid      = MultiGrid(width, height, True)
        self.threshold = threshold
        self.moore     = moore
        self.nRed      = nRed
        self.nBlue     = nBlue
        for i in range(nRed):
            self.place(Red(i, self))
        for i in range(nBlue):
            self.place(Blue(i+nRed, self))
        self.empty     = [(x,y) for x in range(width) for y in range(height) if len(self.grid.get_cell_list_contents((x,y)))==0]

    def __str__(self):
        '''
        Used to generate title for plots
        '''
        return f'{self.nRed} Red + {self.nBlue} Blue, '                                                          \
               f'density={(self.nRed + self.nBlue)/(self.grid.width*self.grid.height):.3f}, '                    \
               f'threshold={self.threshold:.3f}, using {"Moore" if self.moore else "von Neumann"} neighbourhoods'

    def place(self,person):
        '''
        Place a person in a randomly selected empty location on the grid
        '''
        x = self.random.randrange(self.grid.width)
        y = self.random.randrange(self.grid.height)
        while len(self.grid.get_cell_list_contents((x,y)))>0:
            x = self.random.randrange(self.grid.width)
            y = self.random.randrange(self.grid.height)
        self.grid.place_agent(person, (x, y))
        self.schedule.add(person)

    def step(self):
        '''
        Take one step of model, and update happiness scores
        '''
        self.schedule.step()

    def get_counts(self):
        agent_counts = zeros((self.grid.width, self.grid.height),dtype=int8)
        for cell in self.grid.coord_iter():
            cell_content, x, y = cell
            for person in cell_content:
                agent_counts[x][y] = person.get_indicator()
        return agent_counts

    def move(self,person):
        '''
        Move a person to an empty location
        '''
        pos = self.find_empty_location(person)
        if pos!=None:
            n = len(self.empty)
            self.empty.remove(pos)
            self.empty.append(person.pos)
            assert n== len(self.empty)
            self.grid.move_agent(person, pos)

    def find_empty_location(self,person):
        '''
        Search empty locations looking for somewhere to move to
        '''
        shuffle(self.empty)
        for pos in self.empty:
            n_like_me, n_different = self.count_neighbours(person,pos)
            if self.is_happy(n_like_me,n_different):
                return pos

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
        Calculate total happiness of all people
        '''
        def get_cell_content(cell):
            cell_content, _,_ = cell
            return cell_content

        return sum([1 for cell in self.grid.coord_iter() for person in get_cell_content(cell) if person.is_happy()]) / \
               (self.grid.width*self.grid.height)

class DissimilarityCalculator(object):
    def __init__(self,m,n):
        self.m      = m
        self.n      = n

    def get_dissimilarity(self,model):
        counts = model.get_counts()
        red_counts = self.get_count(counts,1)
        blue_counts = self.get_count(counts,2)
        return 0.5 *                                                                                        \
               sum([abs(red_counts[i,j]/model.nRed - blue_counts[i,j]/model.nBlue)   \
                   for i in range(self.m)                                                                   \
                   for j in range(self.n)])

    def get_count(self,counts,indicator):
        cell_counts = counts * (counts==indicator)/indicator
        m,n         = cell_counts.shape
        aggregated  = cell_counts.reshape(m//self.m,self.m,n//self.n,self.n).sum(axis=(1, 3))

        return aggregated

if __name__ == '__main__':
    Palette = array([[255, 255, 255],
                     [255,   0,   0],
                     [  0,   0, 255]])

    parser = ArgumentParser(__doc__)
    parser.add_argument('--width',         type=int,                           default = 100)
    parser.add_argument('--height',        type=int,                           default = 100)
    parser.add_argument('--proportions',   type=float, nargs=2,                default = [0.7, 0.2])
    parser.add_argument('--threshold',     type=float,                         default = 1.0/3.0)
    parser.add_argument('--neighbourhood', type=str, choices=['moore', 'von'], default = 'moore')
    parser.add_argument('--N',             type=int,                           default = 25)
    parser.add_argument('--figs',                                              default = './figs')
    parser.add_argument('--name',                                              default = 'schelling')
    parser.add_argument('--show',          action = 'store_true',              default = False)
    args = parser.parse_args()

    model = SchellingModel(
                width     = args.width,
                height    = args.height,
                nRed      = int(args.width*args.height*args.proportions[0]),
                nBlue     = int(args.width*args.height*args.proportions[1]),
                threshold = args.threshold,
                moore     = args.neighbourhood=='moore')
    happiness                = [model.get_happiness()]
    dissimilarity_calculator = DissimilarityCalculator(10,10)
    dissimilarity            = [dissimilarity_calculator.get_dissimilarity(model)]
    for _ in range(args.N):
        model.step()
        happiness.append(model.get_happiness())
        dissimilarity.append(dissimilarity_calculator.get_dissimilarity(model))
        if happiness[-1]<=happiness[-2]:break

    fig = figure(figsize=(10,10))
    fig.suptitle(f'{model}')

    ax1 = fig.add_subplot(2,1,1)
    ax1.imshow(Palette[model.get_counts()], interpolation="nearest")

    ax2 = fig.add_subplot(2,1,2)
    ax2.plot(happiness, label = 'Happiness')
    ax2.plot(dissimilarity, label = 'Dissimilarity')
    ax2.legend()

    fig.savefig(join(args.figs,args.name))
    if args.show:
        show()
