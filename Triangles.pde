import ddf.minim.spi.*;
import ddf.minim.signals.*;
import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.ugens.*;
import ddf.minim.effects.*;


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
boolean audioDraw = false;
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

// Audio Settings
Minim minim;
AudioInput in;
BeatDetect beat;
FFT fftLeft;
FFT fftRight;
int type = Minim.STEREO;
int bufferSize = 1024;
float sampleRate = 48000.0f;
int bitRate = 16;
float pTime = 0.0f;
float release = 200.0f;

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
  
  minim = new Minim(this);
  in = minim.getLineIn(type, bufferSize, sampleRate, bitRate);
  beat = new BeatDetect(bufferSize, sampleRate);
  fftLeft = new FFT(bufferSize, sampleRate);
  fftRight = new FFT(bufferSize, sampleRate);
}

void draw() {
  // Beat detection
  beat.detect(in.mix);
  if(regenerateOnTransients && beat.isKick() && (beat.isSnare() || beat.isHat()) && (millis() - pTime) >= release) {
    nextTriangles();
    pTime = millis();
  }
  // Spectral analysis
  fftLeft.forward(in.left);
  fftRight.forward(in.right);
  
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

  // Audio Visualizer
  if(audioDraw) {
    float[] fftLeftBand = new float[fftLeft.specSize()];
    float[] fftRightBand = new float[fftRight.specSize()];
    for(int i=0; i<fftLeft.specSize(); i++) {
      fftLeftBand[i] = fftLeft.getBand(i);
      fftRightBand[i] = fftRight.getBand(i);
    }
    
    color[] gPixels = new color[g.pixels.length];
    int[] indices = new int[width];
    for(int i=0; i<indices.length; i++) {
      indices[i] = abs((i-width/2)/2);
    }
    float[] logs = new float[fftLeftBand.length];
    for(int i=0; i<logs.length; i++) {
      logs[i] = log(i+2)/log(fftLeftBand.length)*10.0;
    }
    for(int i=0; i<g.pixels.length; i++) {
      int x = i % width;
      int y = i / width;
      float band = 0.0f;
      int index = indices[x];
      if(index < fftLeftBand.length) {
        if(x < width/2)
          band = fftLeftBand[index];
        else
          band = fftRightBand[index];
        band *= logs[index];
      }
      if(x%2 == 0)
        gPixels[i] = g.pixels[x+width*(max((int)(y-band), 0))];
      else
        gPixels[i] = g.pixels[x+width*(min((int)(y+band), height-1))];
    }
    for(int i=0; i<g.pixels.length; i++) {
      g.pixels[i] = gPixels[i];
    }
  }
  
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
    text("Press T to toggle this text", 30, 30);
    text("fps: "+frameRate, 30, 60);
    text("Press A to toggle audio visualizer: "+(audioDraw?"AUDIO ON":"AUDIO OFF"), 30, 90);
    text("Press L to toggle lighting: "+(renderLights?"LIGHTS ON":"LIGHTS OFF"), 30, 120);
    text("Press P to toggle pixelation: "+(pixelate?"PIXELATION ON":"PIXELATION OFF"), 30, 150);
    text("Press UP and DOWN to change pixel size: PIXEL SIZE "+pixelSize, 30, 180);
    text("Press SPACE to generate a new world", 30, 210);
  }
  
  theta += PI/slowness;
}

void stop() {
  in.close();
  minim.stop();
  super.stop();
}

void mousePressed() {
  nextTriangles();
}

void keyPressed() {
  if(key == ' ') {
    nextTriangles();
  } else if(key == 'a' || key == 'A') {
    audioDraw = !audioDraw;
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
