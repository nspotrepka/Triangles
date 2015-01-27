
class DirectionalLight {
  PVector v;
  
  DirectionalLight(PVector v) {
    v.normalize();
    this.v = v;
  }
  
  void render(PGraphics g) {
    g.directionalLight(0, 0, 100, v.x, v.y, v.z);
  }
}
