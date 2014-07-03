# Control.Promise for PureScript

Define a computation with promises, use `liftEff` to lift `Eff` computations
into `Promise`:

```haskell
greet message = do
  liftEff $ print "Wait a sec..."
  delay 1000
  liftEff $ print ("Hello, " ++ message)
  return "ok"
```

You can handle promise result by using `runPromise` and providing a handler:

```haskell
main = runPromise (greet "John") handler
    where
  handler (Right result) = print ("result: " ++ result)
  handler (Left err) = print ("oops, error happened: " ++ err)
```
