#version 430 compatibility

uniform sampler2D shadowcolor0; // current reflection color
uniform sampler2D shadowtex0; // current reflection shadow
uniform sampler2D colortex1; // reflection data
uniform sampler2D colortex3; // all reflections depth
uniform sampler2D colortex4; // all reflections rendered

#include "/lib/shaders_properties.glsl"

#include "/lib/settings.glsl"

in vec2 texcoord;

uniform float viewWidth;
uniform float viewHeight;

/* RENDERTARGETS: 4,3 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 depth;

uniform float randUvOffset;

void main() {
	vec3 reflectionData = texture2D(colortex1, texcoord).xyz;
	float strength = reflectionData.x;
	vec2 shadowUv = vec2(1.0 - texcoord.x, texcoord.y);
	if (reflectionData.y > 0.05) {
		color.xyz = mix(
			texture2D(colortex4, texcoord).xyz,
			texture2D(shadowcolor0, shadowUv).xyz,
			strength
		);
		depth = vec4(
			mix(
				texture2D(colortex3, texcoord).x,
				texture2D(shadowtex0, shadowUv).x,
				strength
			),
			0.0, 0.0, 1.0
		);
		color.a = 1.0;
	} else {
		vec2 step = vec2(1.0) / vec2(viewWidth, viewHeight);
		vec2 dir = vec2(1.0, 0.0);
		dir *= mix(35.5, 1.5, texture2D(colortex4, texcoord + dir * step).a);
		color.xyz = vec3(0.0);
		float sum = 0.00001;
		float maxWeight = 0.0;
		for (int i = 0; i < 4; i++) {
			dir = vec2(dir.y, -dir.x);
			vec4 myColor = texture2D(colortex4, texcoord + dir * step);
			float weight = myColor.a;
			maxWeight = max(maxWeight, weight);
			sum += weight;
			color.xyz += myColor.xyz * weight;
		}
		color.xyz /= sum;
		color.a = maxWeight * 0.9;
		depth = vec4(2.0, 0.0, 0.0, 1.0);
	}
}