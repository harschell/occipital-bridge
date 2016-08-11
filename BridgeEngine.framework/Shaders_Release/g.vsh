attribute vec4 a_position;varying vec2 e;void main(){e=(a_position.xy+1.)*.5,gl_Position=a_position;}
