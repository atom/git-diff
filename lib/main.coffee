GitDiffView = require './git-diff-view'
DiffListView = require './diff-list-view'

diffListView = null

module.exports =
  activate: ->
    atom.workspace.observeTextEditors (editor) ->
      new GitDiffView(editor)
      atom.commands.add atom.views.getView(editor), 'git-diff:toggle-diff-list', ->
        diffListView ?= new DiffListView()
        diffListView.toggle()

  deactivate: ->
    diffListView?.destroy()
    diffListView = null
