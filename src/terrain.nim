# This is just an example to get you started. A typical hybrid package
# uses this file as the main entry point of the application.

import flippy, vmath, chroma, options, sequtils, random, algorithm, strutils
from math import pow, PI

type
  Point = Vec2
  Layer = seq[Point]

proc newPoint*(x: SomeInteger, y: SomeInteger): Point =
  Point(x: x.float, y: y.float)

proc newPoint*(x: SomeFloat, y: SomeFloat): Point =
  Point(x: x, y: y)

proc insertMidrangePoint(layer: Layer, val: Point): Layer =
  result = layer
  for idx, point in result.pairs:
    if point.x > val.x and idx > 0:
      let lte = filter(result) do (x: Point) -> bool : x.x <= val.x
      let gt = filter(result) do (x: Point) -> bool : x.x > val.x
      result = concat(lte, @[val], gt)
      return result

proc `$`(p: Point): string {.inline.} =
  "[x: $#, y: $#]" % @[$p.x.int, $p.y.int]

proc drawEllipsis(image: var Image, fillColour: ColorRGBA, points: Layer, startingPoint: Point) =
  for point in points:
    image.line(startingPoint, point, fillColour)

proc getEllipsisPoints(startingPoint: Point, radius: float, splits: float = 1.0): Layer =
  result = @[]

  for p in 0 .. int(360 / splits):
    result.add(Point(x: radius * sin(p.float) + startingPoint.x, y: radius * cos(p.float) + startingPoint.y))

proc midpointDisplacement(startPoint, endPoint: Point, roughness: float, verticalDisplacement: int, numIterations: int): Layer =
  var vd:float = verticalDisplacement.float
  if vd == -999.0:
    #If no initial displacement, set to y_start + y_end / 2
    vd = (startPoint.y + endPoint.y) / 2
  result = @[]

  result.add(startPoint)
  result.add(endPoint)

  #Data structures that stores the points is a seq of Points
  var 
    iteration = 1

  var fd = open("log.log", fmWrite)
  while iteration <= numIterations:
    var pointsCopy = result
    for i in 0 ..< pointsCopy.high:
      #Calculate x and y midpoint
      # [(x_i + x_(i + 1)) / 2, (y_i + y_(i+1)) / 2]
      var midpoint = newPoint((pointsCopy[i].x + pointsCopy[i + 1].x) / 2.0, 
                              (pointsCopy[i].y + pointsCopy[i + 1].y) / 2.0)

      midpoint.y += rand(-vd .. vd)

      result = insertMidrangePoint(result, midpoint)

    vd *= pow(2, -roughness)
    iteration.inc

proc drawSun(landscape: var Image, width, height: int) = 
  let
    sunStartPoint = Point(x: width / 8, y: height / 8)
    ellipsisPoints = getEllipsisPoints(sunStartPoint, width / 12, 0.5)
  landscape.drawEllipsis(rgba(255, 255, 255, 255), ellipsisPoints, sunStartPoint)

proc drawLayers*(layers: seq[Layer], width, height: int, colours: var Option[seq[ColorRGBA]]): Image =
  if isNone(colours):
    colours = some(@[rgba(195, 157, 224, 255),
                rgba(158, 98, 204, 255),
                rgba(130, 79, 138, 255),
                rgba(68, 28, 99, 255),
                rgba(49, 7, 82, 255),
                rgba(23, 3, 38, 255),
                rgba(240, 203, 163, 255)])
  else:
    assert(colours.get().len < layers.len + 1)

  result = newImage(width, height, 4)
  result.fill(colours.get()[6])
  result.drawSun(width, height)

  var finalLayers: seq[Layer] = @[]

  for layer in layers:
    var sampled_layer: Layer = @[]
    for i in 0 ..< layer.len - 1:
      sampled_layer.add(layer[i])

      if layer[i + 1].x - layer[i].x > 1:
        #linearly sample the y values in the range x_[i + 1] - x_[i]
        # This is done by obtaining the equation of the straight line
        # in the form of y = m * x * n that connects two consecutive points
        let 
          m = (layer[i + 1].y - layer[i].y) / (layer[i + 1].x - layer[i].x)
          n = layer[i].y - m * layer[i].x

        for j in int(layer[i].x + 1) .. int(layer[i + 1].x):
          sampled_layer.add(Point(x: j.float, y: m * j.float + n ))
    finalLayers.add(sampled_layer)

  for index, finalLayer in finalLayers.pairs:
    for x in 0 ..< finalLayer.high:
      let startPoint = Point(x: finalLayer[x].x, y: height.float - finalLayer[x].y)
      let endPoint = Point(x: finalLayer[x].x, y: height.float)
      result.line(startPoint, endPoint, colours.get()[index])

proc debugLayer(layer: Layer) =
  var image = newImage(1000, 500, 4)
  image.fill(rgba(0, 0, 0, 255))
  for point in layer:
    #image.putRgbaSafe(point.x.int, point.y.int, rgba(255, 255, 255, 255))
    image.line(point, newPoint(point.x, 500), rgba(255, 255, 255, 255))

  image.save("test.png")

proc main() = 
  let
    width = 4000
    height = 1500

  var
    layers: seq[Layer] = @[]
    colours = none(seq[ColorRGBA])

  layers.add(midpointDisplacement(newPoint(0, 1100), newPoint(width, 700), 0.8, 250, 8))
  layers.add(midpointDisplacement(newPoint(0, 500), newPoint(width, 800), 0.6, 120, 9))
  layers.add(midpointDisplacement(newPoint(0, 780), newPoint(width, 380), 0.7, 40, 12))
  layers.add(midpointDisplacement(newPoint(1250, 0), newPoint(width, 200), 1.1, 20, 12))

  var landscape = drawLayers(layers, width, height, colours)
  landscape.save("terrain.png")

when isMainModule:
  randomize()
  main()
