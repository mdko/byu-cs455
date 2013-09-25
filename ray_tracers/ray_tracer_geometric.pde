PVector eyePosition;     // aka LookFrom
PVector gazeDirection;   // aka LookAt
PVector viewUpVector;
float fieldOfView;

int nX, nY;              // screenWidth, screenHeight;
int nearPlaneDistance;
float top, bottom, right, left;

PVector u, v, w;
PVector eyePositionCameraSpace;
Matrix mCam;

PVector[] spheres;      // holds sphere centers
float[] radii;
int numSpheres;
PVector[] sphereIntersections;

PVector lightPosition;
float[] diffuseReflectionIntensities;
PVector[] sphereColors;

static int matrixDim = 4;
static boolean DEBUG_0 = false;    // setUp() information
static boolean DEBUG_1 = false;   // if ray does not intersect sphere
static boolean DEBUG_2 = false;   // if ray intersects sphere
static boolean DEBUG_3 = false;   // coloring information
static boolean DEBUG_5 = false;    // prints information like rayDirection, etc.

class Matrix {

  float[][] matrix;

  public Matrix(PVector u, PVector v, PVector w, PVector e) {
    matrix = new float[matrixDim][matrixDim];
    matrix[0][0] = u.x;
    matrix[0][1] = u.y;
    matrix[0][2] = u.z;
    matrix[0][3] = (u.x * -e.x) + (u.y * -e.y) + (u.z * -e.z);
    matrix[1][0] = v.x;
    matrix[1][1] = v.y;
    matrix[1][2] = v.z;
    matrix[1][3] = (v.x * -e.x) + (v.y * -e.y) + (v.z * -e.z);
    matrix[2][0] = w.x;
    matrix[2][1] = w.y;
    matrix[2][2] = w.z;
    matrix[2][3] = (w.x * -e.x) + (w.y * -e.y) + (w.z * -e.z);
    matrix[3][0] = 0.0f;
    matrix[3][1] = 0.0f;
    matrix[3][2] = 0.0f;
    matrix[3][3] = 1.0f;
  }

  public PVector multiplyByVector(PVector v) {
    float x = (matrix[0][0] * v.x) + (matrix[0][1] * v.y) + (matrix[0][2] * v.z);
    float y = (matrix[1][0] * v.x) + (matrix[1][1] * v.y) + (matrix[1][2] * v.z);
    float z = (matrix[2][0] * v.x) + (matrix[2][1] * v.y) + (matrix[2][2] * v.z);
    return new PVector(x, y, z);
  }

  public void print() {
    String out = new String();
    for (int xN = 0; xN < matrixDim; xN++) {
      out = out + "[ ";
      for (int yN = 0; yN < matrixDim; yN++) {
        out = out + matrix[xN][yN] + " ";
      }
      out = out + "]\n";
    }
    println(out);
  }
}

void setup() {
  eyePosition = new PVector(0.0f, 0.0f, 0.0f);
  gazeDirection = new PVector(0.0f, 0.0f, -1.0f);
  viewUpVector = new PVector(0.0f, 1.0f, 0.0f);

  nX = 800;
  nY = 600;
  nearPlaneDistance = 2;
  fieldOfView = 60.0f;

  top = tan(radians(fieldOfView / 2)) * abs(nearPlaneDistance);
  bottom = -top;
  right = top * nX / nY;
  left = -right;

  w = new PVector();
  u = new PVector();
  v = new PVector();

  gazeDirection.normalize(w);          // stores normalized gazeDirection in w
  (viewUpVector.cross(w)).normalize(u);// stored normalized cross product in u
  v = w.cross(u);                      // basic assignment of cross product to v

  if (DEBUG_0) { 
    println("u: " + u); 
    println("v: " + v); 
    println("w: " + w);
  }

  mCam = new Matrix(u, v, w, eyePosition);
  if (DEBUG_0) { 
    println("mCam:"); 
    mCam.print();
  }
  eyePositionCameraSpace = new PVector(0.0f, 0.0f, 0.0f);

  numSpheres = 3;
  spheres = new PVector[numSpheres];
  radii = new float[numSpheres];
  spheres[0] = mCam.multiplyByVector(new PVector(235.0f, 250.0f, -500.0f));    // world space coordinate -> camera space
  spheres[1] = mCam.multiplyByVector(new PVector(-15.0f, 10.0f, -300.0f));  // world space coordinate -> camera space
  spheres[2] = mCam.multiplyByVector(new PVector(-120.0f, 15.0f, -200.0f)); // world space coordinate -> camera space
  radii[0] = 15.0f;
  radii[1] = 23.0f;
  radii[2] = 50.0f;
  sphereColors = new PVector[numSpheres];
  sphereColors[0] = new PVector(204, 153, 0); // yellow
  sphereColors[1] = new PVector(120, 180, 0); // green
  sphereColors[2] = new PVector(0, 80, 204); // blue
  //sphereIntersections = new PVector[numSpheres];

  if (DEBUG_0) { 
    println("Sphere 0 Camera Space Coordinates: " + spheres[0]);
    println("Sphere 1 Camera Space Coordinates: " + spheres[1]);
    println("Sphere 2 Camera Space Coordinates: " + spheres[2]);
  }

  lightPosition = mCam.multiplyByVector(new PVector(200.0f, -100.0f, 200.0f));

  size(nX, nY);
}

void draw() {

  for (int iPixel = 0; iPixel < nX; iPixel++) {
    for (int jPixel = 0; jPixel < nY; jPixel++) {
      sphereIntersections = new PVector[numSpheres];
      diffuseReflectionIntensities = new float[numSpheres];

      float uS = left + ((right - left) * (iPixel + 0.5)) / nX;
      float vS = bottom + ((top - bottom) * (jPixel + 0.5)) / nY;
      float wS = -nearPlaneDistance;
      PVector s = new PVector(uS, vS, wS);  // target pixel in camera space
      PVector rayOrigin = eyePositionCameraSpace;
      PVector rayDirection = PVector.add(
      PVector.add(
      PVector.mult(u, uS), 
      PVector.mult(v, vS)), 
      PVector.mult(w, wS));
      rayDirection.normalize();

      if (DEBUG_5) { 
        println("uS: " + uS + ", vS: " + vS + ", wS: " + wS);
      }
      if (DEBUG_5) { 
        println("Ray direction from origin to " + iPixel + ", " + jPixel +
          ": " + rayDirection);
      }

      for (int sphereN = 0; sphereN < numSpheres; sphereN++) {
        float t;

        float r = radii[sphereN];
        PVector sphere = spheres[sphereN];
        PVector OC = PVector.sub(sphere, rayOrigin);
        float lenOC = OC.mag();

        boolean roInsideSphere = false;
        if (lenOC <= r) {
          roInsideSphere = true;
          if (DEBUG_1) { 
            println("OC is <= r, inside the sphere");
          }
        }

        float tca = PVector.dot(OC, rayDirection); // TODO review if already normalized

        if (tca < 0.0f && roInsideSphere == false) {
          if (DEBUG_1) { 
            println("Ray does not intersect sphere");
          }
          sphereIntersections[sphereN] = null;
          continue;
        } 
        else {
          float thcSqr = pow(r, 2) - pow(lenOC, 2) + pow(tca, 2);
          if (thcSqr < 0.0f) {
            if (DEBUG_1) { 
              println("Ray does not intersect sphere.");
            }
            sphereIntersections[sphereN] = null;
            continue;
          } 
          else {
            float thc = sqrt(thcSqr);
            t = roInsideSphere ? tca + thc : tca - thc;
          }
        }

        PVector intersectionPoint = 
          PVector.add(rayOrigin, PVector.mult(rayDirection, t));
        sphereIntersections[sphereN] = intersectionPoint;
        if (DEBUG_2) { 
          println("Ray intersects sphere at " + intersectionPoint);
        }

        float xSN = (intersectionPoint.x - sphere.x) / r;
        float ySN = (intersectionPoint.y - sphere.y) / r;
        float zSN = (intersectionPoint.z - sphere.z) / r;
        PVector surfaceNormal = new PVector(xSN, ySN, zSN);
        PVector lightNormal = PVector.sub(lightPosition, intersectionPoint);
        lightNormal.normalize();

        diffuseReflectionIntensities[sphereN] = PVector.dot(surfaceNormal, lightNormal);
        if (DEBUG_2) { 
          println("Surface normal at intersection: " + surfaceNormal);
        }
      } // end foreach sphere

      //  Compute pixel color (if ray misses all objects, pixel set to background color
      //  Compute intesity information for the intersection
      //    point using the Lambertian illumination model
      int indexOfClosestIntersection = -1;
      float closestIntersectionDistance = -1;
      for (int sphereN = 0; sphereN < numSpheres; sphereN++) {
        PVector intersection = sphereIntersections[sphereN];
        if (intersection == null) {  // if this point isn't intersecting this sphere, check next one
          continue;
        }
        float distanceToIntersection = intersection.mag();

        if (distanceToIntersection > closestIntersectionDistance) {
          indexOfClosestIntersection = sphereN;
          closestIntersectionDistance = distanceToIntersection;
        }
      }


      if (indexOfClosestIntersection == -1) { // ray misses all objects, set to background color
        set(iPixel, jPixel, color(30, 30, 30));
        if (DEBUG_3) { 
          println("Ray to " + iPixel + ", " + jPixel + " misses all objects.");
        }
      } 
      else {
        PVector c = sphereColors[indexOfClosestIntersection];
        float dri = diffuseReflectionIntensities[indexOfClosestIntersection];
        color pixelColor = color(c.x * dri, c.y * dri, c.z * dri);   
        set(iPixel, jPixel, pixelColor); 
        if (DEBUG_3) { 
          println("Ray to " + iPixel + ", " + jPixel + " hits an object.");
        }
      }
    }
  }
}

