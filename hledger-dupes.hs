#!/usr/bin/env stack
{- stack runghc --verbosity info
   --package hledger-lib-1.32.3
   --package hledger-1.32.3
   --package safe
   --package text
   --resolver lts-22.9
-}
{-

hledger-dupes [FILE]

Reports duplicates in the account tree: account names having the same leaf
but different prefixes. In other words, two or more leaves that are
categorized differently.
Reads the default journal file, or another specified as an argument.

http://stefanorodighiero.net/software/hledger-dupes.html
-}

import Hledger
import Hledger.Cli.Script
import Text.Printf (printf)
import System.Environment (getArgs)
import Safe (headDef)
import Data.List
import Data.Function
import qualified Data.Text as T


cmdmode = hledgerCommandMode (unlines
  ["hledger-dupes"
    ------------------------------------78----------------------------------------
  ,""
  ,"_FLAGS"
  ])
  [] [generalflagsgroup1] [] ([], Just $ argsFlag "[ARGS]")  -- or Nothing

accountsNames :: Journal -> [(String, AccountName)]
accountsNames j = map leafAndAccountName as
  where leafAndAccountName a = (T.unpack $ accountLeafName a, a)
        ps = journalPostings j
        as = nub $ sort $ map paccount ps


dupes :: (Ord k, Eq k) => [(k, v)] -> [(k, [v])]
dupes l = zip dupLeafs dupAccountNames
  where dupLeafs = map (fst . head) d
        dupAccountNames = map (map snd) d
        d = dupes' l
        dupes' = filter ((> 1) . length)
          . groupBy ((==) `on` fst)
          . sortBy (compare `on` fst)

render :: (String, [AccountName]) -> IO ()
render (leafName, accountNameL) = printf "%s as %s\n" leafName (concat $ intersperse ", " (map T.unpack accountNameL))

main = do
  args <- getArgs
  deffile <- defaultJournalPath
  opts <- getHledgerCliOpts cmdmode

  let file = headDef deffile args
  Right j <- runExceptT $ readJournalFile (inputopts_ opts) file
  mapM_ render $ dupes $ accountsNames j
