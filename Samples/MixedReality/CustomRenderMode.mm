//
//  ScanEnvironmentShader.mm
//  MixedRealityRendering
//
//  Created by Nicholas Shelton on 7/29/16.
//  Copyright © 2016 Occipital. All rights reserved.
//

#import "CustomRenderMode.h"

GLuint CUSTOM_RENDER_MODE_CAMERA_TEXTURE_NAME = -1;

@implementation CustomRenderMode

- (id)init {
    self = [super init];

    return self;
}

//delegate methods
- (void)compile {
    const int NUM_ATTRIBS = 2;
    // Vertex and Normal Layout
    GLuint attributeIds[NUM_ATTRIBS] = {0, 2};
    const char *attributeNames[NUM_ATTRIBS] = {"a_position", "a_normal"};

    _glProgram = BEShaderLoadProgramFromString([self vertexShaderSource],
                                               [self fragmentShaderSource],
                                               NUM_ATTRIBS,
                                               attributeIds,
                                               attributeNames);

    self.projectionMatrixLocation = glGetUniformLocation(_glProgram, "u_perspective_projection");
    self.modelviewMatrixLocation = glGetUniformLocation(_glProgram, "u_modelview");

    self.depthSamplerLocation = glGetUniformLocation(_glProgram, "u_depthSampler");
    self.cameraSamplerLocation = glGetUniformLocation(_glProgram, "u_colorSampler");
    self.renderResolutionLocation = glGetUniformLocation(_glProgram, "u_resolution");

    self.loaded = true;
}

- (void)prepareWithProjection:(const float *)projection
                    modelview:(const float *)modelView
           depthBufferTexture:(const GLuint)depthTexture
           cameraImageTexture:(const GLuint)cameraTexture {
    glUseProgram(_glProgram);

    glUniformMatrix4fv(self.modelviewMatrixLocation, 1, GL_FALSE, modelView);
    glUniformMatrix4fv(self.projectionMatrixLocation, 1, GL_FALSE, projection);

    // Load mesh depth into texture unit 6.
    glActiveTexture(GL_TEXTURE6);
    glBindTexture(GL_TEXTURE_2D, depthTexture);
    glUniform1i(self.depthSamplerLocation, GL_TEXTURE6 - GL_TEXTURE0);

    // Load camera image into texture unit 7.
    //NSLog(@"Allocated a camera texture into integer: %d", cameraTexture);
    CUSTOM_RENDER_MODE_CAMERA_TEXTURE_NAME = cameraTexture;

    glActiveTexture(GL_TEXTURE7);
    glBindTexture(GL_TEXTURE_2D, cameraTexture);
    glUniform1i(self.cameraSamplerLocation, GL_TEXTURE7 - GL_TEXTURE0);

    // update resolution
    GLint vp[4];
    glGetIntegerv(GL_VIEWPORT, vp);
    glUniform2f(self.renderResolutionLocation, vp[2], vp[3]);

    glEnable(GL_DEPTH_TEST);
}

- (const char *)vertexShaderSource {
    NSString *shader = @
    R"(
    
    attribute vec4 a_position;
    attribute vec3 a_normal;
    
    uniform mat4 u_perspective_projection;
    uniform mat4 u_modelview;
    
    varying vec3 v_worldPos;
    varying vec3 v_normal;
    
    void main()
    {
        gl_Position = u_perspective_projection * u_modelview * a_position;
        v_normal = a_normal;
        v_worldPos = a_position.xyz;
    }
    )";

    return [shader UTF8String];
}

- (const char *)fragmentShaderSource {
    NSString *shader = @
    R"(
    
    precision mediump float;

    varying vec3 v_worldPos;
    varying vec3 v_normal;

    uniform sampler2D u_depthSampler;
    uniform sampler2D u_colorSampler;
    uniform vec2 u_resolution;

    void main()
    {
        vec2 uv = gl_FragCoord.xy / u_resolution;
        
        // the fract here is important for stereo rendeirng.
        // In stereo, this will be 0-1 in the left eye, and 1-2 in the right eye.
        // The shader will be called twice, once for each eye
        // and the texture will be hooked up to the the corresponding eye's view (not stereo)
        
        vec4 warpedColor = texture2D( u_colorSampler, fract(uv) ) ;
        vec4 depth = texture2D( u_depthSampler, fract(uv) ) ;
        
        gl_FragColor =  warpedColor;
        //gl_FragColor.a = 0;
        
        // invert color, for effect
        //gl_FragColor.rgb = abs(v_normal);
    }
    )";

    return [shader UTF8String];
}
@end

