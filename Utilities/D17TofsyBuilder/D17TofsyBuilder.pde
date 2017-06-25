import peasy.*;
import peasy.org.apache.commons.math.*;
import peasy.org.apache.commons.math.geometry.*;

// This is the very specific pink used to denote surfaces which
// will host LEDs.
static final int SURFACE_COLOR = -1069827;

// Model to load
static final String INPUT_FILE = "../../Data/tofsy-textured.obj";

// Filename to write to (set to null to not write a file)
static final String OUTPUT_FILE = "../../Data/tofsy.json";

// The short edge of the surface is approximately this size.
static final float SURFACE_SHORT_SIZE = 4.68;
static final float SURFACE_SHORT_TOLERANCE = 0.01;

// Length of the surface and LED strip in inches.
static final float SURFACE_LENGTH = 96;
static final float LEDS_LENGTH = 78.74; // 2m
static final float SURFACE_LED_LERP = (1.0 - (LEDS_LENGTH / SURFACE_LENGTH)) / 2.0;

// 60/m * 2m
static final int LEDS_DENSITY = 120;

PShape model;
PShape child;
PeasyCam cam;

ArrayList<Strip> strips = new ArrayList<Strip>();
JSONArray array = new JSONArray();

public void setup() {
  size(1280, 720, P3D);
  model = loadShape(INPUT_FILE);
  invertShape(model);
  
  cam = new PeasyCam(this, 0, -150, -450, 500);
  cam.setMinimumDistance(1);
  cam.setMaximumDistance(1000);
  cam.setSuppressRollRotationMode();

  int id = 0;
  ArrayList<PShape> shapes = findMarkedShapes();
  for (PShape shape : shapes) {
    
    PVector[] sides = findShortSides(shape);
    PVector[] stripVectors = calcStripLocation(sides);
    Strip strip = new Strip(stripVectors[0], stripVectors[1], LEDS_DENSITY);
    strips.add(strip);
  
    //PVector[] rotatedVectors = rotateStrip(stripVectors);
    array.setJSONObject(id, getJSONObject(id, stripVectors));
    id++;
  }
  
  if (OUTPUT_FILE != null) {
    saveJSONArray(array, OUTPUT_FILE);
    println("Wrote " + OUTPUT_FILE + ".");
  }
}


//public PVector[] rotateStrip(PVector[] vectors) {
//  PVector[] result = new PVector[2];
  
//  // Rotate/translate strip because Sketchup outputs 
//  // everything rotated 180º around X/Z
//  //pushMatrix();
//  //rotateZ(PI);
//  //result[0] = getMatrix().mult(vectors[0], null);
//  //result[1] = getMatrix().mult(vectors[1], null);
//  //popMatrix();
//  result[0] = vectors[0].copy();
//  result[1] = vectors[1].copy();
//  result[0].y = -result[0].y;
//  result[1].y = -result[1].y;
  
//  return result;
//}

public JSONObject getJSONObject(int id, PVector[] vectors) {
  JSONObject result = new JSONObject();
  
  result.setInt("id", id);
  result.setInt("density", LEDS_DENSITY/2);
  result.setInt("numberOfLights", LEDS_DENSITY);
  
  JSONArray start = new JSONArray();
  start.setFloat(0, vectors[0].x);
  start.setFloat(1, vectors[0].y);
  start.setFloat(2, vectors[0].z);
  result.setJSONArray("startPoint", start);
  
  JSONArray end = new JSONArray();
  end.setFloat(0, vectors[1].x);
  end.setFloat(1, vectors[1].y);
  end.setFloat(2, vectors[1].z);
  result.setJSONArray("endPoint", end);
  
  return result;
}

public int offset(int num, int ofs, int size) {
  num += ofs;
  if (num > size) num = 0;
  else if (num < 0) num = size - 1;
  
  return num;
}

public ArrayList<PShape> findMarkedShapes() {
  ArrayList<PShape> shapes = new ArrayList<PShape>();
  
  for (int i=0; i<model.getChildCount(); i++) {
    child = model.getChild(i);
    if (child.getFill(0) == SURFACE_COLOR) {
      shapes.add(child);
    }
  }
 
  println("Found " + shapes.size() + " shapes.");
  
  return shapes;
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
  
public PVector[] findShortSides(PShape shape) {
  PVector[] result = new PVector[4];
  int ridx = 0;
  
  for (int i=0; i<shape.getVertexCount(); i++) {
    int j = offset(i, 1, shape.getVertexCount()-1);
    PVector a = shape.getVertex(i);
    PVector b = shape.getVertex(j);
    float d = a.dist(b);
    
    if (d > SURFACE_SHORT_SIZE-SURFACE_SHORT_TOLERANCE &&
        d < SURFACE_SHORT_SIZE+SURFACE_SHORT_TOLERANCE) 
    {
      result[ridx] = a;
      result[ridx+1] = b;
      ridx += 2;
    }    
  }
 
  return result;
}

public PVector[] calcStripLocation(PVector[] sides) {
  PVector[] result = new PVector[2];
  
  PVector a = PVector.lerp(sides[0], sides[1], 0.5);
  PVector b = PVector.lerp(sides[2], sides[3], 0.5);
  PVector la = PVector.lerp(a, b, SURFACE_LED_LERP);
  PVector lb = PVector.lerp(b, a, SURFACE_LED_LERP);
  
  if (la.y < lb.y || (la.y == lb.y && la.x < lb.x)) {
    result[0] = la;
    result[1] = lb;
  }
  else {
    result[0] = lb;
    result[1] = la;
  }
  
  return result;
}

public void draw() {
  background(50);
  
  pushStyle();
  pushMatrix();
  
  translate(0,0,-400);
  //rotateZ(PI);
  shape(model);
  noStroke();
  
  for (Strip strip : strips) {
      strip.draw();
  }
  
  popMatrix();
  popStyle();  
}