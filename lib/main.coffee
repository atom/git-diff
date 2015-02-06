GitDiffView = null
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
      return if atom.project.getRepositories().length is 0

      GitDiffView ?= require './git-diff-view'
      new GitDiffView(editor)

    atom.commands.add('atom-text-editor', 'git-diff:toggle-diff-list', toggleDiffList)

  deactivate: ->
    diffListView?.cancel()
    diffListView = null
