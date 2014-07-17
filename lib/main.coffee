GitDiffView = require './git-diff-view'
ReactGitDiffView = require './react-git-diff-view'
DiffListView = null


diffListView = null
toggleDiffList = ->
  DiffListView ?= require './diff-list-view'
  diffListView ?= new DiffListView()
  diffListView.toggle()

module.exports =
  configDefaults:
    showIconsInEditorGutter: false

  activate: ->
    atom.workspaceView.eachEditorView (editorView) ->
      if atom.project.getRepo()? and editorView.attached and editorView.getPane()?
        if editorView.hasClass('react')
          new ReactGitDiffView(editorView)
        else
          new GitDiffView(editorView)

        editorView.command 'git-diff:toggle-diff-list', toggleDiffList
