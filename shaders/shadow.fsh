#version 430 compatibility

uniform sampler2D lightmap;
uniform sampler2D gtexture;

uniform float alphaTestRef = 0.1;

in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;

in float skipPixel;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
	if (skipPixel > -0.0001) {
		discard;
	}
	color = texture(gtexture, texcoord) * glcolor;
	color *= texture(lightmap, lmcoord);
	if (color.a < alphaTestRef) {
		discard;
	}
}