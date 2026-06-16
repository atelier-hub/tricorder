module Unit.Tricorder.SourceSpec (spec_Source) where

import Test.Hspec

import Tricorder.SourceLookup (extractFunctionSource, extractSource, stripAnnotations, stripTags, unescapeEntities)


spec_Source :: Spec
spec_Source = do
    describe "extractSource" testExtractSource
    describe "extractFunctionSource" testExtractFunctionSource
    describe "stripAnnotations" testStripAnnotations
    describe "stripTags" testStripTags
    describe "unescapeEntities" testUnescapeEntities


testExtractSource :: Spec
testExtractSource = do
    it "returns content between <pre id=\"src\"> and </pre>, stripped and unescaped" do
        let html = "<html><body><pre id=\"src\"><span>module</span> Foo <span>where</span></pre></body></html>"
        extractSource html `shouldBe` "module Foo where"

    it "strips tags inside the pre block" do
        let html = "<pre id=\"src\"><a href=\"x\">foo</a> <b>bar</b></pre>"
        extractSource html `shouldBe` "foo bar"

    it "unescapes entities inside the pre block" do
        let html = "<pre id=\"src\">&lt;Type&gt; &amp; &quot;val&quot;</pre>"
        extractSource html `shouldBe` "<Type> & \"val\""

    it "falls back to stripping the whole file when no <pre> block is present" do
        let html = "<html><body><p>hello &amp; world</p></body></html>"
        extractSource html `shouldBe` "hello & world"

    -- Regression: some Haddock versions emit <pre> with no id attribute.
    -- extractSource must still strip annottext spans in that case.
    it "strips annottext spans from a <pre> block without an id attribute" do
        let html =
                "<html><body><pre>"
                    <> "<span id=\"line-1\"></span>"
                    <> "<span class=\"annot\"><span class=\"annottext\">foo :: Int\n</span>"
                    <> "<span class=\"hs-identifier hs-var\">foo</span></span>"
                    <> " = "
                    <> "<span class=\"annot\"><span class=\"annottext\">Int\n</span>"
                    <> "<span class=\"hs-number\">42</span></span>\n"
                    <> "</pre></body></html>"
        extractSource html `shouldBe` "foo = 42\n"


testExtractFunctionSource :: Spec
testExtractFunctionSource = do
    it "extracts the type signature and body of a named function" do
        extractFunctionSource "bar" sampleHtml
            `shouldBe` Just "bar :: Int\nbar = 42\n"

    it "stops at blank lines and does not include adjacent functions" do
        let result = toString $ fromMaybe "" (extractFunctionSource "bar" sampleHtml)
        result `shouldNotContain` "other"

    it "does not leak line-number prefixes (N\"> regression)" do
        -- Before the fix, output contained fragments like '45">{-' from the
        -- raw line-span remainder after splitting on <span id="line-".
        let result = toString $ fromMaybe "" (extractFunctionSource "bar" sampleHtml)
        result `shouldNotContain` "\">"

    it "returns Nothing for an unknown function name" do
        extractFunctionSource "unknown" sampleHtml `shouldBe` Nothing

    -- Regression: some Haddock versions emit <pre> with no id attribute.
    it "works when <pre> has no id attribute" do
        let noIdHtml =
                "<pre>"
                    <> "<span id=\"line-1\"></span>bar :: Int\n"
                    <> "<span id=\"line-2\"></span><span id=\"bar\">bar</span> = 42\n"
                    <> "</pre>"
        extractFunctionSource "bar" noIdHtml `shouldBe` Just "bar :: Int\nbar = 42\n"
  where
    -- Minimal Haddock-style source HTML with two functions separated by a blank line.
    sampleHtml =
        "<pre id=\"src\">"
            <> "<span id=\"line-1\"></span>other :: Bool\n"
            <> "<span id=\"line-2\"></span><span id=\"other\">other</span> = True\n"
            <> "<span id=\"line-3\"></span>\n"
            <> "<span id=\"line-4\"></span>bar :: Int\n"
            <> "<span id=\"line-5\"></span><span id=\"bar\">bar</span> = 42\n"
            <> "<span id=\"line-6\"></span>\n"
            <> "</pre>"


testStripAnnotations :: Spec
testStripAnnotations = do
    it "removes an annottext span and its content" do
        stripAnnotations "<span class=\"annottext\">foo :: Int\n</span>bar"
            `shouldBe` "bar"

    it "removes multiple annottext spans" do
        stripAnnotations "a<span class=\"annottext\">X</span>b<span class=\"annottext\">Y</span>c"
            `shouldBe` "abc"

    it "leaves other spans untouched" do
        stripAnnotations "<span class=\"hs-keyword\">module</span>"
            `shouldBe` "<span class=\"hs-keyword\">module</span>"

    it "handles text with no annotations unchanged" do
        stripAnnotations "plain text" `shouldBe` "plain text"

    -- Regression: Haddock emits elaborated types inside annottext that were
    -- leaking into output, e.g. 'universe :: forall a. ...' appearing as a
    -- second type signature, and 'forall a. Bounded a => a' appearing inside
    -- the body of expressions like '[minBound .. maxBound]'.
    it "strips elaborated type annotations from a realistic Haddock snippet" do
        let snippet =
                "<span class=\"annot\">"
                    <> "<span class=\"annottext\">universe :: forall a. (Bounded a, Enum a) =&gt; [a]\n</span>"
                    <> "<a href=\"Relude.Enum.html#universe\">"
                    <> "<span class=\"hs-identifier hs-var\">universe</span>"
                    <> "</a></span>"
                    <> " = [minBound .. maxBound]"
        stripAnnotations snippet
            `shouldBe` "<span class=\"annot\"><a href=\"Relude.Enum.html#universe\"><span class=\"hs-identifier hs-var\">universe</span></a></span> = [minBound .. maxBound]"


testStripTags :: Spec
testStripTags = do
    it "removes a single tag" do
        stripTags "<span>hello</span>" `shouldBe` "hello"

    it "removes nested and adjacent tags" do
        stripTags "<a><b>inner</b></a><em>after</em>" `shouldBe` "innerafter"

    it "leaves plain text untouched" do
        stripTags "plain text" `shouldBe` "plain text"

    it "handles a tag at the very end with no trailing >" do
        -- A truncated tag with no closing '>' — everything after '<' is consumed
        stripTags "text<unclosed" `shouldBe` "text"


testUnescapeEntities :: Spec
testUnescapeEntities = do
    it "replaces &lt;" do
        unescapeEntities "&lt;" `shouldBe` "<"

    it "replaces &gt;" do
        unescapeEntities "&gt;" `shouldBe` ">"

    it "replaces &amp;" do
        unescapeEntities "&amp;" `shouldBe` "&"

    it "replaces &#39;" do
        unescapeEntities "&#39;" `shouldBe` "'"

    it "replaces &quot;" do
        unescapeEntities "&quot;" `shouldBe` "\""

    it "replaces all five entities in one string" do
        unescapeEntities "&lt;a&gt; &amp; &#39;b&#39; &quot;c&quot;"
            `shouldBe` "<a> & 'b' \"c\""

    it "leaves unrecognised entities alone" do
        unescapeEntities "&nbsp;&mdash;" `shouldBe` "&nbsp;&mdash;"
