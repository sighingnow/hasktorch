-------------------------------------------------------------------------------
-- |
-- Module    :  Torch.Cuda
-- Copyright :  (c) Sam Stites 2017
-- License   :  BSD3
-- Maintainer:  sam@stites.io
-- Stability :  experimental
-- Portability: non-portable
--
-- Re-exports of all static CUDA-based tensors
-------------------------------------------------------------------------------
module Torch.Cuda (module X) where

import Torch.Dimensions as X
import Torch.Types.THC as X
import Torch.Cuda.Storage as X

import Torch.Cuda.Byte.Static as X
import Torch.Cuda.Char.Static as X

import Torch.Cuda.Short.Static as X
import Torch.Cuda.Int.Static   as X
import Torch.Cuda.Long.Static  as X

import Torch.Cuda.Double.Static       as X
import Torch.Cuda.Double.StaticRandom as X

