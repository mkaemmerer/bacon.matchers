init = (Bacon) ->
  toFieldExtractor = (f) ->
    parts = f.slice(1).split(".")
    partFuncs = Bacon._.map(toSimpleExtractor, parts)
    (value) ->
      for f in partFuncs
        value = f(value)
      value
  toSimpleExtractor = (key) -> (value) ->
    if not value?
      undefined
    else
      value[key]

  addMatchers = (apply1, apply2, apply3) ->
    context = addPositiveMatchers apply1, apply2, apply3
    context["not"] = ->
      applyNot1 = (f) -> apply1 (a) -> not f(a)
      applyNot2 = (f) -> apply2 (a, b) -> not f(a, b)
      applyNot3 = (f) -> apply3 (val, a, b) -> not f(val, a, b)
      addPositiveMatchers applyNot1, applyNot2, applyNot3
    context

  addPositiveMatchers = (apply1, apply2, apply3) ->
    context = {}
    context["lessThan"] = apply2((a, b) ->
      a < b
    )
    context["lessThanOrEqualTo"] = apply2((a, b) ->
      a <= b
    )
    context["greaterThan"] = apply2((a, b) ->
      a > b
    )
    context["greaterThanOrEqualTo"] = apply2((a, b) ->
      a >= b
    )
    context["equalTo"] = apply2((a, b) ->
      a is b
    )
    context["truthy"] = apply1((a) ->
      !!a
    )
    context["match"] = apply2((val, pattern) ->
      pattern.test val
    )
    context["inOpenRange"] = apply3((val, a, b) ->
      a < val < b
    )
    context["inClosedRange"] = apply3((val, a, b) ->
      a <= val <= b
    )
    context["containerOf"] = apply2((a, b) ->
      if a instanceof Array or typeof a == 'string'
        a.indexOf(b) >= 0
      else if typeof a == 'object'
        matchingKeyValuePairs = 0
        Object.keys(b).forEach (bKey) -> # Object.keys works in IE9 and above
          aHasBKeyAndValue = a.hasOwnProperty(bKey) and a[bKey] == b[bKey]
          if aHasBKeyAndValue
            matchingKeyValuePairs += 1
        aHasAllKeyValuesOfB = matchingKeyValuePairs == Object.keys(b).length
        bIsNotEmpty = Object.keys(b).length > 0
        aHasAllKeyValuesOfB and bIsNotEmpty
      else
        false
    )
    context
  asMatchers = (operation, combinator, fieldKey) ->
        field = if fieldKey? then toFieldExtractor(fieldKey) else Bacon._.id
        apply1 = (f) ->
          ->
            operation (val) -> f(field(val))
        apply2 = (f) ->
          (other) ->
            if other instanceof Bacon.Observable
              combinator other, (val, other) -> f(field(val), other)
            else
              operation (val) -> f(field(val), other)
        apply3 = (f) ->
          (first, second) ->
            operation (val) -> f(field(val), first, second)
        addMatchers apply1, apply2, apply3
  Bacon.Observable::is = (fieldKey) ->
    context = this
    operation = (f) -> context.map(f)
    combinator = (observable, f) -> context.combine(observable, f)
    asMatchers(operation, combinator, fieldKey)
  Bacon.Observable::where = (fieldKey) ->
    context = this
    operation = (f) -> context.filter(f)
    combinator = (observable, f) -> context.filter context.combine(observable, f)
    asMatchers(operation, combinator, fieldKey)
  Bacon

if module?
  Bacon = require("baconjs")
  module.exports = init(Bacon)
else
  if typeof require is "function"
    define "bacon.matchers", ["bacon"], init
  else
    init(this.Bacon)
