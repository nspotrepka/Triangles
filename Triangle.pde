
class Triangle {
  PVector[] v;
  PVector[] n;
  color c;
  
  Triangle(PVector[] v, color c) {
    this.v = v;
    n = new PVector[v.length-2];
    for(int i=0; i<v.length-2; i++) {
      PVector v1 = v[i].get();
      PVector v2 = v[i].get();
      v1.sub(v[i+1]);
      v2.sub(v[i+2]);
      n[i] = v1.cross(v2);
      n[i].normalize();
    }
    this.c = c;
  }
  
  void render(PGraphics g) {
    g.fill(c);
    g.beginShape(TRIANGLES);
    for(int i=0; i<v.length-2; i++) {
      g.normal(n[i].x, n[i].y, n[i].z);
      g.vertex(v[i].x, v[i].y, v[i].z);
    }
    g.endShape();
  }
}
