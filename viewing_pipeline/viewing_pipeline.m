pkg load geometry

# e_cam = location of camera
# g_cam = gaze (points in direction opposite of where camera is)
# t_cam = view up vector

# Choose
e_cam = [2;
         2;
         5]
g_cam = [0;
         0;
         -3]
t_cam = [1;
         1;
         1]
n_x = 800
n_y = 600
n = 1
f = -200
theta = 60

# Matrix holding original points from world (a cube)
# front top-right point
# front bottom-right point
# front bottom-left point
# front top-left point
# back top-right point
# back bottom-right point
# back bottom-left point
# back top-left point
#original_points = [1, 2, -3, 1;
#                   1, 0, -3, 1;
#                  -1, 0, -3, 1;
#                  -1, 2, -3, 1; 
#                   1, 2, -6, 1;
#                   1, 0, -6, 1;
#                  -1, 0, -6, 1;
#                  -1, 2, -6, 1]

#original_points = [0, -3, 1, 1;
#                   0, -4, 1, 1;
#                  -2, -4, 1, 1; 
#                  -2, -3, 1, 1;
#                   0, -3, 0, 1;
#                   0, -4, 0, 1;
#                  -2, -4, 0, 1;
#                  -2, -3, 0, 1]

original_points = [1, 1, 0, 1;
                   1, 0, 0, 1;
                   0, 0, 0, 1;
                   0, 1, 0, 1; 
                   1, 1, -1, 1;
                   1, 0, -1, 1;
                   0, 0, -1, 1;
                   0, 1, -1, 1]

############################
# Do not change below here #
############################
# Matrix to hold final set of points to be written to screen
final_points = [0, 0;
                0, 0;
                0, 0;
                0, 0;
                0, 0;
                0, 0;
                0, 0;
                0, 0]

# Derived from given
t = tand(theta / 2) * abs(n)
b = -t
r = t * n_x / n_y
l = -r

# w, u, and v are 1x3 row vectors
w = -g_cam / norm(g_cam);
u = cross(t_cam, w) / norm(cross(t_cam, w));
v = cross(w, u);

disp("w = "), disp(w);
disp("u = "), disp(u);
disp("v = "), disp(v);

# matrices are indexed starting at 1...
x_e = e_cam(1);
y_e = e_cam(2);
z_e = e_cam(3); 

x_u = u(1);
y_u = u(2);
z_u = u(3);

x_v = v(1);
y_v = v(2);
z_v = v(3);

x_w = w(1);
y_w = w(2);
z_w = w(3);

# Camera transformation
M_cam_left = [x_u, y_u, z_u, 0;
              x_v, y_v, z_v, 0;
              x_w, y_w, z_w, 0;
                0,   0,   0, 1]

M_cam_right = [1, 0, 0, -x_e;
               0, 1, 0, -y_e;
               0, 0, 1, -z_e;
               0, 0, 0,    1]

M_cam = M_cam_left * M_cam_right;

# Perspective matrix
P = [1, 0,       0,  0;
     0, 1,       0,  0;
     0, 0, (n+f)/n, -f;
     0, 0,     1/n,  0]

# Orthographic projection transformation (parallel camera)
M_orth = [2/(r-l),       0,       0, -(l+r)/(r-l);
                0, 2/(t-b),       0, -(b+t)/(t-b);
                0,       0, 2/(n-f), -(n+f)/(n-f);
                0,       0,       0,            1]

# Viewport transformation (scaling and translation, combined into one matrix)
M_vp = [n_x/2,     0, 0, (n_x - 1)/2;
            0, n_y/2, 0, (n_y - 1)/2;
            0,     0, 1,           0;
            0,     0, 0,           1]

# Final matrix, which will be used to convert all world-space points to pixels on screen
M = M_vp * M_orth * P * M_cam


for point_n = 1:8
 coor_col_vector = original_points(point_n,:)'
 new_point = M * coor_col_vector
 # [hx; hy; hx; h] = [x; y; z; 1]
 new_point = new_point / new_point(4)
 final_points(point_n, 1) = new_point(1)
 final_points(point_n, 2) = new_point(2)
 endfor

# Final points is of the form:
# [x_0, y_0;
#  x_1, y_1;
#  x_2, y_2;
#  ...  ...]

# To draw the cube's edges
axis([0 n_x 0 n_y]);
drawEdge([final_points(1,1) final_points(1, 2) final_points(2,1) final_points(2,2)]);
drawEdge([final_points(1,1) final_points(1, 2) final_points(2,1) final_points(2,2)]);
drawEdge([final_points(2,1) final_points(2, 2) final_points(3,1) final_points(3,2)]);
drawEdge([final_points(3,1) final_points(3, 2) final_points(4,1) final_points(4,2)]);
drawEdge([final_points(4,1) final_points(4, 2) final_points(1,1) final_points(1,2)]);
   
drawEdge([final_points(5,1) final_points(5, 2) final_points(6,1) final_points(6,2)]);
drawEdge([final_points(6,1) final_points(6, 2) final_points(7,1) final_points(7,2)]);
drawEdge([final_points(7,1) final_points(7, 2) final_points(8,1) final_points(8,2)]);
drawEdge([final_points(8,1) final_points(8, 2) final_points(5,1) final_points(5,2)]);

drawEdge([final_points(1,1) final_points(1, 2) final_points(5,1) final_points(5,2)]);
drawEdge([final_points(2,1) final_points(2, 2) final_points(6,1) final_points(6,2)]);
drawEdge([final_points(3,1) final_points(3, 2) final_points(7,1) final_points(7,2)]);
drawEdge([final_points(4,1) final_points(4, 2) final_points(8,1) final_points(8,2)]);

# To just draw the points (if not drawing edges)
#final_plot = plot(final_points(:,1), final_points(:,2))
#set(final_plot, "linestyle", "none")
#set(final_plot, "marker", "o")
#set(final_plot, "markersize", 10)
pause()