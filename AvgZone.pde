class AvgZone {

  PVector location = new PVector(0, 0); // middle location of average point in the zone.
  float magnitude; // magnitude of the zone based on the number of pixels read
  int pixelsRead = 0;
  int allPixels = 0;
  float biasY = 1.0;

  void updateLocation (PVector newLocation) {
    PVector newLoc = newLocation.get();
    newLoc.y *= biasY;

    location.add(newLoc);
    pixelsRead++;
    if (biasY > 0.01) {
      biasY -= 0.001;
    }
  }

  void display(int colorFill) {
    fill(colorFill);
    calculateAverageLocation();
    if (pixelsRead > 50) {
      ellipse(location.x, location.y, 200 * magnitude, 200 * magnitude);
    }
  }

  void calculateAverageLocation() {
    if (allPixels != 0) {
      magnitude = (float)pixelsRead / (float)allPixels;
      //println(pixelsRead + " " + allPixels + ":" + magnitude);
    }
    if (pixelsRead > 50) {
      location.x /= pixelsRead;
      location.y /= pixelsRead;
    }
  }
}