path = require 'path'
{fs, WorkspaceView} = require 'atom'

describe "GitDiff package", ->
  [editor, editorView, projectPath] = []

  beforeEach ->
    projectPath = atom.project.resolve('working-dir')
    fs.moveSync(path.join(projectPath, 'git.git'), path.join(projectPath, '.git'))
    atom.project.setPath(projectPath)

    atom.workspaceView = new WorkspaceView
    atom.workspaceView.attachToDom()
    atom.workspaceView.openSync('sample.js')
    atom.packages.activatePackage('git-diff')
    editorView = atom.workspaceView.getActiveView()
    {editor} = editorView

  afterEach ->
    fs.moveSync(path.join(projectPath, '.git'), path.join(projectPath, 'git.git'))

  describe "when the editor has modified lines", ->
    it "highlights the modified lines", ->
      expect(editorView.find('.git-line-modified').length).toBe 0
      editor.insertText('a')
      advanceClock(editor.getBuffer().stoppedChangingDelay)
      expect(editorView.find('.git-line-modified').length).toBe 1
      expect(editorView.find('.git-line-modified')).toHaveClass('line-number-0')

  describe "when the editor has added lines", ->
    it "highlights the added lines", ->
      expect(editorView.find('.git-line-added').length).toBe 0
      editor.moveCursorToEndOfLine()
      editor.insertNewline()
      editor.insertText('a')
      advanceClock(editor.getBuffer().stoppedChangingDelay)
      expect(editorView.find('.git-line-added').length).toBe 1
      expect(editorView.find('.git-line-added')).toHaveClass('line-number-1')

  describe "when the editor has removed lines", ->
    it "highlights the line preceeding the deleted lines", ->
      expect(editorView.find('.git-line-added').length).toBe 0
      editor.setCursorBufferPosition([5])
      editor.deleteLine()
      advanceClock(editor.getBuffer().stoppedChangingDelay)
      expect(editorView.find('.git-line-removed').length).toBe 1
      expect(editorView.find('.git-line-removed')).toHaveClass('line-number-4')

  describe "when a modified line is restored to the HEAD version contents", ->
    it "removes the diff highlight", ->
      expect(editorView.find('.git-line-modified').length).toBe 0
      editor.insertText('a')
      advanceClock(editor.getBuffer().stoppedChangingDelay)
      expect(editorView.find('.git-line-modified').length).toBe 1
      editor.backspace()
      advanceClock(editor.getBuffer().stoppedChangingDelay)
      expect(editorView.find('.git-line-modified').length).toBe 0

  describe "when a modified file is opened", ->
    it "highlights the changed lines", ->
      filePath = atom.project.resolve('sample.txt')
      buffer = atom.project.bufferForPathSync(filePath)
      buffer.setText("Some different text.")
      atom.workspaceView.openSync('sample.txt')
      editorView = atom.workspaceView.getActiveView()
      nextTick = false
      setImmediate -> nextTick = true
      waitsFor -> nextTick
      runs ->
        expect(editorView.find('.git-line-modified').length).toBe 1
        expect(editorView.find('.git-line-modified')).toHaveClass('line-number-0')

  describe "move-to-next-diff/move-to-previous-diff events", ->
    it "moves the cursor to first character of the next/previous diff line", ->
      editor.insertText('a')
      editor.setCursorBufferPosition([5])
      editor.deleteLine()
      advanceClock(editor.getBuffer().stoppedChangingDelay)

      editor.setCursorBufferPosition([0])
      editorView.trigger 'git-diff:move-to-next-diff'
      expect(editor.getCursorBufferPosition()).toEqual [4, 4]

      spyOn(atom, 'beep')
      editorView.trigger 'git-diff:move-to-next-diff'
      expect(atom.beep.callCount).toBe 1

      editorView.trigger 'git-diff:move-to-previous-diff'
      expect(editor.getCursorBufferPosition()).toEqual [0, 0]

      atom.beep.reset()
      editorView.trigger 'git-diff:move-to-previous-diff'
      expect(atom.beep.callCount).toBe 1
