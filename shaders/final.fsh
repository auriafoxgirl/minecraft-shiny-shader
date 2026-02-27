#version 430 compatibility

// #define DEBUG_RENDER // debug render

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

in vec2 texcoord;

uniform sampler2D colortex0; // main
#ifdef DEBUG_RENDER
uniform sampler2D shadowcolor0; // current reflection color
uniform sampler2D allRflectionsDataTex; // all reflections data
uniform sampler2D reflectionDataTex; // current reflection data
uniform sampler2D colortex1; // reflection data
uniform sampler2D colortex2; // last reflections data for composite mode
uniform sampler2D colortex3; // all reflections depth
uniform sampler2D colortex4; // all reflections rendered

#include "/lib/settings.glsl"
#endif

void main() {
	color = texture(colortex0, texcoord);

	#ifdef DEBUG_RENDER
	vec2 miniUv = fract(texcoord * 5.0);
	ivec2 miniPos = ivec2((1.0 - texcoord) * 5.0);
	if (miniPos.x == 0) {
		if (miniPos.y == 0) {
			if (miniUv.x > 0.25) {
				vec2 uv = miniUv;
				uv.x = (uv.x - 0.25) / 0.75;
				vec4 c = texelFetch(allRflectionsDataTex, ivec2(uv * REFLECTIONS_DATA_SIZE), 0);
				color.xyz = vec3((c - 2.0) * 0.5 + 0.5);
			} else {
				color.xyz = texelFetch(reflectionDataTex, ivec2(0, 0), 0).xyz * 0.5 + 0.5;
			}
		} else if (miniPos.y == 1) {
			color = texture2D(shadowcolor0, miniUv);
		} else if (miniPos.y == 2) {
			if (miniUv.x > 0.5) {
				float depth = texture2D(colortex3, miniUv).r;
				depth *= depth;
				depth *= depth;
				depth *= depth;
				color.xyz = vec3(depth);
			} else {
				color = texture2D(colortex4, miniUv);
			}
		} else if (miniPos.y == 3) {
			vec3 data = texture2D(colortex2, miniUv).xyz;
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

				color = vec4(normal * 0.5 + 0.5, 1.0);
			} else {
				color = vec4(1.0);
			}
		} else if (miniPos.y == 4) {
			color = texture2D(colortex1, miniUv);
		}
	}
	#endif
}