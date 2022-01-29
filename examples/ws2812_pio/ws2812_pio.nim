import picostdlib/[pio, gpio, clock, time]

import std/math # Compile-time only

const
  ws2812DataPin = 1.Gpio
  ledBrightnessDiv = 4 # reduce LED brightness by dividing the value

let ws2812Pio = pio0

{.push header: "ws2812.pio.h".}
proc ws2812_program_get_default_config(offset: uint): PioSmConfig {.importc.}

let
  ws2812_T1 {.importc.}: int 
  ws2812_T2 {.importc.}: int 
  ws2812_T3 {.importc.}: int 

  ws2812_program* {.importc.}: PioProgram
{.pop.}

proc initWs2812*(
    pioIns: PioInstance, sm: PioStateMachine, offset: uint, pin: Gpio
    ) =
  pioIns.gpioInit pin
  pioIns.setPindirs(sm, Out, {ws2812DataPin})

  var cfg = ws2812_program_get_default_config offset
  cfg.setSidesetPins pin
  cfg.setOutShift(shiftRight=false, autopull=true, pullThreshold=32)
  cfg.setFifoJoin PioFifoJoin.tx

  const ws2812Freq = 800_000 # ws2812 data bitrate in bits/s

  let
    cyclesPerBit = ws2812_T1 + ws2812_T2 + ws2812_T3
    clockdiv = getHz(ClockIndex.sys).float / (ws2812Freq * cyclesPerBit.float)
  cfg.setClkdiv clockdiv

  pioIns.init(sm, offset, cfg)
  pioIns.enable sm

proc ws2812Put*(pioIns: PioInstance, sm: PioStateMachine,
    r: uint8, g: uint8, b: uint8, w: uint8) =
  var val: uint32 = w or (b.uint32 shl 8) or (r.uint32 shl 16) or (g.uint32 shl 24)
  pioIns.putBlocking(sm, val)

type
  PrimaryColor = enum colRed, colGreen, colBlue
  RgbColor = array[PrimaryColor, uint8]

proc createRainbowTable(): seq[RgbColor] {.compileTime.} =
  const
    maxAngle = 3.0 * PI
    numSteps = 100
    angleStep = maxAngle / numSteps
    twoPi = 2 * PI

  # convert the range -1.0 .. 1.0 to 0 .. 255
  proc trig2byte(x: float): uint8 = ((1.0 + x) * 127.5).toInt.uint8

  result = newSeq[RgbColor](numSteps)
  for i in 0 ..< numSteps:
    let angle = angleStep * i.float
    if angle <= PI:
      result[i][colRed] = cos(angle).trig2byte
      result[i][colGreen] = (-cos(angle)).trig2byte
      result[i][colBlue] = 0
    elif angle <= twoPi:
      result[i][colRed] = 0
      result[i][colGreen] = (-cos(angle)).trig2byte
      result[i][colBlue] = cos(angle).trig2byte
    else:
      result[i][colRed] = (-cos(angle)).trig2byte
      result[i][colGreen] = 0
      result[i][colBlue] = cos(angle).trig2byte

const ColorTable = createRainbowTable()

proc nextColor(sm: PioStateMachine) =
  var i {.global.} = 0
  let color = ColorTable[i]
  ws2812Put(ws2812Pio, sm,
    (color[colRed] div ledBrightnessDiv),
    (color[colGreen] div ledBrightnessDiv),
    (color[colBlue] div ledBrightnessDiv),
    0
  )

  i.inc
  if i > ColorTable.high: i = 0

proc main() =
  # Init PIO program
  let
    ws2812Offset = ws2812Pio.addProgram(ws2812_program)
    ws2812SmResult = ws2812Pio.claimUnusedSm(false)

  # Check that we succeeded in claiming a state machine
  var ws2812Sm: PioStateMachine
  if ws2812SmResult >= 0:
    ws2812Sm = ws2812SmResult.PioStateMachine
    ws2812Pio.initws2812(ws2812Sm, ws2812Offset, ws2812DataPin)

  while true:
    if ws2812SmResult >= 0:
      nextColor(ws2812Sm)
    sleep 40

main()
