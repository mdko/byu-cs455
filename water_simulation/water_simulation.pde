int gridWidth;
int gridHeight;
PVector[][] grid;
PVector[][] futureGrid;
float deltaT;
float largestVelocity;
float tAccumulation;
int iterationN;

// Constants that should be tinkered with for stability
float baseHeight = 10.20;           //5.20
float gravity = 1.5;               //0.5
float viscocity = 2.0;             //4.0
float hColorScaleConstant = 6.0;   //6.0
float adaptiveConstant = 0.009;    //0.009
float renderWait = 0.10;           //0.10
float deltaX = 1.00;
float deltaY = 1.00;

// Constants that probably shouldn't be tinkered with
float initialUVelocity = 0.0;
float initialVVelocity = 0.0;
int initialHue = 210;
int initialSaturation = 100;
int initialBrightness = 92;

int scale = 13; // 7

boolean DEBUG = false;
//true;

void setup() {

  gridWidth = 100; // 100
  gridHeight = 100; // 100
  grid = new PVector[gridWidth][gridHeight];
  futureGrid = new PVector[gridWidth][gridHeight];

  for (int widthN = 0; widthN < gridWidth; widthN++) {
    for (int heightN = 0; heightN < gridHeight; heightN++) {
      grid[widthN][heightN] = new PVector(initialUVelocity, // PVector.x = u
                                          initialVVelocity, // PVector.y = v
                                          baseHeight);      // PVector.z = h
      futureGrid[widthN][heightN] = new PVector(initialUVelocity, 
                                                initialVVelocity, 
                                                baseHeight);
    }
  }

  // Add the first drop in the middle of the surface, to cause waves
  //grid[gridWidth/2][gridHeight/2].z = baseHeight * 2;

  deltaT = 0.01; // 0.18;
  largestVelocity = 0.05f; // LARGENEGNUM;
  tAccumulation = 0;
  iterationN = 0;

  size(gridWidth * scale, gridHeight * scale, P3D);
  camera(width/2.0, height/2.0 + 1800, (height/2.0) / tan(PI*30.0 / 180.0) - 680, 
         width/2.0, height/2.0, 0, 
         0, 1, 0);
}

void mouseClicked() {
  grid[mouseX / scale][mouseY / scale].z = baseHeight * 2; 
}

void draw() {
  tAccumulation += deltaT;
  iterationN++;

  // Find and store the changes
  for (int xN = 0; xN < gridWidth; xN++) {
    for (int yN = 0; yN < gridHeight; yN++) {      
      PVector currentCell = grid[xN][yN];
      float uT = currentCell.x;
      float vT = currentCell.y;
      float hT = currentCell.z;

      float uXPlus1Y = (xN == (gridWidth - 1)) ? initialUVelocity : grid[xN + 1][yN].x;
      float uXMinu1Y = (xN == 0)               ? initialUVelocity : grid[xN - 1][yN].x;
      float vXYPlus1 = (yN == (gridHeight-1))  ? initialVVelocity : grid[xN][yN + 1].y;
      float vXYMinu1 = (yN == 0)               ? initialVVelocity : grid[xN][yN - 1].y;
  
      float hXPlus1Y = (xN == (gridWidth - 1)) ? baseHeight : grid[xN + 1][yN].z;
      float hXMinu1Y = (xN == 0)               ? baseHeight : grid[xN - 1][yN].z;
      float hXYPlus1 = (yN == (gridHeight-1))  ? baseHeight : grid[xN][yN + 1].z;
      float hXYMinu1 = (yN == 0)               ? baseHeight : grid[xN][yN - 1].z;   

      float uTPlusDt = uT + deltaT * 
                              ((-gravity * 
                                (hXPlus1Y - hXMinu1Y) / (2 * deltaX))
                               - (viscocity * uT));

      float vTPlusDt = vT + deltaT * 
                              ((-gravity *
                                (hXYPlus1 /** -*/ - hXYMinu1) / (2 * deltaY))
                              - (viscocity * vT));
       
      // Reflect velocity at edge 
//      if (xN == 0 || xN == (gridWidth - 1)) {
//        grid[xN][yN].x = -grid[xN][yN].x;
//      }
//      
//      // Reflect velocity at edge  
//      if (yN == 0 || yN == (gridHeight - 1)) {
//        grid[xN][yN].x = -grid[xN][yN].y;
//      }

      float deltaH =  -(((uXPlus1Y * (baseHeight + hXPlus1Y)) -
                          (uXMinu1Y * (baseHeight + hXMinu1Y)))
                       / (2 * deltaX))
                      -(((vXYPlus1 * (baseHeight + hXYPlus1)) -
                          (vXYMinu1 * (baseHeight + hXYMinu1))) 
                       / (2 * deltaY));

      if (abs(deltaH) > largestVelocity)
        largestVelocity = abs(deltaH);

      float hTPlusDt = hT + (deltaT * deltaH);
      futureGrid[xN][yN] = new PVector(uTPlusDt, vTPlusDt, hTPlusDt);
    }
  }

  if (DEBUG) println("***************************");
  if (DEBUG) println("Largest velocity: " + largestVelocity);
  if (DEBUG) println("tAccumulation: " + tAccumulation);

  //deltaT = adaptiveConstant / largestVelocity;
  largestVelocity = 0.0; //LARGENEGNUM; // Reset so it can updated correctly during the next iteration  

  if (DEBUG) println("DeltaT: " + deltaT);

  boolean timeToRender = (tAccumulation - renderWait) >= 0;

  if (DEBUG) {
    if (!timeToRender)
      println("Not drawing to screen... " + iterationN);
    else
      println("Drawing to the screen on... " + iterationN);
  }

  // Make all the changes at once
  for (int xN = 0; xN < gridWidth; xN++) {
    for (int yN = 0; yN < gridHeight; yN++) {
      grid[xN][yN] = futureGrid[xN][yN];

      if (timeToRender) {
        tAccumulation = 0.0;
        iterationN = 0;
        float relHeightDiff = (grid[xN][yN].z - baseHeight);// / (baseHeight);
        float additive = relHeightDiff * hColorScaleConstant;
        colorMode(HSB, 360, 100, 100);
        fill(initialHue + additive, 
          initialSaturation, 
          initialBrightness);
        stroke(initialHue + additive, 
          initialSaturation, 
          initialBrightness);  
        translate(xN * scale, yN * scale, 0);
        box(scale, scale, grid[xN][yN].z * scale);
        //rect(xN * scale, yN * scale, scale, scale);
        translate(-xN * scale, -yN * scale, 0);
      }
    }
  }
}


