{-# LANGUAGE TupleSections #-}
module CodeGen.ParseSpec where

import Test.Hspec
import Text.Megaparsec hiding (runParser', State)
import CodeGen.Parse hiding (describe)
import CodeGen.Types hiding (describe)
import CodeGen.Prelude
import Data.List
import Data.Either
import Data.Maybe
import qualified Data.Text as T


main :: IO ()
main = hspec spec

spec :: Spec
spec = do
  -- describe "the skip parser" skipSpec
  -- describe "the ptr parser" ptrSpec
  -- describe "the ptr2 parser" ptr2Spec
  -- describe "the ctypes parser" ctypesSpec
  describe "the functionArg parser" functionArgSpec
  describe "the functionArgs parser" functionArgsSpec
  describe "the function parser" functionSpec
  -- describe "running the full parser" $ do
  --   describe "in concrete mode" fullConcreteParser
    -- describe "in generic mode" fullGenericParser

runParser' p = runParser p "test"

testCGParser = runParser parser "test"


succeeds :: (Show x, Eq x) => Parser x -> (String, x) -> IO ()
succeeds parser (str, res) = runParser' parser str `shouldBe` Right res


fails :: (Show x, Eq x) => Parser x -> String -> IO ()
fails parser str = runParser' parser str `shouldSatisfy` isLeft


fullConcreteParser :: Spec
fullConcreteParser = do
  it "should error if the header is first(??)" $
    testCGParser "TH_API \n" `shouldBe` Right [Nothing]

  it "should return Nothing if the API header" $
    testCGParser "foob TH_API \n" `shouldBe` Right [Nothing]

  it "should return a valid THFile function" $
    testCGParser thFileFunction `shouldBe` Right [Just thFileFunctionRendered]

  it "should return Nothing for declarations" $
    testCGParser "TH_API const double THLog2Pi;" `shouldBe` Right [Nothing]

  it "should return valid THLogAdd functions" $
    testCGParser thLogAddFunction `shouldBe` Right [Just thLogAddFunctionRendered]

  it "should return all functions in THFile" $
    thFileContents `fullFileTest` (155, 70, 70)


fullGenericParser :: Spec
fullGenericParser = do
  it "should return valid types for the example string" $
    testCGParser exampleGeneric `shouldBe` Right [Just exampleGeneric']

  it "should return valid types for the example string with junk" $
    testCGParser (withAllJunk exampleGeneric) `shouldBe` Right [Nothing, Just exampleGeneric', Nothing, Nothing]

  it "should return all functions for THStorage" $
    thGenericStorageContents `fullFileTest` (86, 22, 22)

  it "should return all functions for THCTensorTopK" $
    thcGenericTensorTopKContents `fullFileTest` (10, 1, 1)

  it "should return valid types for THNN" $
    pendingWith "we don't currently support THNN"


fullFileTest :: String -> (Int, Int, Int) -> Expectation
fullFileTest contents (all, found, uniq) = do
  let res = testCGParser contents
  res `shouldSatisfy` isRight
  let Right contents = res
  length contents `shouldSatisfy` (== all)
  length (catMaybes contents) `shouldSatisfy` (== found)
  length (nub $ catMaybes contents) `shouldSatisfy` (== uniq)


skipSpec :: Spec
skipSpec = do
  it "finds the number of lines as \\n characters" $
    runSomeSkipOn "\n\n" `shouldSatisfy` foundNlines 2
  it "finds the number of lines in exampleGeneric" $
    runSomeSkipOn exampleGeneric `shouldSatisfy` foundNlines 1
  it "finds the number of lines in exampleGeneric withEndJunk" $
    runSomeSkipOn (withEndJunk exampleGeneric) `shouldSatisfy` foundNlines 2
  it "finds the number of lines in exampleGeneric withStartJunk" $
    runSomeSkipOn (withStartJunk exampleGeneric) `shouldSatisfy` foundNlines 2
  it "finds the number of lines in exampleGeneric withAllJunk" $
    runSomeSkipOn (withAllJunk exampleGeneric) `shouldSatisfy` foundNlines 3
 where
  foundNlines n = either (const False) ((== n) . length)
  runSomeSkipOn = runParser' (some skip)


ptrSpec :: Spec
ptrSpec = do
  it "will parse pointers correctly"         $ mapM_ (succeeds ptr . (,())) [" * ", " *", "* ", "*"]
  it "will parse invalid pointers correctly" $ mapM_ (fails ptr)    [" ", ";*", "_* ", ""]


ptr2Spec :: Spec
ptr2Spec = do
  it "will not parse single pointers" $ mapM_ (fails ptr2) [" * ", " *", "* ", "*"]
  it "will not parse invalid inputs"  $ mapM_ (fails ptr2) [" ", ";*", "_* ", ""]
  it "will parse double pointers" $ mapM_ (succeeds ptr2 . (,()))
    [ " ** " , " **" , "** " , "**" , " * * " , " * *" , "* * " , "* *"
    , " * * " , " * *" , "* * " , "* *", "**      ", "     ** ", "  *   * "
    ]


ctypesSpec :: Spec
ctypesSpec = do
  describe "direct types" $
    it "renders happy path CTypes" $
      mapM_ (succeeds ctypes)
        [ ("uint64_t", CType CUInt64)
        , ("int", CType CInt)
        , ("int64_t", CType CInt64)
        , ("void", CType CVoid)
        ]

  describe "pointer ctypes" $
    it "renders happy path CType pointers" $
      mapM_ (succeeds ctypes)
        [ ("uint64_t *", Ptr (CType CUInt64))
        , ("int*", Ptr (CType CInt))
        , ("int64_t *", Ptr (CType CInt64))
        , ("void   *   ", Ptr (CType CVoid))
        ]

  describe "double-pointer ctypes" $
    it "renders happy path CType pointers of pointers" $
      mapM_ (succeeds ctypes)
        [ ("uint64_t * *", Ptr (Ptr (CType CUInt64)))
        , ("int**", Ptr (Ptr (CType CInt)))
        , ("int64_t **", Ptr (Ptr (CType CInt64)))
        , ("void   *   * ", Ptr (Ptr (CType CVoid)))
        ]


functionArgSpec :: Spec
functionArgSpec = do
  let result = Right (Arg (CType CInt) "k")
  it "will find arguments with no name" $
    runParser' (char '(' >> functionArg) "(void)" `shouldBe` Right (Arg (CType CVoid) "")

  it "will find arguments with prefixed whitespaces" $
    runParser' functionArg "         int k)" `shouldBe` result

  it "will find arguments with comments" $
    runParser' functionArg "  int k, // foobar" `shouldBe` result

  describe "capturing arguments from THC's TensorTopK function" $ do
    it "captures `THCState* state,`" $
      runParser' functionArg "THCState* state," `shouldBe` Right (Arg (Ptr (TenType (Pair (State, THC)))) "state")
    it "captures `THCTensor* topK,`" $
      runParser' functionArg "THCTensor* topK," `shouldBe` Right (Arg (Ptr (TenType (Pair (Tensor, THC)))) "topK")
    it "captures `THCudaLongTensor*indices,`" $
      runParser' functionArg "THCudaLongTensor*indices," `shouldBe` Right (Arg (Ptr (TenType (Pair (LongTensor, THC)))) "indices")
    it "captures `THCTensor* input,`" $
      runParser' functionArg "THCTensor* input," `shouldBe` Right (Arg (Ptr (TenType (Pair (Tensor, THC)))) "input")

functionArgsSpec :: Spec
functionArgsSpec = do
  let result = Right [Arg (CType CVoid) "", Arg (CType CInt) "foo"]
  it "will find arguments in newline-delineated lists" $
    runParser' functionArgs "(void,\n         int foo)" `shouldBe` result

  it "will find arguments in newline-delineated lists with spaces between command and newline" $
    runParser' functionArgs "(void,    \n         int foo)" `shouldBe` result

  it "will find arguments in newline-delineated lists with comments, v1" $
    runParser' functionArgs "(void,\n int foo //foobar\n)" `shouldBe` result

  it "will find arguments in newline-delineated lists with comments, v2" $
    runParser' functionArgs "(void,\n int foo //foobar\n    )" `shouldBe` result

  it "will find arguments in newline-delineated lists with comments, v3" $
    runParser' functionArgs "(void, //foobar \n int foo \n)" `shouldBe` result

  it "will find arguments in newline-delineated lists with comments, v4" $
    runParser' functionArgs "(void,//foobar\n int foo\n)" `shouldBe` result

  it "will find arguments in newline-delineated lists with comments which start with a newline" $
    runParser' functionArgs "(\nvoid,\n int foo //foobar\n)" `shouldBe` result

  it "will find arguments in newline-delineated lists from THCTensorTopK" $
    runParser' functionArgs thctensortopkArgs `shouldBe` Right (funArgs thcGenericTensorTopKFunction')
 where
  thctensortopkArgs = "(THCState* state,\n   THCTensor* topK,\n   THCudaLongTensor* "
    <> "indices,\n   THCTensor* input,\n  int64_t k, int dim, int dir, int sorted)"


functionSpec :: Spec
functionSpec = do
  it "will find functions where the arguments have no name" $
    runParser' function storageElementSize `shouldBe` Right (Just storageElementSize')

  it "will find concrete THC functions in THCTensorRandom.h" $
    runParser' function thcRandomFunction `shouldBe` Right (Just thcRandomFunction')

  it "will find functions with arguments that span several lines (THCTensorTopK.h)" $
    runParser' function thcGenericTensorTopKFunction `shouldBe` Right (Just thcGenericTensorTopKFunction')

  describe "finding TH primatives in the generic/THCTensorCopy.h header" $ do
    it "finds thcCopyAsyncCPU" $
      runParser' function thcCopyAsyncCPU `shouldBe` Right (Just thcCopyAsyncCPURendered)

    it "finds thcCopyAsyncCuda" $
      runParser' function thcCopyAsyncCuda `shouldBe` Right (Just thcCopyAsyncCudaRendered)

  it "will find functions with comments between arguments, like in THNN.h" $
    runParser' function thNNFunction `shouldBe` Right (Just thNNFunctionRendered)


thcCopyAsyncCPU  = "THC_API void THCTensor_(copyAsyncCPU)(THCState *state, THCTensor *self, THTensor *src);"
thcCopyAsyncCPURendered = Function (Just (THC, "Tensor")) "copyAsyncCPU"
  [ Arg (Ptr (TenType (Pair (State, THC)))) "state"
  , Arg (Ptr (TenType (Pair (Tensor, THC)))) "self"
  , Arg (Ptr (TenType (Pair (Tensor, TH)))) "src"
  ] (CType CVoid)

thcCopyAsyncCuda = "THC_API void THTensor_(copyAsyncCuda)(THCState *state, THTensor *self, THCTensor *src);"
thcCopyAsyncCudaRendered = Function (Just (TH, "Tensor")) "copyAsyncCuda"
  [ Arg (Ptr (TenType (Pair (State, THC)))) "state"
  , Arg (Ptr (TenType (Pair (Tensor, TH)))) "self"
  , Arg (Ptr (TenType (Pair (Tensor, THC)))) "src"
  ] (CType CVoid)


-- ========================================================================= --


exampleGeneric :: String
exampleGeneric = "TH_API void THTensor_(setFlag)(THTensor *self,const char flag);"
exampleGeneric' = Function (Just (TH, "Tensor")) "setFlag" [ Arg (Ptr (TenType (Pair (Tensor, TH)))) "self", Arg (CType CChar) "flag"] (CType CVoid)

withStartJunk :: String -> String
withStartJunk x = "skip this garbage line line\n" <> x

withEndJunk :: String -> String
withEndJunk x = x <> "\nanother garbage line ( )@#R @# 324 32"

withAllJunk :: String -> String
withAllJunk = withEndJunk . withStartJunk

thFileFunction = intercalate ""
  [ "TH_API size_t THFile_readStringRaw(THFile *self, const char *format, char **str_); /* you must "
  , "deallocate str_ */"
  ]

thFileFunctionRendered = Function Nothing "THFile_readStringRaw"
  [ Arg      (Ptr (TenType (Pair (File, TH)))) "self"
  , Arg      (Ptr (CType CChar)) "format"
  , Arg (Ptr (Ptr (CType CChar))) "str_"
  ] (CType CSize)

thLogAddFunction :: String
thLogAddFunction = "TH_API double THLogAdd(double log_a, double log_b);"
thLogAddFunctionRendered = Function Nothing "THLogAdd"
  [ Arg (CType CDouble) "log_a"
  , Arg (CType CDouble) "log_b"
  ] (CType CDouble)

thNNFunction = intercalate "\n"
  [ "TH_API void THNN_(L1Cost_updateOutput)("
  , "         THNNState *state,            // library's state"
  , "         THTensor *input,             // input tensor"
  , "         THTensor *output);           // [OUT] output tensor"
  ]
thNNFunctionRendered = Function (Just (THNN, "")) "L1Cost_updateOutput"
  [ Arg (Ptr (TenType (Pair (State, THNN)))) "state"
  , Arg (Ptr (TenType (Pair (Tensor, TH)))) "input"
  , Arg (Ptr (TenType (Pair (Tensor, TH)))) "output"
  ] (CType CVoid)



thcRandomFunction = "THC_API void THCRandom_init(struct THCState *state, int num_devices, int current_device);"
thcRandomFunction' = Function Nothing "THCRandom_init" [Arg (Ptr (TenType (Pair (State, THC)))) "state", Arg (CType CInt) "num_devices", Arg (CType CInt) "current_device" ] (CType CVoid)

thFileContents = intercalate ""
  [ "#ifndef TH_FILE_INC\n#define TH_FILE_INC\n\n#include \"THStorage.h\"\n\ntypedef struct THFile__ "
  , "THFile;\n\nTH_API int THFile_isOpened(THFile *self);\nTH_API int THFile_isQuiet(THFile *self);\n"
  , "TH_API int THFile_isReadable(THFile *self);\nTH_API int THFile_isWritable(THFile *self);\nTH_API"
  , "int THFile_isBinary(THFile *self);\nTH_API int THFile_isAutoSpacing(THFile *self);\nTH_API int T"
  , "HFile_hasError(THFile *self);\n\nTH_API void THFile_binary(THFile *self);\nTH_API void THFile_as"
  , "cii(THFile *self);\nTH_API void THFile_autoSpacing(THFile *self);\nTH_API void THFile_noAutoSpac"
  , "ing(THFile *self);\nTH_API void THFile_quiet(THFile *self);\nTH_API void THFile_pedantic(THFile "
  , "*self);\nTH_API void THFile_clearError(THFile *self);\n\n/* scalar */\nTH_API uint8_t THFile_rea"
  , "dByteScalar(THFile *self);\nTH_API int8_t THFile_readCharScalar(THFile *self);\nTH_API int16_t T"
  , "HFile_readShortScalar(THFile *self);\nTH_API int32_t THFile_readIntScalar(THFile *self);\nTH_API"
  , "int64_t THFile_readLongScalar(THFile *self);\nTH_API float THFile_readFloatScalar(THFile *self);"
  , "\nTH_API double THFile_readDoubleScalar(THFile *self);\n\nTH_API void THFile_writeByteScalar(THF"
  , "ile *self, uint8_t scalar);\nTH_API void THFile_writeCharScalar(THFile *self, int8_t scalar);\nT"
  , "H_API void THFile_writeShortScalar(THFile *self, int16_t scalar);\nTH_API void THFile_writeIntSc"
  , "alar(THFile *self, int32_t scalar);\nTH_API void THFile_writeLongScalar(THFile *self, int64_t sc"
  , "alar);\nTH_API void THFile_writeFloatScalar(THFile *self, float scalar);\nTH_API void THFile_wri"
  , "teDoubleScalar(THFile *self, double scalar);\n\n/* storage */\nTH_API size_t THFile_readByte(THF"
  , "ile *self, THByteStorage *storage);\nTH_API size_t THFile_readChar(THFile *self, THCharStorage *"
  , "storage);\nTH_API size_t THFile_readShort(THFile *self, THShortStorage *storage);\nTH_API size_t"
  , "THFile_readInt(THFile *self, THIntStorage *storage);\nTH_API size_t THFile_readLong(THFile *self"
  , ", THLongStorage *storage);\nTH_API size_t THFile_readFloat(THFile *self, THFloatStorage *storage"
  , ");\nTH_API size_t THFile_readDouble(THFile *self, THDoubleStorage *storage);\n\nTH_API size_t TH"
  , "File_writeByte(THFile *self, THByteStorage *storage);\nTH_API size_t THFile_writeChar(THFile *se"
  , "lf, THCharStorage *storage);\nTH_API size_t THFile_writeShort(THFile *self, THShortStorage *stor"
  , "age);\nTH_API size_t THFile_writeInt(THFile *self, THIntStorage *storage);\nTH_API size_t THFile"
  , "_writeLong(THFile *self, THLongStorage *storage);\nTH_API size_t THFile_writeFloat(THFile *self,"
  , "THFloatStorage *storage);\nTH_API size_t THFile_writeDouble(THFile *self, THDoubleStorage *stora"
  , "ge);\n\n/* raw */\nTH_API size_t THFile_readByteRaw(THFile *self, uint8_t *data, size_t n);\nTH_"
  , "API size_t THFile_readCharRaw(THFile *self, int8_t *data, size_t n);\nTH_API size_t THFile_readS"
  , "hortRaw(THFile *self, int16_t *data, size_t n);\nTH_API size_t THFile_readIntRaw(THFile *self, i"
  , "nt32_t *data, size_t n);\nTH_API size_t THFile_readLongRaw(THFile *self, int64_t *data, size_t n"
  , ");\nTH_API size_t THFile_readFloatRaw(THFile *self, float *data, size_t n);\nTH_API size_t THFil"
  , "e_readDoubleRaw(THFile *self, double *data, size_t n);\nTH_API size_t THFile_readStringRaw(THFil"
  , "e *self, const char *format, char **str_); /* you must deallocate str_ */\n\nTH_API size_t THFil"
  , "e_writeByteRaw(THFile *self, uint8_t *data, size_t n);\nTH_API size_t THFile_writeCharRaw(THFile"
  , "*self, int8_t *data, size_t n);\nTH_API size_t THFile_writeShortRaw(THFile *self, int16_t *data,"
  , "size_t n);\nTH_API size_t THFile_writeIntRaw(THFile *self, int32_t *data, size_t n);\nTH_API siz"
  , "e_t THFile_writeLongRaw(THFile *self, int64_t *data, size_t n);\nTH_API size_t THFile_writeFloat"
  , "Raw(THFile *self, float *data, size_t n);\nTH_API size_t THFile_writeDoubleRaw(THFile *self, dou"
  , "ble *data, size_t n);\nTH_API size_t THFile_writeStringRaw(THFile *self, const char *str, size_t"
  , "size);\n\nTH_API THHalf THFile_readHalfScalar(THFile *self);\nTH_API void THFile_writeHalfScalar"
  , "(THFile *self, THHalf scalar);\nTH_API size_t THFile_readHalf(THFile *self, THHalfStorage *stora"
  , "ge);\nTH_API size_t THFile_writeHalf(THFile *self, THHalfStorage *storage);\nTH_API size_t THFil"
  , "e_readHalfRaw(THFile *self, THHalf* data, size_t size);\nTH_API size_t THFile_writeHalfRaw(THFil"
  , "e *self, THHalf* data, size_t size);\n\nTH_API void THFile_synchronize(THFile *self);\nTH_API vo"
  , "id THFile_seek(THFile *self, size_t position);\nTH_API void THFile_seekEnd(THFile *self);\nTH_AP"
  , "I size_t THFile_position(THFile *self);\nTH_API void THFile_close(THFile *self);\nTH_API void TH"
  , "File_free(THFile *self);\n\n#endif\n"
  ]

storageElementSize :: String
storageElementSize = "TH_API size_t THStorage_(elementSize)(void);"

storageElementSize' :: Function
storageElementSize' = Function (Just (TH, "Storage")) "elementSize" [ Arg (CType CVoid) "" ] (CType CSize)

thGenericStorageContents :: String
thGenericStorageContents = intercalate ""
  [ "#ifndef TH_GENERIC_FILE\n#define TH_GENERIC_FILE \"generic/THStorage.h\"\n#else\n\n/* on pourra"
  , "it avoir un liste chainee\n   qui initialise math, lab structures (or more).\n   mouais -- comp"
  , "lique.\n\n   Pb: THMapStorage is kind of a class\n   THLab_()... comment je m'en sors?\n\n   en"
  , " template, faudrait que je les instancie toutes!!! oh boy!\n   Et comment je sais que c'est pou"
  , "r Cuda? Le type float est le meme dans les <>\n\n   au bout du compte, ca serait sur des pointe"
  , "urs float/double... etc... = facile.\n   primitives??\n */\n\n#define TH_STORAGE_REFCOUNTED 1\n"
  , "#define TH_STORAGE_RESIZABLE  2\n#define TH_STORAGE_FREEMEM    4\n#define TH_STORAGE_VIEW      "
  , " 8\n\ntypedef struct THStorage\n{\n    real *data;\n    ptrdiff_t size;\n    int refcount;\n   "
  , " char flag;\n    THAllocator *allocator;\n    void *allocatorContext;\n    struct THStorage *vi"
  , "ew;\n} THStorage;\n\nTH_API real* THStorage_(data)(const THStorage*);\nTH_API ptrdiff_t THStora"
  , "ge_(size)(const THStorage*);\nTH_API size_t THStorage_(elementSize)(void);\n\n/* slow access --"
  , " checks everything */\nTH_API void THStorage_(set)(THStorage*, ptrdiff_t, real);\nTH_API real T"
  , "HStorage_(get)(const THStorage*, ptrdiff_t);\n\nTH_API THStorage* THStorage_(new)(void);\nTH_AP"
  , "I THStorage* THStorage_(newWithSize)(ptrdiff_t size);\nTH_API THStorage* THStorage_(newWithSize"
  , "1)(real);\nTH_API THStorage* THStorage_(newWithSize2)(real, real);\nTH_API THStorage* THStorage"
  , "_(newWithSize3)(real, real, real);\nTH_API THStorage* THStorage_(newWithSize4)(real, real, real"
  , ", real);\nTH_API THStorage* THStorage_(newWithMapping)(const char *filename, ptrdiff_t size, in"
  , "t flags);\n\n/* takes ownership of data */\nTH_API THStorage* THStorage_(newWithData)(real *dat"
  , "a, ptrdiff_t size);\n\nTH_API THStorage* THStorage_(newWithAllocator)(ptrdiff_t size,\n        "
  , "                                       THAllocator* allocator,\n                               "
  , "                void *allocatorContext);\nTH_API THStorage* THStorage_(newWithDataAndAllocator)"
  , "(\n    real* data, ptrdiff_t size, THAllocator* allocator, void *allocatorContext);\n\n/* shoul"
  , "d not differ with API */\nTH_API void THStorage_(setFlag)(THStorage *storage, const char flag);"
  , "\nTH_API void THStorage_(clearFlag)(THStorage *storage, const char flag);\nTH_API void THStorag"
  , "e_(retain)(THStorage *storage);\nTH_API void THStorage_(swap)(THStorage *storage1, THStorage *s"
  , "torage2);\n\n/* might differ with other API (like CUDA) */\nTH_API void THStorage_(free)(THStor"
  , "age *storage);\nTH_API void THStorage_(resize)(THStorage *storage, ptrdiff_t size);\nTH_API voi"
  , "d THStorage_(fill)(THStorage *storage, real value);\n\n#endif\n"
  ]

thcGenericTensorTopKContents :: String
thcGenericTensorTopKContents = intercalate ""
  [ "#ifndef THC_GENERIC_FILE\n#define THC_GENERIC_FILE \"generic/THCTensorTopK.h\"\n#else\n\n/* Ret"
  , "urns the set of all kth smallest (or largest) elements, depending */\n/* on `dir` */\nTHC_API v"
  , "oid THCTensor_(topk)(THCState* state,\n                               THCTensor* topK,\n       "
  , "                        THCudaLongTensor* indices,\n                               THCTensor* i"
  , "nput,\n                               int64_t k, int dim, int dir, int sorted);\n\n#endif // TH"
  , "C_GENERIC_FILE\n"
  ]

thcGenericTensorTopKFunction :: String
thcGenericTensorTopKFunction = intercalate ""
  [ "THC_API void THCTensor_(topk)(THCState* state,\n                               THCTensor* topK,"
  , "\n                               THCudaLongTensor* indices,\n                               THC"
  , "Tensor* input,\n                               int64_t k, int dim, int dir, int sorted);"
  ]

thcGenericTensorTopKFunction' :: Function
thcGenericTensorTopKFunction' = Function (Just (THC, "Tensor")) "topk"
  [ Arg (Ptr (TenType (Pair (State, THC)))) "state"
  , Arg (Ptr (TenType (Pair (Tensor, THC)))) "topK"
  , Arg (Ptr (TenType (Pair (LongTensor, THC)))) "indices"
  , Arg (Ptr (TenType (Pair (Tensor, THC)))) "input"
  , Arg (CType CInt64) "k"
  , Arg (CType CInt) "dim"
  , Arg (CType CInt) "dir"
  , Arg (CType CInt) "sorted"
  ] (CType CVoid)
