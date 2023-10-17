#version 460 core

#include <flutter/runtime_effect.glsl>

#define PI 3.1415926535

precision mediump float;

uniform vec2 resolution;
uniform float t;
uniform float selectionOffset;
uniform float selectionDist;
uniform float prevOffset;
uniform float targetOffset;
uniform sampler2D tex;


out vec4 fragColor;

// Magic colors
const vec3 mTransparent = vec3(52, 143, 0) / 255;

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

// (f(x), strength)
// strength - resistance to waviness
vec2 computeBoundary(vec2 norm) {
  norm.x -= selectionOffset;

  float strength = exp(-pow(abs(norm.x * 16), 2)) * mix(0.9, 0.1, selectionDist);

  float value = - pow(abs(norm.x), 2.5) + mix(0.7, 0.6, selectionDist);
  value += exp(-pow(
    abs(norm.x * mix(12, 4, selectionDist)), 
    mix(4, 2, selectionDist)
  )) / mix(6, 32, selectionDist);

  return vec2(value, strength);
}

vec2 waveOffset(vec2 norm, vec2 noise) {
  vec2 boundary = computeBoundary(norm);
  float boundaryValue = boundary.x;
  float strength = boundary.y;

  float boundaryDist = abs(norm.y - boundaryValue);

  boundaryDist = exp(- boundaryDist * boundaryDist * 64);
  vec2 offset = vec2(
    noise.x * (boundaryDist / mix(32, 1024, strength)),
    noise.y * (boundaryDist / mix(32, 1024, strength))
  );

  return offset;
}

float f1() {
  vec2 pos = FlutterFragCoord().xy;
  vec2 norm = pos / resolution.xy;
  
  vec2 pos0 = pos / 96;
  vec2 n0 = vec2(
    snoise(vec3(pos0.x, pos0.y, t)),
    snoise(- vec3(pos0.x , pos0.y, t))
  );
  vec2 offset0 = waveOffset(norm, n0);
  
  vec2 pos1 = pos / 256;
  vec2 n1 = vec2(
    snoise(vec3(pos1.x, pos1.y, t)),
    snoise(- vec3(pos1.x , pos1.y, t))
  );
  vec2 offset1 = waveOffset(norm, n1);


  vec2 offset = offset0 + offset1 * 1.5;

  vec2 posRes = norm + offset;
  vec2 boundary = computeBoundary(posRes);
  float boundaryValue = boundary.x;

  return boundar

  float res = 0;
  if (posRes.y > boundaryValue) {
    res = 1;
  }

  return res;
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
  
  float mask = f1();

  fragColor = col * mask;

  // float transparent = colorDiff(col.xyz, mTransparent);
  // if (transparent < 0.01) {
  //   fragColor = vec4(0);
  // }
}

