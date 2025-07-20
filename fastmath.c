#include <math.h>

// Fast distance between two points
__declspec(dllexport) double fast_distance(double x1, double y1, double x2, double y2) {
    double dx = x2 - x1;
    double dy = y2 - y1;
    return sqrt(dx*dx + dy*dy);
}

// Fast dot product of 2D vectors
__declspec(dllexport) double fast_dot(double x1, double y1, double x2, double y2) {
    return x1 * x2 + y1 * y2;
}

// Fast length of a 2D vector
__declspec(dllexport) double fast_length(double x, double y) {
    return sqrt(x*x + y*y);
} 