module Control.Promise where

import Control.Monad.Eff
import Debug.Trace
import Data.Either

foreign import data Promise :: * -> *

-- Currently we use bluebird, someday we can switch to native Promise
-- implementation when it will be deployed across runtimes.
foreign import promiseImpl
  "var promiseImpl = require('bluebird')"
  :: forall a. a

foreign import fmap
  "function fmap(f) { \
  \  return function(a) { \
  \    return a.then(f) \
  \  } \
  \}"
  :: forall a b. (a -> b) -> Promise a -> Promise b

foreign import app
  "function app(f) { \
  \  return function(a) { \
  \    return Promise.props({f: f, a: a}).then(function(x) { return x.f(x.a); }) \
  \  } \
  \}"
  :: forall a b. Promise (a -> b) -> Promise a -> Promise b

foreign import bind
  "function bind(a) { \
  \  return function(f) { \
  \    return a.then(f); \
  \} \
  \}"
  :: forall a b. Promise a -> (a -> Promise b) -> Promise b

foreign import resolve
  "var resolve = promiseImpl.resolve"
  :: forall a. a -> Promise a

foreign import reject
  "function reject(err) { return promiseImpl.reject(err); }"
  :: forall a. String -> Promise a

foreign import resolveAsync'
  "function make(compute) { \
  \  return new promiseImpl(function(resolve, reject) { \
  \    compute(resolve)(reject)(); \
  \  }); \
  \}"
  :: forall a b eff. ((a -> Unit) -> (String -> Unit) -> Eff (eff) b) -> Promise a

-- Make a promise from a computation which reports a result via a callback.
--
-- xhrPromise url = resolveAsync doXHR
--     where
--   doXHR report = do
--     req <- xhr url
--     onResult req \result -> report (Right result)
--     onError req \error -> report (Left error)
--
resolveAsync :: forall a eff b. ((Either String a -> Unit) -> Eff (eff) b) -> Promise a
resolveAsync action = resolveAsync' compute
    where
  compute resolve reject = do
    action report
      where
    report (Right r) = resolve r
    report (Left err) = reject err

-- Execute Eff actions inside Promise
--
-- do
--   liftEff $ print "Wait a sec..."
--   delay 1000
--   liftEff $ print "Here we go"
foreign import liftEff
  "function liftEff(f) { \
  \  return new promiseImpl(function(resolve) { \
  \    resolve(f()); \
  \  }); \
  \}"
  :: forall a eff. Eff eff a -> Promise a

foreign import runPromise
  "function runPromise(p) {\
  \  return function(handler) {\
  \    return p\
  \      .then(function(r) { handler(PS.Data_Either.Right(r))(); }) \
  \      .catch(function(e) { handler(PS.Data_Either.Left(e))(); }); \
  \  }\
  \}"
  :: forall a b eff eff2. Promise a -> (Either String a -> Eff eff b) -> Eff eff2 {}

-- Delay for a numner of milliseconds
foreign import delay
  "var delay = promiseImpl.delay;"
  :: Number -> Promise Unit

-- Delay value for a numner of milliseconds
foreign import delayValue
  "var delayValue = promiseImpl.delay;"
  :: forall a. a -> Number -> Promise a

instance promiseFunctor :: Functor Promise where
  (<$>) = fmap

instance promiseApply :: Apply Promise where
  (<*>) = app

instance promiseApplication :: Applicative Promise where
  pure = resolve

instance promiseBind :: Bind Promise where
  (>>=) = bind

instance promiseMonad :: Monad Promise
