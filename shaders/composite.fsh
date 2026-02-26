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

#if ADD_REFLECTION_MODE == 2
uniform sampler2D colortex2; // reflections add composite mode
layout (rgba16f) uniform image2D allReflectionsDataImage;

float rand4(vec4 co){
    return fract(sin(dot(co, vec4(12.9898, 78.233, 19.943, 8.814))) * 43758.5453);
}

vec2 generateReflectionsDataUv(vec4 id) {
	return vec2(rand4(id + randUvOffset), rand4(id + vec4(3.0, 0.0, 0.0, 0.0) + randUvOffset));
}

ivec2 generateReflectionsDataUvTexel(vec4 id) {
	return ivec2(generateReflectionsDataUv(id) * REFLECTIONS_DATA_SIZE);
}

#endif

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
		vec2 step = vec2(8.5) / vec2(viewWidth, viewHeight);
		vec2 dir = vec2(1.0, 0.0);
		// color.xyz = texture2D(colortex4, texcoord).xyz;
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
	#if ADD_REFLECTION_MODE == 2
	vec3 data = texture2D(colortex2, texcoord).xyz;
	if (data.x > 0.5) {
		data.x -= 2.0;
		bool flipZ = false;
		if (data.y > 1.5) {
			flipZ = true;
			data.y -= 4.0;
		}
		vec3 normal = vec3(
			data.x,
			data.y,
			sqrt(max(1.0 - dot(data.xy, data.xy), 0.0))
		);
		if (flipZ) {
			normal.z = -normal.z;
		}
		normal = normalize(normal);
		vec4 id = vec4(normal, data.z);
		#ifdef REFLECTION_PIORITY
		id.yz += floor(texcoord.xy * 4.0);
		#endif
		imageStore(
			allReflectionsDataImage,
			generateReflectionsDataUvTexel(id),
			vec4(normal + 2.0, data.z)
		);
	}
	#endif
}