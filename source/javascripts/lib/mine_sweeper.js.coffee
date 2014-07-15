
app = angular.module('MineSweeper', [])

app.factory 'BoardService', () ->
  mines     = 10
  height    = 8
  width     = 8
  board     = null
  neighbors = [
    [-1, -1], [0, -1], [1, -1],
    [-1,  0],          [1,  0],
    [-1,  1], [0,  1], [1,  1]
  ]

  emptyBoard = ->
    board = []

    for i in [1..width]
      line = []
      for j in [1..height]
        line.push { bomb: false, bombsAround: 0, open: false }
      board.push line

    board

  newBoard = (dimensions = {}, mine_count) ->
    width     = dimensions[0] || 8
    height    = dimensions[1] || 8
    mines     = mine_count    || 10

    emptyBoard()
    populateBoard(randomCoordinates(mines))

  randomCoordinates = (count) ->
    coordinates = []

    coordinateAlreadyChosen = (coordinate) ->
      coordinates.filter (value, index, array) ->
        value.toString() == coordinate.toString()
      .length > 0

    while coordinates.length < count
      coordinate = [Math.floor(Math.random() * width), Math.floor(Math.random() * height)]
      coordinates.push(coordinate) unless coordinateAlreadyChosen(coordinate)

    coordinates

  validNeighbors = (coordinate) ->
    neighbors.reduce (memo, current, index, array) ->
      outOfBoundaries = (coordinate) ->
        (board[coordinate[0]] == undefined) || (board[coordinate[0]][coordinate[1]] == undefined)

      adjustedCoordinate = [coordinate[0] + current[0], coordinate[1] + current[1]]

      memo.push(adjustedCoordinate) unless outOfBoundaries(adjustedCoordinate)

      memo
    , []

  populateBoard = (coordinates) ->
    coordinates.map (current, index, array) ->
      board[current[0]][current[1]].bomb = true

      validNeighbors(current).map (current, index, array) ->
        board[current[0]][current[1]].bombsAround += 1

    board

  return {
    board: ->
      board
    newBoard: newBoard
    validNeighbors: validNeighbors
  }

# the original konami code directive was in pure javascript. I just ported it to coffeescript
# and changed it so it can be fired as many times as i want
#
# angular-konami 0.2
# https://github.com/dos1/angular-konami
# based on https://gist.github.com/benajnim/5238495
app.directive "konami", ['$document', ($document) ->
  return {
    restrict: 'A'
    scope: {
        konami: '&'
    }
    link: (scope) ->
      konami_keys = [38, 38, 40, 40, 37, 39, 37, 39, 66, 65]
      index = 0

      handler = (e) ->
        if e.keyCode == konami_keys[index++]
          if index == konami_keys.length
            scope.$apply(scope.konami)
            index = 0
        else
          index = 0

      $document.on('keydown', handler)
      scope.$on '$destroy', ->
        $document.off('keydown', handler)
  }
]

app.controller 'GameController', ['$scope', 'BoardService', ($scope, BoardService) ->
  $scope.game = {
    board:{
      size: 8
    }
    difficulty: 16
    finished: false
    flag: false
    message: ''
  }

  $scope.newGame = ->
    size = $scope.game.board.size
    mines = Math.floor((size * size) * ($scope.game.difficulty / 100))

    $scope.board         = BoardService.newBoard([size, size], mines)
    $scope.game.finished = false
    $scope.game.flag     = false
    $scope.game.message  = ''

  $scope.newGame()

  $scope.cellState = (coordinate) ->
    $scope.board[coordinate[0]][coordinate[1]]

  $scope.cellText = (coordinate) ->
    cell = $scope.cellState(coordinate)

    if cell.open && !cell.bomb && cell.bombsAround > 0
      cell.bombsAround
    else
      ''

  $scope.cellClick = (coordinate) ->
    return if $scope.game.finished

    cell = $scope.cellState(coordinate)
    cell.open = true

    $scope.loss() if cell.bomb
    $scope.clickNeighbors(coordinate) if cell.bombsAround == 0 && !cell.bomb

  $scope.clickNeighbors = (coordinate) ->
    BoardService.validNeighbors(coordinate).map (current, index, array) ->
      cell = $scope.cellState(current)

      $scope.cellClick(current) unless cell.open

  $scope.validate = ->
    for line in $scope.board
      for cell in line
        return $scope.loss() if !cell.bomb && !cell.open

    $scope.victory()

  $scope.victory = ->
    $scope.game.finished = true
    $scope.game.message  = 'Victory!!! :)'

  $scope.loss = ->
    $scope.game.finished = true
    $scope.game.message  = 'Defeat... :C'

  $scope.flag = ->
    $scope.game.flag = true

]
