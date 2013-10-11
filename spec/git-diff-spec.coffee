path = require 'path'
{_, fs, RootView} = require 'atom'

repoPath = path.join(__dirname, 'fixtures', 'working-dir')

beforeEach ->
  fs.move(path.join(repoPath, 'git.git'), path.join(repoPath, '.git'))

afterEach ->
  fs.move(path.join(repoPath, '.git'), path.join(repoPath, 'git.git'))

describe "GitDiff package", ->
  editor = null

  beforeEach ->
    project.setPath(repoPath)
    window.rootView = new RootView
    rootView.attachToDom()
    rootView.open('sample.js')
    atom.activatePackage('git-diff')
    editor = rootView.getActiveView()

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
      filePath = project.resolve('sample.txt')
      buffer = project.buildBuffer(filePath)
      buffer.setText("Some different text.")
      rootView.open('sample.txt')
      editor = rootView.getActiveView()
      nextTick = false
      _.nextTick -> nextTick = true
      waitsFor -> nextTick
      runs ->
        expect(editor.find('.git-line-modified').length).toBe 1
        expect(editor.find('.git-line-modified')).toHaveClass('line-number-0')
