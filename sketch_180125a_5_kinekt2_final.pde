import peasy.*;

import org.openkinect.processing.*;  
import processing.sound.*;
SoundFile part1;
SoundFile part2;

Kinect2 kinect2;

PImage img;
AvgZone zone1;
AvgZone zone2;
AvgZone zone3;

//Particle p;
int nrParticles = 50000;
ArrayList<Particle> particles = new ArrayList<Particle>();
PVector wind = new PVector(0.0, 0, 0);
PVector gravity = new PVector(0, 0.0, 1);
float angle = 0;
float angleX = 0;
float angleY = 0;
float rotationAcceleration = 0;
int bgColor = 255;
int strColor = 0;
boolean startRotation = false;
boolean stopCheck = false;
PVector prevMouse;
boolean trigger = false;
float counter = 0;

boolean stopReadingKinekt = false;
float zoomOut = -10000;

boolean disperse = false;

boolean deleteGalaxy = false;

boolean incAngleX = true;
boolean incAngleY = true;

int noVelocityParticles = 0;

int stopCounter = 0;

PeasyCam cam;

int counterSound = 0;

void setup() {
  println(nrParticles);
  size(1200, 900, P3D);
  //fullScreen(P3D);
  createParticles();

  kinect2 = new Kinect2(this);
  kinect2.initDepth();
  kinect2.initDevice();
  img = createImage(kinect2.depthWidth, kinect2.depthHeight, RGB);

  part1 = new SoundFile(this, "space_final_16-1part.wav");
  part2 = new SoundFile(this, "space_final_16-2part.wav");

  part1.loop();
}

void draw() {

  //println(particles.size());

  if (counterSound > 1800) {
    counterSound = -1;
    part2.stop();
    part1.loop();
    println("start part 1");
  }

  if (trigger && counterSound >= 0) {
    if (counterSound == 0) {
      part1.stop();
      part2.play();
    println("start part 2");
    }
    counterSound++;
  }

  background(0);
  zone1 = new AvgZone();
  zone2 = new AvgZone();
  zone3 = new AvgZone();

  stroke(200);
  if (zoomOut < -1200) {
    zoomOut += 100;
    //println(zoomOut);
  }
  translate(width/2, height/2, zoomOut - rotationAcceleration*100);
  if (startRotation && rotationAcceleration < 0.001) {
    rotationAcceleration += 0.00001;
  }
  angle += rotationAcceleration;
  rotateZ(angle);
  if (disperse) {
    //rotateX(angleX);
    if (angleX < 1.2) {
      rotateX(angleX);
    } else {
      rotateX(1.2);
      angleY += 0.001;
      if (angleY < 1.2) {
        rotateY(angleY);
      } else {
        rotateY(1.2);
      }
    }


    angleX += 0.001;

    //// rotate X Y
    //if (incAngleX) {
    //  angleX += 0.001;
    //} else {
    //  angleX -= 0.001;
    //}

    //if (angleX < 0.001) {
    //  incAngleX = true;
    //} else if (angleX > 1.2) {
    //  incAngleX = false;
    //}
  }

  if (trigger && !startRotation) {
    stopCounter += 1;
  }

  if (!startRotation && stopCounter > 1020) {
    startRotation = true;
    println("start rotation");
  }

  if (!stopReadingKinekt && stopCounter > 1000) {
    stopReadingKinekt = true;
    stopCounter = 0;
    println("start slowdown");
  }

  if (trigger && counter < 1) {
    counter += 0.1; //TODO: not needed?
  }

  // Get the raw depth as array of integers
  int[] depth = kinect2.getRawDepth();
  int skip = 5;
  stroke(255);
  strokeWeight(2);

  for (int x = 0; x < kinect2.depthWidth; x += skip) {
    for (int y = 0; y < kinect2.depthHeight; y += skip) {
      int offset = x + y * kinect2.depthWidth;
      int d = depth[offset];

      if (d > 0 && d < 1500) {
        int x1 = (int)map(x, 0, 512, -width, width);
        int y1 = (int)map(y, 0, 424, -height, height);
        //point(x1, y1);

        if (x1 > - width && x1 < -2*width/3) {
          zone1.updateLocation(new PVector(x1, y1), null);
        } else if (x1 > -2*width/3 && x1 < 2*width/3) {
          zone2.updateLocation(new PVector(x1, y1), null);
        } else {
          zone3.updateLocation(new PVector(x1, y1), null);
        }
      } else {
        // nix
      }
    }
  }


  int allPixelNumber = zone1.pixelsRead + zone2.pixelsRead + zone3.pixelsRead;
  zone1.allPixels=allPixelNumber;
  zone2.allPixels=allPixelNumber;
  zone3.allPixels=allPixelNumber;

  zone1.display(0);
  zone2.display(100);
  zone3.display(255);

  if (deleteGalaxy) {
    int removeNr = (int)random(15);
    while (removeNr > 0 && particles.size() > 0) {
      particles.remove(0);
      removeNr--;
    }
  }

  noVelocityParticles = 0;

  for (int i = 0; i < particles.size(); i++) {
    Particle p = particles.get(i);
    PVector mouse = new PVector(mouseX, mouseY, 0);
    if (prevMouse != null && pmouseX == mouseX) {
      mouse = new PVector(width/2, height/2, 0);
    }
    prevMouse = mouse.get();

    PVector averageZones = getZoneAverages(zone1, zone2, zone3);
    //PVector averageZones = new PVector(mouseX, mouseY, 0);
    PVector dir = PVector.sub(averageZones, p.location);
    dir.normalize();
    dir.z = -200;

    if (trigger && counter < 1 && random(1) < 0.1) {
      p.applyForce(dir);
    } else if (trigger && counter > 1) {
      p.applyForce(dir);
    }
    p.applyForce(gravity);
    p.update();
    p.checkZ();
    if (!trigger) {
      p.checkEdges();
    }

    p.display();

    //slowdown particles
    if (stopReadingKinekt && !disperse) {
      p.stopParticle();
    }

    if (startRotation) {
      //p.applyForce(disperseVector);
    }

    if (disperse) {
      PVector disperseVector = new PVector(random(-100, 100), random(-100, 100), random(-100, 100));
      p.applyForce(disperseVector);
    }

    if (p.velocityCoef == 0) {
      noVelocityParticles++;
    }

    //println(p.velocity);
  }

  //println(noVelocityParticles);
  if (noVelocityParticles > particles.size() * 0.8) {
    disperse = true;
    deleteGalaxy = true;
  }
}
void createParticles() {
  float r = 500;
  int total = 300;
  for (int i = 0; i < total; i++) {
    float lon = map(i, 0, total, -PI, PI);
    for (int j = 0; j < total; j++) {
      float lat = map(j, 0, total, -HALF_PI, HALF_PI);
      float x = r * sin(lon) * cos(lat);
      float y = r * sin(lon) * sin(lat);
      float z = r * cos(lon);
      if (random(1) < 0.3) {
        Particle p = new Particle(x, y, z);
        particles.add(p);
      }
    }
  }
}


PVector getZoneAverages(AvgZone z1, AvgZone z2, AvgZone z3) {
  PVector avgZone = new PVector();
  int calculatedZones = 0;
  float xSum = 0;
  float ySum = 0;

  if (z1.pixelsRead > 50) {
    xSum += z1.location.x;
    ySum += z1.location.y;
    calculatedZones++;
  }

  if (z2.pixelsRead > 50) {
    xSum += z2.location.x;
    ySum += z2.location.y;
    calculatedZones++;
  }

  if (z3.pixelsRead > 50) {
    xSum += z3.location.x;
    ySum += z3.location.y;
    calculatedZones++;
  }

  if (calculatedZones > 0) {
    avgZone = new PVector(xSum/calculatedZones, ySum/calculatedZones, 0);
  } else {
    avgZone = new PVector(width/2, height/2, 0);
  }

  return avgZone;
}


void mousePressed() {
  trigger = !trigger;
}

void keyPressed() {
  if (key == 'b' || key == 'B') {
    stopCheck = true;
  }
  if (key == 'c' || key == 'C') {
    startRotation = true;
    stopReadingKinekt = true;
    bgColor = abs(bgColor - 255);
    strColor = abs(strColor - 255);
  }
  if (key == 'd' || key == 'D') {
    disperse = true;
  }
  if (key == 'x' || key == 'X') {
    deleteGalaxy = true;
  }
  if (key == 'q' || key == 'Q') {
    createParticles();
  }
} 