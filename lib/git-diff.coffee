GitDiffView = require './git-diff-view'

module.exports =
  activate: ->
    atom.rootView.eachEditor (editor) =>
      if atom.project.getRepo()? and editor.attached and editor.getPane()?
        new GitDiffView(editor)
