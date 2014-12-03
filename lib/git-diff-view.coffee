{Subscriber} = require 'emissary'
{CompositeDisposable} = require 'atom'

module.exports =
class GitDiffView
  Subscriber.includeInto(this)

  constructor: (@editorView) ->
    @subscriptions = new CompositeDisposable()
    {@editor, @gutter} = @editorView
    @decorations = {}
    @markers = null

    @subscribe @editorView, 'editor:path-changed', @subscribeToBuffer

    atom.project.getRepositories().forEach (repository) =>
      @subscriptions.add repository.onDidChangeStatuses =>
        @scheduleUpdate()
      @subscriptions.add repository.onDidChangeStatus (changedPath) =>
        @scheduleUpdate() if changedPath is @editor.getPath()

    @subscribeToBuffer()

    @subscriptions.add @editor.onDidDestroy =>
      @cancelUpdate()
      @unsubscribe()
      @unsubscribeFromBuffer()
      @subscriptions.dispose()

    @subscribeToCommand @editorView, 'git-diff:move-to-next-diff', =>
      @moveToNextDiff()
    @subscribeToCommand @editorView, 'git-diff:move-to-previous-diff', =>
      @moveToPreviousDiff()

    @subscribe atom.config.observe 'git-diff.showIconsInEditorGutter', =>
      if atom.config.get 'git-diff.showIconsInEditorGutter'
        @gutter.addClass('git-diff-icon')
      else
        @gutter.removeClass('git-diff-icon')

    @subscribe atom.config.observe 'editor.showLineNumbers', =>
      {@gutter} = @editorView
      if atom.config.get('editor.showLineNumbers') and atom.config.get('git-diff.showIconsInEditorGutter')
        @gutter.addClass('git-diff-icon')

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

  cancelUpdate: ->
    clearImmediate(@immediateId)

  scheduleUpdate: ->
    @cancelUpdate()
    @immediateId = setImmediate(@updateDiffs)

  updateDiffs: =>
    return if @editor.isDestroyed()

    @removeDecorations()
    if path = @buffer?.getPath()
      if @diffs = atom.project.getRepo()?.getLineDiffs(path, @buffer.getText())
        @addDecorations(@diffs)

  addDecorations: (diffs) ->
    for {oldStart, newStart, oldLines, newLines} in diffs
      startRow = newStart - 1
      endRow = newStart + newLines - 2
      if oldLines is 0 and newLines > 0
        @markRange(startRow, endRow, 'git-line-added')
      else if newLines is 0 and oldLines > 0
        @markRange(startRow, startRow, 'git-line-removed')
      else
        @markRange(startRow, endRow, 'git-line-modified')
    return

  removeDecorations: ->
    return unless @markers?
    marker.destroy() for marker in @markers
    @markers = null

  markRange: (startRow, endRow, klass) ->
    marker = @editor.markBufferRange([[startRow, 0], [endRow, Infinity]], invalidate: 'never')
    @editor.decorateMarker(marker, type: 'gutter', class: klass)
    @markers ?= []
    @markers.push(marker)
