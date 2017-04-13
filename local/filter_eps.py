# -*- coding: utf-8 -*-


import sys

if __name__ == '__main__':
    for line in sys.stdin:
        if "<eps>" in line :
            donothing = 1
        else :
            print(line)
## end if __name__ == '__main__'