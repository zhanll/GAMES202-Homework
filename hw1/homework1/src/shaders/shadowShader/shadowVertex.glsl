attribute vec3 aVertexPosition;
attribute vec3 aNormalPosition;
attribute vec2 aTextureCoord;

#define NUM_LIGHTS 2

uniform mat4 uModelMatrix;
uniform mat4 uViewMatrix;
uniform mat4 uProjectionMatrix;
uniform mat4 uLightMVP[NUM_LIGHTS];

uniform int uLightIndex;

varying highp vec3 vNormal;
varying highp vec2 vTextureCoord;

void main(void) {

  vNormal = aNormalPosition;
  vTextureCoord = aTextureCoord;

  gl_Position = uLightMVP[uLightIndex] * vec4(aVertexPosition, 1.0);
}