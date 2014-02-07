import processing.serial.*;
import com.rapplogic.xbee.api.PacketListener;
import com.rapplogic.xbee.api.XBee;
import com.rapplogic.xbee.api.XBeeResponse;
import com.rapplogic.xbee.api.zigbee.ZNetRxBaseResponse;
import com.rapplogic.xbee.api.zigbee.ZNetRxIoSampleResponse;

// remote xbee
XBee xbee;
XBeeAddress64 address;
RemoteAtRequest request;
RemoteAtResponse response;
XBeeResponse answer;

// iteration counter draw loop
int k = 0;

// hyt sensor class
public class HYT
{
  private int clPin;
  private int daPin;
  private int delay;
  private int sampleRate;
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
    this.sampleRate = 100;
    this.delay = 180;
    this.serialPort = "/dev/ttyUSB0";
    xbee = new XBee();
    try { xbee.open(serialPort, 9600); }
    catch (Exception e) { println("Error connecting to remote XBEE"); }
  }
 
  // sleeps the whole thread for this.delay seconds 
  private void delay()
  {
    try { Thread.sleep(delay); }
    catch(Exception e) { println("sleep error"); }
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

  // switches the data pin to input mode
  private void swToInput()
  {
   	request = new RemoteAtRequest(address, "D" + daPin, new int[] {3});
   	try { response = (RemoteAtResponse) xbee.sendSynchronous(request, 1000); }
    catch (Exception e) { println("could not switch D" + daPin + " to input"); }
   	/*request = new RemoteAtRequest(address, "D" + clPin, new int[] {3});
   	try { response = (RemoteAtResponse) xbee.sendSynchronous(request, 1000); }
   	catch (Exception e) { println("could not switch D" + clPin + " to input"); }*/
  }
  
  private void readInput()
  {
    try { answer = xbee.getResponse(); }
    catch (Exception e) { println("answer error"); }
    println(answer.getApiId());
    if (answer.getApiId() == ApiId.ZNET_IO_SAMPLE_RESPONSE) {
      ZNetRxIoSampleResponse ioSample = (ZNetRxIoSampleResponse) answer;    
      // println("Received a sample from " + ioSample.getRemoteAddress64());
      println("Digital D0 is " + (ioSample.isD0On() ? "on" : "off"));
    }

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

    if(!currentBit)
      daHigh();

    clHigh();
    clLow();
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

}

// other functions
void blinkD0()
{
  try { Thread.sleep(1000); }
  catch (Exception e) { println("error"); }
  request = new RemoteAtRequest(address, "D0", new int[] {5});
  try { response = (RemoteAtResponse) xbee.sendSynchronous(request, 1000); }
  catch (Exception e) { println("error request"); }
  try { Thread.sleep(1000); }
  catch (Exception e) { println("error sleep"); }
  request = new RemoteAtRequest(address, "D0", new int[] {4});
  try { response = (RemoteAtResponse) xbee.sendSynchronous(request, 1000); }
  catch (Exception e) { println("error response"); }  
}
void enableD0()
{
  request = new RemoteAtRequest(address, "D0", new int[] {5});
  try { response = (RemoteAtResponse) xbee.sendSynchronous(request, 1000); }
  catch (Exception e) { println("error request"); }
}

void disableD0()
{
  request = new RemoteAtRequest(address, "D0", new int[] {4});
  try { response = (RemoteAtResponse) xbee.sendSynchronous(request, 1000); }
  catch (Exception e) { println("error response"); }  
}

void sleep(int msec)
{
  try { Thread.sleep(msec); }
  catch (Exception e) { println("error sleeping the thread"); }
}

HYT hyt;
float x = 0;
float y = 0;
float w = 150;
float h = 80;

// setup function, runs once on startup of the program
// useful to initialise values / classes
void setup()
{
  size(200,200);
  background(255);
  stroke(0);
  noFill();
  /*xbee = new XBee();
  try {
  xbee.open("/dev/ttyUSB0", 9600);}
  catch (Exception e) {
    println("error connection");} */
  address = new XBeeAddress64(0, 0x13, 0xa2, 0x00, 0x40, 0xaa, 0x1a, 0x41);
  /*request = new RemoteAtRequest(address, "D1", new int[] {0x3});
  try { xbee.sendSynchronous(request, 10000); }
  catch (Exception e) { println("D1 input AT error"); }
  request = new RemoteAtRequest(address, "IC", new int[] {0x64});
  try { xbee.sendSynchronous(request, 10000); }
  catch (Exception e) { println("D1 input AT error"); }*/
  hyt = new HYT(address, 1, 0);
}

  
// draw loop: loops infinitifly
void draw()
{
  k++;

  background(255);
  rect(x,y,w,h);
  fill(128);
  if(mousePressed){
    if(mouseX>x && mouseX <x+w && mouseY>y && mouseY <y+h){
      fill(0);
      exit();
    }
  }
                     
  /*try { answer = xbee.getResponse(); }
  catch (Exception e) { println("answer error"); }
  println(answer.getApiId());
  if (answer.getApiId() == ApiId.ZNET_IO_SAMPLE_RESPONSE) {
    ZNetRxIoSampleResponse ioSample = (ZNetRxIoSampleResponse) answer;    
    println("Received a sample from " + ioSample.getRemoteAddress64());
    println("Digital D1 (pin 11) is " + (ioSample.isD1On() ? "on" : "off"));
    if(ioSample.isD1On())
      enableD0();
    else
      disableD0();
  }*/
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
