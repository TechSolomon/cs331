-- PA5.hs
-- Solomon Himelbloom
-- Glenn G. Chappell
-- 2022-03-16
--
-- For CS F331 / CSCE A331 Spring 2022
-- Solutions to Assignment 5 Exercise B

module PA5 where


-- =====================================================================


-- collatzCounts
collatzCounts :: [Integer]
collatzCounts = map collatzCount [1..] where
    collatzCount n = collatzCount' n 0 where
        collatzCount' 1 c = c
        collatzCount' n c = collatzCount' (collatz n) (c+1)
    collatz n
        | even n = n `div` 2
        | otherwise = 3*n + 1


-- =====================================================================


-- findList
findList :: Eq a => [a] -> [a] -> Maybe Int
findList first second
    | null first = Just 0
    | fst (location first second 0) = Just (snd (location first second 0))
    | otherwise = Nothing
    where
        location first second iteration
            | first == take (length first) second = (True, iteration)
            | null second = (False, iteration)
            | otherwise = location first (drop 1 second) (iteration+1)


-- =====================================================================


-- operator ##
(##) :: Eq a => [a] -> [a] -> Int
first ## second = length matches where
    matches = filter (\i -> first !! i == second !! i) [0..(length first - 1)]


-- =====================================================================


-- filterAB
filterAB :: (a -> Bool) -> [a] -> [b] -> [b]
filterAB _ _ [] = []
filterAB _ [] _ = []
filterAB f (x:xs) (y:ys)
    | f x = y : filterAB f xs ys
    | otherwise = filterAB f xs ys


-- =====================================================================


-- sumEvenOdd
sumEvenOdd :: Num a => [a] -> (a, a)
{-
  The assignment requires sumEvenOdd to be written as a fold.
  Like this:

    sumEvenOdd xs = fold* ... xs  where
        ...

  Above, "..." should be replaced by other code. "fold*" must be one of
  the following: foldl, foldr, foldl1, foldr1.
-}
sumEvenOdd xs = 
    (foldl (+) 0 (even xs), 
    foldl (+) 0 (odd xs)) where
        odd [] = [] 
        odd (_:xs) = even xs
        even [] = []
        even (x:xs) = x:odd xs
