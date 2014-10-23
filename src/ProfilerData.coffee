class ProfilerData
  
  @reactiveValues_valueRecalculations: 0
  @reactiveValues_signatureCalculations: 0
  @reactiveValues_signatureComparison: 0
  @reactiveValues_argumentInvalidations: 0
  @reactiveValues_valueInvalidations: 0
  @reactiveValues_parentValuesRechecks: 0
  @reactiveValues_createdGroundVals: 0
  @reactiveValues_createdBasicCalculatedValues: 0

  @resetReactiveValuesCounts: ->
    @reactiveValues_valueRecalculations = 0
    @reactiveValues_signatureCalculations = 0
    @reactiveValues_signatureComparison = 0
    @reactiveValues_argumentInvalidations = 0
    @reactiveValues_valueInvalidations = 0
    @reactiveValues_parentValuesRechecks = 0
    @reactiveValues_createdGroundVals = 0
    @reactiveValues_createdBasicCalculatedValues = 0


