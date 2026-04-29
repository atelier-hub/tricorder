-- | Template Haskell deriver for RPC protocol GADTs indexed by 'Multiplicity'.
module Atelier.Effects.RPC.TH (makeProtocol) where

import Data.Aeson (FromJSON (..), ToJSON (..), Value, withArray)
import Data.Aeson.Types (Parser)
import Language.Haskell.TH hiding (Type)

import Data.Text qualified as Text
import Language.Haskell.TH qualified as TH

import Atelier.Effects.RPC (Multiplicity (..), SomeRPC (..))


-- | Generate JSON wire-format instances for an RPC-protocol GADT indexed by
-- 'Multiplicity'.
--
-- For a GADT @Foo :: Multiplicity -> Type -> Type@, the splice
-- @makeProtocol ''Foo@ emits:
--
--   * @instance ToJSON (Foo m a)@
--   * @instance FromJSON (SomeRPC Foo)@
--
-- Each constructor encodes as a 2-element JSON array @[tag, contents]@:
--
--   * Nullary: @["StatusNow", []]@
--   * Unary:   @["DiagnosticAt", 3]@
--   * N-ary:   @["Foo", [a, b, c]]@
--
-- The 'OnceRPC' / 'ManyRPC' wrapper is selected from the constructor's
-- return-type index — 'Once'-indexed constructors round-trip through 'OnceRPC',
-- 'Many'-indexed through 'ManyRPC'. Adding a constructor at a new multiplicity
-- is a compile-time fact: the splice picks the right wrapper, and the tag
-- dispatch table is generated from the constructor list directly, so missing
-- or typo'd tags become impossible.
makeProtocol :: Name -> Q [Dec]
makeProtocol gadtName = do
    info <- reify gadtName
    cons <- case info of
        TyConI (DataD _ _ _ _ cs _) -> pure cs
        _ ->
            fail
                $ "makeProtocol: " <> show gadtName <> " is not a data declaration"
    ctors <- concat <$> traverse analyzeCon cons
    toJSOND <- buildToJSON gadtName ctors
    fromJSONDs <- buildFromJSON gadtName ctors
    pure (toJSOND : fromJSONDs)


data CtorInfo = CtorInfo Name Bool Int


analyzeCon :: Con -> Q [CtorInfo]
analyzeCon (GadtC names fields retTy) = do
    isMany <- multiplicityFromReturn retTy
    pure [CtorInfo n isMany (length fields) | n <- names]
analyzeCon (RecGadtC names fields retTy) = do
    isMany <- multiplicityFromReturn retTy
    pure [CtorInfo n isMany (length fields) | n <- names]
analyzeCon (ForallC _ _ con) = analyzeCon con
analyzeCon other =
    fail
        $ "makeProtocol: unsupported constructor (must be GADT syntax): "
            <> show other


multiplicityFromReturn :: TH.Type -> Q Bool
multiplicityFromReturn = goReturn
  where
    goReturn (ParensT t) = goReturn t
    goReturn (SigT t _) = goReturn t
    goReturn (AppT (AppT _ multTy) _) = matchMult multTy
    goReturn t =
        fail
            $ "makeProtocol: cannot find multiplicity index in return type: "
                <> show t

    matchMult (PromotedT n) = matchName n
    matchMult (ConT n) = matchName n
    matchMult (SigT t _) = matchMult t
    matchMult (ParensT t) = matchMult t
    matchMult t =
        fail
            $ "makeProtocol: expected promoted 'Once or 'Many at first index, "
                <> "got: "
                <> show t

    matchName n
        | n == 'Once = pure False
        | n == 'Many = pure True
        | otherwise =
            fail
                $ "makeProtocol: expected 'Once or 'Many at first index, got: "
                    <> show n


-- ---------------------------------------------------------------------------
-- ToJSON

buildToJSON :: Name -> [CtorInfo] -> Q Dec
buildToJSON gadtName ctors = do
    arg <- newName "x"
    matches <- traverse mkToJSONMatch ctors
    let body = CaseE (VarE arg) matches
        m = mkName "m"
        a = mkName "a"
        instType =
            ConT ''ToJSON
                `AppT` (ConT gadtName `AppT` VarT m `AppT` VarT a)
    pure
        $ InstanceD
            Nothing
            []
            instType
            [FunD 'toJSON [Clause [VarP arg] (NormalB body) []]]


mkToJSONMatch :: CtorInfo -> Q Match
mkToJSONMatch (CtorInfo cName _ arity) = do
    let tagLitE = SigE (LitE (StringL (nameBase cName))) (ConT ''Text)
    case arity of
        0 -> do
            let emptyArr = SigE (ListE []) (AppT ListT (ConT ''Value))
                pair = TupE [Just tagLitE, Just emptyArr]
                body = AppE (VarE 'toJSON) pair
            pure $ Match (ConP cName [] []) (NormalB body) []
        1 -> do
            x <- newName "x"
            let pair = TupE [Just tagLitE, Just (VarE x)]
                body = AppE (VarE 'toJSON) pair
            pure $ Match (ConP cName [] [VarP x]) (NormalB body) []
        _ -> do
            args <- replicateM arity (newName "x")
            let argTup = TupE (map (Just . VarE) args)
                pair = TupE [Just tagLitE, Just argTup]
                body = AppE (VarE 'toJSON) pair
            pure $ Match (ConP cName [] (map VarP args)) (NormalB body) []


-- ---------------------------------------------------------------------------
-- FromJSON
--
-- A top-level helper @__makeProtocol_dispatch_<Gadt>@ maps (tag, contents) to
-- a parser. The instance body is a thin shell that splits the JSON array and
-- calls the helper. Pulling dispatch into a top-level function keeps name
-- hygiene simple — no need to splice patterns under a quoted lambda.

buildFromJSON :: Name -> [CtorInfo] -> Q [Dec]
buildFromJSON gadtName ctors = do
    let gadtStr = nameBase gadtName
        helperName = mkName ("__makeProtocol_dispatch_" <> gadtStr)

    helperClauses <- traverse mkHelperClause ctors
    defaultClause <- mkDefaultClause gadtStr

    let helperSig =
            SigD
                helperName
                ( ArrowT
                    `AppT` ConT ''Text
                    `AppT` ( ArrowT
                                `AppT` ConT ''Value
                                `AppT` ( ConT ''Parser
                                            `AppT` (ConT ''SomeRPC `AppT` ConT gadtName)
                                       )
                           )
                )
        helperDef = FunD helperName (helperClauses ++ [defaultClause])

    body <-
        [|
            withArray $(stringE gadtStr) $ \arr -> case toList arr of
                [tagV, contentsV] -> do
                    tag <- parseJSON tagV
                    $(varE helperName) tag contentsV
                _ -> fail "expected 2-element array"
            |]

    let inst =
            InstanceD
                Nothing
                []
                (ConT ''FromJSON `AppT` (ConT ''SomeRPC `AppT` ConT gadtName))
                [FunD 'parseJSON [Clause [] (NormalB body) []]]

    pure [helperSig, helperDef, inst]


mkHelperClause :: CtorInfo -> Q Clause
mkHelperClause (CtorInfo cName isMany arity) = do
    let tagStr = nameBase cName
        wrapper = ConE (if isMany then 'ManyRPC else 'OnceRPC)
        ctorE = ConE cName
    case arity of
        0 -> do
            let body = AppE (VarE 'pure) (AppE wrapper ctorE)
            pure $ Clause [LitP (StringL tagStr), WildP] (NormalB body) []
        1 -> do
            v <- newName "v"
            let composed = InfixE (Just wrapper) (VarE '(.)) (Just ctorE)
                body =
                    InfixE
                        (Just composed)
                        (VarE '(<$>))
                        (Just (AppE (VarE 'parseJSON) (VarE v)))
            pure $ Clause [LitP (StringL tagStr), VarP v] (NormalB body) []
        _ -> do
            v <- newName "v"
            argNames <- replicateM arity (newName "a")
            let pat = TupP (map VarP argNames)
                applied = foldl' AppE ctorE (map VarE argNames)
                wrapped = AppE wrapper applied
                stmts =
                    [ BindS pat (AppE (VarE 'parseJSON) (VarE v))
                    , NoBindS (AppE (VarE 'pure) wrapped)
                    ]
                body = DoE Nothing stmts
            pure $ Clause [LitP (StringL tagStr), VarP v] (NormalB body) []


mkDefaultClause :: String -> Q Clause
mkDefaultClause gadtStr = do
    other <- newName "other"
    body <-
        [|
            fail
                ( $(stringE ("Unknown " <> gadtStr <> " tag: "))
                    <> Text.unpack $(varE other)
                )
            |]
    pure $ Clause [VarP other, WildP] (NormalB body) []
