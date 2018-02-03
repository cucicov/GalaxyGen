class AvgZone {

  PVector location = new PVector(0, 0); // middle location of average point in the zone.
  float magnitude; // magnitude of the zone based on the number of pixels read
  int pixelsRead = 0;
  int allPixels = 0;
  float additionCoefY = 1.0;
  float additionCoefXLeft = 1.1;
  float additionCoefXRight = 1.5;

  void updateLocation (PVector newLocation, Boolean biasLeft) {

    PVector newLoc = newLocation.get();
    newLoc.y *= additionCoefY;
    if (biasLeft != null && biasLeft) { // bias left
      newLoc.x *= additionCoefXLeft;
      //if (additionCoefXLeft > 0) {
      //  additionCoefXLeft -= 0.001;
      //}
    } else if (biasLeft != null && !biasLeft) { // bias right
      newLoc.x *= additionCoefXRight;
      //if (additionCoefXRight < 1) {
      //  additionCoefXRight += 0.0001;
      //}
    }

    location.add(newLoc);
    pixelsRead++;
    if (additionCoefY > 0.01) {
      additionCoefY -= 0.001;
    }
  }

  void display(int colorFill) {
    fill(colorFill);
    if (allPixels != 0) {
      magnitude = (float)pixelsRead / (float)allPixels;
      //println(pixelsRead + " " + allPixels + ":" + magnitude);
    }
    if (pixelsRead > 50) {
      location.x /= pixelsRead;
      location.y /= pixelsRead;
      //ellipse(location.x, location.y, 200 * magnitude, 200 * magnitude);
    }
  }
}