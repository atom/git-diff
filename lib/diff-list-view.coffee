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
    $$ ->
      @li class: 'two-lines', =>
        @div atom.workspace.getActiveEditor()?.lineForBufferRow(bufferRow), class: 'primary-line'
        @div "-#{oldStart},#{oldLines} +#{newStart},#{newLines}", class: 'secondary-line'

  populate: ->
    if editor = atom.workspace.getActiveEditor()
      diffs = atom.project.getRepo()?.getLineDiffs(editor.getPath(), editor.getText()) ? []
      @setItems(diffs)

  toggle: ->
    if @hasParent()
      @cancel()
    else
      @populate()
      @attach()

  confirmed: ({newStart})->
    @cancel()

    editorView = atom.workspaceView.getActiveView()
    if editor = editorView?.getEditor?()
      bufferRow = if newStart > 0 then newStart - 1 else newStart
      editorView.scrollToBufferPosition([bufferRow, 0], center: true)
      editor.setCursorBufferPosition([bufferRow, 0])
      editor.moveCursorToFirstCharacterOfLine()
