#version 430 compatibility

uniform sampler2D colortex0; // main
uniform sampler2D shadowcolor0; // current reflection color
uniform sampler2D colortex1; // reflection data
uniform sampler2D colortex3; // all reflections depth
uniform sampler2D colortex4; // all reflections rendered

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferPreviousProjection;
uniform mat4 gbufferPreviousModelView;

uniform vec3 cameraPositionDiff;

in vec2 texcoord;

#include "/lib/settings.glsl"

uniform float viewWidth;
uniform float viewHeight;

vec3 projectAndDivide(mat4 projMat, vec3 pos) {
	vec4 homogeneousPos = projMat * vec4(pos, 1.0);
	return homogeneousPos.xyz / homogeneousPos.w;
}

/* RENDERTARGETS: 4,3 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 depthOutput;

vec3 eyeToOldViewPos(vec3 pos) {
	return mat3(gbufferPreviousModelView) * (pos - cameraPositionDiff);
}

vec3 oldViewToOldScreenPos(vec3 pos) {
	return projectAndDivide(gbufferPreviousProjection, pos) * 0.5 + 0.5;
}

void main() {
	vec3 myScreenPos = vec3(texcoord, 0.1);
	vec3 ndcPos = myScreenPos * 2.0 - 1.0;
	vec3 viewPos = projectAndDivide(gbufferProjectionInverse, ndcPos);
	vec3 eyePos = mat3(gbufferModelViewInverse) * viewPos;
	vec3 dir = normalize(eyePos);

	vec3 pos = vec3(0.0);

	float stepSize = 0.05;
	float stepIncrease = 1.25;
	
	float dist = 0.0;

	for (int i = 0; i < 32; i++) {
		dist += stepSize;
		pos = dir * dist;
		stepSize *= stepIncrease;
		stepIncrease *= 1.01;
		vec3 myView = eyeToOldViewPos(pos);
		if (myView.z < 0.0) {
			myScreenPos = oldViewToOldScreenPos(myView);
			float myDepth = texture2D(colortex3, myScreenPos.xy).r;
			if (myDepth < myScreenPos.z) {
				break;
			}
		}
	}

	dist -= stepSize;
	pos -= dir * stepSize;
	for (int i = 0; i < 6; i++) {
		stepSize *= 0.5;
		dist += stepSize;
		pos = dir * dist;
		vec3 myView = eyeToOldViewPos(pos);
		if (myView.z < 0.0) {
			myScreenPos = oldViewToOldScreenPos(myView);
			float myDepth = texture2D(colortex3, myScreenPos.xy).r;
			if (myDepth < myScreenPos.z) { // inside
				pos -= dir * stepSize;
			}
		}
	}

	#ifdef SHARP_REPROJECTION
	ivec2 uv = ivec2(myScreenPos.xy * vec2(viewWidth, viewHeight));
	uv.x = clamp(uv.x, 0, int(viewWidth) - 1);
	uv.y = clamp(uv.y, 0, int(viewHeight) - 1);
	color = texelFetch(colortex4, uv, 0);
	#else
	color = texture2D(colortex4, myScreenPos.xy);
	#endif
	depthOutput = texture2D(colortex3, myScreenPos.xy);
}