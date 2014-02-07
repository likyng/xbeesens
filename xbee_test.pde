import processing.serial.*;
import com.rapplogic.xbee.api.PacketListener;
import com.rapplogic.xbee.api.XBee;
import com.rapplogic.xbee.api.XBeeResponse;
import com.rapplogic.xbee.api.zigbee.ZNetRxBaseResponse;
import com.rapplogic.xbee.api.zigbee.ZNetRxIoSampleResponse;

// remote xbee address; integrate into class? yes!
XBeeAddress64 address;

// iteration counter draw loop
int k = 0;

// hyt sensor class
public class HYT
{
  private int clPin;
  private int daPin;
  private int delay;
  private int sampleRate;
  private int readCounter;
  private String serialPort;
  private XBeeAddress64 address;
  private XBee xbee;
  private RemoteAtRequest request;
  private RemoteAtResponse response;
  private XBeeResponse answer;
  
  public HYT(XBeeAddress64 address, int clPin, int daPin)
  {
    this.xbee = xbee;
    this.address = address;
    this.clPin = clPin;
    this.daPin = daPin;
    this.delay = 180;
    this.sampleRate = 100;
    this.readCounter = 11;
    this.serialPort = "/dev/ttyUSB0";
    xbee = new XBee();
    try { xbee.open(serialPort, 9600); }
    catch (Exception e) { println("Error connecting to local XBEE, check Serial Port"); }
  }
 
  // sleeps the whole thread for this.delay mseconds 
  private void delay()
  {
    try { Thread.sleep(delay); }
    catch(Exception e) { println("Thread sleeping error"); }
  }
  
  // following functions send synchronous requests to turn on/off certain pins
  // which time out after 500msec to the xbee, waiting for their response
  // if responded, an error (exception) will be triggered and displayed
  // lastly the next command is delayed
  private void clHigh()
  {
    request = new RemoteAtRequest(address, "D" + clPin, new int[] {5});
    try { response = (RemoteAtResponse) xbee.sendSynchronous(request, 500); }
    catch (Exception e) { println("error clHigh"); }    
    delay();
  }
  
  private void daHigh()
  {
    request = new RemoteAtRequest(address, "D" + daPin, new int[] {5});
    try { response = (RemoteAtResponse) xbee.sendSynchronous(request, 500); }
    catch (Exception e) { println("error clHigh"); }    
    delay();
  }
  
  private void clLow()
  {
    request = new RemoteAtRequest(address, "D" + clPin, new int[] {4});
    try { response = (RemoteAtResponse) xbee.sendSynchronous(request, 500); }
    catch (Exception e) { println("error clHigh"); }    
    delay();
  }
  
  private void daLow()
  {
    request = new RemoteAtRequest(address, "D" + daPin, new int[] {4});
    try { response = (RemoteAtResponse) xbee.sendSynchronous(request, 500); }
    catch (Exception e) { println("error clHigh"); }    
    delay();
  }

  private void sendCmd(int cmd)
  {
    boolean lastBit = true;
    boolean currentBit = false;

    // for loop compares cmd and 128base2 and sets currentBit to high
    // if both are 1; finally, cmd is shifted to the left by one
    // as 128base2 only has bit "7" set to one, bits will be output correctly
    for(int i = 0; i < 8; ++i)
    {
      currentBit = ((cmd & 0x80) != 0);
      if(currentBit != lastBit)
      {
        if(currentBit)
          daHigh();
        else
          daLow();
      }
      lastBit = currentBit;

      clHigh();
      clLow();
      cmd <<= 1;
    }
	
    // now, instantly read the data and acknowledge the ACK bit by pulsing SCL
    // therefore, call this.swToInput();
  }

  // switches the data pin to input mode
  private void swToInput()
  {
   	request = new RemoteAtRequest(address, "D" + daPin, new int[] {3});
   	try { response = (RemoteAtResponse) xbee.sendSynchronous(request, 100); }
    catch (Exception e) { println("could not switch D" + daPin + " to input"); }
   	/*request = new RemoteAtRequest(address, "D" + clPin, new int[] {3});
   	try { response = (RemoteAtResponse) xbee.sendSynchronous(request, 1000); }
   	catch (Exception e) { println("could not switch D" + clPin + " to input"); }*/

    // pulse clock to aknowledge ACK bit (turn on to "read" it and turn off to say "ok"
	  clHigh();
    clLow();
  }
  
  // reads input from remote xbee; sometimes also still receives 0x97 (AT_RESPONSE) type
  // of answers. -> should only return IO_SAMPLE_RESPONSE  
  private void readInput()
  {
    for(int i = 0; i < readCounter; ++i)
    {
      try { answer = xbee.getResponse(); }
      catch (Exception e) { println("answer error"); }
      // println(answer.getApiId());
      if (answer.getApiId() == ApiId.ZNET_IO_SAMPLE_RESPONSE) 
      {
        ZNetRxIoSampleResponse ioSample = (ZNetRxIoSampleResponse) answer;    
        // println("Received a sample from " + ioSample.getRemoteAddress64());
        println("Digital D0 is " + (ioSample.isD0On() ? "on" : "off"));
      }
      delay();
    }
  }

  void start()
  {
    clHigh();
    daLow();
    clLow();
    clHigh();
    daHigh();
    clLow();
  }

  public void reset()
  {
    // pulse clock while data high to reset
    daHigh();
    for (int i = 0; i < 11; ++i)
    {
      clHigh();
      clLow();
    }
  }

} // end HYT class

void sleep(int msec)
{
  try { Thread.sleep(msec); }
  catch (Exception e) { println("error sleeping the thread"); }
}

// "main" program begins
//

HYT hyt;
// setup function, runs once on startup of the program
// useful to initialise values / classes
void setup()
{
  address = new XBeeAddress64(0, 0x13, 0xa2, 0x00, 0x40, 0xaa, 0x1a, 0x41);
  // new HYT object (addres, clockPin, dataPin)
  hyt = new HYT(address, 1, 0);
}

// draw loop: loops infinitifly
// special to processing programming environment
void draw()
{
  k++;

  /*hyt.delay();
  hyt.daHigh();
  hyt.delay();
  hyt.daLow();
  hyt.swToInput();
  hyt.readInput();*/
  hyt.reset();
  hyt.delay();
  hyt.delay();
  hyt.start();
  hyt.delay();
  hyt.delay();
  hyt.sendCmd(60);
  hyt.swToInput();
  hyt.clHigh();
  hyt.clLow();
  hyt.readInput();
  sleep(2000);

  println("iteration: " + k);
}
