{_, Subscriber} = require 'atom'

module.exports =
class GitDiffView
  _.extend @prototype, Subscriber
  classes: ['git-line-added', 'git-line-modified', 'git-line-removed']

  constructor: (@editor) ->
    @gutter = @editor.gutter
    @diffs = {}

    @subscribe @editor, 'editor:path-changed', @subscribeToBuffer
    @subscribe @editor, 'editor:display-updated', @renderDiffs
    @subscribe project.getRepo(), 'statuses-changed', =>
      @diffs = {}
      @scheduleUpdate()
    @subscribe project.getRepo(), 'status-changed', (path) =>
      delete @diffs[path]
      @scheduleUpdate() if path is @editor.getPath()

    @subscribeToBuffer()

    @subscribe @editor, 'editor:will-be-removed', =>
      @unsubscribe()
      @unsubscribeFromBuffer()

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
    _.nextTick(@updateDiffs)

  updateDiffs: =>
    return unless @buffer?
    @generateDiffs()
    @renderDiffs()

  generateDiffs: ->
    if path = @buffer.getPath()
      @diffs[path] = project.getRepo()?.getLineDiffs(path, @buffer.getText())

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
