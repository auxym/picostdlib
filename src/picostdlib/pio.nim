import gpio

{.push header: "pio.h".}
type
  PioSmConfig* {.importc: "pio_sm_config", bycopy.} = object
    clkdiv {.importc: "clkdiv".}: uint32
    execctrl {.importc: "execctrl".}: uint32
    shiftctrl {.importc: "shiftctrl".}: uint32
    pinctrl {.importc: "pinctrl".}: uint32

  PioInstance* {.importc: "pio_hw_t", nodecl.} = object

  PioStateMachine* = range[0'u .. 3'u]

  PioProgram* {.importc: "pio_program_t", nodecl.} = object

let
  pio0* {.importc, nodecl.}: PioInstance 
  pio1* {.importc, nodecl.}: PioInstance 
{.pop.}

# PIO State Machine Config
# Private C API

{.push header: "pio.h".}
proc smConfigSetOutPins(c: ptr PioSmConfig; outBase: uint; outCount: uint)
  {.importc: "sm_config_set_out_pins".}

proc smConfigSetInPins(c: ptr PioSmConfig; inBase: uint)
  {.importc: "sm_config_set_in_pins".}

proc smConfigSetSetPins(c: ptr PioSmConfig; setBase: uint; setCount: uint)
  {.importc: "sm_config_set_set_pins".}

proc smConfigSetSidesetPins(c: ptr PioSmConfig; sidesetBase: uint)
  {.importc: "sm_config_set_sideset_pins".}

proc smConfigSetSideset(c: ptr PioSmConfig; bitCount: uint; optional: bool;
  pindirs: bool) {.importc: "sm_config_set_sideset".}

proc smConfigSetClkdivIntFrac(c: ptr PioSmConfig; divInt: uint16; divFrac: uint8)
  {.importc: "sm_config_set_clkdiv_int_frac".}
{.pop.}

# PIO State Machine Config
# Exported Nim API

proc setOutPins*(c: var PioSmConfig, outBase: Gpio, outCount: uint) =
  smConfigSetOutPins(c.addr, outBase.uint, outCount)

proc setInPins*(c: var PioSmConfig; inBase: Gpio) =
  smConfigSetInPins(c.addr, inBase.uint)

proc setSetPins*(c: var PioSmConfig; setBase: Gpio; setCount: uint) =
  smConfigSetSetPins(c.addr, setBase.uint, setCount)

proc setSidesetPins*(c: var PioSmConfig; sidesetBase: Gpio) =
  smConfigSetSidesetPins(c.addr, sidesetBase.uint)

proc setSideset*(c: var PioSmConfig; bitCount: uint; optional: bool; pinDirs: bool) =
  smConfigSetSideset(c.addr, bitCount, optional, pinDirs)

proc setClkDiv*(c: var PioSmConfig; divInt: uint16; divFrac: uint8) =
  smConfigSetClkdivIntFrac(c.addr, divInt, divFrac)

template setClkDiv*(c: var PioSmConfig, divisor: static[1.0 .. 65536.0]) =
  static:
    let
      divInt = divisor.uint16
      divFrac: uint8 = ((divisor - divInt.float32) * 256).toInt.uint8
  smConfigSetClkdivIntFrac(c.addr, divInt, divFrac)
  
# Main PIO API

{.push header: "pio.h".}
proc gpioInit*(pio: PioInstance; pin: Gpio)
  {.importc: "pio_gpio_init".}

proc canAddProgram*(pio: PioInstance; program: ptr PioProgram): bool
  {.importc: "pio_can_add_program".}

proc canAddProgram*(pio: PioInstance; program: ptr PioProgram; offset: uint): bool
  {.importc: "pio_can_add_program_at_offset".}

proc addProgram*(pio: PioInstance; program: ptr PioProgram): uint
  {.importc: "pio_add_program".}

proc addProgram*(pio: PioInstance; program: ptr PioProgram; offset: uint)
  {.importc: "pio_add_program_at_offset".}

proc removeProgram*(pio: PioInstance; program: ptr PioProgram; loadedOffset: uint)
  {.importc: "pio_remove_program".}

proc clearInstructionMemory*(pio: PioInstance) {.importc: "pio_clear_instruction_memory".}

proc smInit*(pio: PioInstance; sm: uint; initialpc: uint; config: ptr PioSmConfig) {.
    importc: "pio_sm_init".}
{.pop}

# State Machine API

{.push header: "pio.h".}
proc setPins*(pio: PioInstance; sm: PioStateMachine; pinValues: set[Gpio])
  {.importc: "pio_sm_set_pins".}

proc setPinsWithMask*(pio: PioInstance; sm: PioStateMachine; pinValues: set[Gpio]; pinMask: set[Gpio])
  {.importc: "pio_sm_set_pins_with_mask".}

proc setPindirsWithMask*(pio: PioInstance; sm: PioStateMachine; pinDirs: set[Gpio]; pinMask: set[Gpio])
  {.importc: "pio_sm_set_pindirs_with_mask".}

proc setConsecutivePindirs*(pio: PioInstance; sm: PioStateMachine; pinBase: Gpio; pinCount: uint;
  isOut: bool) {.importc: "pio_sm_set_consecutive_pindirs"}

proc claim*(pio: PioInstance; sm: PioStateMachine) {.importc: "pio_sm_claim"}

proc claimSmMask*(pio: PioInstance; smMask: set[PioStateMachine]) {.importc: "pio_claim_sm_mask".}

proc unclaim*(pio: PioInstance; sm: PioStateMachine) {.importc: "pio_sm_unclaim".}

proc claimUnusedSm*(pio: PioInstance; required: bool): int {.importc: "pio_claim_unused_sm".}

proc isClaimed*(pio: PioInstance; sm: PioStateMachine): bool {.importc: "pio_sm_is_claimed".}
{.pop}

#[

proc smConfigSetWrap*(c: ptr PioSmConfig; wrapTarget: uint; wrap: uint) {.inline.} =
  validParamsIf(pio, wrap < pio_Instruction_Count)
  validParamsIf(pio, wrapTarget < pio_Instruction_Count)
  c.execctrl = (c.execctrl and
      not (pio_Sm0Execctrl_Wrap_Top_Bits or pio_Sm0Execctrl_Wrap_Bottom_Bits)) or
      (wrapTarget shl pio_Sm0Execctrl_Wrap_Bottom_Lsb) or
      (wrap shl pio_Sm0Execctrl_Wrap_Top_Lsb)


proc smConfigSetJmpPin*(c: ptr PioSmConfig; pin: uint) {.inline.} =
  validParamsIf(pio, pin < 32)
  c.execctrl = (c.execctrl and not pio_Sm0Execctrl_Jmp_Pin_Bits) or
      (pin shl pio_Sm0Execctrl_Jmp_Pin_Lsb)


proc smConfigSetInShift*(c: ptr PioSmConfig; shiftRight: bool; autopush: bool;
                        pushThreshold: uint) {.inline.} =
  validParamsIf(pio, pushThreshold <= 32)
  c.shiftctrl = (c.shiftctrl and
      not (pio_Sm0Shiftctrl_In_Shiftdir_Bits or pio_Sm0Shiftctrl_Autopush_Bits or
      pio_Sm0Shiftctrl_Push_Thresh_Bits)) or
      (boolToBit(shiftRight) shl pio_Sm0Shiftctrl_In_Shiftdir_Lsb) or
      (boolToBit(autopush) shl pio_Sm0Shiftctrl_Autopush_Lsb) or
      ((pushThreshold and 0x1f) shl pio_Sm0Shiftctrl_Push_Thresh_Lsb)


proc smConfigSetOutShift*(c: ptr PioSmConfig; shiftRight: bool; autopull: bool;
                         pullThreshold: uint) {.inline.} =
  validParamsIf(pio, pullThreshold <= 32)
  c.shiftctrl = (c.shiftctrl and
      not (pio_Sm0Shiftctrl_Out_Shiftdir_Bits or pio_Sm0Shiftctrl_Autopull_Bits or
      pio_Sm0Shiftctrl_Pull_Thresh_Bits)) or
      (boolToBit(shiftRight) shl pio_Sm0Shiftctrl_Out_Shiftdir_Lsb) or
      (boolToBit(autopull) shl pio_Sm0Shiftctrl_Autopull_Lsb) or
      ((pullThreshold and 0x1f) shl pio_Sm0Shiftctrl_Pull_Thresh_Lsb)


proc smConfigSetFifoJoin*(c: ptr PioSmConfig; join: PioFifoJoin) {.inline.} =
  validParamsIf(pio, join == pio_Fifo_Join_None or join == pio_Fifo_Join_Tx or
      join == pio_Fifo_Join_Rx)
  ## !!!Ignored construct:  c -> shiftctrl = ( c -> shiftctrl & ( uint ) ~ ( PIO_SM0_SHIFTCTRL_FJOIN_TX_BITS | PIO_SM0_SHIFTCTRL_FJOIN_RX_BITS ) ) | ( ( ( uint ) join ) << PIO_SM0_SHIFTCTRL_FJOIN_TX_LSB ) ;
  ## Error: token expected: ) but got: ->!!!


proc smConfigSetOutSpecial*(c: ptr PioSmConfig; sticky: bool; hasEnablePin: bool;
                           enablePinIndex: uint) {.inline.} =
  ## !!!Ignored construct:  c -> execctrl = ( c -> execctrl & ( uint ) ~ ( PIO_SM0_EXECCTRL_OUT_STICKY_BITS | PIO_SM0_EXECCTRL_INLINE_OUT_EN_BITS | PIO_SM0_EXECCTRL_OUT_EN_SEL_BITS ) ) | ( bool_to_bit ( sticky ) << PIO_SM0_EXECCTRL_OUT_STICKY_LSB ) | ( bool_to_bit ( has_enable_pin ) << PIO_SM0_EXECCTRL_INLINE_OUT_EN_LSB ) | ( ( enable_pin_index << PIO_SM0_EXECCTRL_OUT_EN_SEL_LSB ) & PIO_SM0_EXECCTRL_OUT_EN_SEL_BITS ) ;
  ## Error: token expected: ) but got: ->!!!


proc smConfigSetMovStatus*(c: ptr PioSmConfig; statusSel: PioMovStatusType;
                          statusN: uint) {.inline.} =
  validParamsIf(pio, statusSel == status_Tx_Lessthan or
      statusSel == status_Rx_Lessthan)
  c.execctrl = (c.execctrl and
      not (pio_Sm0Execctrl_Status_Sel_Bits or pio_Sm0Execctrl_Status_N_Bits)) or
      (((cast[uint](statusSel)) shl pio_Sm0Execctrl_Status_Sel_Lsb) and
      pio_Sm0Execctrl_Status_Sel_Bits) or
      ((statusN shl pio_Sm0Execctrl_Status_N_Lsb) and
      pio_Sm0Execctrl_Status_N_Bits)


proc pioGetDefaultSmConfig*(): PioSmConfig {.inline.} =
  var c: PioSmConfig
  smConfigSetClkdivIntFrac(addr(c), 1, 0)
  smConfigSetWrap(addr(c), 0, 31)
  smConfigSetInShift(addr(c), true, false, 32)
  smConfigSetOutShift(addr(c), true, false, 32)
  return c


proc pioSmSetConfig*(pio: Pio; sm: uint; config: ptr PioSmConfig) {.inline.} =
  checkPioParam(pio)
  checkSmParam(sm)
  pio.sm[sm].clkdiv = config.clkdiv
  pio.sm[sm].execctrl = config.execctrl
  pio.sm[sm].shiftctrl = config.shiftctrl
  pio.sm[sm].pinctrl = config.pinctrl


proc pioGetIndex*(pio: Pio): uint {.inline.} =
  checkPioParam(pio)
  return if pio == pio1: 1 else: 0


proc pioGetDreq*(pio: Pio; sm: uint; isTx: bool): uint {.inline.} =
  staticAssert(dreq_Pio0Tx1 == dreq_Pio0Tx0 + 1, "")
  staticAssert(dreq_Pio0Tx2 == dreq_Pio0Tx0 + 2, "")
  staticAssert(dreq_Pio0Tx3 == dreq_Pio0Tx0 + 3, "")
  staticAssert(dreq_Pio0Rx0 == dreq_Pio0Tx0 + num_Pio_State_Machines, "")
  staticAssert(dreq_Pio1Rx0 == dreq_Pio1Tx0 + num_Pio_State_Machines, "")
  checkPioParam(pio)
  checkSmParam(sm)
  return sm + (if isTx: 0 else: num_Pio_State_Machines) +
      (if pio == pio0: dreq_Pio0Tx0 else: dreq_Pio1Tx0)

## !!!Ignored construct:  typedef struct pio_program { const uint16_t * instructions ; uint8_t length ; int8_t origin ;  required instruction memory origin or -1 } __packed pio_program_t ;
## Error: token expected: ; but got: [identifier]!!!

proc pioSmSetEnabled*(pio: Pio; sm: uint; enabled: bool) {.inline.} =
  checkPioParam(pio)
  checkSmParam(sm)
  pio.ctrl = (pio.ctrl and not (1u'i64 shl sm)) or (boolToBit(enabled) shl sm)


proc pioSetSmMaskEnabled*(pio: Pio; mask: uint32; enabled: bool) {.inline.} =
  checkPioParam(pio)
  checkSmMask(mask)
  pio.ctrl = (pio.ctrl and not mask) or (if enabled: mask else: 0u'i64)


proc pioSmRestart*(pio: Pio; sm: uint) {.inline.} =
  checkPioParam(pio)
  checkSmParam(sm)
  pio.ctrl = pio.ctrl or 1u'i64 shl (pio_Ctrl_Sm_Restart_Lsb + sm)


proc pioRestartSmMask*(pio: Pio; mask: uint32) {.inline.} =
  checkPioParam(pio)
  checkSmMask(mask)
  pio.ctrl = pio.ctrl or
      (mask shl pio_Ctrl_Sm_Restart_Lsb) and pio_Ctrl_Sm_Restart_Bits


proc pioSmClkdivRestart*(pio: Pio; sm: uint) {.inline.} =
  checkPioParam(pio)
  checkSmParam(sm)
  pio.ctrl = pio.ctrl or 1u'i64 shl (pio_Ctrl_Clkdiv_Restart_Lsb + sm)


proc pioClkdivRestartSmMask*(pio: Pio; mask: uint32) {.inline.} =
  checkPioParam(pio)
  checkSmMask(mask)
  pio.ctrl = pio.ctrl or
      (mask shl pio_Ctrl_Clkdiv_Restart_Lsb) and pio_Ctrl_Clkdiv_Restart_Bits


proc pioEnableSmMaskInSync*(pio: Pio; mask: uint32) {.inline.} =
  checkPioParam(pio)
  checkSmMask(mask)
  pio.ctrl = pio.ctrl or
      (((mask shl pio_Ctrl_Clkdiv_Restart_Lsb) and pio_Ctrl_Clkdiv_Restart_Bits) or
      ((mask shl pio_Ctrl_Sm_Enable_Lsb) and pio_Ctrl_Sm_Enable_Bits))


type
  PioInterruptSource* {.size: sizeof(cint).} = enum
    pisInterrupt0 = pio_Intr_Sm0Lsb, pisInterrupt1 = pio_Intr_Sm1Lsb,
    pisInterrupt2 = pio_Intr_Sm2Lsb, pisInterrupt3 = pio_Intr_Sm3Lsb,
    pisSm0TxFifoNotFull = pio_Intr_Sm0Txnfull_Lsb,
    pisSm1TxFifoNotFull = pio_Intr_Sm1Txnfull_Lsb,
    pisSm2TxFifoNotFull = pio_Intr_Sm2Txnfull_Lsb,
    pisSm3TxFifoNotFull = pio_Intr_Sm3Txnfull_Lsb,
    pisSm0RxFifoNotEmpty = pio_Intr_Sm0Rxnempty_Lsb,
    pisSm1RxFifoNotEmpty = pio_Intr_Sm1Rxnempty_Lsb,
    pisSm2RxFifoNotEmpty = pio_Intr_Sm2Rxnempty_Lsb,
    pisSm3RxFifoNotEmpty = pio_Intr_Sm3Rxnempty_Lsb



proc pioSetIrq0SourceEnabled*(pio: Pio; source: PioInterruptSource; enabled: bool) {.
    inline.} =
  checkPioParam(pio)
  invalidParamsIf(pio, source >= 12)
  if enabled:
    hwSetBits(addr(pio.inte0), 1u'i64 shl source)
  else:
    hwClearBits(addr(pio.inte0), 1u'i64 shl source)


proc pioSetIrq1SourceEnabled*(pio: Pio; source: PioInterruptSource; enabled: bool) {.
    inline.} =
  checkPioParam(pio)
  invalidParamsIf(pio, source >= 12)
  if enabled:
    hwSetBits(addr(pio.inte1), 1u'i64 shl source)
  else:
    hwClearBits(addr(pio.inte1), 1u'i64 shl source)


proc pioSetIrq0SourceMaskEnabled*(pio: Pio; sourceMask: uint32; enabled: bool) {.
    inline.} =
  checkPioParam(pio)
  invalidParamsIf(pio, sourceMask > pio_Intr_Bits)
  if enabled:
    hwSetBits(addr(pio.inte0), sourceMask)
  else:
    hwClearBits(addr(pio.inte0), sourceMask)


proc pioSetIrq1SourceMaskEnabled*(pio: Pio; sourceMask: uint32; enabled: bool) {.
    inline.} =
  checkPioParam(pio)
  invalidParamsIf(pio, sourceMask > pio_Intr_Bits)
  if enabled:
    hwSetBits(addr(pio.inte1), sourceMask)
  else:
    hwClearBits(addr(pio.inte1), sourceMask)


proc pioSetIrqnSourceEnabled*(pio: Pio; irqIndex: uint; source: PioInterruptSource;
                             enabled: bool) {.inline.} =
  invalidParamsIf(pio, irqIndex > 1)
  if irqIndex:
    pioSetIrq1SourceEnabled(pio, source, enabled)
  else:
    pioSetIrq0SourceEnabled(pio, source, enabled)


proc pioSetIrqnSourceMaskEnabled*(pio: Pio; irqIndex: uint; sourceMask: uint32;
                                 enabled: bool) {.inline.} =
  invalidParamsIf(pio, irqIndex > 1)
  if irqIndex:
    pioSetIrq0SourceMaskEnabled(pio, sourceMask, enabled)
  else:
    pioSetIrq1SourceMaskEnabled(pio, sourceMask, enabled)


proc pioInterruptGet*(pio: Pio; pioInterruptNum: uint): bool {.inline.} =
  checkPioParam(pio)
  invalidParamsIf(pio, pioInterruptNum >= 8)
  return pio.irq and (1u'i64 shl pioInterruptNum)


proc pioInterruptClear*(pio: Pio; pioInterruptNum: uint) {.inline.} =
  checkPioParam(pio)
  invalidParamsIf(pio, pioInterruptNum >= 8)
  hwSetBits(addr(pio.irq), (1u'i64 shl pioInterruptNum))


proc pioSmGetPc*(pio: Pio; sm: uint): uint8 {.inline.} =
  checkPioParam(pio)
  checkSmParam(sm)
  return cast[uint8](pio.sm[sm].`addr`)


proc pioSmExec*(pio: Pio; sm: uint; instr: uint) {.inline.} =
  checkPioParam(pio)
  checkSmParam(sm)
  pio.sm[sm].instr = instr


proc pioSmIsExecStalled*(pio: Pio; sm: uint): bool {.inline.} =
  checkPioParam(pio)
  checkSmParam(sm)
  return not not (pio.sm[sm].execctrl and pio_Sm0Execctrl_Exec_Stalled_Bits)


proc pioSmExecWaitBlocking*(pio: Pio; sm: uint; instr: uint) {.inline.} =
  checkPioParam(pio)
  checkSmParam(sm)
  pioSmExec(pio, sm, instr)
  while pioSmIsExecStalled(pio, sm):
    tightLoopContents()


proc pioSmSetWrap*(pio: Pio; sm: uint; wrapTarget: uint; wrap: uint) {.inline.} =
  checkPioParam(pio)
  checkSmParam(sm)
  validParamsIf(pio, wrap < pio_Instruction_Count)
  validParamsIf(pio, wrapTarget < pio_Instruction_Count)
  pio.sm[sm].execctrl = (pio.sm[sm].execctrl and
      not (pio_Sm0Execctrl_Wrap_Top_Bits or pio_Sm0Execctrl_Wrap_Bottom_Bits)) or
      (wrapTarget shl pio_Sm0Execctrl_Wrap_Bottom_Lsb) or
      (wrap shl pio_Sm0Execctrl_Wrap_Top_Lsb)


proc pioSmSetOutPins*(pio: Pio; sm: uint; outBase: uint; outCount: uint) {.inline.} =
  checkPioParam(pio)
  checkSmParam(sm)
  validParamsIf(pio, outBase < 32)
  validParamsIf(pio, outCount <= 32)
  pio.sm[sm].pinctrl = (pio.sm[sm].pinctrl and
      not (pio_Sm0Pinctrl_Out_Base_Bits or pio_Sm0Pinctrl_Out_Count_Bits)) or
      (outBase shl pio_Sm0Pinctrl_Out_Base_Lsb) or
      (outCount shl pio_Sm0Pinctrl_Out_Count_Lsb)


proc pioSmSetSetPins*(pio: Pio; sm: uint; setBase: uint; setCount: uint) {.inline.} =
  checkPioParam(pio)
  checkSmParam(sm)
  validParamsIf(pio, setBase < 32)
  validParamsIf(pio, setCount <= 5)
  pio.sm[sm].pinctrl = (pio.sm[sm].pinctrl and
      not (pio_Sm0Pinctrl_Set_Base_Bits or pio_Sm0Pinctrl_Set_Count_Bits)) or
      (setBase shl pio_Sm0Pinctrl_Set_Base_Lsb) or
      (setCount shl pio_Sm0Pinctrl_Set_Count_Lsb)


proc pioSmSetInPins*(pio: Pio; sm: uint; inBase: uint) {.inline.} =
  checkPioParam(pio)
  checkSmParam(sm)
  validParamsIf(pio, inBase < 32)
  pio.sm[sm].pinctrl = (pio.sm[sm].pinctrl and not pio_Sm0Pinctrl_In_Base_Bits) or
      (inBase shl pio_Sm0Pinctrl_In_Base_Lsb)


proc pioSmSetSidesetPins*(pio: Pio; sm: uint; sidesetBase: uint) {.inline.} =
  checkPioParam(pio)
  checkSmParam(sm)
  validParamsIf(pio, sidesetBase < 32)
  pio.sm[sm].pinctrl = (pio.sm[sm].pinctrl and
      not pio_Sm0Pinctrl_Sideset_Base_Bits) or
      (sidesetBase shl pio_Sm0Pinctrl_Sideset_Base_Lsb)


proc pioSmPut*(pio: Pio; sm: uint; data: uint32) {.inline.} =
  checkPioParam(pio)
  checkSmParam(sm)
  pio.txf[sm] = data


proc pioSmGet*(pio: Pio; sm: uint): uint32 {.inline.} =
  checkPioParam(pio)
  checkSmParam(sm)
  return pio.rxf[sm]


proc pioSmIsRxFifoFull*(pio: Pio; sm: uint): bool {.inline.} =
  checkPioParam(pio)
  checkSmParam(sm)
  return (pio.fstat and (1u'i64 shl (pio_Fstat_Rxfull_Lsb + sm))) != 0


proc pioSmIsRxFifoEmpty*(pio: Pio; sm: uint): bool {.inline.} =
  checkPioParam(pio)
  checkSmParam(sm)
  return (pio.fstat and (1u'i64 shl (pio_Fstat_Rxempty_Lsb + sm))) != 0


proc pioSmGetRxFifoLevel*(pio: Pio; sm: uint): uint {.inline.} =
  checkPioParam(pio)
  checkSmParam(sm)
  var bitoffs: uint
  var mask: uint32
  return (pio.flevel shr bitoffs) and mask


proc pioSmIsTxFifoFull*(pio: Pio; sm: uint): bool {.inline.} =
  checkPioParam(pio)
  checkSmParam(sm)
  return (pio.fstat and (1u'i64 shl (pio_Fstat_Txfull_Lsb + sm))) != 0


proc pioSmIsTxFifoEmpty*(pio: Pio; sm: uint): bool {.inline.} =
  checkPioParam(pio)
  checkSmParam(sm)
  return (pio.fstat and (1u'i64 shl (pio_Fstat_Txempty_Lsb + sm))) != 0


proc pioSmGetTxFifoLevel*(pio: Pio; sm: uint): uint {.inline.} =
  checkPioParam(pio)
  checkSmParam(sm)
  var bitoffs: cuint
  var mask: uint32
  return (pio.flevel shr bitoffs) and mask


proc pioSmPutBlocking*(pio: Pio; sm: uint; data: uint32) {.inline.} =
  checkPioParam(pio)
  checkSmParam(sm)
  while pioSmIsTxFifoFull(pio, sm):
    tightLoopContents()
  pioSmPut(pio, sm, data)


proc pioSmGetBlocking*(pio: Pio; sm: uint): uint32 {.inline.} =
  checkPioParam(pio)
  checkSmParam(sm)
  while pioSmIsRxFifoEmpty(pio, sm):
    tightLoopContents()
  return pioSmGet(pio, sm)


proc pioSmDrainTxFifo*(pio: Pio; sm: uint) {.importc: "pio_sm_drain_tx_fifo",
                                        header: "pio_nim.h".}

proc pioSmSetClkdivIntFrac*(pio: Pio; sm: uint; divInt: uint16; divFrac: uint8) {.
    inline.} =
  checkPioParam(pio)
  checkSmParam(sm)
  pio.sm[sm].clkdiv = ((cast[uint](divFrac)) shl pio_Sm0Clkdiv_Frac_Lsb) or
      ((cast[uint](divInt)) shl pio_Sm0Clkdiv_Int_Lsb)


proc pioSmSetClkdiv*(pio: Pio; sm: uint; `div`: cfloat) {.inline.} =
  checkPioParam(pio)
  checkSmParam(sm)
  var divInt: uint16
  var divFrac: uint8
  pioCalculateClkdivFromFloat(`div`, addr(divInt), addr(divFrac))
  pioSmSetClkdivIntFrac(pio, sm, divInt, divFrac)


proc pioSmClearFifos*(pio: Pio; sm: uint) {.inline.} =
  checkPioParam(pio)
  checkSmParam(sm)
  hwXorBits(addr(pio.sm[sm].shiftctrl), pio_Sm0Shiftctrl_Fjoin_Rx_Bits)
  hwXorBits(addr(pio.sm[sm].shiftctrl), pio_Sm0Shiftctrl_Fjoin_Rx_Bits)
]#