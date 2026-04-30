-- | Template Haskell deriver for RPC protocol GADTs indexed by an arbitrary
-- tag kind (e.g. 'Multiplicity', or a HasAgency-style state kind).
module Atelier.Effects.RPC.TH (makeProtocol) where

import Data.Aeson (FromJSON (..), ToJSON (..), Value, withArray)
import Data.Aeson.Types (Parser)
import Language.Haskell.TH hiding (Type)

import Data.Text qualified as Text
import Language.Haskell.TH qualified as TH


-- | Generate JSON wire-format instances for a GADT indexed by a user-supplied
-- tag kind.
--
-- For a tag kind @T = T1 | T2 | ...@ (closed sum of nullary constructors) and
-- a GADT @Foo :: T -> Type -> Type@, the splice @makeProtocol ''Foo ''T@ emits:
--
--   * @data SomeFoo where T1Foo :: ToJSON a => Foo 'T1 a -> SomeFoo; ...@
--   * @instance ToJSON (Foo t a)@
--   * @instance FromJSON SomeFoo@
--
-- Each GADT constructor encodes as a 2-element JSON array @[tag, contents]@:
--
--   * Nullary: @["MkA", []]@
--   * Unary:   @["MkB", 3]@
--   * N-ary:   @["MkC", [a, b, c]]@
--
-- The wrapper constructor is selected from the GADT constructor's return-type
-- index — a @Foo 'T1 a@-returning constructor wraps in @T1Foo@. Adding a GADT
-- constructor at a new tag value is a compile-time fact: the splice walks the
-- constructor list, so missing or typo'd tags become impossible.
makeProtocol :: Name -> Name -> Q [Dec]
makeProtocol gadtName tagKindName = do
    tagCtors <- reifyTagKind tagKindName
    info <- reify gadtName
    cons <- case info of
        TyConI (DataD _ _ _ _ cs _) -> pure cs
        _ ->
            fail
                $ "makeProtocol: " <> show gadtName <> " is not a data declaration"
    ctors <- concat <$> traverse (analyzeCon tagCtors) cons
    let wrapperName = mkName ("Some" <> nameBase gadtName)
    wrapperD <- buildWrapper gadtName wrapperName tagCtors
    toJSOND <- buildToJSON gadtName ctors
    fromJSONDs <- buildFromJSON gadtName wrapperName ctors
    pure (wrapperD : toJSOND : fromJSONDs)


-- | Reify a tag kind, returning the 'Name' of each (nullary) constructor.
reifyTagKind :: Name -> Q [Name]
reifyTagKind n = do
    info <- reify n
    cs <- case info of
        TyConI (DataD _ _ _ _ cs _) -> pure cs
        _ ->
            fail
                $ "makeProtocol: tag kind "
                    <> show n
                    <> " must be a data declaration"
    traverse extractNullary cs
  where
    extractNullary (NormalC name []) = pure name
    extractNullary (NormalC name _) =
        fail
            $ "makeProtocol: tag constructor "
                <> show name
                <> " must be nullary"
    extractNullary c =
        fail
            $ "makeProtocol: unsupported tag constructor: " <> show c


-- | A GADT constructor: its name, the tag value it returns, and its arity.
data CtorInfo = CtorInfo Name Name Int


analyzeCon :: [Name] -> Con -> Q [CtorInfo]
analyzeCon tagCtors (GadtC names fields retTy) = do
    tag <- tagFromReturn tagCtors retTy
    pure [CtorInfo n tag (length fields) | n <- names]
analyzeCon tagCtors (RecGadtC names fields retTy) = do
    tag <- tagFromReturn tagCtors retTy
    pure [CtorInfo n tag (length fields) | n <- names]
analyzeCon tagCtors (ForallC _ _ con) = analyzeCon tagCtors con
analyzeCon _ other =
    fail
        $ "makeProtocol: unsupported constructor (must be GADT syntax): "
            <> show other


tagFromReturn :: [Name] -> TH.Type -> Q Name
tagFromReturn validTags = goReturn
  where
    goReturn (ParensT t) = goReturn t
    goReturn (SigT t _) = goReturn t
    goReturn (AppT (AppT _ tagTy) _) = matchTag tagTy
    goReturn t =
        fail
            $ "makeProtocol: cannot find tag index in return type: "
                <> show t

    matchTag (PromotedT n) = check n
    matchTag (ConT n) = check n
    matchTag (SigT t _) = matchTag t
    matchTag (ParensT t) = matchTag t
    matchTag t =
        fail
            $ "makeProtocol: expected promoted tag at first index, got: "
                <> show t

    check n
        | n `elem` validTags = pure n
        | otherwise =
            fail
                $ "makeProtocol: tag "
                    <> show n
                    <> " is not a constructor of the supplied tag kind"


-- ---------------------------------------------------------------------------
-- Wrapper data declaration
--
-- For tag kind { T1, T2 } and GADT Foo, generate:
--
--   data SomeFoo where
--     T1Foo :: ToJSON a => Foo 'T1 a -> SomeFoo
--     T2Foo :: ToJSON a => Foo 'T2 a -> SomeFoo

buildWrapper :: Name -> Name -> [Name] -> Q Dec
buildWrapper gadtName wrapperName tagCtors = do
    cons <- traverse mkCon tagCtors
    pure $ DataD [] wrapperName [] Nothing cons []
  where
    mkCon tagName = do
        a <- newName "a"
        let conName = wrapperCtorName gadtName tagName
            payloadTy =
                ConT gadtName `AppT` PromotedT tagName `AppT` VarT a
            ctx = [ConT ''ToJSON `AppT` VarT a]
            field = (Bang NoSourceUnpackedness NoSourceStrictness, payloadTy)
        pure
            $ ForallC
                [PlainTV a SpecifiedSpec]
                ctx
                (GadtC [conName] [field] (ConT wrapperName))


wrapperCtorName :: Name -> Name -> Name
wrapperCtorName gadtName tagName =
    mkName (nameBase tagName <> nameBase gadtName)


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

buildFromJSON :: Name -> Name -> [CtorInfo] -> Q [Dec]
buildFromJSON gadtName wrapperName ctors = do
    let gadtStr = nameBase gadtName
        helperName = mkName ("__makeProtocol_dispatch_" <> gadtStr)

    helperClauses <- traverse (mkHelperClause gadtName) ctors
    defaultClause <- mkDefaultClause gadtStr

    let helperSig =
            SigD
                helperName
                ( ArrowT
                    `AppT` ConT ''Text
                    `AppT` ( ArrowT
                                `AppT` ConT ''Value
                                `AppT` (ConT ''Parser `AppT` ConT wrapperName)
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
                (ConT ''FromJSON `AppT` ConT wrapperName)
                [FunD 'parseJSON [Clause [] (NormalB body) []]]

    pure [helperSig, helperDef, inst]


mkHelperClause :: Name -> CtorInfo -> Q Clause
mkHelperClause gadtName (CtorInfo cName tagName arity) = do
    let tagStr = nameBase cName
        wrapper = ConE (wrapperCtorName gadtName tagName)
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
