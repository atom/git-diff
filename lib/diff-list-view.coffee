{$$, SelectListView} = require 'atom'

module.exports =
class DiffListView extends SelectListView
  initialize: ->
    super
    @addClass('symbols-view overlay from-top')

  attach: ->
    @storeFocusedElement()
    atom.workspaceView.appendToTop(this)
    @focusFilterEditor()

  viewForItem: ({oldStart, newStart, oldLines, newLines}) ->
    bufferRow = if newStart > 0 then newStart - 1 else newStart
    lineText = @editor.lineForBufferRow(bufferRow) ? ''
    $$ ->
      @li class: 'two-lines', =>
        @div lineText, class: 'primary-line'
        @div "-#{oldStart},#{oldLines} +#{newStart},#{newLines}", class: 'secondary-line'

  populate: ->
    diffs = atom.project.getRepo()?.getLineDiffs(@editor.getPath(), @editor.getText()) ? []
    @setItems(diffs)

  toggle: ->
    if @hasParent()
      @cancel()
    else if @editor = atom.workspace.getActiveEditor()
      @populate()
      @attach()

  confirmed: ({newStart})->
    @cancel()

    bufferRow = if newStart > 0 then newStart - 1 else newStart
    @editor.setCursorBufferPosition([bufferRow, 0], autoscroll: true)
    @editor.moveCursorToFirstCharacterOfLine()
