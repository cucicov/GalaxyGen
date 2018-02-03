class Particle {
  PVector location;
  PVector velocity;
  PVector acceleration;
  float mass;
  boolean stop = false;

  float velocityCoef = 1.0;

  Particle(float x, float y, float z) {
    location = new PVector(x, y, z);
    velocity = new PVector(0, 0, 0);
    acceleration = new PVector(-0.001, 0.001, 0.001);
    mass = random(1, 5);
  }

  void stopParticle() {
    stop = true;
  }

  void update() {
    if (stop && velocity.x > 0 && velocity.y > 0) {
      if (velocityCoef > 0) {
        velocityCoef -= 0.005;
      } else {
        velocityCoef = 0;
      }
    }
    velocity.add(acceleration);
    location.add(velocity.get().mult(velocityCoef));
    acceleration.mult(0);
    velocity.limit(20000);
  }

  void applyGravity(PVector force) {
    PVector f = force.get();
    f.mult(mass);
    acceleration.add(f);
  }

  void applyForce(PVector force) {
    PVector f = force.get();
    f.div(mass);
    acceleration.add(f);
  }


  void display() {
    if (random(1) < 0.0001) {
      strokeWeight(random(5));
    } else {
      strokeWeight(1);
    }
    point(location.x, location.y, location.z);
  }

  void checkEdges() {
    if (location.x > width || location.x < -width) {
      velocity.x = velocity.x * -1;
    }
    if (location.y > height || location.y < -height) {
      velocity.y = velocity.y * -1; 
    }
    if (location.z > random(1000, 2000) || location.z < 0) {
      velocity.z = velocity.z * -1;
    }
  }

  void checkZ() {
    if (location.z < -1500) {
      location.z = 0;
    }
  }
}