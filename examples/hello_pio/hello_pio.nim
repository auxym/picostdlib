import picostdlib/[gpio, pio, time]

{.push header: "hello.pio.h".}
let helloProgram {.importc: "hello_program".}: PioProgram

proc helloProgramGetDefaultConfig(offset: uint): PioSmConfig
  {.importc: "hello_program_get_default_config".}
{.pop.}

proc initPioHelloProgram(pio: PioInstance, sm: PioStateMachine, offset: uint, pin: Gpio) =
  var cfg = helloProgramGetDefaultConfig(offset)
  cfg.setOutPins(pin, 1)
  
  pio.gpioInit(pin)
  pio.setConsecutivePindirs(sm, pin, 1, true)

  pio.init(sm, offset, cfg)
  pio.setEnabled(sm, true)

let
  helloPioInst = pio0
  offset = helloPioInst.addProgram(helloProgram.unsafeAddr)
  smResult = helloPioInst.claimUnusedSm(false)

if smResult >= 0:
  let sm = smResult.PioStateMachine
  initPioHelloProgram(helloPioInst, sm, offset, DefaultLedPin)

  while true:
    helloPioInst.putBlocking(sm, 1)
    sleep 500  
    helloPioInst.putBlocking(sm, 0)
    sleep 500  
