{Directory} = require 'atom'

module.exports =
  repositoryForPath: (goalPath) ->
    goalDir = new Directory(goalPath)
    atom.project.repositoryForDirectory(goalDir)
