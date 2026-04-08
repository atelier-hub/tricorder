module Unit.Ghcib.SourceSpec (spec_Source) where

import Test.Hspec

import Ghcib.SourceLookup (extractSource, stripTags, unescapeEntities)


spec_Source :: Spec
spec_Source = do
    describe "extractSource" testExtractSource
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

    it "falls back to stripping the whole file when <pre id=\"src\"> is absent" do
        let html = "<html><body><p>hello &amp; world</p></body></html>"
        extractSource html `shouldBe` "hello & world"


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
