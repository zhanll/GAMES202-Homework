#ifdef GL_ES
#extension GL_EXT_draw_buffers: enable
precision highp float;
#endif

uniform sampler2D uMip;
uniform int uWidth;
uniform int uHeight;
uniform int uLevel;

/*
level 0
  0 1

-------------------

level 1
  0 0.5               1 - 1/(2^1)

level 2
  0.5 0.75            1 - 1/(2^2)

level 3
  0.75  0.875         1 - 1/(2^3)

level 4
  0.875 0.9375        1 - 1/(2^4)

level n
  1 - 1/[2^(n-1)]     1 - 1/(2^n)
*/

float GetRangeMin(int level) {
  if (level <= 1) {
    return 0.0;
  }

  return 1.0 - 1.0/pow(2.0, float(level-1));
}

float GetRangeMax(int level) {
  if (level <= 0) {
    return 1.0;
  }

  return 1.0 - 1.0/pow(2.0, float(level));
}

float GetSideLength(int level) {
  if (level == 0) {
    return 1.0;
  }

  return 1.0/pow(2.0, float(level));
}


void main(void) {
  float length = GetSideLength(uLevel);
  float minU = GetRangeMin(uLevel);
  float minV = 0.0;
  float maxU = GetRangeMax(uLevel);
  float maxV = length;

  vec2 uv = gl_FragCoord.xy / vec2(float(uWidth), float(uHeight));

  if (uv.x >= minU && uv.x <= maxU && uv.y <= maxV) {
    float uUnit = 1.0 / float(uWidth);
    float vUnit = 1.0 / float(uHeight);

    float u1 = (uv.x - minU) / length;
    float v1 = (uv.y - minV) / length;

    float lengthPrv = GetSideLength(uLevel-1);
    float minUPrv = GetRangeMin(uLevel-1);
    float minVPrv = 0.0;
    //float maxUPrv = GetRangeMax(uLevel-1);
    //float maxVPrv = lengthPrv;
    
    float u0 = minUPrv + u1 * lengthPrv;
    float v0 = minVPrv + v1 * lengthPrv;

    float d00 = texture2D(uMip, vec2(u0-uUnit, v0-vUnit)).x;
    float d01 = texture2D(uMip, vec2(u0+uUnit, v0-vUnit)).x;
    float d10 = texture2D(uMip, vec2(u0-uUnit, v0+vUnit)).x;
    float d11 = texture2D(uMip, vec2(u0+uUnit, v0+vUnit)).x;

    float minDepth = min( min(d00, d01), min(d10, d11) );
    gl_FragData[5] = vec4(vec3(minDepth), 1.0);
  } else {
    gl_FragData[5] = vec4(texture2D(uMip, uv).xyz, 1.0);
  }
}