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
    atom.workspaceView.eachEditorView (editorView) ->
      if atom.project.getRepositories()[0]? and editorView.attached and editorView.getPane()?
        new GitDiffView(editorView)

        editorView.command 'git-diff:toggle-diff-list', toggleDiffList
