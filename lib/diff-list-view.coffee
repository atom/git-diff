{$$, SelectListView} = require 'atom-space-pen-views'
{repositoryForPath, getRichDiffsForPath, equalDiffs} = require './helpers'

module.exports =
class DiffListView extends SelectListView
  initialize: ->
    super
    @panel = atom.workspace.addModalPanel(item: this, visible: false)
    @addClass('diff-list-view')

  getEmptyMessage: (itemCount) ->
    if itemCount is 0
      'No diffs in file'
    else
      super

  getFilterKey: ->
    'lineText'

  attach: ->
    @storeFocusedElement()
    @panel.show()
    @focusFilterEditor()

  viewForItem: ({oldStart, newStart, oldLines, newLines, lineText, exceedsLimit, richLines}) ->
    $$ ->
      @li class: 'two-lines', =>
        @div class: 'primary-line', =>
          for richDiff in richLines
            if richDiff.newLineNumber is -1
              # removed line, prepend '-' and mark as deleted
              @code "- #{richDiff.line}", class: 'diff-line removed'
            else if richDiff.oldLineNumber is -1
              # added line, prepend '+' and mark as new
              @code "+ #{richDiff.line}", class: 'diff-line added'
          if exceedsLimit
            @div "... more lines", class: 'diff-line more-lines'
        @div "-#{oldStart},#{oldLines} +#{newStart},#{newLines}", class: 'secondary-line'

  populate: ->
    repo = repositoryForPath(@editor.getPath())
    diffs = repo?.getLineDiffs(@editor.getPath(), @editor.getText()) ? []
    richDiffs = getRichDiffsForPath(repo, @editor.getPath(), @editor.getText()) ? []
    limit = 12 # limit displayed lines per diff, will show message with "... more lines"
    for diff in diffs
      diff.richLines = [] # corresponding lines for this range diff
      diff.exceedsLimit = false # whether or not all lines are included
    i = j = 0
    while i < diffs.length and j < richDiffs.length
      if equalDiffs(diffs[i], richDiffs[j])
        if not diffs[i].exceedsLimit
          diffs[i].richLines.push richDiffs[j]
          diffs[i].exceedsLimit = diffs[i].richLines.length >= limit
        j += 1
      else
        i += 1 # current rich diff belongs to the next diff
    @setItems(diffs)

  toggle: ->
    if @panel.isVisible()
      @cancel()
    else if @editor = atom.workspace.getActiveTextEditor()
      @populate()
      @attach()

  cancelled: ->
    @panel.hide()

  confirmed: ({newStart}) ->
    @cancel()

    bufferRow = if newStart > 0 then newStart - 1 else newStart
    @editor.setCursorBufferPosition([bufferRow, 0], autoscroll: true)
    @editor.moveToFirstCharacterOfLine()
