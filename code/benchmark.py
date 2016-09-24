import re
from datetime import datetime as dt
from random import randint
from string import ascii_lowercase
import subprocess

import matplotlib.pyplot as plt

INPUT_FNAME = 'input.txt'
N = 3 # How many times we run the program (to take the mean)
n_letters = range(1, 1000, 50)
n_words = range(1, 10000, 500)

def random_letters(n):
    """Return a random string of n letters from a-z."""
    return ''.join(ascii_lowercase[randint(0, 25)] for _ in range(n))

def create_dict(n_words, n_letters):
    return '\n'.join(random_letters(n_letters) for _ in range(n_words))

def strtime_to_sec(strtime):
    """Parse an input like '0m1.520' and return a number of seconds"""
    search = re.search('([0-9]+)m([0-9\.]+)s', strtime)
    m = float(search.group(1))
    s = float(search.group(2))

    return m * 60 + s

def measure_time(input_string):
    with open(INPUT_FNAME, 'w') as f:
        f.write(input_string)

        p = subprocess.Popen(
            ['./measure_time.sh', INPUT_FNAME],
            stdout=subprocess.PIPE,
            stdin=subprocess.PIPE,
            stderr=subprocess.STDOUT,
        )
        output = p.communicate()[0].decode()

        times = output.strip().replace('\t', '\n').split('\n')[1::2]
        times = [strtime_to_sec(time) for time in times]

        return times

def letters():
    means = [0] * len(n_letters)
    times = [0] * N

    # One word, multiple numbers of letters
    for i in range(len(n_letters)):
        n_letter = n_letters[i]
        print('Processing {} letters'.format(n_letter))

        for j in range(N):
            times[j], _, _ = measure_time(create_dict(1, n_letter))

        means[i] = sum(times)/float(N)

    m = min(means)
    means = [mean - m for mean in means]
    
    plt.plot(n_letters, means, 'o')
    plt.xlabel('Nombre de lettres')
    plt.ylabel('Temps (s)')
    plt.savefig('./benchmark-letters.png')
    plt.clf()

def words(): 
    means = [0] * len(n_words)
    times = [0] * N

    for i in range(len(n_words)):
        n_word = n_words[i]
        n_letter = 10
        print('Processing {} words with {} letters'.format(n_word, n_letter))

        for j in range(N):
            times[j], _, _ = measure_time(create_dict(n_word, n_letter))

        means[i] = sum(times)/float(N)

    # Plot
    plt.plot(n_words, means, 'o')
    plt.xlabel('Nombre de mots')
    plt.ylabel('Temps (s)')
    plt.savefig('./benchmark-words.png')
    plt.clf()

def main():
    #words()
    letters()


if __name__ == '__main__':
    main()
