/*

 Test Pattern lights each strip in order.

 */

class TestPattern extends DisplayableStrips {
  int s=0;

  TestPattern(PixelMap pixelMap, Structure structure) {
    super(pixelMap, structure);
  }

  void display() {
    pg.beginDraw();
    pg.clear();

    pg.stroke(255);
    pg.line(0,s,pg.width,s);
    
    pg.endDraw();
    
    if (frameCount % 10 == 0) {
      s++;
      if (s>pg.height) s=0;
    }
    
    super.display();
  }
}