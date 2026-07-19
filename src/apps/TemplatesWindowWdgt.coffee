# TemplatesWindowWdgt -- builds the editor's "useful snippets" templates window:
# a SimpleDocumentScrollPanelWdgt pre-filled with one of every document building
# block (headings, paragraphs, a quote, links, spacers, dividers, the special-
# characters paragraph) turned into draggable templates, wrapped in a FrameWdgt.
# Lifted verbatim out of MenusHelper.createNewTemplatesWindow as a per-app
# window-builder class -- the *.create() factory pattern also used by
# WelcomeMessageInfoWdgt: the heavy builder becomes a
# static @create factory and its two callers (the templates toolbar buttons) call
# TemplatesWindowWdgt.create() directly. Ships in the homepage build (it is
# reached from the toolbars), so it is NOT homepage-excluded. OO-backlog Phase 6
# step 6c.1.

class TemplatesWindowWdgt extends FrameWdgt

  @create: ->
    sdspw = new SimpleDocumentScrollPanelWdgt

    sdspw._applyExtent new Point 365, 335

    startingContent = new SimpleTextWdgt(
      "Simply drag the items below into your document",nil,nil,nil,nil,nil,WorldWdgt.preferencesAndSettings.editableItemBackgroundColor, 1)
    startingContent.alignCenter()
    startingContent.setFontSize 18
    startingContent.isEditable = true
    startingContent.enableSelecting()

    sdspw.setContents startingContent, 5


    startingContent = new ArrowSIconWdgt
    startingContent._applyExtent new Point 25, 25
    sdspw.add startingContent
    startingContent.layoutSpecDetails.setAlignmentToCenter()

    sdspw.addDivider()

    # the Title building block IS the TitleWdgt role (§5.B, D7) -- the style
    # lives in the class, and a dragged-out copy carries the "a Title" identity
    sdspw.add new TitleWdgt

    startingContent = new SimpleTextWdgt(
      "Section X",nil,nil,nil,nil,nil,WorldWdgt.preferencesAndSettings.editableItemBackgroundColor, 1)
    startingContent.toggleWeight()
    startingContent.isEditable = true
    startingContent.enableSelecting()
    startingContent.setFontSize 28
    sdspw.add startingContent

    startingContent = new SimpleTextWdgt(
      "Section X.X",nil,nil,nil,nil,nil,WorldWdgt.preferencesAndSettings.editableItemBackgroundColor, 1)
    startingContent.isEditable = true
    startingContent.enableSelecting()
    startingContent.setFontSize 24
    sdspw.add startingContent

    sdspw.addNormalParagraph "Normal text."

    startingContent = new SimpleTextWdgt(
      "“Be careful--with quotations, you can damn anything.”\n― André Malraux",nil,nil,nil,nil,nil,WorldWdgt.preferencesAndSettings.editableItemBackgroundColor, 1)
    startingContent.toggleItalic()
    startingContent.alignRight()
    startingContent.isEditable = true
    startingContent.enableSelecting()
    sdspw.add startingContent


    sdspw.addIndentedText "indentedText"
    sdspw.addBulletPoint "bullet point"
    sdspw.addCodeBlock "a code block with\n  some example\n    code in here"


    startingContent = new SimpleTextWdgt(
      "Spacers:",nil,nil,nil,nil,nil,WorldWdgt.preferencesAndSettings.editableItemBackgroundColor, 1)
    startingContent.toggleWeight()
    startingContent.isEditable = true
    startingContent.enableSelecting()
    sdspw.add startingContent

    sdspw.addSpacer()
    sdspw.addSpacer 2
    sdspw.addSpacer 3

    startingContent = new SimpleTextWdgt(
      "Divider line:",nil,nil,nil,nil,nil,WorldWdgt.preferencesAndSettings.editableItemBackgroundColor, 1)
    startingContent.toggleWeight()
    startingContent.isEditable = true
    startingContent.enableSelecting()
    sdspw.add startingContent

    sdspw.addDivider()

    startingContent = new SimpleTextWdgt(
      "Links:",nil,nil,nil,nil,nil,WorldWdgt.preferencesAndSettings.editableItemBackgroundColor, 1)
    startingContent.toggleWeight()
    startingContent.isEditable = true
    startingContent.enableSelecting()
    sdspw.add startingContent

    startingContent = new SimpleLinkWdgt
    startingContent._applyExtent new Point 405, 50
    sdspw.add startingContent
    startingContent.layoutSpecDetails.setAlignmentToRight()

    startingContent = new SimpleVideoLinkWdgt
    startingContent._applyExtent new Point 405, 50
    sdspw.add startingContent
    startingContent.layoutSpecDetails.setAlignmentToRight()

    startingContent = new SimpleTextWdgt(
      "Useful characters:",nil,nil,nil,nil,nil,WorldWdgt.preferencesAndSettings.editableItemBackgroundColor, 1)
    startingContent.toggleWeight()
    startingContent.isEditable = true
    startingContent.enableSelecting()
    sdspw.add startingContent
    # in March 2018, greek chars take a long time to paint on OSX/Chrome so
    # not adding those to the paragraph, however here they are:
    # αβγδεζηθικλμνξοπρστυφχψω ΑΒΓΔΕΖΗΘΙΚΛΜΝΞΟΠΡΣΤΥΦΧΨΩ
    specialCharsParagraph = sdspw.addNormalParagraph "… †‡§ ↵⏎⇧␣ ☐☑☒✓X✗ •‣⁃◦ °±⁻¹²³µ×÷ℓΩ√∛∜∝∞∟∠∡∩∪∿≈⊂⋅⌀▫◽◻□⩽⩾ ¼½¾⅛⅜⅝⅞ ←↑→↓↔↕↵⇎⇏⇑⇒⇓⇔⇕ ©®™ $£€¥"
    specialCharsParagraph.setFontSize 16


    sdspw.makeAllContentIntoTemplates()

    wm = new FrameWdgt sdspw
    wm.setExtent new Point 370, 335
    wm.setTitleWithoutPrependedContentName "useful snippets"

    return wm
