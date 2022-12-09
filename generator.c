#include <stdio.h>
#include <stdlib.h>

int main(void) {

    int chr;

    for (int i = 0, i < 4800, i++){
        chr = rand() % 0x7F;

        if (chr == 0x09 || chr == 0x0A || (chr <= 0x7E && chr >= 0x20)){
            putchar(chr);
        }
    }

    return 0;

}