#version 430 compatibility

uniform sampler2D lightmap;
uniform sampler2D gtexture;

uniform sampler2D shadowcolor0;

uniform sampler2D colortex4; // all reflections rendered

uniform float viewWidth;
uniform float viewHeight;

uniform float alphaTestRef = 0.1;

in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;

in float isCurrentReflection;
in float isReflective;

in float blockIdFloat;

#include "/lib/settings.glsl"

#ifdef ENABLE_PBR
uniform sampler2D specular;
uniform float wetness;
#endif

#if ADD_REFLECTION_MODE >= 1
in vec4 myReflectData;
in vec2 reflectDataUv;
#endif
#if ADD_REFLECTION_MODE == 1
layout (rgba16f) uniform image2D allReflectionsDataImage;
#endif

#if ADD_REFLECTION_MODE == 2
/* RENDERTARGETS: 0,1,2 */
layout(location = 2) out vec4 reflectionDataCulled;
#else
/* RENDERTARGETS: 0,1 */
#endif
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 reflectionPixelData;


#if ADD_REFLECTION_MODE == 2
float encodeFloat(vec2 v) {
	v.x = clamp(v.x, 0.0, 1.0) * 0.99;
	return v.x + floor(v.y * 255.0);
}
#endif

void main() {
	color = texture(gtexture, texcoord) * glcolor;
	color *= texture(lightmap, lmcoord);
	int blockId = int(blockIdFloat + 0.25);
	#ifdef ENABLE_PBR
	if (blockId == 6) {
		color.a = max(color.a, 0.25);
	}
	#endif
	reflectionPixelData = vec4(0.0, 0.0, 0.0, color.a);
	#if ADD_REFLECTION_MODE == 2
	reflectionDataCulled = vec4(0.0, 0.0, 0.0, color.a > 0.99 ? 1.0 : 0.0);
	#endif
	if (color.a < alphaTestRef) {
		discard;
	}

	vec2 fragcoord = gl_FragCoord.xy / vec2(viewWidth, viewHeight);
	vec3 reflectionColor;
	if (isCurrentReflection > 0.5) {
		reflectionColor = texture(shadowcolor0, vec2(1.0 - fragcoord.x, fragcoord.y)).rgb;
	} else {
		reflectionColor = texture(colortex4, fragcoord).rgb;
	}

	float reflectionStrength = isReflective;

	#ifdef ENABLE_PBR
	vec4 specularData = texture2D(specular, texcoord);
	{
		int greenInt = int(specularData.g * 255.0 + 0.01);
		int blueInt = int(specularData.b * 255.0 + 0.01);
		float porosity = 0.0;
		if (blueInt <= 64.0) {
			porosity = specularData.b * wetness * 2.0; // * 4.0
			porosity *= lmcoord.y;
		}
		if (blockId == 5) {
			reflectionStrength *= 0.75;
			reflectionColor *= color.rgb * 0.5 + 0.5;
		} else if (blockId == 6) {
			reflectionStrength *= 1.0 - min((color.a - 0.5) * 1.8, 1.0);
		} else if (blockId == 7) {
			reflectionColor *= color.rgb;
			reflectionStrength *= 1.0 - min((color.a - 0.5) * 1.8, 1.0);
		} else if (blockId == MIRROR_BLOCK) {

		} else if (greenInt >= 230) {
			reflectionColor *= color.rgb;
		} else {
			reflectionStrength *= mix(
				specularData.g,
				1.0,
				porosity
			);
		}
	}
	#endif

	color = vec4(mix(color.rgb, reflectionColor, reflectionStrength), color.a);
	reflectionPixelData.g = reflectionStrength;

	#if ADD_REFLECTION_MODE >= 1
	if (reflectionStrength > 0.05) {
		reflectionPixelData.r = isCurrentReflection;
		#if ADD_REFLECTION_MODE == 2
			reflectionDataCulled = vec4(
				myReflectData.x + 2.0,
				myReflectData.y,
				myReflectData.w,
				1.0
			);
			if (myReflectData.z < 0.0) {
				reflectionDataCulled.y += 4.0;
			}
		#else
		imageStore(
			allReflectionsDataImage,
			ivec2(reflectDataUv * REFLECTIONS_DATA_SIZE),
			vec4(myReflectData.xyz + 2.0, myReflectData.w)
		);
		#endif
	}
	#endif
}