GitDiffView = require './git-diff-view'
DiffListView = null

diffListView = null
toggleDiffList = ->
  DiffListView ?= require './diff-list-view'
  diffListView ?= new DiffListView()
  diffListView.toggle()

module.exports =
  config:
    showIconsInEditorGutter:
      type: 'boolean'
      default: false

  activate: ->
    atom.workspace.observeTextEditors (editor) ->
      return unless atom.project.getRepositories()[0]?

      new GitDiffView(editor)
      atom.commands.add(atom.views.getView(editor), 'git-diff:toggle-diff-list', toggleDiffList)

  deactivate: ->
    diffListView?.cancel()
    diffListView = null
