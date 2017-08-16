precision mediump float;

uniform vec2 u_resolution;
uniform sampler2D cameraSampler;

varying vec3 v_color;

void main(void)
{
    vec2 uv = gl_FragCoord.xy / u_resolution;
    vec4 col = texture2D(cameraSampler, fract(uv));

    gl_FragColor = col;
    gl_FragColor = vec4(v_color, 1.0);
}
