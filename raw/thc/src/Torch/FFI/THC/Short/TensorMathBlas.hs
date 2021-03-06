{-# LANGUAGE ForeignFunctionInterface #-}
module Torch.FFI.THC.Short.TensorMathBlas where

import Foreign
import Foreign.C.Types
import Torch.Types.THC
import Data.Word
import Data.Int

-- | c_dot :  state self src -> accreal
foreign import ccall "THCTensorMathBlas.h THCShortTensor_dot"
  c_dot :: Ptr C'THCState -> Ptr C'THCudaShortTensor -> Ptr C'THCudaShortTensor -> IO CLong

-- | c_addmv :  state self beta t alpha mat vec -> void
foreign import ccall "THCTensorMathBlas.h THCShortTensor_addmv"
  c_addmv :: Ptr C'THCState -> Ptr C'THCudaShortTensor -> CShort -> Ptr C'THCudaShortTensor -> CShort -> Ptr C'THCudaShortTensor -> Ptr C'THCudaShortTensor -> IO ()

-- | c_addmm :  state self beta t alpha mat1 mat2 -> void
foreign import ccall "THCTensorMathBlas.h THCShortTensor_addmm"
  c_addmm :: Ptr C'THCState -> Ptr C'THCudaShortTensor -> CShort -> Ptr C'THCudaShortTensor -> CShort -> Ptr C'THCudaShortTensor -> Ptr C'THCudaShortTensor -> IO ()

-- | c_addr :  state self beta t alpha vec1 vec2 -> void
foreign import ccall "THCTensorMathBlas.h THCShortTensor_addr"
  c_addr :: Ptr C'THCState -> Ptr C'THCudaShortTensor -> CShort -> Ptr C'THCudaShortTensor -> CShort -> Ptr C'THCudaShortTensor -> Ptr C'THCudaShortTensor -> IO ()

-- | c_addbmm :  state result beta t alpha batch1 batch2 -> void
foreign import ccall "THCTensorMathBlas.h THCShortTensor_addbmm"
  c_addbmm :: Ptr C'THCState -> Ptr C'THCudaShortTensor -> CShort -> Ptr C'THCudaShortTensor -> CShort -> Ptr C'THCudaShortTensor -> Ptr C'THCudaShortTensor -> IO ()

-- | c_baddbmm :  state result beta t alpha batch1 batch2 -> void
foreign import ccall "THCTensorMathBlas.h THCShortTensor_baddbmm"
  c_baddbmm :: Ptr C'THCState -> Ptr C'THCudaShortTensor -> CShort -> Ptr C'THCudaShortTensor -> CShort -> Ptr C'THCudaShortTensor -> Ptr C'THCudaShortTensor -> IO ()

-- | p_dot : Pointer to function : state self src -> accreal
foreign import ccall "THCTensorMathBlas.h &THCShortTensor_dot"
  p_dot :: FunPtr (Ptr C'THCState -> Ptr C'THCudaShortTensor -> Ptr C'THCudaShortTensor -> IO CLong)

-- | p_addmv : Pointer to function : state self beta t alpha mat vec -> void
foreign import ccall "THCTensorMathBlas.h &THCShortTensor_addmv"
  p_addmv :: FunPtr (Ptr C'THCState -> Ptr C'THCudaShortTensor -> CShort -> Ptr C'THCudaShortTensor -> CShort -> Ptr C'THCudaShortTensor -> Ptr C'THCudaShortTensor -> IO ())

-- | p_addmm : Pointer to function : state self beta t alpha mat1 mat2 -> void
foreign import ccall "THCTensorMathBlas.h &THCShortTensor_addmm"
  p_addmm :: FunPtr (Ptr C'THCState -> Ptr C'THCudaShortTensor -> CShort -> Ptr C'THCudaShortTensor -> CShort -> Ptr C'THCudaShortTensor -> Ptr C'THCudaShortTensor -> IO ())

-- | p_addr : Pointer to function : state self beta t alpha vec1 vec2 -> void
foreign import ccall "THCTensorMathBlas.h &THCShortTensor_addr"
  p_addr :: FunPtr (Ptr C'THCState -> Ptr C'THCudaShortTensor -> CShort -> Ptr C'THCudaShortTensor -> CShort -> Ptr C'THCudaShortTensor -> Ptr C'THCudaShortTensor -> IO ())

-- | p_addbmm : Pointer to function : state result beta t alpha batch1 batch2 -> void
foreign import ccall "THCTensorMathBlas.h &THCShortTensor_addbmm"
  p_addbmm :: FunPtr (Ptr C'THCState -> Ptr C'THCudaShortTensor -> CShort -> Ptr C'THCudaShortTensor -> CShort -> Ptr C'THCudaShortTensor -> Ptr C'THCudaShortTensor -> IO ())

-- | p_baddbmm : Pointer to function : state result beta t alpha batch1 batch2 -> void
foreign import ccall "THCTensorMathBlas.h &THCShortTensor_baddbmm"
  p_baddbmm :: FunPtr (Ptr C'THCState -> Ptr C'THCudaShortTensor -> CShort -> Ptr C'THCudaShortTensor -> CShort -> Ptr C'THCudaShortTensor -> Ptr C'THCudaShortTensor -> IO ())