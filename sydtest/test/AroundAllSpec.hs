{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeFamilies #-}

module AroundAllSpec (spec) where

import Control.Concurrent.STM
import Control.Monad.IO.Class
import Test.Syd

spec :: Spec
spec = sequential $ do
  describe "beforeAll" $ do
    var <- liftIO $ newTVarIO (0 :: Int)
    let readAndIncrement :: IO Int
        readAndIncrement = atomically $ stateTVar var $ \i -> (i + 1, i + 1)
    beforeAll readAndIncrement $ do
      let t :: HList '[Int] -> () -> IO ()
          t (HCons i HNil) () = i `shouldBe` 1
      it' "reads 1" t
      it' "reads 1" t
  describe "beforeAll_" $ do
    var <- liftIO $ newTVarIO (0 :: Int)
    let increment :: IO ()
        increment = atomically $ modifyTVar var (+ 1)
    beforeAll_ increment $ do
      let t :: IO ()
          t = do
            i <- readTVarIO var
            i `shouldBe` 1
      it' "reads 1" t
      it' "reads 1" t
  describe "afterAll" $ do
    var <- liftIO $ newTVarIO (0 :: Int)
    let readAndIncrement :: IO Int
        readAndIncrement = atomically $ stateTVar var $ \i -> (i + 1, i + 1)
        addExtra :: Int -> IO ()
        addExtra i = atomically $ modifyTVar var (+ i)
    beforeAll readAndIncrement $
      afterAll addExtra $ do
        let t :: HList '[Int] -> () -> IO ()
            t (HCons i HNil) () = i `shouldBe` 1
        it' "reads 1" t
        it' "reads 1" t
  describe "afterAll_" $ do
    var <- liftIO $ newTVarIO (0 :: Int)
    let increment :: IO ()
        increment = atomically $ modifyTVar var (+ 1)
    afterAll_ increment $ do
      let t :: IO ()
          t = do
            i <- readTVarIO var
            i `shouldBe` 0
      it' "reads 0" t
      it' "reads 0" t
  describe "aroundAll" $ do
    var <- liftIO $ newTVarIO (0 :: Int)
    let readAndIncrement :: IO Int
        readAndIncrement = atomically $ stateTVar var $ \i -> (i + 1, i + 1)
    let increment :: IO ()
        increment = atomically $ modifyTVar var (+ 1)
    let incrementBeforeAndAfter :: (Int -> IO ()) -> IO ()
        incrementBeforeAndAfter func = do
          i <- readAndIncrement
          func i
          increment
    aroundAll incrementBeforeAndAfter $ do
      let t :: HList '[Int] -> () -> IO ()
          t (HCons i HNil) () = i `shouldBe` 1
      it' "reads 1" t
      it' "reads 1" t

-- describe "aroundAll" $ do
--   var <- liftIO $ newTVarIO (0 :: Int)
--   let increment = atomically $ modifyTVar var succ
--       readAndIncrement = atomically $ stateTVar var $ \i -> (i, i + 1)
--       aroundAllWithFunc :: (Int -> IO ()) -> Int -> IO ()
--       aroundAllWithFunc intFunc j = do
--         i <- readAndIncrement
--         intFunc $ i + j
--         increment
--       aroundAllFunc :: (HList Int '[] -> IO ()) -> IO ()
--       aroundAllFunc intFunc = do
--         i <- readAndIncrement
--         intFunc (HLast i)
--         increment
--       aroundAllFunc_ :: IO () -> IO ()
--       aroundAllFunc_ func = do
--         increment
--         func
--         increment
--   aroundAll aroundAllFunc $
--     aroundAllWith aroundAllWithFunc $
--       aroundAll_ aroundAllFunc_ $ do
--         pure () :: TestDefM (HList Int '[Int]) () ()
--         it "reads 1" $ \(HCons i (HLast j)) () -> do
--           i `shouldBe` 1
--           j `shouldBe` 1
--         it "reads 1" $ \(HCons i (HLast j)) () -> do
--           i `shouldBe` 1
--           j `shouldBe` 1
--         it "reads 1" $ \(HCons i (HLast j)) () -> do
--           i `shouldBe` 1
--           j `shouldBe` 1
