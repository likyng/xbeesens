import processing.serial.*;

import com.rapplogic.xbee.api.PacketListener;
import com.rapplogic.xbee.api.XBee;
import com.rapplogic.xbee.api.XBeeResponse;
import com.rapplogic.xbee.api.wpan.RxResponseIoSample;

XBee xbee;
XBeeAddress64 address;
RemoteAtRequest request;
RemoteAtResponse response;
void setup()
{
  xbee = new XBee();
  try {
  xbee.open("/dev/ttyUSB0", 9600);}
  catch (Exception e) {
    println("error connection");}
  address = new XBeeAddress64(0, 0x13, 0xa2, 0x00, 0x40, 0xaa, 0x1a, 0x41);
}

void draw()
{
  request = new RemoteAtRequest(address, "D0", new int[] {5});

  try {
    response = (RemoteAtResponse) xbee.sendSynchronous(request, 10000);
  }
  catch (Exception e) { println("error request"); }

// pause for 2 seconds
  try { Thread.sleep(20); }
  catch (Exception e) { println("error sleep"); }

  request = new RemoteAtRequest(address, "D0", new int[] {4});

// send the command
  try {
    response = (RemoteAtResponse) xbee.sendSynchronous(request, 10000);
  }
  catch (Exception e) { println("error response"); }
}
