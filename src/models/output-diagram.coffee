#
# Exports the diagram stream representing the output diagram.
#
Rx = require 'rx'
Utils = require 'rxmarbles/models/utils'
InputDiagrams = require 'rxmarbles/models/input-diagrams'
# TODO Change below with SandboxModel.example
OperatorsMenuModel = require 'rxmarbles/models/operators-menu'

MAXTIME = 100 # Time of completion

outputDiagramStream = InputDiagrams.continuous$
  .filter((x) -> x isnt null)
  .flatMapLatest((arrayOfDiagramStreams) ->
    return Rx.Observable.combineLatest(arrayOfDiagramStreams, (args...) -> args)
  )
  .combineLatest(OperatorsMenuModel.selectedExample$, (diagrams, example) ->
    vtscheduler = Utils.makeScheduler()
    inputVTStreams = (Utils.toVTStream(d, vtscheduler) for d in diagrams)
    outputVTStream = example["apply"](inputVTStreams, vtscheduler)
    # Necessary correction to include marbles at exactly 100.01
    correctedMaxTime = MAXTIME + 0.02
    outputVTStream = outputVTStream.takeUntilWithTime(correctedMaxTime, vtscheduler)
    outputDiagram = Utils.getDiagramPromise(outputVTStream, vtscheduler, MAXTIME)
    vtscheduler.start()
    return outputDiagram
  )
  .mergeAll()

module.exports = outputDiagramStream