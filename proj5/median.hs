-- median.hs
-- Solomon Himelbloom
-- 2022-03-20
-- Exercise C: A Complete Haskell Program
-- Median in Haskell

module Main where

import Data.List
import System.IO ()


main = do
    putStrLn ""
    putStrLn "Enter a list of integers, one on each line."
    putStrLn "I will compute the median of the list."
    putStrLn "Enter numbers (blank line to end): "
    putStrLn ""

    output <- start

    if null output then
        putStrLn "Empty list -- no median."
    else
        do
            let sorted = sort output
            let median = calculation sorted
            putStrLn ("Median: " ++ show median)

            continue


calculation list = list !! (length list `div` 2)

start = do
    input <- getLine
    if input == "" then
        return []
    else
        do
            let location = read input :: Int
            remaining <- start
            return (location : remaining)


continue = do
    putStrLn "Compute another median? [y/n]\n"
    decision <- getChar 
    if decision == 'y' then do
        main
    else if decision == 'n' then do
        putStrLn "Bye!"
        return ()
    else
        main
    