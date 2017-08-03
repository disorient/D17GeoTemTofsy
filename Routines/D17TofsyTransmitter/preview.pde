public class Preview extends PApplet {
  PImage nextFrame = null;
  PImage thisFrame = null;
  
  public Preview() {
    
  }
  
  public void setFrame(PGraphics pg) {
    this.nextFrame = pg.copy();
  }
  
  public void settings() {
    size(1024, 768, P3D);
  }
  
  public void setup() {
    background(0);
  }
  
  public void draw() {
    if (thisFrame != null)
      image(thisFrame, 0 ,0);
     
    if (nextFrame != null) {
      thisFrame = nextFrame;
      nextFrame = null;
    } 
  }  
}