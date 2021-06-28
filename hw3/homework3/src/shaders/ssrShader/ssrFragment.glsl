#ifdef GL_ES
precision highp float;
#endif

uniform vec3 uLightDir;
uniform vec3 uCameraPos;
uniform vec3 uLightRadiance;
uniform sampler2D uGDiffuse;
uniform sampler2D uGDepth;
uniform sampler2D uGNormalWorld;
uniform sampler2D uGShadow;
uniform sampler2D uGPosWorld;
uniform sampler2D uMipmap;
uniform float uWidth;
uniform float uHeight;
uniform vec2 uLineStart;
uniform vec2 uLineEnd;

varying mat4 vWorldToScreen;
varying highp vec4 vPosWorld;
varying mat4 vWorldToView;

#define M_PI 3.1415926535897932384626433832795
#define TWO_PI 6.283185307
#define INV_PI 0.31830988618
#define INV_TWO_PI 0.15915494309

#define MIP_LEVEL 8

float Rand1(inout float p) {
  p = fract(p * .1031);
  p *= p + 33.33;
  p *= p + p;
  return fract(p);
}

vec2 Rand2(inout float p) {
  return vec2(Rand1(p), Rand1(p));
}

float InitRand(vec2 uv) {
	vec3 p3  = fract(vec3(uv.xyx) * .1031);
  p3 += dot(p3, p3.yzx + 33.33);
  return fract((p3.x + p3.y) * p3.z);
}

vec3 SampleHemisphereUniform(inout float s, out float pdf) {
  vec2 uv = Rand2(s);
  float z = uv.x;
  float phi = uv.y * TWO_PI;
  float sinTheta = sqrt(1.0 - z*z);
  vec3 dir = vec3(sinTheta * cos(phi), sinTheta * sin(phi), z);
  pdf = INV_TWO_PI;
  return dir;
}

vec3 SampleHemisphereCos(inout float s, out float pdf) {
  vec2 uv = Rand2(s);
  float z = sqrt(1.0 - uv.x);
  float phi = uv.y * TWO_PI;
  float sinTheta = sqrt(uv.x);
  vec3 dir = vec3(sinTheta * cos(phi), sinTheta * sin(phi), z);
  pdf = z * INV_PI;
  return dir;
}

void LocalBasis(vec3 n, out vec3 b1, out vec3 b2) {
  float sign_ = sign(n.z);
  if (n.z == 0.0) {
    sign_ = 1.0;
  }
  float a = -1.0 / (sign_ + n.z);
  float b = n.x * n.y * a;
  b1 = vec3(1.0 + sign_ * n.x * n.x * a, sign_ * b, -sign_ * n.x);
  b2 = vec3(b, sign_ + n.y * n.y * a, -n.y);
}

vec4 Project(vec4 a) {
  return a / a.w;
}

float GetDepth(vec3 posWorld) {
  float depth = (vWorldToScreen * vec4(posWorld, 1.0)).w;
  return depth;
}

/*
 * Transform point from world space to screen space([0, 1] x [0, 1])
 *
 */
vec2 GetScreenCoordinate(vec3 posWorld) {
  vec2 uv = Project(vWorldToScreen * vec4(posWorld, 1.0)).xy * 0.5 + 0.5;
  return uv;
}

float GetGBufferDepth(vec2 uv) {
  float depth = texture2D(uGDepth, uv).x;
  if (depth < 1e-2) {
    depth = 1000.0;
  }
  return depth;
}

vec3 GetGBufferNormalWorld(vec2 uv) {
  vec3 normal = texture2D(uGNormalWorld, uv).xyz;
  return normal;
}

vec3 GetGBufferPosWorld(vec2 uv) {
  vec3 posWorld = texture2D(uGPosWorld, uv).xyz;
  return posWorld;
}

float GetGBufferuShadow(vec2 uv) {
  float visibility = texture2D(uGShadow, uv).x;
  return visibility;
}

vec3 GetGBufferDiffuse(vec2 uv) {
  vec3 diffuse = texture2D(uGDiffuse, uv).xyz;
  diffuse = pow(diffuse, vec3(2.2));
  return diffuse;
}

/*
 * Evaluate diffuse bsdf value.
 *
 * wi, wo are all in world space.
 * uv is in screen space, [0, 1] x [0, 1].
 *
 */
vec3 EvalDiffuse(vec3 wi, vec3 wo, vec2 uv) {
  vec3 L = vec3(0.0);
  vec3 n = normalize( GetGBufferNormalWorld(uv) );
  L = GetGBufferDiffuse(uv) * INV_PI * max(0.0, dot(wi, n));
  return L;
}

/*
 * Evaluate directional light with shadow map
 * uv is in screen space, [0, 1] x [0, 1].
 *
 */
vec3 EvalDirectionalLight(vec2 uv) {
  vec3 Le = vec3(0.0);
  Le = uLightRadiance * GetGBufferuShadow(uv);
  return Le;
}

// no mipmap
bool RayMarch(vec3 ori, vec3 dir, out vec3 hitPos) {
  const float stepMin = 0.125;
  const float stepMax = 16.0;

  float step = stepMin;
  float t = step;
  for (int i = 0; i < 50; ++i) {
    if (step >= stepMax) {
      return false;
    }

    vec3 p = ori + dir * t;

    float depthR = GetDepth(p);
    vec2 uv = GetScreenCoordinate(p);
    float depthG = GetGBufferDepth(uv);

    if (depthR >= depthG) {
      if (step <= stepMin) {
        hitPos = texture2D(uGPosWorld, uv).xyz;
        return true;
      }

      step *= 0.5;
    } else {
      t += step;
      step *= 2.0;
    }
  }

  return false;
}

// mipmap texture min uv.x of level
float GetRangeMin(int level) {
  if (level <= 1) {
    return 0.0;
  }

  return 1.0 - 1.0/pow(2.0, float(level-1));
}

// mipmap texture side lenth of level
float GetSideLength(int level) {
  return 1.0/pow(2.0, float(level));
}

// depth min pool
float GetMipmapDepth(vec2 uv, int level) {
  if (level <= 0) {
    return texture2D(uGDepth, uv).x;
  }

  if (level >= MIP_LEVEL) {
    return 1000.0;
  }

  float sideLen = GetSideLength(level);
  float u = GetRangeMin(level) + uv.x * sideLen;
  float v = uv.y * sideLen;
  return texture2D(uMipmap, vec2(u,v)).x;
}

vec2 GetMipmapUV(vec2 uv, int level) {
  float sideLen = GetSideLength(level);
  float u = GetRangeMin(level) + uv.x * sideLen;
  float v = uv.y * sideLen;
  return vec2(u,v);
}

float snapToLevel(int level, float u, bool permute) {
  if (level < 1) {
    return 1.0;
  }

  float x = floor( u * (permute ? uHeight : uWidth) );
  float l = pow(2.0, float(level));
  float a = mod(x, l);

  return l - a;
}

// with mipmap
bool RayMarchWithMipmap(vec3 ori, vec3 dir, out vec3 hitPos) {
  const float maxDistance = 8.0;
  vec3 tail = ori + dir * maxDistance;

  // to view space
  vec4 csOri = vWorldToView * vec4(ori, 1.0);
  vec4 csTail = vWorldToView * vec4(tail, 1.0);

  // project into screen space
  vec4 H0 = vWorldToScreen * vec4(ori, 1.0);
  vec4 H1 = vWorldToScreen * vec4(tail, 1.0);

  float k0 = 1.0 / H0.w;
  float k1 = 1.0 / H1.w;

  vec3 Q0 = csOri.xyz * k0;
  vec3 Q1 = csTail.xyz * k1;

  // screen space endpoints
  vec2 P0 = (H0.xy * k0);
  vec2 P1 = (H1.xy * k1);

  bool permute = false;
  float stride = 2.0 / uWidth;
  vec2 delta = P1 - P0;
  if (abs(delta.x) < abs(delta.y)) {
    permute = true;
    stride = 2.0 / uHeight;
    delta = delta.yx;
    P0 = P0.yx;
    P1 = P1.yx;
  }

  float stepDir = sign(delta.x);
  float invdx = stepDir / delta.x;

  float dk = (k1 - k0) * invdx;
  vec3 dQ = (Q1 - Q0) * invdx;
  vec2 dP = vec2(stepDir, delta.y * invdx);

  float s = stride;
  float k = k0;
  vec3 Q = Q0;
  vec2 P = P0;

  float endX = stepDir * P1.x;
  int level = 0;

  for (int i=0; i<256; ++i) {
    if (P.x * stepDir >= endX) {
      break;
    }

    float kt = k + dk * s;
    vec3 Qt = Q + dQ * s;
    vec2 Pt = P + dP * s;

    vec2 R = permute ? Pt.yx : Pt;
    vec2 uv = R * 0.5 + 0.5;

    float depth = GetMipmapDepth(uv, level);
    float rayZ = -Qt.z / kt;
    if (rayZ + 0.0001 >= depth) {
      if (level < 1) {
        hitPos = GetGBufferPosWorld(uv);
        return true;
      } else {
        --level;
        s = stride * snapToLevel(level, uv.x, permute);
      }
      
    } else {
      ++level;
      if (level >= MIP_LEVEL) {
        level = MIP_LEVEL - 1;
      }

      k += dk * s;
      Q += dQ * s;
      P += dP * s;

      s = stride * snapToLevel(level, uv.x, permute);
    }

  }
  return false;
}

#define SAMPLE_NUM 16

void main() {
  float s = InitRand(gl_FragCoord.xy);

  vec3 L = vec3(0.0);
  vec3 wi = normalize(uLightDir);
  vec3 wo = normalize(uCameraPos - vPosWorld.xyz);
  vec2 uv = GetScreenCoordinate(vPosWorld.xyz);
  L = EvalDiffuse(wi, wo, uv) * EvalDirectionalLight(uv);

  vec3 b1;
  vec3 b2;
  vec3 n = GetGBufferNormalWorld(uv);
  LocalBasis(n, b1, b2);
  mat3 TBN = mat3(b1, b2, n);

  vec3 Lind = vec3(0.0);
  for (int i = 0; i < SAMPLE_NUM; ++i) {
    float pdf;
    vec3 dir = SampleHemisphereCos(s, pdf);
    dir = normalize( TBN * dir );
    vec3 hitPos;
    //if ( RayMarch(vPosWorld.xyz, dir, hitPos) ) {
    if ( RayMarchWithMipmap(vPosWorld.xyz, dir, hitPos) ) {
      vec3 wi1 = normalize(hitPos - vPosWorld.xyz);
      vec2 uv1 = GetScreenCoordinate(hitPos);
      Lind += EvalDiffuse(wi1, wo, uv) / pdf * EvalDiffuse(wi, wo, uv1) * EvalDirectionalLight(uv1);
    }
  }

  Lind /= float(SAMPLE_NUM);
  L += Lind;

  vec3 color = pow(clamp(L, vec3(0.0), vec3(1.0)), vec3(1.0 / 2.2));
  //vec3 color = vec3(texture2D(uMipmap, uv).x / 10.0);
  //vec3 color = vec3(GetMipmapDepth(uv, 6) / 10.0);
  //vec3 color = vec3(GetMipmapUV(uv, 1), 1.0);
  //vec3 color = vec3(GetGBufferDepth(uv) / 10.0);
  gl_FragColor = vec4(vec3(color.rgb), 1.0);
}
