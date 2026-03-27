module AtomicKernel.FanoWinner where

import Data.Bits (shiftL, testBit)
import Data.List (nub)
import Data.Word (Word8)
import Numeric (showHex)

-- ==========================================================================
-- FANO / CHIRALITY
-- ==========================================================================

fanoLines :: [(Int, Int, Int)]
fanoLines =
  [ (0,1,3), (0,2,5), (0,4,6)
  , (1,2,4), (1,5,6)
  , (2,3,6)
  , (3,4,5)
  ]

newtype ChiralBit = ChiralBit { unChiralBit :: Int }
  deriving (Eq, Show)

mkChiralBit :: Int -> Maybe ChiralBit
mkChiralBit 0 = Just (ChiralBit 0)
mkChiralBit 1 = Just (ChiralBit 1)
mkChiralBit _ = Nothing

chiralBitOrZero :: Int -> ChiralBit
chiralBitOrZero b = case mkChiralBit b of
  Just cb -> cb
  Nothing -> ChiralBit 0

fromChiralBit :: ChiralBit -> Int
fromChiralBit = unChiralBit

data FanoWinner = FanoWinner
  { fwTick      :: Int
  , fwTriplet   :: (Int, Int, Int)
  , fwChiralBit :: ChiralBit
  , fwWinner    :: Int
  , fwPivot     :: Int
  , fwLosers    :: [Int]
  , fwCycleN    :: Int
  } deriving (Eq, Show)

computeWinner :: Int -> ChiralBit -> FanoWinner
computeWinner tick cb =
  let triplet@(p0,p1,p2) = fanoLines !! (tick `mod` 7)
      winner             = if fromChiralBit cb == 0 then p0 else p2
      losers             = filter (/= winner) [p0,p1,p2]
      cycleN             = tick `div` 7
  in FanoWinner
      { fwTick      = tick
      , fwTriplet   = triplet
      , fwChiralBit = cb
      , fwWinner    = winner
      , fwPivot     = p1
      , fwLosers    = losers
      , fwCycleN    = cycleN
      }

computeWinnerUnsafe :: Int -> Int -> FanoWinner
computeWinnerUnsafe tick b = computeWinner tick (chiralBitOrZero b)

winnerSequence :: [ChiralBit] -> [FanoWinner]
winnerSequence bits = zipWith computeWinner [0..] bits

-- ==========================================================================
-- BRAILLE DUAL REGISTER
-- ==========================================================================

hexWeightTable :: [Int]
hexWeightTable = [0x01, 0x02, 0x04, 0x40, 0x10, 0x08, 0x20, 0x80]

binaryWeight :: Int -> Int
binaryWeight i = 1 `shiftL` (i - 1)

data BrailleCell = BrailleCell
  { bcRaisedDots   :: [Int]
  , bcBinaryValue  :: Int
  , bcHexWtValue   :: Int
  , bcUnicodeCP    :: Int
  , bcBrailleChar  :: Char
  } deriving (Eq, Show)

buildBrailleCell :: Word8 -> BrailleCell
buildBrailleCell byte =
  let raised = [ i | i <- [1..8], testBit byte (i-1) ]
      binVal = fromIntegral byte
      hexWt  = sum [ hexWeightTable !! (d-1) | d <- raised ]
      cp     = 0x2800 + hexWt
  in BrailleCell
      { bcRaisedDots   = raised
      , bcBinaryValue  = binVal
      , bcHexWtValue   = hexWt
      , bcUnicodeCP    = cp
      , bcBrailleChar  = toEnum cp
      }

data DualRegister = DualRegister
  { drCell   :: BrailleCell
  , drBinary :: Int
  , drHexWt  :: Int
  , drTick   :: Int
  } deriving (Eq, Show)

buildDualRegister :: Int -> Word8 -> DualRegister
buildDualRegister tick byte =
  let cell = buildBrailleCell byte
  in DualRegister
      { drCell   = cell
      , drBinary = bcBinaryValue cell
      , drHexWt  = bcHexWtValue cell
      , drTick   = tick
      }

-- ==========================================================================
-- FACTORADIC / CONFIGURATION
-- ==========================================================================

factoradicRadices :: [Int]
factoradicRadices = [1,2,3,4,5,6,7,8,9,10]

encodeFactoradic :: Int -> [Int]
encodeFactoradic = go factoradicRadices
  where
    go [] v     = [v]
    go (r:rs) v = (v `mod` r) : go rs (v `div` r)

decodeFactoradic :: [Int] -> Int
decodeFactoradic [] = 0
decodeFactoradic ds = foldr step (last ds) (zip (init ds) factoradicRadices)
  where
    step (d, r) acc = d + r * acc

factoradicRoundtrip :: Int -> Bool
factoradicRoundtrip v =
  v >= 0
  && v < product factoradicRadices
  && decodeFactoradic (encodeFactoradic v) == v

data FactorialAddress = FactorialAddress
  { faDigits      :: [Int]
  , faBinaryBytes :: [Word8]
  , faHexWtBytes  :: [Word8]
  , faConfigIndex :: Int
  } deriving (Eq, Show)

buildFactorialAddress :: Int -> [Word8] -> FactorialAddress
buildFactorialAddress _startTick bytes =
  let win      = take 8 (bytes ++ repeat 0)
      regs     = zipWith buildDualRegister [0..] win
      bins     = map (fromIntegral . drBinary) regs
      hexes    = map (fromIntegral . drHexWt) regs
      digits   = zipWith (\b r -> fromIntegral b `mod` r) hexes factoradicRadices
      cfg      = decodeFactoradic digits
  in FactorialAddress
      { faDigits      = digits
      , faBinaryBytes = bins
      , faHexWtBytes  = hexes
      , faConfigIndex = cfg
      }

-- ==========================================================================
-- 240-SPACE ADDRESSING
-- 240 = 15 lanes × 16 quadrants = 15 × (4 channels × 4 orientations)
-- ==========================================================================

data Addr240 = Addr240
  { a240Raw       :: Int
  , a240LaneIdx   :: Int
  , a240Quadrant  :: Int
  , a240Channel   :: Int
  , a240Lane      :: Int
  , a240Orient    :: Int
  } deriving (Eq, Show)

addr240FromWinner :: FanoWinner -> Addr240
addr240FromWinner fw =
  let cycleN   = fwCycleN fw
      laneIdx  = cycleN `mod` 15
      channel  = fwWinner fw `mod` 4
      orient   = ((cycleN `div` 15) + fromChiralBit (fwChiralBit fw)) `mod` 4
      quadrant = channel * 4 + orient
      raw      = quadrant * 15 + laneIdx
  in Addr240
      { a240Raw       = raw
      , a240LaneIdx   = laneIdx
      , a240Quadrant  = quadrant
      , a240Channel   = channel
      , a240Lane      = laneIdx + 1
      , a240Orient    = orient
      }

channelName :: Int -> String
channelName 0 = "US"
channelName 1 = "RS"
channelName 2 = "GS"
channelName 3 = "FS"
channelName n = "CH" ++ show n

-- ==========================================================================
-- WINNER FRAME
-- ==========================================================================

data WinnerFrame = WinnerFrame
  { wfTick        :: Int
  , wfWinner      :: FanoWinner
  , wfRegister    :: DualRegister
  , wfAddr240     :: Addr240
  , wfFactAddr    :: FactorialAddress
  , wfBrailleChar :: Char
  , wfUnicodeCP   :: Int
  , wfConfigLabel :: String
  } deriving (Eq, Show)

buildWinnerFrame :: Int -> ChiralBit -> Word8 -> [Word8] -> WinnerFrame
buildWinnerFrame tick cb kernelByte history =
  let winner   = computeWinner tick cb
      reg      = buildDualRegister tick kernelByte
      addr     = addr240FromWinner winner
      factAddr = buildFactorialAddress (tick - 7) history
      cell     = drCell reg
  in WinnerFrame
      { wfTick        = tick
      , wfWinner      = winner
      , wfRegister    = reg
      , wfAddr240     = addr
      , wfFactAddr    = factAddr
      , wfBrailleChar = bcBrailleChar cell
      , wfUnicodeCP   = bcUnicodeCP cell
      , wfConfigLabel = describeConfig addr factAddr winner
      }

describeConfig :: Addr240 -> FactorialAddress -> FanoWinner -> String
describeConfig addr fa fw =
  channelName (a240Channel addr)
  ++ "/lane" ++ show (a240Lane addr)
  ++ "/orient" ++ show (a240Orient addr)
  ++ " fano=" ++ show (fwWinner fw)
  ++ " cfg=" ++ show (faConfigIndex fa)

-- ==========================================================================
-- INVARIANTS
-- ==========================================================================

invW1_deterministic :: Bool
invW1_deterministic =
  all (\(t, b) -> computeWinner t b == computeWinner t b)
      [ (t, cb) | t <- [0..64], cb <- [ChiralBit 0, ChiralBit 1] ]

invW2_tripletPeriod7 :: Bool
invW2_tripletPeriod7 =
  all (\t -> fwTriplet (computeWinner t (ChiralBit 0)) == fwTriplet (computeWinner (t + 7) (ChiralBit 0)))
      [0..128]

invW3_addrFieldsLawful :: Bool
invW3_addrFieldsLawful =
  all lawful [ addr240FromWinner (computeWinner t cb)
             | t <- [0..5039]
             , cb <- [ChiralBit 0, ChiralBit 1]
             ]
  where
    lawful a =
         a240Raw a == a240Quadrant a * 15 + a240LaneIdx a
      && a240Raw a >= 0 && a240Raw a < 240
      && a240LaneIdx a >= 0 && a240LaneIdx a < 15
      && a240Quadrant a >= 0 && a240Quadrant a < 16
      && a240Channel a >= 0 && a240Channel a < 4
      && a240Orient a >= 0 && a240Orient a < 4
      && a240Lane a >= 1 && a240Lane a <= 15

invW4_fullCoverage :: Bool
invW4_fullCoverage =
  let addrs = [ a240Raw (addr240FromWinner (computeWinner t cb))
              | t <- [0..5039]
              , cb <- [ChiralBit 0, ChiralBit 1]
              ]
  in length (nub addrs) == 240

invW5_binaryIsIdentity :: Bool
invW5_binaryIsIdentity =
  all (\b -> bcBinaryValue (buildBrailleCell b) == fromIntegral b)
      [minBound .. maxBound :: Word8]

invW6_hexWtInRange :: Bool
invW6_hexWtInRange =
  all (\b -> let v = bcHexWtValue (buildBrailleCell b) in v >= 0 && v <= 255)
      [minBound .. maxBound :: Word8]

invW7_distinctMappings :: Bool
invW7_distinctMappings =
  let pairs = [ let c = buildBrailleCell b in (bcBinaryValue c, bcHexWtValue c)
              | b <- [minBound .. maxBound :: Word8] ]
  in length (filter (uncurry (/=)) pairs) > 200

invW8_factoradicRoundtrip :: Bool
invW8_factoradicRoundtrip =
  all factoradicRoundtrip [0 .. min 9999 (product factoradicRadices - 1)]

invW9_knownBraille :: Bool
invW9_knownBraille =
  let cell125 = buildBrailleCell 0x13
      cellAll = buildBrailleCell 0xFF
  in bcUnicodeCP cell125 == 0x2813 && bcUnicodeCP cellAll == 0x28FF

checkWinnerInvariants :: [(String, Bool)]
checkWinnerInvariants =
  [ ("W1 deterministic winner",          invW1_deterministic)
  , ("W2 triplet period-7",              invW2_tripletPeriod7)
  , ("W3 lawful 240-field decomposition", invW3_addrFieldsLawful)
  , ("W4 full 240 coverage",             invW4_fullCoverage)
  , ("W5 binary register identity",      invW5_binaryIsIdentity)
  , ("W6 hex-weight range",              invW6_hexWtInRange)
  , ("W7 binary/hex mappings differ",    invW7_distinctMappings)
  , ("W8 factoradic roundtrip",          invW8_factoradicRoundtrip)
  , ("W9 known Braille examples",        invW9_knownBraille)
  ]

-- ==========================================================================
-- DEMO
-- ==========================================================================

showWinnerFrame :: WinnerFrame -> String
showWinnerFrame wf =
  "tick=" ++ show (wfTick wf)
  ++ " " ++ [wfBrailleChar wf]
  ++ " U+" ++ showHex (wfUnicodeCP wf) ""
  ++ " bin=" ++ show (drBinary (wfRegister wf))
  ++ " hexwt=" ++ show (drHexWt (wfRegister wf))
  ++ " addr240=" ++ show (a240Raw (wfAddr240 wf))
  ++ " " ++ wfConfigLabel wf
