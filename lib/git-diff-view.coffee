{Subscriber} = require 'emissary'

module.exports =
class GitDiffView
  Subscriber.includeInto(this)

  classes: ['git-line-added', 'git-line-modified', 'git-line-removed']

  constructor: (@editorView) ->
    {@editor, @gutter} = @editorView
    @diffs = {}

    @subscribe @editorView, 'editor:path-changed', @subscribeToBuffer
    @subscribe @editorView, 'editor:display-updated', @renderDiffs
    @subscribe atom.project.getRepo(), 'statuses-changed', =>
      @diffs = {}
      @scheduleUpdate()
    @subscribe atom.project.getRepo(), 'status-changed', (path) =>
      delete @diffs[path]
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
    hunks = @diffs[@editor.getPath()] ? []
    for {newStart} in hunks
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
    hunks = @diffs[@editor.getPath()] ? []
    for {newStart} in hunks
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
      @removeDiffs()
      delete @diffs[@buffer.getPath()] if @buffer.destroyed
      @buffer.off 'contents-modified', @updateDiffs
      @buffer = null

  subscribeToBuffer: =>
    @unsubscribeFromBuffer()

    if @buffer = @editor.getBuffer()
      @scheduleUpdate() unless @diffs[@buffer.getPath()]?
      @buffer.on 'contents-modified', @updateDiffs

  scheduleUpdate: ->
    setImmediate(@updateDiffs)

  updateDiffs: =>
    return unless @buffer?
    @generateDiffs()
    @renderDiffs()

  generateDiffs: ->
    if path = @buffer.getPath()
      @diffs[path] = atom.project.getRepo()?.getLineDiffs(path, @buffer.getText())

  removeDiffs: =>
    if @gutter.hasGitLineDiffs
      @gutter.removeClassFromAllLines(klass) for klass in @classes
      @gutter.hasGitLineDiffs = false

  renderDiffs: =>
    return unless @gutter.isVisible()

    @removeDiffs()

    hunks = @diffs[@editor.getPath()] ? []
    linesHighlighted = false
    for {oldStart, newStart, oldLines, newLines} in hunks
      if oldLines is 0 and newLines > 0
        for row in [newStart...newStart + newLines]
          linesHighlighted |= @gutter.addClassToLine(row - 1, 'git-line-added')
      else if newLines is 0 and oldLines > 0
        linesHighlighted |= @gutter.addClassToLine(newStart - 1, 'git-line-removed')
      else
        for row in [newStart...newStart + newLines]
          linesHighlighted |= @gutter.addClassToLine(row - 1, 'git-line-modified')
    @gutter.hasGitLineDiffs = linesHighlighted
