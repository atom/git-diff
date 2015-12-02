GitDiffView = require './git-diff-view'
DiffListView = null

diffListView = null
toggleDiffList = ->
  DiffListView ?= require './diff-list-view'
  diffListView ?= new DiffListView()
  diffListView.toggle()

module.exports =
  config:
    highlightBackgroundInEditorGutter:
      type: 'boolean'
      default: false
      description: 'Highlight the background color in the editor\'s gutter.'
    showIconsInEditorGutter:
      type: 'boolean'
      default: false
      description: 'Show colored icons for added (`+`), modified (`·`) and removed (`-`) lines in the editor\'s gutter, instead of colored markers (`|`).'

  activate: ->
    atom.workspace.observeTextEditors (editor) ->
      new GitDiffView(editor)
      atom.commands.add(atom.views.getView(editor), 'git-diff:toggle-diff-list', toggleDiffList)

  deactivate: ->
    diffListView?.cancel()
    diffListView = null
