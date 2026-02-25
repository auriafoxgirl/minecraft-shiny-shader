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

	for (int i = 0; i < 32; i++) {
		pos += dir * stepSize;
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

	pos -= dir * stepSize;
	for (int i = 0; i < 6; i++) {
		stepSize *= 0.5;
		pos += dir * stepSize;
		vec3 myView = eyeToOldViewPos(pos);
		if (myView.z < 0.0) {
			myScreenPos = oldViewToOldScreenPos(myView);
			float myDepth = texture2D(colortex3, myScreenPos.xy).r;
			if (myDepth < myScreenPos.z) { // inside
				pos -= dir * stepSize;
			}
		}
	}

	color = texture2D(colortex4, myScreenPos.xy);
	// color.rgb = vec3(color.a);
	depthOutput = texture2D(colortex3, myScreenPos.xy);
}