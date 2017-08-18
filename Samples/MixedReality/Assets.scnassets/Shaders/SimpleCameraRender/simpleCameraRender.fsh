precision mediump float;

uniform vec2 u_resolution;
uniform sampler2D cameraSampler;

varying vec4 v_positionClipSpace;

void main(void)
{
    vec2 uv = gl_FragCoord.xy / u_resolution;
    vec4 col = texture2D(cameraSampler, fract(uv));

    gl_FragColor = col;


    vec4 screenSpace = v_positionClipSpace / v_positionClipSpace.w;
    screenSpace.x = (screenSpace.x + 1.0) / 2.0;
    screenSpace.y = (screenSpace.y + 1.0) / 2.0;

    vec2 textureCoords = clamp(screenSpace.xy, 0.0, 1.0);
    vec4 colorFromBakedPosition = texture2D(cameraSampler, textureCoords);

    //gl_FragColor = mix(colorFromBakedPosition, vec4(1,0,0,1), 0.5);
    gl_FragColor = mix(colorFromBakedPosition, vec4(1,0,0,1), 0.0);
    //gl_FragColor = vec4(screenSpace.xxx, 1.0);
}
