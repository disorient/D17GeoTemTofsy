import hypermedia.net.*;
import moonpaper.*;
import java.util.Collections;
import java.util.Comparator;


int meter = 100;

/***********************************************************************************************************************/

public class Broadcast {
  
  PixelMap pixelMap;
  String ip;
  int port;
  UDP udp;
  PGraphics pg;
  int offset;
  int nPixels;
  int bufferSize;
  byte buffer[];
  boolean isListening = false;

  public Broadcast(Object broadcastReceiver, PixelMap pixelMap, String ip, int port) {
    this(pixelMap, ip, port);
    setup();
    println("No longer necessary to instantiate with broadcastReceiver.  Also, please call setup() explicitly.");
  }
  
  public Broadcast(PixelMap pixelMap, String ip, int port) {
    this.pixelMap = pixelMap;
    this.ip = ip;
    this.port = port;
    this.offset = 0;
    this.nPixels = pixelMap.rows * pixelMap.columns;
  }

  public void setListen(boolean listen) {
    this.isListening = listen;
  }
  
  public void setOffset(int offset) {
    this.offset = offset;
  }
  
  public void setSize(int size) {
    this.nPixels = size;
  }
  
  protected void setupBuffer() {
    bufferSize =  nPixels * 3 + 1;
    buffer = new byte[bufferSize];
  }
  
  protected void setupUDP() {
    if (isListening) {
      udp = new UDP(this, port);
      udp.setReceiveHandler("receive");
      udp.listen(true);
      println("Broadcast listening on "+ this.ip + ":" + port + 
              " offset="+offset + " size="+nPixels);
    }
    else {
      udp = new UDP(this);
      udp.listen(false);
      println("Broadcast transmitting to "+ this.ip + ":" + port + 
              " offset="+offset + " size="+nPixels);
    }
    
    udp.log(false);
  }

  public void setup() {
    setupBuffer();
    setupUDP();
    pg = pixelMap.pg;
  }
  
  public void update() {
    if (isListening) {
      println("Trying to update on a listening Broadcast.  You probably want draw().");
      return;
    }
    
    try {
      pg.loadPixels();
      
      buffer[0] = 1;  // Header. Always 1.
  
      for (int i = 0; i < nPixels; i++) {
        int ofs = i * 3 + 1;
        int c = pg.pixels[i + offset];
  
        buffer[ofs] = byte((c >> 16) & 0xFF);     // Red 
        buffer[ofs + 1] = byte((c >> 8) & 0xFF);  // Blue
        buffer[ofs + 2] = byte(c & 0xFF);         // Green
      }
      
      udp.send(buffer, ip, port);
    }
    catch (Exception e) {
      println("frame: " + frameCount + "  Broadcast.update() frame dropped");
    }
  }

  public void receive(byte[] data, String ip, int port) {
    if (data.length != bufferSize || data[0] != 1) {
       System.out.println("rx " + str(data.length) + " != " + str(bufferSize) + " or data[0] = " + str(data[0]));
       return;
    }
    
    System.arraycopy(data, 0, buffer, 0, data.length);
  }

  public void draw() {
    if (!isListening) {
      println("Trying to draw on a non-listening Broadcast.  You probably want update() to send.");
      return;
    }
    
    pg.loadPixels();
   
    for (int i = 0; i < nPixels; i++) {
      int ofs = i * 3 + 1;
   
      int r = buffer[ofs+0] & 0xFF;
      int g = buffer[ofs+1] & 0xFF;
      int b = buffer[ofs+2] & 0xFF;
   
      pg.pixels[i + offset] = 0x7F000000 // alpha
           | r << 16
           | g <<  8
           | b <<  0;
    }
   
    pg.updatePixels();
  }
}


/***********************************************************************************************************************/

public class BroadcastReceiver extends Broadcast {
  // NOTE This has been folded into broadcast.
  
  public BroadcastReceiver(Object broadcastReceiver, PixelMap pixelMap, String ip, int port) {
    this(pixelMap, ip, port);
    println("BroadcastReceiver is deprecated.  Please use Broadcast and setListen(true).");    
  }

  public BroadcastReceiver(PixelMap pixelMap, String ip, int port) {
    super(pixelMap, ip, port);
    this.setListen(true);
    this.setup();
  }
}

/**
 * Implements Art-Net on top of Broadcast.
 *
 * @author justin
 * @version 1
 **/
public class ArtNetBroadcast extends Broadcast {
  byte[] ARTNET_HEADER = { 'A', 'r', 't', '-', 'N', 'e', 't', 0, 0, 0x50, 0, 14 };
  byte[] ARTNET_SYNC = { 'A', 'r', 't', '-', 'N', 'e', 't', 0, 0, 0x52, 0, 14, 0, 0 };
  int rows;
  int dataSize;
  int packetSize;
  int rowsPerPacket;
  boolean gotSync;

  public ArtNetBroadcast(PixelMap pixelMap, String ip, int port) {
    super(pixelMap, ip, port);
    this.rowsPerPacket = 1;
    this.rows = this.nPixels / pixelMap.columns;
    this.gotSync = false;
  }
  
  public void setRowsPerPacket(int rowsPerPacket) {
    this.rowsPerPacket = rowsPerPacket;
  }
  
  public void setSize(int size) {
    this.nPixels = size;
    this.rows = size / pixelMap.columns;
  }
  
  public void setHeader(int row) {
    // Static header
    System.arraycopy(ARTNET_HEADER, 0, buffer, 0, ARTNET_HEADER.length);
    
    // Sequence allows out of order transmission (1..255, 0 to disable)
    buffer[12] = (byte)(frameCount % 254 + 1);
    
    // Physical port
    buffer[13] = (byte)(row / rowsPerPacket);
    
    // Universe (0..32767, we only support 0..255)
    buffer[14] = (byte)(row / rowsPerPacket);
    buffer[15] = 0;
    
    // Size of data packet
    buffer[16] = (byte)(dataSize >> 8);
    buffer[17] = (byte)dataSize;    
  }
  
  public void setSyncPacket() {
    // Static header
    System.arraycopy(ARTNET_HEADER, 0, buffer, 0, ARTNET_HEADER.length);    
    
    buffer[9] = 0x52;
    
    for (int i=12; i<buffer.length; i++) {
      buffer[i] = 0;
    }
  }

  protected void setupBuffer() {
    dataSize = rowsPerPacket * pixelMap.columns * 3;
    
    if (isListening) {
      // Use the same +1 buffer so we can reuse draw
      super.setupBuffer();
      packetSize = dataSize + 18;
    }
    else {    
      packetSize = bufferSize = dataSize + 18;
      buffer = new byte[bufferSize];
    }
  }

  public void update() {
    if (isListening) {
      println("Trying to update on a listening Broadcast.  You probably want draw().");
      return;
    }
    
    try {
      pg.loadPixels();
      
      // Art-Net is one packet per strip (universe), so we'll do this by row/column
      for (int row = 0; row<rows; row++) {
        if (row % rowsPerPacket == 0)
          setHeader(row);
        
        for (int col = 0; col<pixelMap.columns; col++) {
          int ofs = (row % rowsPerPacket * pixelMap.columns + col) * 3 + 18;
          int c = pg.pixels[offset + (row * pixelMap.columns + col)];
          
          buffer[ofs] = byte((c >> 16) & 0xFF);     // Red 
          buffer[ofs + 1] = byte((c >> 8) & 0xFF);  // Blue
          buffer[ofs + 2] = byte(c & 0xFF);         // Green
        }
        
        if ((row + 1) % rowsPerPacket == 0) {
          udp.send(buffer, ip, port);
        }
      }
      
      udp.send(ARTNET_SYNC, ip, port);
    }
    catch (Exception e) {
      println("frame: " + frameCount + "  Broadcast.update() frame dropped");
      throw(e);
    }
  }

  public void receive(byte[] data, String ip, int port) {
    if (data.length != packetSize || data[0] != 65 || data[1] != 114 || data[2] != 116) {
       System.out.println("rx " + str(data.length) + " != " + str(packetSize) + " or malformed header");
       return;
    }
    
    if (data[9] == 0x52) {
      gotSync = true;
    }
    else {
      int row = (int)data[14];
      int ofs = row * rowsPerPacket * pixelMap.columns * 3 + 1;
      int size = (int(data[16]) << 8) + int(data[17]);
      
      System.arraycopy(data, 18, buffer, ofs, size);
    }
  }
  
  public void draw() {
    // No need to redraw if we haven't received sync.
    if (gotSync) {
      gotSync = false;
      super.draw();
    }
  }
}


/***********************************************************************************************************************/

/**
 * Use this class when you're using multiple receivers for the same installation.
 *
 * @version 1.1
 * @author justin
 */
public class Multicast {
  Broadcast[] broadcasters;
  PixelMap pixelMap;
  Strips strips;
  String[] hosts;
  int[] ports;
  boolean isListening;
  PGraphics pg = null;
  
  /**
   * Create a Multicast where the number of strips (rows in PixelMap) are evenly divisable
   * by the number of hosts/ports specified.  If all ports on all controllers are used this
   * should hold true.
   */
  public Multicast(PixelMap pixelMap, String[] hosts, int[] ports) {
    this.pixelMap = pixelMap;
    this.strips = null;
    this.hosts = hosts;
    this.ports = ports;
    this.broadcasters = new Broadcast[hosts.length];
    this.pg = pixelMap.pg;
  }

  public Multicast(PixelMap pixelMap, Strips strips, String start_host, int port) {
    int controllers = strips.getControllerCount();
    
    this.pixelMap = pixelMap;
    this.strips = strips;
    this.hosts = new String[controllers];
    this.ports = new int[controllers];
    this.broadcasters = new Broadcast[controllers];
    this.pg = pixelMap.pg;
    
    for (int i=0; i<controllers; i++) {
      this.hosts[i] = start_host;
      this.ports[i] = port;
      start_host = nextHost(start_host);
    }    
  }
  
  public Multicast(PixelMap pixelMap, Strips strips, int start_port, String host) {
    int controllers = strips.getControllerCount();
    
    this.pixelMap = pixelMap;
    this.strips = strips;
    this.hosts = new String[controllers];
    this.ports = new int[controllers];
    this.broadcasters = new Broadcast[controllers];
    this.pg = pixelMap.pg;

    for (int i=0; i<controllers; i++) {
      this.hosts[i] = host;
      this.ports[i] = start_port;
      start_port += 1;
    }    
  }
  
  public void setListen(boolean isListening) {
    this.isListening = isListening;
  }
  
  public void setPG(PGraphics pg) {
    this.pg = pg;
  }

  public void setup() {
    if (strips == null) {
      this.setupByHosts();
    }
    else {
      this.setupByStrips();
    }
    
    for (Broadcast broadcast : broadcasters) {
      broadcast.setup();
    }
  }
  
  protected void setupByHosts() {
    if (pixelMap.rows % hosts.length > 0) {
      throw new RuntimeException("The number of strips defined doesn't divide evenly by the number of controllers specified."); 
    }
    
    if (hosts.length != ports.length) {
      throw new RuntimeException("Mismatched number of hosts and ports");
    }
    
    int size = pixelMap.rows / hosts.length * pixelMap.columns;
    int offset = 0;
    for (int i=0; i<broadcasters.length; i++) {
      broadcasters[i] = getBroadcast(pixelMap, hosts[i], ports[i], offset, size);
      offset += size;
    }
  }
  
  protected void setupByStrips() {
    int lastController = strips.get(0).controller;;
    int hostNo = 0;
    int lastOffset = 0;
    int offset = 0;
    int size = 0;
        
    for (Strip strip : strips) {
      if (strip.controller != lastController) {
        broadcasters[lastController] = getBroadcast(pixelMap, hosts[hostNo], ports[hostNo], lastOffset, size);

        size = 0;
        hostNo++;
        lastController = strip.controller;
        lastOffset = offset;
      }
      size += strip.nLights;
      offset += strip.nLights;
    }
    
    broadcasters[lastController] = getBroadcast(pixelMap, hosts[hostNo], ports[hostNo], lastOffset, size);
  }
  
  protected Broadcast getBroadcast(PixelMap pixelMap, String host, int port, int offset, int size) {
    Broadcast b = new Broadcast(pixelMap, host, port);
    b.setOffset(offset);
    b.setSize(size);
    b.setListen(isListening);
    b.pg = pg;
    
    return b;
  }
  
  /**
   * Increments the last byte of an IP without doing any checks, DNS lookups, or overflows 
   */
  protected String nextHost(String host) {
    String[] parts = host.split(".");
    parts[3] = (int(parts[3]) + 1) + "";
    
    return String.join(".", parts);
  }
  
  public void update() {
    for (Broadcast broadcast : broadcasters) {
      broadcast.update();
    }
  }
  
  public void draw() {
    for (Broadcast broadcast : broadcasters) {
      broadcast.draw();
    }
  }
}

public class ArtNetMulticast extends Multicast {
  int rowsPerPacket = 1;
  
  public ArtNetMulticast(PixelMap pixelMap, String[] hosts, int[] ports) {
    super(pixelMap, hosts, ports);
  }
  public ArtNetMulticast(PixelMap pixelMap, Strips strips, String start_host, int port) {
    super(pixelMap, strips, start_host, port);
  }
  public ArtNetMulticast(PixelMap pixelMap, Strips strips, int start_port, String host) {
    super(pixelMap, strips, start_port, host);
  }
  
  public void setRowsPerPacket(int rowsPerPacket) {
    this.rowsPerPacket = rowsPerPacket;
  }
  
  protected Broadcast getBroadcast(PixelMap pixelMap, String host, int port, int offset, int size) {
    ArtNetBroadcast b = new ArtNetBroadcast(pixelMap, host, port);
    b.setOffset(offset);
    b.setSize(size);
    b.setListen(isListening);
    b.setRowsPerPacket(rowsPerPacket);

    return b;
  }
}

/***********************************************************************************************************************/

public class DisplayableStructure extends Displayable {
  PixelMap pixelMap;
  PGraphics pixelMapPG;
  Structure structure;
  PGraphics pg;            // Portion of structure, initialized in child
  Patchable<Integer> theBlendMode;
  Patchable<Float> transparency;

  public DisplayableStructure(PixelMap pixelMap, Structure structure) {
    this.pixelMap = pixelMap;
    this.structure = structure;
    pixelMapPG = this.pixelMap.pg;
    theBlendMode = new Patchable<Integer>(BLEND);
    transparency = new Patchable<Float>(255.0);
  }
}


/***********************************************************************************************************************/

public class DisplayableStrips extends DisplayableStructure {
  Strips strips;
  int rowOffset;

  public DisplayableStrips(PixelMap pixelMap, Structure structure) {
    super(pixelMap, structure);
    setup();
  }

  public void setup() {
    rowOffset = structure.rowOffset;
    strips = structure.strips;
    pg = createGraphics(structure.getMaxWidth(), strips.size());
  }

  public void display() {
    pixelMapPG.beginDraw();
    pixelMapPG.blendMode(theBlendMode.value());
    pixelMapPG.tint(255, transparency.value());
    pixelMapPG.image(pg, 0, rowOffset);
    pixelMapPG.endDraw();
  }
}


/***********************************************************************************************************************/

public class DisplayableLEDs extends DisplayableStrips {
  ArrayList<LEDs> ledMatrix;
  LEDs leds;
  int maxStripLength;

  public DisplayableLEDs(PixelMap pixelMap, Structure structure) {
    super(pixelMap, structure);
    //    setup();
  }

  public void setup() {
    super.setup();
    leds = new LEDs();
    maxStripLength = strips.getMaxStripLength();

    // Create LED Matrix that has a 1 to 1 ordered relationship to
    // the LEDs in the strip
    ledMatrix = new ArrayList<LEDs>();
    int nRows = strips.size();

    for (int row = 0; row < nRows; row++) {
      Strip strip = strips.get(row);
      int nCols = strip.nLights;
      LEDs stripLeds = new LEDs();

      for (int col = 0; col < nCols; col++) {
        LED thisLed = new LED();
        LED led = strip.leds.get(col);

        thisLed.position = led.position.get();
        stripLeds.add(thisLed);
        leds.add(thisLed);
      }

      ledMatrix.add(stripLeds);
    }
  }

  public void update() {
    pg.beginDraw();
    pg.clear();
    pg.loadPixels();

    int nRows = ledMatrix.size();

    for (int row = 0; row < nRows; row++) {
      LEDs stripLeds = ledMatrix.get(row);
      int nCols = stripLeds.size();
      int rowOffset = row * maxStripLength;

      for (int col = 0; col < nCols; col++) {
        LED led = stripLeds.get(col);
        pg.pixels[rowOffset + col] = led.c;
      }
    }
    
    pg.updatePixels();
    pg.endDraw();
  }
  
  public void clear() {
    for (LED led : leds) {
        led.c = color(0, 0);
    }
  }
}


/***********************************************************************************************************************/

public class LED {
  PVector position;
  color c;
 
  public LED() {
    this.position = new PVector();
    c = color(0);
  }

  public LED(PVector position) {
    this.position = position;
    c = color(0);
  }
}


/***********************************************************************************************************************/

public class LEDs extends ArrayList<LED> {
}


/***********************************************************************************************************************/

public class PixelMap extends Displayable {
  Strips strips;
  ArrayList<LED> leds;
  int rows = 0;
  int columns;
  PGraphics pg;
  int nLights;

  public PixelMap() {
    strips = new Strips();
  }

  public void addStrips(Strips theStrips) {
    strips.addAll(theStrips);
    rows += theStrips.size();
  }

  public void finalize() {
    leds = new LEDs();
    columns = 0;

    for (Strip strip : strips) {
      columns = max(columns, strip.nLights);

      for (LED L : strip.leds) {
        leds.add(L);
        L.c = color(random(255));
      }
    }

    pg = createGraphics(columns, rows);
    pg.beginDraw();
    pg.background(255, 0, 0);
    pg.endDraw();
    nLights = leds.size();
  }

  public void display() {
    try {
      pg.clear();
      image(pg, 0, 0);
    }
    catch (Exception e) {
      println("Frame: " + frameCount + "  PixelMap.display() exception. Could not draw image");
    }
  }
}


/***********************************************************************************************************************/

public class Strip {
  int id = -1;
  PVector p1;
  PVector p2;
  int density;
  int nLights;
  ArrayList<LED> leds;
  int controller = -1;
  int port = -1;

  public Strip(PVector p1, PVector p2, int density) {
    this(p1, p2, density, ceil(dist(p1, p2) / meter * density));
  }
  
  public Strip(PVector p1, PVector p2, int density, int nLights) {
    this(-1, p1, p2, density, nLights, -1, -1);
  }
  
  public Strip(int id, PVector p1, PVector p2, int density, int nLights, int controller, int port) {
    this.id = id;
    this.p1 = p1;
    this.p2 = p2;
    this.density = density;
    this.nLights = nLights;
    this.controller = controller;
    this.port = port;
    
    this.createLEDs();
  }
  
  public Strip(JSONObject data) {
    this.id = data.getInt("id");
    this.density = data.getInt("density");
    this.nLights = data.getInt("numberOfLights");
    this.controller = data.isNull("controller") ? -1 : data.getInt("controller");
    this.port = data.isNull("port") ? -1 : data.getInt("port");

    JSONArray startPoint = data.getJSONArray("startPoint");
    JSONArray endPoint = data.getJSONArray("endPoint");

    // Apply transformations
    float x1 = startPoint.getInt(0);
    float y1 = startPoint.getInt(1);
    float z1 = startPoint.getInt(2);
    float x2 = endPoint.getInt(0);
    float y2 = endPoint.getInt(1);
    float z2 = endPoint.getInt(2);
    float x3 = modelX(x1, y1, z1); 
    float y3 = modelY(x1, y1, z1); 
    float z3 = modelZ(x1, y1, z1); 
    float x4 = modelX(x2, y2, z2); 
    float y4 = modelY(x2, y2, z2); 
    float z4 = modelZ(x2, y2, z2); 

    this.p1 = new PVector(x3, y3, z3);
    this.p2 = new PVector(x4, y4, z4);
    
    this.createLEDs();
  }
  
  protected void createLEDs() { 
    // Create positions for each LED
    leds = new ArrayList<LED>();    
    for (int i = 0; i < nLights; i++) {
      float n = i / float(nLights);
      PVector p = lerp(p1, p2, n);
      leds.add(new LED(p));
    }
  }
}


/***********************************************************************************************************************/

public class Strips extends ArrayList<Strip> {
  public int getMaxStripLength() {
    int L = 0;
    for (Strip strip : this) {
      if (strip.nLights > L) {
        L = strip.nLights;
      }
    }
    return L;
  }
  
  public void loadFromJSON(String filename) {
    JSONArray values = loadJSONArray(filename);
    int nValues = values.size();

    for (int i = 0; i < nValues; i++) {
      JSONObject data = values.getJSONObject(i);
      this.add(new Strip(data));
    }
    
    // If controller and port are specified sort so that
    // the rows are in controller/port order.
    if (this.size() > 0 && this.get(1).controller > 0) {
      this.sortList();
    }
  }
  
  // Sort by controller, then port.  
  protected void sortList() {
    Collections.sort(this, new Comparator<Strip>() {
      @Override
      public int compare(Strip left, Strip right) {
        int result = new Integer(left.controller).compareTo(right.controller);
        
        if (result == 0)
          result = new Integer(left.port).compareTo(right.port);
          
        return result;
      }
    });
  }
  
  public void writeToJSON(String saveAs) {
    JSONArray values = new JSONArray();

    for (int i = 0; i < this.size (); i++) {
      JSONObject data = new JSONObject();
      Strip strip = this.get(i);

      data.setInt("id", i);
      data.setInt("density", strip.density);
      data.setInt("numberOfLights", strip.nLights);
  
      JSONArray p1 = new JSONArray();
      p1.setFloat(0, strip.p1.x);
      p1.setFloat(1, strip.p1.y);
      p1.setFloat(2, strip.p1.z);
      data.setJSONArray("startPoint", p1);
  
      JSONArray p2 = new JSONArray();
      p2.setFloat(0, strip.p2.x);
      p2.setFloat(1, strip.p2.y);
      p2.setFloat(2, strip.p2.z);    
      data.setJSONArray("endPoint", p2);
  
      values.setJSONObject(i, data);
    }

    println(values);
    saveJSONArray(values, saveAs);
  }
  
  public int getControllerCount() {
    return this.get(this.size() - 1).controller + 1;
  }
}


/***********************************************************************************************************************/

public class Structures extends ArrayList<Structure> {
}


/***********************************************************************************************************************/

public class Structure {
  PixelMap pixelMap;
  String filename;
  Strips strips;
  int rowOffset = 0;

  public Structure(PixelMap pixelMap) {
    this.pixelMap = pixelMap;
  }

  public Structure(PixelMap pixelMap, String filename) {
    this.pixelMap = pixelMap;
    this.filename = filename;
    setup();
  }  

  public void setup() {
    strips = new Strips();    
    strips.loadFromJSON(filename);
    rowOffset = pixelMap.rows;
    this.pixelMap.addStrips(strips);
  }

  int getMaxWidth() {
    int w = 0;
    for (Strip strip : strips) {
      int size = strip.nLights;

      if (size > w) {
        w = size;
      }
    }
    return w;
  }
  // getBox
  // getHeight
  // getDepth
  // getXBoundaries
  // etc...
}


/***********************************************************************************************************************/

public class ComboStructure extends Structure {
  ComboStructure(PixelMap pixelMap, Structures structures) {
    super(pixelMap);
  }
}


/***********************************************************************************************************************/

public class StructurePixelMap extends Structure {
  StructurePixelMap(PixelMap pixelMap) {
    super(pixelMap);
    setup();
  }

  public void setup() {
    strips = new Strips();
    strips.addAll(pixelMap.strips);
    rowOffset = 0;
  }
}

/***********************************************************************************************************************
*
* UTILITY FUNCITONS
* 
***********************************************************************************************************************/

// Distance between two PVectors
float dist(PVector p1, PVector p2) {
  return dist(p1.x, p1.y, p1.z, p2.x, p2.y, p2.z);
}

// Interpolate between two PVectors
PVector lerp(PVector p1, PVector p2, float amt) {
  float x = lerp(p1.x, p2.x, amt);
  float y = lerp(p1.y, p2.y, amt);
  float z = lerp(p1.z, p2.z, amt);

  return new PVector(x, y, z);
}

// Convert point to include matrix translation
PVector transPVector(float x, float y, float z) {
  float x1 = modelX(x, y, z);
  float y1 = modelY(x, y, z);
  float z1 = modelZ(x, y, z);
  return new PVector(x1, y1, z1);  
}

// Convert point to include matrix translation
PVector transPVector(PVector p) {
  return transPVector(p.x, p.y, p.z);  
}

// Inches to Centimeters
float inchesToCM(float inches) {
  return inches / 0.393701;
}