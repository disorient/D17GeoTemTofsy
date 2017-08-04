import hypermedia.net.*;
import moonpaper.*;
import moonpaper.opcodes.*;

import peasy.org.apache.commons.math.*;
import peasy.*;
import peasy.org.apache.commons.math.geometry.*;

public static final String TEATRO_MODEL = "../../Data/teatro.obj";
public static final String TOFSY_MODEL = "../../Data/tofsy.obj";
public static final String TOFSY_JSON = "../../Data/tofsy.json";

float lightSize = 4;  // Size of LEDs

Strips strips;
PixelMap pixelMap;
String ip = "localhost";
int port = 6100;

PeasyCam g_pCamera;
PShape teatro_model;
PShape tofsy_model;
ArtNetBroadcast broadcastReceiver;
Multicast multicast;

void drawPlane() {
  float corner = 10000;
  pushStyle();
  fill(64);  
  beginShape();
  vertex(corner, 0, corner);
  vertex(corner, 0, -corner);
  vertex(-corner, 0, -corner);
  vertex(-corner, 0, corner);
  endShape(CLOSE);
  popStyle();
}

void setup() {
  size(1280, 720, P3D);
  frameRate(60);
  
  g_pCamera = new PeasyCam(this, 100, -200, 0, 700);
  g_pCamera.setMinimumDistance(100);
  g_pCamera.setMaximumDistance(5000);
  g_pCamera.setWheelScale(1);
  //g_pCamera.setYawRotationMode();
  g_pCamera.rotateY(-PI/8);

  // Fix the front clipping plane
  float fov = PI/3.0;
  float cameraZ = (height/2.0) / tan(fov/2.0);
  perspective(fov, float(width)/float(height), cameraZ/1000.0, cameraZ*50.0);

  // Setup Virtual Installation  
  strips = new Strips();

  // Load teatro
  teatro_model = loadShape(TEATRO_MODEL);
  invertShape(teatro_model);
  
  // Load tofsy
  tofsy_model = loadShape(TOFSY_MODEL);
  invertShape(tofsy_model);
  Strips tofsy_strips = new Strips();
  strips.loadFromJSON(TOFSY_JSON);
  strips.addAll(tofsy_strips);

  // Generate PixelMap
  pixelMap = new PixelMap();
  pixelMap.addStrips(strips);
  pixelMap.finalize();

  // Receiver
  broadcastReceiver = new ArtNetBroadcast(pixelMap, ip, port, 0, pixelMap.columns * pixelMap.rows, true);
  //multicast = new Multicast(pixelMap, strips, port, ip, true);
  //multicast = new Multicast(pixelMap, new String[] { ip, ip }, new int[] { port, port + 1 }, true);
}

void pixelMapToStrips(PixelMap pixelMap, Strips strips) {
  int rows = strips.size();
  PGraphics pg = pixelMap.pg;
  pg.loadPixels();

  for (int row = 0; row < rows; row++) {
    Strip strip = strips.get(row);
    ArrayList<LED> lights = strip.leds;
    int cols = strip.nLights;
    int rowOffset = row * pixelMap.columns;

    for (int col = 0; col < cols; col++) {
      LED led = lights.get(col);
      led.c = pg.pixels[rowOffset + col];
    }
  }
}

// Processing's coordinate system is "left-handed", whereas 
// SketchUp is "right-handed".  We should invert all three
// axis, but either Processing or SketchUp has the Z axis
// backwards.
public void invertShape(PShape shape) {
  for (int i=0; i<shape.getChildCount(); i++) {
    PShape child = shape.getChild(i);
    for (int j=0; j<child.getVertexCount(); j++) {
      PVector v = child.getVertex(j);
      v.y = -v.y;
      v.x = -v.x;
      
      child.setVertex(j, v);
    }
  }
}

void draw() {
  background(32);
  pushMatrix();

  // Draw landscape and structure  
  drawPlane();

  // Draw Teatro
  pushMatrix();
  translate(510,0,-2000);
  rotateX(PI-PI/2);
  rotateZ(PI/12);
  scale(30);
  shape(teatro_model, 0, 0);
  popMatrix();

  // Draw Tofsy
  pushStyle();
  noStroke();
  pushMatrix();
  shape(tofsy_model);
  popMatrix();
  
  broadcastReceiver.draw();
  //multicast.draw();
  pixelMapToStrips(pixelMap, strips);
  
  for (Strip strip : strips) {
    for (LED led : strip.leds) {
      pushMatrix();
      PVector p = led.position;
      fill(led.c);
      translate(p.x, p.y, p.z);
      box(lightSize);
      popMatrix();
    }
  }
  
  popStyle();
  popMatrix();
}