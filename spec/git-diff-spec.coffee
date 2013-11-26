path = require 'path'
{fs, WorkspaceView} = require 'atom'

describe "GitDiff package", ->
  [editor, projectPath] = []

  beforeEach ->
    projectPath = atom.project.resolve('working-dir')
    fs.moveSync(path.join(projectPath, 'git.git'), path.join(projectPath, '.git'))
    atom.project.setPath(projectPath)

    atom.workspaceView = new WorkspaceView
    atom.workspaceView.attachToDom()
    atom.workspaceView.openSync('sample.js')
    atom.packages.activatePackage('git-diff')
    editor = atom.workspaceView.getActiveView()

  afterEach ->
    fs.moveSync(path.join(projectPath, '.git'), path.join(projectPath, 'git.git'))

  describe "when the editor has modified lines", ->
    it "highlights the modified lines", ->
      expect(editor.find('.git-line-modified').length).toBe 0
      editor.insertText('a')
      advanceClock(editor.getBuffer().stoppedChangingDelay)
      expect(editor.find('.git-line-modified').length).toBe 1
      expect(editor.find('.git-line-modified')).toHaveClass('line-number-0')

  describe "when the editor has added lines", ->
    it "highlights the added lines", ->
      expect(editor.find('.git-line-added').length).toBe 0
      editor.moveCursorToEndOfLine()
      editor.insertNewline()
      editor.insertText('a')
      advanceClock(editor.getBuffer().stoppedChangingDelay)
      expect(editor.find('.git-line-added').length).toBe 1
      expect(editor.find('.git-line-added')).toHaveClass('line-number-1')

  describe "when the editor has removed lines", ->
    it "highlights the line preceeding the deleted lines", ->
      expect(editor.find('.git-line-added').length).toBe 0
      editor.setCursorBufferPosition([5])
      editor.deleteLine()
      advanceClock(editor.getBuffer().stoppedChangingDelay)
      expect(editor.find('.git-line-removed').length).toBe 1
      expect(editor.find('.git-line-removed')).toHaveClass('line-number-4')

  describe "when a modified line is restored to the HEAD version contents", ->
    it "removes the diff highlight", ->
      expect(editor.find('.git-line-modified').length).toBe 0
      editor.insertText('a')
      advanceClock(editor.getBuffer().stoppedChangingDelay)
      expect(editor.find('.git-line-modified').length).toBe 1
      editor.backspace()
      advanceClock(editor.getBuffer().stoppedChangingDelay)
      expect(editor.find('.git-line-modified').length).toBe 0

  describe "when a modified file is opened", ->
    it "highlights the changed lines", ->
      filePath = atom.project.resolve('sample.txt')
      buffer = atom.project.bufferForPathSync(filePath)
      buffer.setText("Some different text.")
      atom.workspaceView.openSync('sample.txt')
      editor = atom.workspaceView.getActiveView()
      nextTick = false
      setImmediate -> nextTick = true
      waitsFor -> nextTick
      runs ->
        expect(editor.find('.git-line-modified').length).toBe 1
        expect(editor.find('.git-line-modified')).toHaveClass('line-number-0')
