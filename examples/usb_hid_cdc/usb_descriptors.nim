{.used.}
import tinyusb

# Endpoint 0 max packet size, must match in the config and in the device
# descriptor.
const Ep0Size = Ep0MaxPacketSize.Size64

# configureUsbDevice runs at compile-time to generate the "tusb_config.h" file
# in the nimcache folder.
static:
  configureUsbDevice(
    mcu=TinyUsbMcu.RP2040,
    os=TinyUsbOs.None,
    debug=false,
    cdc=1, hid=1,
    ep0size=Ep0Size,
  )

# Device descriptor
setDeviceDescriptor initDeviceDescriptor(
  usbVersion=initBcdVersion(2, 0, 0),

  # These class/subclass/protocol values required for CDC
  # See TinyUSB examples for more info.
  class=UsbClass.Misc,
  subclass=MiscSubclassCommon,
  protocol=MiscProtocolIad,

  ep0Size=Ep0Size,
  vendorId=0xCAFE,
  productId=0x4005,
  deviceVersion=initBcdVersion(89, 1, 4),
  manufacturerStr=1.StringIndex,
  productStr=2.StringIndex,
  serialNumberStr=3.StringIndex,
  numConfigurations=1
)

# HID Report Descriptor
const
  KeyboardReportId = 1
  MouseReportId = 2
  GamepadReportId = 3

  myHidReportDescriptor =
    keyboardReportDescriptor(id=KeyboardReportId) &
    mouseReportDescriptor(id=MouseReportId) &
    gamepadReportDescriptor(id=GamepadReportId)

  hidReportDescLen = len(myHidReportDescriptor)

hidReportDescriptorCallback(inst):
  let desc {.global.} = toArrayLit myHidReportDescriptor
  return desc[0].unsafeAddr

# Configuration descriptor

const
  CdcInterface* = 0.InterfaceNumber
  CdcDataInterface* = 1.InterfaceNumber
  HidInterface* = 2.InterfaceNumber
  NumInterfaces* = 3

const
  fullConfigSize = sizeof(ConfigurationDescriptor) +
                   sizeof(CompleteCdcSerialPortInterface) +
                   sizeof(CompleteHidInterface)

  configDescriptor = initConfigurationDescriptor(
    val=1,
    totalLength=fullConfigSize.uint16,
    numItf=NumInterfaces,
    powerma=100,
  )

  cdcDesc = initCompleteCdcSerialPortInterface(
    controlItf=CdcInterface,
    controlEpNum=1,
    controlEpSize=8,
    dataEpNum=2,
    dataEpSize=64,
    str=4.StringIndex
  )

  hidDesc = initCompleteHidInterface(
    HidInterface,
    reportDescLen=hidReportDescLen,
    epIn=3,
    epInSize=16,
    epInterval=5,
    str=5.StringIndex
  )

configurationDescriptorCallback(index):
  # Per USB spec, a request for the configuration descriptor must
  # return the configuration descriptor and all associated interface 
  # and endpoint descriptors. Here we concatenate all the descriptors.
  const
    fullCfg =
      configDescriptor.serialize &
      cdcDesc.serialize &
      hidDesc.serialize

  # Use the toArrayLit macro to generate a static byte array and assign
  # to a {.global.} variable to ensure that the pointer is always valid.
  let fullCfgBytes {.global.} = toArrayLit(fullCfg)

  # Can handle multiple different configurations, here we only have one.
  #
  # Note on multiple configurations: `index` here is a 0-based index of
  # defined configurations. I.e., `index` is in the range
  # [0 .. (numConfigurations - 1)]. `index` does *not* correspond to the
  # configuration value, which must be at least 1, and is not necessarily
  # sequential.
  result = case index:
  of 0:
    fullCfgBytes[0].unsafeAddr
  else:
    nil

#stringDescriptorCallback(index, langId):
#  return nil
