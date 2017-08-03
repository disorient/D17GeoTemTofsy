class Box extends DisplayableLEDs {
  PVector v1 = new PVector(100000,100000,100000);
  PVector v2 = new PVector(-100000,-100000,-100000);
  float size = 0.25;
  float r = 0;
  PVector v = new PVector(0,0,0);
  PGraphics rg;
  
  Box(PixelMap pixelMap, Structure structure) {
    super(pixelMap, structure);
    rg = createGraphics(1,1,P3D);
    findDimensions();
  }
  
  void findDimensions() {
    for (LED led : leds) {
      v1.x = min(v1.x, led.position.x);
      v1.y = min(v1.y, led.position.y);
      v1.z = min(v1.z, led.position.z);
      v2.x = max(v2.x, led.position.x);
      v2.y = max(v2.y, led.position.y);
      v2.z = max(v2.z, led.position.z);
    }
    
    v1.x = v1.x + (v2.x - v1.x) * (size / 2);
    v2.x = v2.x - (v2.x - v1.x) * (size / 2);
    v1.y = v1.y + (v2.y - v1.y) * (size / 2);
    v2.y = v2.y - (v2.y - v1.y) * (size / 2);
    v1.z = v1.z + (v2.z - v1.z) * (size / 2);
    v2.z = v2.z - (v2.z - v1.z) * (size / 2);
    
  }
  
  void update() {
    rg.pushMatrix();
    r += Math.PI / 100;
    rg.translate((v2.x-v1.x)/2,(v2.y-v1.y)/2,0);
    rg.rotateZ(r);
    
    for (LED led : leds) {
      v.x = rg.modelX(led.position.x, led.position.y, led.position.z);
      v.y = rg.modelY(led.position.x, led.position.y, led.position.z);
      v.z = rg.modelZ(led.position.x, led.position.y, led.position.z);
      
      if (v.x > v1.x && v.y > v1.y && v.z > v1.z &&
          v.x < v2.x && v.y < v2.y && v.z < v2.z
      ) {
            led.c = color(255,0,0);
      }
      else {
        led.c = color(0);
      }   
    }
    rg.popMatrix();
    super.update();
  }
}