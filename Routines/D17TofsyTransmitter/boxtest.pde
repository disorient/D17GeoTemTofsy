class BoxTest extends DisplayableLEDs {
  //class Box {
  //  PVector t;
  //  PVector r;
  //  PVector s;
  //  PVector[] b;
  //  color c;
    
  //  public Box(PVector t, PVector r, PVector s) {
  //    this.t = t;
  //    this.r = r;
  //    this.s = s;
  //    this.b = new PVector[2];
  //    this.b[0] = new PVector();
  //    this.b[1] = new PVector();
  //  }
    
  //  public void applyMatrix() {
  //    pg.translate(t.x,t.y,t.z);
  //    pg.rotateX(r.x);
  //    pg.rotateY(r.y);
  //    pg.rotateZ(r.z);
  //  }

  //  public void applyBounds() {
  //    pg.scale(s.x,s.y,s.z);

  //    b[0].x = pg.modelX(-0.5,-0.5,-0.5);
  //    b[0].y = pg.modelY(-0.5,-0.5,-0.5);
  //    b[0].z = pg.modelZ(-0.5,-0.5,-0.5);
  //    b[1].x = pg.modelX(0.5,0.5,0.5);
  //    b[1].y = pg.modelY(0.5,0.5,0.5);
  //    b[1].z = pg.modelZ(0.5,0.5,0.5);
  //  }
  //  public void draw() {
  //    pg.lights();

  //    pg.pushMatrix();
  //    pg.pushStyle();
      
  //    applyMatrix();
      
  //    pg.stroke(c);
  //    pg.noFill();
  //    pg.box(s.x, s.y, s.z);
      
  //    applyBounds();
      
  //    pg.popMatrix();
  //    pg.popStyle();
  //  }
    
  //}
  
  PixelMap pixelMap;
  
  //Box b;
  
  BoxTest(PixelMap pixelMap, Structure structure) {
    super(pixelMap, structure);
    
    this.pixelMap = pixelMap;
    
    
    //b = new Box(new PVector(1024/2,768/2,0),new PVector(0,0,0), new PVector(100,100,100));
    //b.c = color(0,255,0);
  }
  
  int i = 0;
  float r = 0;
  
  void preview(PGraphics ppg) {
    ppg.beginDraw();
    
    ppg.background(0);

    ppg.pushStyle();
    r += Math.PI / 100;

    ppg.noStroke();
    
    i=0;
    for (LED l : pixelMap.leds) {
      println(i++);
      ppg.pushMatrix();
      ppg.translate(l.position.x, l.position.y, l.position.z);
      ppg.rotateX(r);
      ppg.rotateY(r);
      ppg.fill(l.c);
      ppg.box(5);
      ppg.popMatrix();
    }
    
    ppg.popStyle();
    
    ////b.r.x += Math.PI/100;
    ////b.r.y += Math.PI/100;
    ////b.draw();
    
    ppg.endDraw();
  }
}