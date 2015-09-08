#include <stdio.h>
#include "rng.h"

#define DUMMY 11

int main()
{
    RngData rd;
    float rn;
    int i;

    rngDataInit (&rd);
    zigset(&rd, DUMMY);
    rd.seed = 1;

    while (i < 10) {
        rn = _randomNormal ((&rd));
        printf ("%f\n", rn);
        i++;
    }
    return i;
}

//  g++ -o testnormal testnormal.cpp -lm
