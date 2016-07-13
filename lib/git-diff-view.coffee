{CompositeDisposable} = require 'atom'
{repositoryForPath} = require './helpers'

module.exports =
class GitDiffView
  constructor: (@editor) ->
    @subscriptions = new CompositeDisposable()
    @decorations = {}
    @markers = []

    @subscriptions.add(@editor.onDidStopChanging(@updateDiffs))
    @subscriptions.add(@editor.onDidChangePath(@updateDiffs))

    @subscribeToRepository()
    @subscriptions.add atom.project.onDidChangePaths => @subscribeToRepository()

    @subscriptions.add @editor.onDidDestroy =>
      @cancelUpdate()
      @removeDecorations()
      @subscriptions.dispose()

    editorView = atom.views.getView(@editor)

    @subscriptions.add atom.commands.add editorView, 'git-diff:move-to-next-diff', =>
      @moveToNextDiff()
    @subscriptions.add atom.commands.add editorView, 'git-diff:move-to-previous-diff', =>
      @moveToPreviousDiff()

    @subscriptions.add atom.config.onDidChange 'git-diff.showIconsInEditorGutter', =>
      @updateIconDecoration()

    @subscriptions.add atom.config.onDidChange 'editor.showLineNumbers', =>
      @updateIconDecoration()

    editorElement = atom.views.getView(@editor)
    @subscriptions.add editorElement.onDidAttach =>
      @updateIconDecoration()

    @updateIconDecoration()
    @scheduleUpdate()

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

  updateIconDecoration: ->
    gutter = atom.views.getView(@editor).rootElement?.querySelector('.gutter')
    if atom.config.get('editor.showLineNumbers') and atom.config.get('git-diff.showIconsInEditorGutter')
      gutter?.classList.add('git-diff-icon')
    else
      gutter?.classList.remove('git-diff-icon')

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
      @editor.moveToFirstCharacterOfLine()

  subscribeToRepository: ->
    if @repository = repositoryForPath(@editor.getPath())
      @subscriptions.add @repository.onDidChangeStatuses =>
        @scheduleUpdate()
      @subscriptions.add @repository.onDidChangeStatus (changedPath) =>
        @scheduleUpdate() if changedPath is @editor.getPath()

  cancelUpdate: ->
    clearImmediate(@immediateId)

  scheduleUpdate: ->
    @cancelUpdate()
    @immediateId = setImmediate(@updateDiffs)

  updateDiffs: =>
    return if @editor.isDestroyed()

    @removeDecorations()
    if path = @editor?.getPath()
      if @diffs = @repository?.getLineDiffs(path, @editor.getText())
        @addDecorations(@diffs)

  addDecorations: (diffs) ->
    for {oldStart, newStart, oldLines, newLines} in diffs
      startRow = newStart - 1
      endRow = newStart + newLines - 1
      if oldLines is 0 and newLines > 0
        @markRange(startRow, endRow, 'git-line-added')
      else if newLines is 0 and oldLines > 0
        @markRange(startRow, startRow, 'git-line-removed')
      else
        @markRange(startRow, endRow, 'git-line-modified')
    return

  removeDecorations: ->
    marker.destroy() for marker in @markers
    @markers = []

  markRange: (startRow, endRow, klass) ->
    marker = @editor.markBufferRange([[startRow, 0], [endRow, 0]], invalidate: 'never')
    @editor.decorateMarker(marker, type: 'line-number', class: klass)
    @markers.push(marker)
