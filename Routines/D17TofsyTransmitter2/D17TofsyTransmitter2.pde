import hypermedia.net.*;
import moonpaper.*;
import moonpaper.opcodes.*;

// Turn on frame capture
boolean captureFrames = false;
String captureFolder = "./frames/";

// Broadcast
Broadcast broadcast;
Multicast multicast;
String ip = "localhost"; 
int port = 6100;

// Set FrameRate
int fps = 60;        // Frames-per-second

public static final String TOFSY_JSON = "../../Data/tofsy.json";

// PixelMap and Structures
Structure tofsy;
PixelMap pixelMap;  // PixelMap is the master canvas which all animations will draw to
Moonpaper mp;

// Animation
StripSweep stripSweep;

void verifySize() {
  if (width != pixelMap.pg.width || height != pixelMap.pg.height) {
    println("Set size() in setup to this:");
    println("  size(" + pixelMap.pg.width + ", " + pixelMap.pg.height + ", P2D);");
    exit();
  }
}

void setupPixelMap() {
  // Setup Virtual LED Installation  
  pixelMap = new PixelMap();  // Create 2D PixelMap from strips

  // Create teatro structure
  tofsy = new Structure(pixelMap, TOFSY_JSON);

  // Once all structures are loaded, finalize the pixelMap
  pixelMap.finalize();
  verifySize();
}

void setup() {
  size(75, 80, P3D);
  frameRate(fps);
  
  // Load in structures and create master PixelMap
  setupPixelMap();

  // Setup Broadcasting
  //broadcast = new Broadcast(this, pixelMap, ip, port);
  //broadcast.pg = g;
  multicast = new Multicast(pixelMap, tofsy.strips, port, ip);
  //multicast = new Multicast(pixelMap, new String[] { ip, ip }, new int[] { port, port + 1 });
  multicast.setPG(g);

  // Create sequence
  createSequence();
}

void draw() {
  background(0);

  // Update and display animation
  mp.update();
  mp.display();

  // Capture frame
  if (captureFrames) {
    saveFrame(captureFolder + "f########.png");
  }

  // Broadcast to simulator
  //broadcast.update();
  multicast.update();
}