GitDiffView = require './git-diff-view'
DiffListView = null

diffListView = null
toggleDiffList = ->
  DiffListView ?= require './diff-list-view'
  diffListView ?= new DiffListView()
  diffListView.toggle()

module.exports =
  activate: ->
    atom.workspace.observeTextEditors (editor) ->
      new GitDiffView(editor)
      atom.commands.add(atom.views.getView(editor), 'git-diff:toggle-diff-list', toggleDiffList)

  deactivate: ->
    diffListView?.cancel()
    diffListView = null
