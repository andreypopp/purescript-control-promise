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
  :: forall a b eff eff2. Promise a -> (Either a String -> Eff eff b) -> Eff eff2 {}

foreign import delay
  "var delay = promiseImpl.delay;"
  :: Number -> Promise Unit

instance promiseFunctor :: Functor Promise where
  (<$>) = fmap

instance promiseApply :: Apply Promise where
  (<*>) = app

instance promiseApplication :: Applicative Promise where
  pure = resolve

instance promiseBind :: Bind Promise where
  (>>=) = bind

instance promiseMonad :: Monad Promise

greet message = do
  liftEff $ print "Wait a sec..."
  delay 1000
  liftEff $ print ("Hello, " ++ message)
  return "ok"

main = runPromise (greet "John") handler
    where
  handler (Right result) = print ("result: " ++ result)
  handler (Left err) = print ("oops, error happened: " ++ err)
