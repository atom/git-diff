{Subscriber} = require 'emissary'

module.exports =
class ReactGitDiffView
  Subscriber.includeInto(this)

  constructor: (@editorView) ->
    {@editor, @gutter} = @editorView
    @decorations = {}

    @subscribe @editorView, 'editor:path-changed', @subscribeToBuffer
    @subscribe atom.project.getRepo(), 'statuses-changed', =>
      @decorations = {}
      @scheduleUpdate()
    @subscribe atom.project.getRepo(), 'status-changed', (path) =>
      @scheduleUpdate() if path is @editor.getPath()

    @subscribeToBuffer()

    @subscribe @editorView, 'editor:will-be-removed', =>
      @unsubscribe()
      @unsubscribeFromBuffer()

    @subscribeToCommand @editorView, 'git-diff:move-to-next-diff', =>
      @moveToNextDiff()
    @subscribeToCommand @editorView, 'git-diff:move-to-previous-diff', =>
      @moveToPreviousDiff()

    @subscribe atom.config.observe 'git-diff.showIconsInEditorGutter', =>
      if atom.config.get 'git-diff.showIconsInEditorGutter'
        @gutter.addClass('git-diff-icon')
      else
        @gutter.removeClass('git-diff-icon')

  moveToNextDiff: ->
    cursorLineNumber = @editor.getCursorBufferPosition().row + 1
    nextDiffLineNumber = null
    firstDiffLineNumber = null
    for {newStart} in @diffs ? []
      if newStart > cursorLineNumber
        nextDiffLineNumber ?= newStart - 1
        nextDiffLineNumber = Math.min(newStart - 1, nextDiffLineNumber)

      firstDiffLineNumber ?= newStart - 1
      firstDiffLineNumber = Math.min(newStart - 1, firstDiffLineNumber)

    # Wrap around to the first diff in the file
    nextDiffLineNumber = firstDiffLineNumber unless nextDiffLineNumber?

    @moveToLineNumber(nextDiffLineNumber)

  moveToPreviousDiff: ->
    cursorLineNumber = @editor.getCursorBufferPosition().row + 1
    previousDiffLineNumber = -1
    lastDiffLineNumber = -1
    for {newStart} in @diffs ? []
      if newStart < cursorLineNumber
        previousDiffLineNumber = Math.max(newStart - 1, previousDiffLineNumber)
      lastDiffLineNumber = Math.max(newStart - 1, lastDiffLineNumber)

    # Wrap around to the last diff in the file
    previousDiffLineNumber = lastDiffLineNumber if previousDiffLineNumber is -1

    @moveToLineNumber(previousDiffLineNumber)

  moveToLineNumber: (lineNumber=-1) ->
    if lineNumber >= 0
      @editor.setCursorBufferPosition([lineNumber, 0])
      @editor.moveCursorToFirstCharacterOfLine()

  unsubscribeFromBuffer: ->
    if @buffer?
      @removeDecorations()
      @buffer.off 'contents-modified', @updateDiffs
      @buffer = null

  subscribeToBuffer: =>
    @unsubscribeFromBuffer()

    if @buffer = @editor.getBuffer()
      @scheduleUpdate()
      @buffer.on 'contents-modified', @updateDiffs

  scheduleUpdate: ->
    setImmediate(@updateDiffs)

  updateDiffs: =>
    @removeDecorations(@decorations)
    if path = @buffer?.getPath()
      if @diffs = atom.project.getRepo()?.getLineDiffs(path, @buffer.getText())
        @decorations = @generateDecorations(@diffs)
        @addDecorations(@decorations)

  generateDecorations: (diffs) ->
    decorations = {}

    for {oldStart, newStart, oldLines, newLines} in diffs
      if oldLines is 0 and newLines > 0
        for row in [newStart...newStart + newLines]
          decorations[row - 1] = {type: 'gutter', class: 'git-line-added'}
      else if newLines is 0 and oldLines > 0
        decorations[newStart - 1] = {type: 'gutter', class: 'git-line-removed'}
      else
        for row in [newStart...newStart + newLines]
          decorations[row - 1] = {type: 'gutter', class: 'git-line-modified'}

    decorations

  removeDecorations: (decorations) =>
    return unless decorations?
    for bufferRow, decoration of decorations
      @editor.removeDecorationFromBufferRow(bufferRow, decoration)
    return

  addDecorations: (decorations) =>
    return unless decorations?
    for bufferRow, decoration of decorations
      @editor.addDecorationToBufferRow(bufferRow, decoration)
    return
