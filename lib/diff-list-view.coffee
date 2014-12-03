{$$, SelectListView} = require 'atom'

module.exports =
class DiffListView extends SelectListView
  initialize: ->
    super
    @addClass('diff-list-view overlay from-top')

  getEmptyMessage: (itemCount) ->
    if itemCount is 0
      'No diffs in file'
    else
      super

  getFilterKey: ->
    'lineText'

  attach: ->
    @storeFocusedElement()
    atom.workspaceView.appendToTop(this)
    @focusFilterEditor()

  viewForItem: ({oldStart, newStart, oldLines, newLines, lineText}) ->
    $$ ->
      @li class: 'two-lines', =>
        @div lineText, class: 'primary-line'
        @div "-#{oldStart},#{oldLines} +#{newStart},#{newLines}", class: 'secondary-line'

  populate: ->
    diffs = atom.project.getRepositories()[0]?.getLineDiffs(@editor.getPath(), @editor.getText()) ? []
    for diff in diffs
      bufferRow = if diff.newStart > 0 then diff.newStart - 1 else diff.newStart
      diff.lineText = @editor.lineTextForBufferRow(bufferRow)?.trim() ? ''
    @setItems(diffs)

  toggle: ->
    if @hasParent()
      @cancel()
    else if @editor = atom.workspace.getActiveTextEditor()
      @populate()
      @attach()

  confirmed: ({newStart})->
    @cancel()

    bufferRow = if newStart > 0 then newStart - 1 else newStart
    @editor.setCursorBufferPosition([bufferRow, 0], autoscroll: true)
    @editor.moveToFirstCharacterOfLine()
