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

float GetGBufferDepth(vec2 uv) {
  float depth = texture2D(uMip, uv).x;
  if (depth < 1e-2) {
    depth = 1000.0;
  }
  return depth;
}


void main(void) {
  float length = GetSideLength(uLevel);
  float minU = GetRangeMin(uLevel);
  float minV = 0.0;
  float maxU = GetRangeMax(uLevel);
  float maxV = length;

  float lengthPrv = GetSideLength(uLevel-1);
  float minUPrv = GetRangeMin(uLevel-1);
  float minVPrv = 0.0;
  float maxUPrv = GetRangeMax(uLevel-1);
  float maxVPrv = lengthPrv;

  vec2 uv = gl_FragCoord.xy / vec2(float(uWidth), float(uHeight));

  if (uv.x >= minU && uv.x <= maxU && uv.y <= maxV) {
    float uUnit = 1.0 / float(uWidth);
    float vUnit = 1.0 / float(uHeight);

    float u1 = (uv.x - minU) / length;
    float v1 = (uv.y - minV) / length;

    float x1 = (float(uWidth) * length) * u1;
    float y1 = (float(uHeight) * length) * v1;

    float x01 = x1 * 2.0;
    float x02 = x01 + 1.0;
    float y01 = y1 * 2.0;
    float y02 = y01 + 1.0;

    float w0 = float(uWidth) * lengthPrv;
    float u01 = minUPrv + clamp(x01 / w0, 0.0, 1.0) * lengthPrv;
    float u02 = minUPrv + clamp(x02 / w0, 0.0, 1.0) * lengthPrv;

    float h0 = float(uHeight) * lengthPrv;
    float v01 = minVPrv + clamp(y01 / h0, 0.0, 1.0) * lengthPrv;
    float v02 = minVPrv + clamp(y02 / h0, 0.0, 1.0) * lengthPrv;
    
    //float u0 = minUPrv + u1 * lengthPrv;
    //float v0 = minVPrv + v1 * lengthPrv;

    float d00 = GetGBufferDepth(vec2(u01, v01));
    float d01 = GetGBufferDepth(vec2(u01, v02));
    float d10 = GetGBufferDepth(vec2(u02, v01));
    float d11 = GetGBufferDepth(vec2(u02, v02));

    float minDepth = min( min(d00, d01), min(d10, d11) );
    gl_FragData[5] = vec4(vec3(minDepth), 1.0);
  } else {
    //if (uv.x >= minUPrv && uv.x < maxUPrv && uv.y < maxVPrv && uLevel > 1) {
      //gl_FragData[5] = vec4(vec3(GetGBufferDepth(uv)), 1.0);
    if (uLevel == 1) {
      gl_FragData[5] = vec4(vec3(1000.0), 1.0);
    } else {
      gl_FragData[5] = vec4(vec3(GetGBufferDepth(uv)), 1.0);
    }
  }
}