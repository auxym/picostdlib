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
    classes={UsbClass.Hid, UsbClass.Cdc},
    ep0size=Ep0Size,
  )


# Device descriptor
setDeviceDescriptor:
  DeviceDescriptor(
    length: sizeof(DeviceDescriptor).uint8,
    descriptorType: UsbDescriptorType.Device,
    usbVersion: initBcdVersion(2, 0, 0),

    # These class/subclass/protocol values required for CDC
    # See TinyUSB examples for more info.
    class: UsbClass.Misc,
    subclass: MiscSubclassCommon,
    protocol: MiscProtocolIad,

    ep0MaxPacketSize: Ep0Size,
    vendorId: 0xCAFE,
    productId: 0x4005,
    deviceVersion: initBcdVersion(0, 1, 0),
    manufacturerStr: 1.StringIndex,
    productStr: 2.StringIndex,
    serialNumberStr: 3.StringIndex,
    numConfigurations: 1
  )
