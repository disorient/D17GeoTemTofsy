public class Strip {
  PVector a;
  PVector b;
  float density;
  
  public Strip(PVector a, PVector b, float density) {
    this.a = a;
    this.b = b;
    this.density = density;
  }
  
  public void draw() {
    pushStyle();
    pushMatrix();
    translate(a.x, a.y, a.z);
    fill(255);
    box(4);
    popMatrix();
    popStyle();
    
    pushStyle();
    pushMatrix();
    translate(b.x, b.y, b.z);
    fill(0);
    box(4);
    popMatrix();
    popStyle();
    
    pushStyle();
    colorMode(HSB);
    
    PVector v;
    for (int i=0; i<density; i++) {
      fill(int(i/density*255), 255, 255);
      v = PVector.lerp(a, b, i/(density-1));
      pushMatrix();  
      translate(v.x, v.y, v.z);
      box(2);
      popMatrix();  
    }
    
    popStyle();
  }
  
  
} 