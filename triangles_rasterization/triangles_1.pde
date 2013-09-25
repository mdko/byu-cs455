// Triangles take two
M_Point p0, p1, p2, mid, min, max, left, right;
ColorVector col0, col1, col2;

void setup() {
 size(800, 600);
 p0 = null;
 p1 = null;
 p2 = null;
}

public void mouseClicked() {
  println("Mouse pressed at " + mouseX + "," + mouseY);
  if (p0 == null) {
    p0 = new M_Point(mouseX, mouseY, col0);
    println("p0 isn't null!");
  }
  else if (p1 == null) {
    p1 = new M_Point(mouseX, mouseY, col1);
    println("p1 isn't null!");     
  }
  else if (p2 == null) {
    p2 = new M_Point(mouseX, mouseY, col2);
    println("p1 isn't null!");
  }
  else { // else reset
    //background(200);
    p0 = new M_Point(mouseX, mouseY, col0);
    p1 = null;
    p2 = null; 
    println("Resetting all points, assigning p0 to a new point...");
  }
}

M_Point getAPoint(ArrayList<M_Point> points, int pos /*0 = min, 1 = mid, 2 = max*/) {
  int indexLowest = 0;
  int indexHighest = points.size() - 1;
  for (int i = 0; i < points.size(); i++) {
    if (points.get(i).getYCoor() < points.get(indexLowest).getYCoor())
      indexLowest = i;
    if (points.get(i).getYCoor() > points.get(indexHighest).getYCoor())
      indexHighest = i;
  }
  switch (pos) {
    case 0:
      return points.get(indexLowest);
    case 1:
      return points.get(3 - (indexLowest + indexHighest));
    case 2:
      return points.get(indexHighest);
    default:
      return null;
  }
}

void draw() {
  col0 = new ColorVector(255.0, 0.0, 0.0);
  col1 = new ColorVector(0.0, 255.0, 0.0);
  col2 = new ColorVector(0.0, 0.0, 255.0);
  
  // 1. Find mid, min, max (sort p0, p1, p2 on y-values)
  if (p0 == null || p1 == null || p2 == null)
    return;
  println("No points are null!");
   
  println("Min: " + p0.toString());
  println("Mid: " + p2.toString());
  println("Max: " + p1.toString());
  ArrayList<M_Point> points = new ArrayList<M_Point>();
  points.add(p0); points.add(p1); points.add(p2);
  min = getAPoint(points, 0);
  mid = getAPoint(points, 1);
  max = getAPoint(points, 2);  
  
  // 2. Instantiate the left and right points that will move during algorithm
  //    such that left.x = right.x = min.x
  left = new M_Point((int)min.getXCoor(), (int)min.getYCoor(), min.getColorVector());
  right = new M_Point((int)min.getXCoor(), (int)min.getYCoor(), min.getColorVector());
  
  // 3. Calculate deltas. Note: assume that the broken edge is on the left
  left.calculateDelta(mid, min);
  left.calculateColorDelta(mid, min);
  right.calculateDelta(max, min);
  right.calculateColorDelta(max, min);
  
  // 4. For each scanline, determine which pixels should be colored
  //  a) 1st half of broken edge
  for (int scanline = (int)min.getYCoor(); scanline < (int)mid.getYCoor(); scanline++) {
    left.incrementX();
    left.incrementColor();
    right.incrementX();
    right.incrementColor();
    for (int x = floor(left.getXCoor()); x < ceil(right.getXCoor()); x++) {
      if (left.getXCoor() <= x && right.getXCoor() > x) {
        float red, green, blue;
        
        ColorVector leftColors = left.getColorVector();
        ColorVector rightColors = right.getColorVector();
        float deltaX = right.getXCoor() - left.getXCoor();
        float distanceFromLeft = x - left.getXCoor(); // TODO review
          
        //          Base color on left    Gradient of color change across scan line                 Current location in scan line
        red = leftColors.getRed() + ((rightColors.getRed() - leftColors.getRed()) / deltaX) * distanceFromLeft;
        green = leftColors.getGreen() + ((rightColors.getGreen() - leftColors.getGreen()) / deltaX) * distanceFromLeft;
        blue = leftColors.getBlue() + ((rightColors.getBlue() - leftColors.getBlue()) / deltaX) * distanceFromLeft;
        
//        float outpxRed, outpxGreen, outpxBlue;
//        float percentIn;
//        //Anti-alias, we're on left-edge
//        if (x == floor(left.getXCoor())) {
//          color c = get(x-1, scanline);
//          outpxRed = red(c);
//          outpxGreen = green(c);
//          outpxBlue = blue(c);
//          percentIn = left.getXCoor() - x;
//          red += outpxRed * (1 - percentIn);
//          green += outpxGreen * (1 - percentIn);
//          blue += outpxBlue * (1 - percentIn);
//        }
//        //Anti-alias, we're on the right-edge
//        else if (x == (ceil(right.getXCoor()) - 1)) {
//          color c = get(x, scanline);
//          outpxRed = red(c);
//          outpxGreen = green(c);
//          outpxBlue = blue(c);
//          percentIn = right.getXCoor() - x;
//          red += outpxRed * (1 - percentIn);
//          green += outpxGreen * (1 - percentIn);
//          blue += outpxBlue * (1 - percentIn);
//        }
        stroke(red, green, blue);
        point(x, scanline);
      }
    }
  }
  // b) 2nd half of broken edge, so change deltaX
  left.calculateDelta(max, mid);
  left.calculateColorDelta(max, mid);
  for (int scanline = (int)mid.getYCoor(); scanline < (int)max.getYCoor(); scanline++) {
    left.incrementX();
    left.incrementColor();
    right.incrementX();
    right.incrementColor();
    for (int x = floor(left.getXCoor()); x < ceil(right.getXCoor()); x++) {
      if (left.getXCoor() <= x && right.getXCoor() > x) {
        ColorVector leftColors = left.getColorVector();
        ColorVector rightColors = right.getColorVector();
        float deltaX = right.getXCoor() - left.getXCoor();
        float distanceFromLeft = x - left.getXCoor();
        
        //          Base color on left    Gradient of color change across scan line                 Current location in scan line
        float red = leftColors.getRed() + ((rightColors.getRed() - leftColors.getRed()) / deltaX) * distanceFromLeft;
        float green = leftColors.getGreen() + ((rightColors.getGreen() - leftColors.getGreen()) / deltaX) * distanceFromLeft;
        float blue = leftColors.getBlue() + ((rightColors.getBlue() - leftColors.getBlue()) / deltaX) * distanceFromLeft;
        stroke(red, green, blue);
        point(x, scanline); 
      }
    }
  }
}

public class ColorVector {
  float red;
  float green;
  float blue;
  float redDelta;
  float greenDelta;
  float blueDelta;
  
  public ColorVector(float o_red, float o_green, float o_blue) {
    red = o_red;
    green = o_green;
    blue = o_blue;
    redDelta = 0.0;
    greenDelta = 0.0;
    blueDelta = 0.0;
  }
   
  public void calculateDeltas(M_Point upper, M_Point lower) {
    ColorVector upperColors = upper.getColorVector();
    ColorVector lowerColors = lower.getColorVector();
    redDelta = (upperColors.getRed() - lowerColors.getRed()) / 
               ((int)upper.getYCoor() - (int)lower.getYCoor());
    greenDelta = (upperColors.getGreen() - lowerColors.getGreen()) /
                 ((int)upper.getYCoor() - (int)lower.getYCoor());
    blueDelta = (upperColors.getBlue() - lowerColors.getBlue()) /
                ((int)upper.getYCoor() - (int)lower.getYCoor());
  }
  
  public float getRed() {
    return red;
  }
  
  public float getGreen() {
    return green;
  }
  
  public float getBlue() {
    return blue;
  }
  
  public void incrementColor() {
    red += redDelta;
    green += greenDelta;
    blue += blueDelta;
  }
}

public class M_Point {
  
  float xCoor;
  float yCoor;
  float deltaX;
  ColorVector colors;
 
  public M_Point(int o_xCoor, int o_yCoor, ColorVector o_colors) {
    xCoor = (float)o_xCoor;
    yCoor = (float)o_yCoor;
    deltaX = 0.0;
    colors = new ColorVector(o_colors.getRed(), o_colors.getGreen(), o_colors.getBlue());
  } 
  
  public void calculateDelta(M_Point upper, M_Point lower) {
     float slope = (upper.getYCoor() - lower.getYCoor()) / (upper.getXCoor() - lower.getXCoor());
     deltaX = 1 / slope;
  }
  
  public float getXCoor() {
    return xCoor; 
  }
  
  public float getYCoor() {
    return yCoor; 
  }
  
  public ColorVector getColorVector(){
    return colors;
  }
  
  // How each color changes as y is incremented by 1 going up a scan line
  public void calculateColorDelta(M_Point upper, M_Point lower) {
    colors.calculateDeltas(upper, lower);
  }
  
  public void incrementX() {
    xCoor += deltaX; 
  }
  
  public void incrementColor() {
    colors.incrementColor(); 
  }
  
  public String toString() {
   String output = "(" + xCoor + "," + yCoor + ")"; 
   return output;
  }
}
