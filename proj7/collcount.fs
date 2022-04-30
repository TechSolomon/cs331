\ collcount.fs
\ Solomon Himelbloom
\ 2022-04-21
\
\ For CS F331 / CSCE A331 Spring 2022
\ Programming in Forth

\ collatz
\ A. if n is even, divide by 2
\ B. if n is odd, multiply by 3 and add 1
: collatz ( n -- c )
    dup dup 1 = if 0 
    else 2 mod 0 = if
        2 /
    else
        3 * 1 +
    then
    dup recurse 1 +
    then
;

\ collcount
\ n is a positive integer
\ c is the number of iterations of the Collatz function
: collcount ( n -- c )
    collatz
;
