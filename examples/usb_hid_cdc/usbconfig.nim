{.used.}

import tinyusb

static:
  configureUsbDevice(
    mcu=TinyUsbMcu.RP2040,
    os=TinyUsbOs.None,
    debug=false,
    classes={UsbClass.Hid, UsbClass.Cdc},
  )
