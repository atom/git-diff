{$$, SelectListView} = require 'atom-space-pen-views'
{repositoryForPath} = require './helpers'

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

  viewForItem: ({oldStart, newStart, oldLines, newLines, lineText}) ->
    $$ ->
      @li class: 'two-lines', =>
        @div lineText, class: 'primary-line'
        @div "-#{oldStart},#{oldLines} +#{newStart},#{newLines}", class: 'secondary-line'

  populate: ->
    diffs = repositoryForPath(@editor.getPath())?.getLineDiffs(@editor.getPath(), @editor.getText()) ? []
    for diff in diffs
      bufferRow = if diff.newStart > 0 then diff.newStart - 1 else diff.newStart
      diff.lineText = @editor.lineTextForBufferRow(bufferRow)?.trim() ? ''
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
