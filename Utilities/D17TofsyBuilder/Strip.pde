public class Strip {
  PVector a;
  PVector b;
  int idx;    // Original position based on sorting by Y,X,Z
  int id;     // Position updated by user
  float leds;
  PFont font;
  boolean isHighlighted;
  boolean isDuplicate;
  boolean isInverted;
  
  public Strip(PVector a, PVector b, int idx, int leds) {
    this.a = a;
    this.b = b;
    this.id = this.idx = idx;
    this.leds = leds;
    this.isHighlighted = false;
    this.isDuplicate = false;
    this.isInverted = false;
    font = createFont("Arial Bold.ttf", 14);
  }
  
  public void draw(int idx) {
    PVector v;

    pushStyle();
    pushMatrix();
    translate(a.x, a.y, a.z);
    fill(255);
    if (isHighlighted)
      box(10);
    else
      box(4);
    popMatrix();
    popStyle();
    
    pushStyle();
    pushMatrix();
    translate(b.x, b.y, b.z);
    fill(0);
    if (isHighlighted)
      box(10);
    else
      box(4);
    popMatrix();
    popStyle();

    pushMatrix();
    pushStyle();
    if (this.isDuplicate)
      fill(255,0,0);
    else
      fill(255);
    
    if (this.isHighlighted)
      textFont(font, 14);
    else
      textFont(font, 9);
      
    v = PVector.lerp(a, b, 0.5);
    translate(v.x, v.y, v.z);
    rotateX(cam.getRotations()[0]);
    rotateY(cam.getRotations()[1]);
    rotateZ(cam.getRotations()[2]);
    
    text(idx+"="+id, 0, 0, 0);
    
    popStyle();
    popMatrix();

    pushStyle();
    colorMode(HSB);
    
    for (int i=0; i<leds; i++) {
      if (isHighlighted)
        fill(0, 192, 255);
      else
        fill(int(i/leds*255), 255, 127);
        
      v = PVector.lerp(a, b, i/(leds-1));
      pushMatrix();  
      translate(v.x, v.y, v.z);
      box(2);
      popMatrix();  
    }
    
    popStyle();
  }
  
  public int compareTo(Strip that) {
    int result = new Float(this.a.y).compareTo(that.a.y);

    if (result != 0)
        return result;

    result = new Float(this.a.x).compareTo(that.a.x);

    if (result != 0)
        return result;

    result = new Float(this.a.z).compareTo(that.a.z);

    return result;
  }

  public void invert() {
    this.isInverted = !this.isInverted;
    PVector tmp = this.a;
    this.a = this.b;
    this.b = tmp;
  }
} 