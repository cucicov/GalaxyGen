import peasy.*;
import org.openkinect.processing.*;  
import processing.sound.*;

SoundFile part1;
SoundFile part2;
Kinect2 kinect2;
AvgZone zone1;
AvgZone zone2;
AvgZone zone3;

// ------------- SETTINGS ------------
int kinectZoneMinThreshold;
int stopCounter;
int rotationDelay;
int kinectSkipStep;
int kinectVectorZ;
ArrayList<Particle> particles;
PVector centerGravity = new PVector(0, 0, 1);
float angle;
float angleX;
float angleY;
float rotationAcceleration;
int bgColor;
int strColor;
boolean startRotation;
boolean triggerGalaxyCreation;
int idleResetCounter;
boolean startSlowDown;
float zoomOut;
boolean disperse;
boolean deleteGalaxy;
int noVelocityParticles;
boolean isPart1Playing;
boolean isPart2Playing;
int kinectStartDelayCounter;
int minPixelsForKinectActivation;
int restartWorldCounter;
boolean debug;
// ------------- -------- ------------

void resetSettings() {
  kinectZoneMinThreshold = 50; // minimum number of points read by kinect in a zone in order to consider presence in this zone.
  stopCounter = 1000; // counter to particle slowdown event.
  rotationDelay = -1000; // counter to particle rotation event.
  kinectSkipStep = 5;
  kinectVectorZ = -200;
  particles = new ArrayList<Particle>();
  angle = 0;
  angleX = 0;
  angleY = 0;
  rotationAcceleration = 0;
  bgColor = 0;
  strColor = 255;
  startRotation = false;
  triggerGalaxyCreation = false;
  startSlowDown = false;
  zoomOut = -10000;
  disperse = false; // trigger for dispersing particles 
  deleteGalaxy = false; // trigger for particles delete process
  noVelocityParticles = 0; // number of particles with velocity = 0
  isPart1Playing = false;
  isPart2Playing = false;
  idleResetCounter = 3500; // counter for idle animation loop
  kinectStartDelayCounter = 60; // delay period before triggering kinect interaction
  minPixelsForKinectActivation = 100; // minimum number of pixels for triggering galaxy creation.
  restartWorldCounter = 500; // counter for restarting whole process after galaxy destruction.
  debug = false; // flag for debug mode
}

void initSetup() {
  createParticles();

  part1 = new SoundFile(this, "space_final_16-1part.wav");
  part2 = new SoundFile(this, "space_final_16-2part.wav");

  part1.loop();
}

void setup() {
  //size(1200, 900, P3D);
  fullScreen(P3D);
  kinect2 = new Kinect2(this);
  kinect2.initDepth();
  kinect2.initDevice();

  resetSettings();
  initSetup();
}

void initDraw() {
  background(bgColor);
  stroke(strColor);
  noVelocityParticles = 0;

  // after short delay, start galaxy creation if any kinect activity
  if (zone1 != null && zone1.allPixels > minPixelsForKinectActivation) {
    kinectStartDelayCounter--;
    if (kinectStartDelayCounter < 0) {
      triggerGalaxyCreation = true;
    }
  }

  // reset zones for new read
  zone1 = new AvgZone();
  zone2 = new AvgZone();
  zone3 = new AvgZone();

  // zoom in effect at the start of world
  if (zoomOut < -1200) {
    zoomOut += 100;
  }
  translate(width/2, height/2, zoomOut + rotationAcceleration*10000);

  // start countdown to particle slowdown event.
  if (triggerGalaxyCreation && !startRotation) {
    stopCounter--;
  }

  // start slowdown after delay.
  if (!startSlowDown && stopCounter < 0) {
    startSlowDown = true;
    println("start slowdown");
  }

  // start rotation after delay.
  if (!startRotation && stopCounter < rotationDelay) {
    startRotation = true;
    println("start rotation");
    startSoundPart1();
  }

  // countdown reset world if idle.
  if (!triggerGalaxyCreation) {
    idleResetCounter--;
  }
}

void draw() {

  initDraw();

  if (triggerGalaxyCreation) {
    startSoundPart2();
  }
  if (startRotation) {
    startZRotation();
  }
  if (disperse) {
    startXYRotation();
  }
  if (deleteGalaxy) {
    removeSomeParticles();
  }

  readKinectDataAndPopulateZones();
  drawParticles();

  // if more than 80% of particles have zero velocity -> disperse the rest and start deletion process.
  if (noVelocityParticles > particles.size() * 0.8) {
    disperse = true;
    deleteGalaxy = true;
  }

  //restart idle animation
  if (!triggerGalaxyCreation && idleResetCounter < 0) {
    restartWorld();
  }

  if (particles.size() == 0) {
    if (restartWorldCounter < 0) {
      restartWorld();
    }
    restartWorldCounter--;
  }
}

// -------------------------------------------------------------------------------------

void restartWorld() {
  part1.stop();
  part2.stop();
  resetSettings();
  initSetup();
}

void startZRotation() {
  if (rotationAcceleration < 0.0005) {
    rotationAcceleration += 0.00001;
  }
  angle += rotationAcceleration;
  rotateZ(angle);
}

void removeSomeParticles() {
  int removeNr = (int)random(15);
  while (removeNr > 0 && particles.size() > 0) {
    particles.remove(0);
    removeNr--;
  }
}

void drawParticles() {
  for (int i = 0; i < particles.size(); i++) {
    Particle p = particles.get(i);

    PVector averageZones = getZoneAverages(zone1, zone2, zone3);
    //PVector averageZones = new PVector(mouseX, mouseY, 0);
    PVector kinectVector = PVector.sub(averageZones, p.location);
    kinectVector.normalize();
    kinectVector.z = kinectVectorZ;

    if (triggerGalaxyCreation) {
      p.applyForce(kinectVector);
    }

    p.applyForce(centerGravity);
    p.update();
    p.checkZ();
    if (!triggerGalaxyCreation) {
      p.checkEdges();
    }

    p.display();

    //slowdown particles
    if (startSlowDown && !disperse) {
      p.stopParticle();
    }

    if (disperse) {
      PVector disperseVector = new PVector(random(-100, 100), random(-100, 100), random(-100, 100));
      p.applyForce(disperseVector);
    }

    if (p.velocityCoef == 0) {
      noVelocityParticles++;
    }
  }
}

void readKinectDataAndPopulateZones() {
  // Get the raw depth as array of integers
  int[] depth = kinect2.getRawDepth();

  for (int x = 0; x < kinect2.depthWidth; x += kinectSkipStep) {
    for (int y = 0; y < kinect2.depthHeight; y += kinectSkipStep) {
      int offset = x + y * kinect2.depthWidth;
      int d = depth[offset];

      // limit distance of kinect reading to exclude background elements
      if (d > 0 && d < 1500) {
        // calibration from kinect values
        int x1 = (int)map(x, 0, 512, -width, width);
        int y1 = (int)map(y, 0, 424, -height, height);
        if (debug) {
          strokeWeight(2);
          point(x1, y1, map(d, 0, 1500, -750, 750));
        }

        //split points read in three main zones
        if (x1 > - width && x1 < -width/3) {
          zone1.updateLocation(new PVector(x1, y1));
        } else if (x1 > -width/3 && x1 < width/3) {
          zone2.updateLocation(new PVector(x1, y1));
        } else {
          zone3.updateLocation(new PVector(x1, y1));
        }
      }
    }
  }

  // set all pixels read in order to calculate magnitude.
  int allPixelNumber = zone1.pixelsRead + zone2.pixelsRead + zone3.pixelsRead;
  zone1.allPixels=allPixelNumber;
  zone2.allPixels=allPixelNumber;
  zone3.allPixels=allPixelNumber;

  if (debug) {
    zone1.display(0);
    zone2.display(100);
    zone3.display(255);
  } else {
    zone1.calculateAverageLocation();
    zone2.calculateAverageLocation();
    zone3.calculateAverageLocation();
  }
}

void startSoundPart1() {
  if (!isPart1Playing) {
    part2.stop();
    part1.loop();
    println("start part 1");
    isPart1Playing = true;
  }
}

void startSoundPart2() {
  if (!isPart2Playing) {
    part1.stop();
    part2.play();
    println("start part 2");
    isPart2Playing = true;
  }
}

void startXYRotation() {
  angleX += 0.001;
  if (angleX < 0.9) {
    rotateX(angleX);
  } else {
    rotateX(0.9);

    angleY += 0.001;
    if (angleY < 0.9) {
      rotateY(angleY);
    } else {
      rotateY(0.9);
    }
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

// calculates an average vector based on the average of all zone locations.
PVector getZoneAverages(AvgZone... zones) {
  PVector avgZone = new PVector();
  int calculatedZones = 0;
  float xSum = 0;
  float ySum = 0;

  for (AvgZone zone : zones) {
    if (zone.pixelsRead > kinectZoneMinThreshold) {
      xSum += zone.location.x * map(zone.magnitude, 0, 10, 1, 1.5);
      ySum += zone.location.y * map(zone.magnitude, 0, 10, 1, 1.5);
      calculatedZones++;
    }
  }

  if (calculatedZones > 0) {
    avgZone = new PVector(xSum/calculatedZones, ySum/calculatedZones, 0);
  } else {
    avgZone = new PVector(width/2, height/2, 0);
  }

  return avgZone;
}

void mousePressed() {
  triggerGalaxyCreation = !triggerGalaxyCreation;
}

void keyPressed() {
  if (key == 'd' || key == 'D') {
    debug = !debug;
  }
  if (debug && (key == 'r' || key == 'R')) {
    restartWorld();
  }
} 