GitDiffView = require './git-diff-view'
DiffListView = require './diff-list-view'

diffListView = null

module.exports =
  activate: ->
    watchedEditors = new WeakSet()

    atom.workspace.observeTextEditors (editor) ->
      return if watchedEditors.has(editor)

      new GitDiffView(editor)
      atom.commands.add atom.views.getView(editor), 'git-diff:toggle-diff-list', ->
        diffListView ?= new DiffListView()
        diffListView.toggle()

      watchedEditors.add(editor)
      editor.onDidDestroy -> watchedEditors.delete(editor)

  deactivate: ->
    diffListView?.destroy()
    diffListView = null
