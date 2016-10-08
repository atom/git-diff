module.exports =
  repositoryForPath: (goalPath) ->
    for directory, i in atom.project.getDirectories()
      if goalPath is directory.getPath() or directory.contains(goalPath)
        return atom.project.getRepositories()[i]
    null

  # Return set of added/removed lines per diff, currently this is not atom repo functionality
  # so we have to use Repository from 'git-utils'
  getRichDiffsForPath: (repo, goalPath, text) ->
    gitRepo = repo?.getRepo()
    gitRepo?.getLineDiffDetails(gitRepo?.relativize(goalPath), text)

  # Whether or not 2 diffs are equal, e.g. belong to the same group
  equalDiffs: (diff1, diff2) ->
    if not diff1 or not diff2
      return false
    diff1.newLines is diff2.newLines and diff1.newStart is diff2.newStart and
      diff1.oldLines is diff2.oldLines and diff1.oldStart is diff2.oldStart
