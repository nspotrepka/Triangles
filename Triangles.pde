// Current triangles
ArrayList<Triangle> triangles = new ArrayList<Triangle>();
// Next triangles to be displayed
ArrayList<Triangle> trianglesNext = new ArrayList<Triangle>();


// OPTIONS

// color options
int colors = 3;
int complexity = 1;

// distance from center
float z = 0;

// Pixelation
boolean pixelate = false;
int pixelSize = 32;

// Audio Visualizer
boolean regenerateOnTransients = false;

// Movement variables
float radius = 1.0/complexity;
float petals = 1.5;
float theta = 0;
float slowness = 360.0;

//Lighting
boolean renderLights = false;
DirectionalLight[] lights = new DirectionalLight[6];
//PShader lightShader;

// Drawing
PGraphics g;

// Show info text
boolean showText = true;


void setup() {
  frameRate(120);
  noCursor();
  size(displayWidth, displayHeight, P2D);
  colorMode(HSB, 360, 100, 100, 100);
  
  g = createGraphics(displayWidth, displayHeight, P3D);
  
  //lightShader = loadShader("lightfrag.glsl", "lightvert.glsl");
  
  createTriangles();
  triangles = trianglesNext;
  createTriangles();
}

void draw() {
  
  /* BEGIN 3D DRAWING */
  
  g.beginDraw();
  g.colorMode(HSB, 360, 100, 100, 100);
  g.perspective(PI/3.0f, (float)width/height, complexity, 100000);
  g.background(0, 0, 100);
  //g.shader(lightShader);
  
  // Lighting
  if(renderLights) {
    for(int i=0; i<lights.length; i++) {
      lights[i].render(g);
    }
  }
  
  double r = complexity*radius + complexity*radius*cos(petals*theta);
  
  g.pushMatrix();
  
  // Transformations
  g.translate((float)(r*cos(theta)), (float)(-r*sin(theta)), (float)(width/4*pow(sin(theta/20), 3)-sin(theta)));
  g.translate(width/2, height/2, -z);
  g.rotateX(0.00005f*z*sin(theta));
  g.rotateY(0.00005f*z*cos(theta));
  g.rotateX(-PI/6);
  g.rotateZ(0.01f*theta+0.02f*sin(theta));
  
  g.scale(1);
  g.noStroke();
  // Slowly shift triangle hue
  boolean changeHue = random(1)<0.025;
  for(Triangle t : triangles) {
    
    float a = alpha(t.c);
    float h = hue(t.c);
    float s = saturation(t.c);
    float b = brightness(t.c);
    if(changeHue)
      h++;
    t.c = color(h, s, b, a);
    
    t.render(g);
  }
  
  g.popMatrix();
  g.endDraw();
  
  /* END 3D DRAWING */
  
  g.loadPixels();
  
  // Pixelation
  if(pixelate) {
    color[] gPixels = new color[g.pixels.length];
    for(int i=0; i<g.pixels.length; i++) {
      int x = i % width;
      int y = i / width;
      gPixels[i] = g.pixels[(x-x%pixelSize)+width*(y-y%pixelSize)];
    }
    for(int i=0; i<g.pixels.length; i++) {
      g.pixels[i] = gPixels[i];
    }
  }
  
  g.updatePixels();
  
  noStroke();
  background(0, 0, 100);
  // Draw the final image
  image(g, 0, 0);
  
  // Text on screen
  if(showText) {
    fill(300);
    text("fps: "+frameRate, 30, 30);
    text("Press T to toggle this text", 30, 60);
    text("Press L to toggle lighting: "+(renderLights?"LIGHTS ON":"LIGHTS OFF"), 30, 120);
    text("Press P to toggle pixelation: "+(pixelate?"PIXELATION ON":"PIXELATION OFF"), 30, 150);
    text("Press UP and DOWN to change pixel size: PIXEL SIZE "+pixelSize, 30, 180);
    text("Press Z to toggle zoom: "+(z==0?"NEAR":"FAR"), 30, 210);
    text("Press SPACE to generate a new world", 30, 240);
  }
  
  theta += PI/slowness;
}

void stop() {
  super.stop();
}

void mousePressed() {
  nextTriangles();
}

void keyPressed() {
  if(key == ' ') {
    nextTriangles();
  } else if(key == 'l' || key == 'L') {
    renderLights = !renderLights;
  } else if(key == 'p' || key == 'P') {
    pixelate = !pixelate;
  } else if(key == 't' || key == 'T') {
    showText = !showText;
  } else if(keyCode == UP) {
    if(pixelSize < width)
      pixelSize *= 2;
  } else if(keyCode == DOWN) {
    if(pixelSize > 1)
      pixelSize /= 2;
  } else if(key == 'z' || key == 'Z') {
    if(z == 0)
      z = 3000;
    else
      z = 0;
  }
}

void nextTriangles() {
  triangles = trianglesNext;
  redraw();
  createTriangles();
}

void createTriangles() {
  trianglesNext.clear();
  int n = colors;
  float rHue = random(360);
  for(int i=0; i<n; i++) {
    int nSides = complexity*1000/colors;
    PVector[] v = new PVector[nSides];
    
    // Generate vertices
    for(int k=0; k<v.length; k++) {
      float p = random(2*PI);
      float t = acos(random(-1, 1));
      float x = width*cos(p)*sin(t);
      float y = width*sin(p)*sin(t);
      float z = width*cos(t);
      v[k] = new PVector(x, y, z);
    }
    
    // Generate colors
    color c = color((rHue + (45f)*i) % 360f, 84f+random(16f), 100f*i/n + random(100f/n), random(50f));
    
    // Add triangle
    trianglesNext.add(new Triangle(v, c));
  }
  
  // Generate point light position
  float p = random(2*PI);
  float t = acos(random(-1, 1));
  float x = width*2*cos(p)*sin(t);
  float y = width*2*sin(p)*sin(t);
  float z = width*2*cos(t);
  float h = sqrt(x*x + y*y);
  
  // Generate point lights
  lights[0] = new DirectionalLight(new PVector(x, y, z));
  lights[1] = new DirectionalLight(new PVector(-x, -y, -z));
  lights[2] = new DirectionalLight(new PVector(-y, x, 0));
  lights[3] = new DirectionalLight(new PVector(y, -x, 0));
  lights[4] = new DirectionalLight(new PVector(x*z/h, y*z/h, -h));
  lights[5] = new DirectionalLight(new PVector(-x*z/h, -y*z/h, h));
  
}