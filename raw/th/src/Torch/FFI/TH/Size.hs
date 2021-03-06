{-# LANGUAGE ForeignFunctionInterface #-}
module Torch.FFI.TH.Size where

import Foreign
import Foreign.C.Types
import Data.Word
import Data.Int
import Torch.Types.TH

-- | c_THSize_isSameSizeAs :  sizeA dimsA sizeB dimsB -> int
foreign import ccall "THSize.h THSize_isSameSizeAs"
  c_THSize_isSameSizeAs :: Ptr CLLong -> CLLong -> Ptr CLLong -> CLLong -> IO CInt

-- | c_THSize_nElement :  dims size -> ptrdiff_t
foreign import ccall "THSize.h THSize_nElement"
  c_THSize_nElement :: CLLong -> Ptr CLLong -> IO CPtrdiff

-- | p_THSize_isSameSizeAs : Pointer to function : sizeA dimsA sizeB dimsB -> int
foreign import ccall "THSize.h &THSize_isSameSizeAs"
  p_THSize_isSameSizeAs :: FunPtr (Ptr CLLong -> CLLong -> Ptr CLLong -> CLLong -> IO CInt)

-- | p_THSize_nElement : Pointer to function : dims size -> ptrdiff_t
foreign import ccall "THSize.h &THSize_nElement"
  p_THSize_nElement :: FunPtr (CLLong -> Ptr CLLong -> IO CPtrdiff)