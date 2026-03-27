-- aztec.hs
-- stdin → Braille stream → Aztec code

import System.IO
import qualified Data.ByteString as B

main = do
    bytes <- B.getContents
    let braille = bytesToBraille bytes
        aztec = brailleToAztec braille
    B.putStr aztec