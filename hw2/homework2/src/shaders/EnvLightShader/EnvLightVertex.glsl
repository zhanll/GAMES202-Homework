attribute vec3 aVertexPosition;
attribute mat3 aPrecomputeLT;

uniform mat3 uPrecomputeLR;
uniform mat3 uPrecomputeLG;
uniform mat3 uPrecomputeLB;

uniform mat4 uModelMatrix;
uniform mat4 uViewMatrix;
uniform mat4 uProjectionMatrix;

varying highp vec3 vColor;

float mat3_dot(mat3 a, mat3 b) {
  float result = 0.0;
  for (int i=0; i<3; ++i) {
    for (int j=0; j<3; ++j) {
      result += a[i][j] * b[i][j];
    }
  }
  return result;
}

void main(void) {

  gl_Position = uProjectionMatrix * uViewMatrix * uModelMatrix *
                vec4(aVertexPosition, 1.0);

  vColor = vec3(mat3_dot(uPrecomputeLR, aPrecomputeLT), mat3_dot(uPrecomputeLG, aPrecomputeLT), mat3_dot(uPrecomputeLB, aPrecomputeLT));
}