attribute vec3 aVertexPosition;
attribute vec3 aNormalPosition;
attribute vec2 aTextureCoord;

#define NUM_LIGHTS 2

uniform mat4 uModelMatrix;
uniform mat4 uViewMatrix;
uniform mat4 uProjectionMatrix;
uniform mat4 uLightMVP[NUM_LIGHTS];

varying highp vec2 vTextureCoord;
varying highp vec3 vFragPos;
varying highp vec3 vNormal;
varying highp vec4 vPositionFromLight[NUM_LIGHTS];

void main(void) {

  vFragPos = (uModelMatrix * vec4(aVertexPosition, 1.0)).xyz;
  vNormal = (uModelMatrix * vec4(aNormalPosition, 0.0)).xyz;

  gl_Position = uProjectionMatrix * uViewMatrix * uModelMatrix *
                vec4(aVertexPosition, 1.0);

  vTextureCoord = aTextureCoord;
  for(int l=0; l<NUM_LIGHTS; ++l) {
    vPositionFromLight[l] = uLightMVP[l] * vec4(aVertexPosition, 1.0);
  }
  
}