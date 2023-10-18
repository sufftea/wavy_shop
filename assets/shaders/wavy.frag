#version 460 core

#include <flutter/runtime_effect.glsl>

#define PI 3.1415926535

precision mediump float;

uniform vec2 resolution;
uniform float t;
uniform float selectionOffset;
uniform float selectionAnim;
uniform float yOffset;
uniform float prevOffset;
uniform float targetOffset;
uniform sampler2D tex;


out vec4 fragColor;

// Magic colors
const vec3 mBlackWhite = vec3(0, 0, 0) / 255;

//	Simplex 3D Noise 
//	by Ian McEwan, Ashima Arts
//
vec4 permute(vec4 x){return mod(((x*34.0)+1.0)*x, 289.0);}
vec4 taylorInvSqrt(vec4 r){return 1.79284291400159 - 0.85373472095314 * r;}

float snoise(vec3 v){ 
  const vec2  C = vec2(1.0/6.0, 1.0/3.0) ;
  const vec4  D = vec4(0.0, 0.5, 1.0, 2.0);

  // First corner
  vec3 i  = floor(v + dot(v, C.yyy) );
  vec3 x0 =   v - i + dot(i, C.xxx) ;

  // Other corners
  vec3 g = step(x0.yzx, x0.xyz);
  vec3 l = 1.0 - g;
  vec3 i1 = min( g.xyz, l.zxy );
  vec3 i2 = max( g.xyz, l.zxy );

  //  x0 = x0 - 0. + 0.0 * C 
  vec3 x1 = x0 - i1 + 1.0 * C.xxx;
  vec3 x2 = x0 - i2 + 2.0 * C.xxx;
  vec3 x3 = x0 - 1. + 3.0 * C.xxx;

  // Permutations
  i = mod(i, 289.0 ); 
  vec4 p = permute( permute( permute( 
             i.z + vec4(0.0, i1.z, i2.z, 1.0 ))
           + i.y + vec4(0.0, i1.y, i2.y, 1.0 )) 
           + i.x + vec4(0.0, i1.x, i2.x, 1.0 ));

  // Gradients
  // ( N*N points uniformly over a square, mapped onto an octahedron.)
  float n_ = 1.0/7.0; // N=7
  vec3  ns = n_ * D.wyz - D.xzx;

  vec4 j = p - 49.0 * floor(p * ns.z *ns.z);  //  mod(p,N*N)

  vec4 x_ = floor(j * ns.z);
  vec4 y_ = floor(j - 7.0 * x_ );    // mod(j,N)

  vec4 x = x_ *ns.x + ns.yyyy;
  vec4 y = y_ *ns.x + ns.yyyy;
  vec4 h = 1.0 - abs(x) - abs(y);

  vec4 b0 = vec4( x.xy, y.xy );
  vec4 b1 = vec4( x.zw, y.zw );

  vec4 s0 = floor(b0)*2.0 + 1.0;
  vec4 s1 = floor(b1)*2.0 + 1.0;
  vec4 sh = -step(h, vec4(0.0));

  vec4 a0 = b0.xzyw + s0.xzyw*sh.xxyy ;
  vec4 a1 = b1.xzyw + s1.xzyw*sh.zzww ;

  vec3 p0 = vec3(a0.xy,h.x);
  vec3 p1 = vec3(a0.zw,h.y);
  vec3 p2 = vec3(a1.xy,h.z);
  vec3 p3 = vec3(a1.zw,h.w);

  //Normalise gradients
  vec4 norm = taylorInvSqrt(vec4(dot(p0,p0), dot(p1,p1), dot(p2, p2), dot(p3,p3)));
  p0 *= norm.x;
  p1 *= norm.y;
  p2 *= norm.z;
  p3 *= norm.w;

  // Mix final noise value
  vec4 m = max(0.6 - vec4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 0.0);
  m = m * m;
  return 42.0 * dot( m*m, vec4( dot(p0,x0), dot(p1,x1), 
                                dot(p2,x2), dot(p3,x3) ) );
}

float computeBoundary(vec2 norm) {
  norm.x -= selectionOffset;

  float value = - pow(abs(norm.x), 3);

  return value;
}

float f1() {
  vec2 pos = FlutterFragCoord().xy;
  vec2 norm = pos / resolution.xy;
  
  vec2 pos0 = pos / 96;
  vec2 n0 = vec2(
    snoise(vec3(pos0.x, pos0.y, t)),
    snoise(- vec3(pos0.x , pos0.y, t))
  ) / 48;
  
  vec2 pos1 = pos / 256;
  vec2 n1 = vec2(
    snoise(vec3(pos1.x, pos1.y, t)),
    snoise(- vec3(pos1.x , pos1.y, t))
  ) / 48;

  vec2 offset = n0 + n1;
  offset *= -exp(-10*norm.x*norm.x) + 1;

  vec2 posRes = norm + offset;
  float boundary = computeBoundary(posRes);

  float y = 1 - posRes.y;
  y = exp(y);

  return boundary + y;
}

float f2(float offset) {
  vec2 pos = FlutterFragCoord().xy;
  vec2 norm = pos / resolution.xy;


  float x = norm.x - offset;
  float y = norm.y - yOffset;

  y += 0.02 * (-pow(selectionAnim*2-1, 2) + 1);

  float z = exp( 
    256 * (-x*x - y*y)
  );

  return z;
}

float smoothMax(float a, float b) {
  const float k = 5;
  float res = exp2(k * a) + exp2(k * b);
  return log2(res) / k;
}


float inverseLerp(float start, float end, float value) {
  if (start == end) {
      return float(0);
  }
  return (value - start) / (end - start);
}

float dist(float a, float b) {
  return inverseLerp(
    a, 
    a < b ? a + 1 : a - 1, 
    b
  );
}

float colorDiff(vec3 col, vec3 match) {
  float dx = dist(col.x, match.x);
  float dy = dist(col.y, match.y);
  float dz = dist(col.z, match.z);

  return (dx + dy + dz) / 3;
}

void main() {
  vec2 st = FlutterFragCoord().xy / resolution.xy;

  vec4 col = texture(
    tex, 
    st
  );
  
  float v1 = f1() * 0.75;
  const float rippleCoef = 2.3;
  float v2 = f2(prevOffset) * (1-selectionAnim) * rippleCoef;
  float v3 = f2(targetOffset) * selectionAnim * rippleCoef;

  float value = smoothMax(v1, v2);
  value = smoothMax(value, v3);

  float mask = 0;
  if (value < 1) {
    mask = 1;
  }

  fragColor = col * mask;

  float blackWhite = colorDiff(col.xyz, mBlackWhite);
  if (blackWhite < 0.01 && mask == 0) {
    fragColor = vec4(1, 1, 1, 1);
  }
}