/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

// Todo: heightmap should really be rendered on GPU
// Todo: should return NO, instead of using a height of 999.f if navigationPoint is not reachable.

#import "NavigationComponent.h"
#import "../Utils/Math.h"
#import <BridgeEngine/BEDebugging.h>

@import GLKit;

@interface NavigationComponent()
@property (nonatomic) NSMutableData * navigationMap;
@property (atomic) GLKVector2 minMapCoord;
@property (atomic) float mapResolution;
@property (atomic) int mapWidth;
@property (atomic) int mapHeight;

@end

@implementation NavigationComponent

- (void) preProcess:(SCNNode *)collisionNode startY:(float)startY endY:(float)endY minBB:(GLKVector2)minBB maxBB:(GLKVector2)maxBB resolution:(float)resolution agentRadius:(float)radius {
    
    // step 1, calculate heightmap
    int width = (maxBB.x-minBB.x) / resolution;
    int height = (maxBB.y-minBB.y) / resolution;
    
    self.minMapCoord = GLKVector2Make(MIN(maxBB.x, minBB.x), MIN(maxBB.y, minBB.y));
    self.mapResolution = resolution;
    self.mapWidth = width;
    self.mapHeight = height;
    
    
    // filename of cached data
    NSString * cachedDataFileName = [NSString stringWithFormat:@"navMesh_%@_%d_%d_%.2f_%.2f_%.2f_%.2f_%.2f_%.2f.bin", collisionNode.name, width, height, self.minMapCoord.x, self.minMapCoord.y, resolution, radius, startY, endY];
    
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *filePath = [documentsPath stringByAppendingPathComponent:cachedDataFileName];
    
    NSData *data = [[NSFileManager defaultManager] contentsAtPath:filePath];
    
    if( data ) {
        self.navigationMap = [NSMutableData dataWithData:data];
        return;
    }
    
    be_dbg("size: %lu", sizeof(float) * width * height );
    
    float* heightMap = malloc( sizeof(float) * width * height );
    
    for(int x=0; x<width; x++) {
        for(int y=0; y<height; y++) {
            GLKVector3 start = GLKVector3Make(minBB.x + ((float)x)*resolution, startY, minBB.y + ((float)y)*resolution );
            GLKVector3 end = GLKVector3Make(minBB.x + ((float)x)*resolution, endY, minBB.y + ((float)y)*resolution );
            
            SCNVector3 from = SCNVector3FromGLKVector3( start);
            SCNVector3 to = SCNVector3FromGLKVector3( end );
            
            NSArray<SCNHitTestResult *> *hitTestResults = [collisionNode hitTestWithSegmentFromPoint:from toPoint:to options:nil];
            
            if( [hitTestResults count] ) {
                heightMap[x+y*width] = [hitTestResults objectAtIndex:0].worldCoordinates.y;
            } else {
                heightMap[x+y*width] = 999.f;
            }
        }
    }
    
    // step 2, construct 'navigation map' from heightmap, based on radius
    self.navigationMap = [NSMutableData dataWithLength: sizeof(float) * width * height];
    float* navBytes = (float *)[self.navigationMap mutableBytes];
    
    int radiusSize = MAX(1,radius/resolution);
    
    for(int x=0; x<width; x++) {
        for(int y=0; y<height; y++) {
            // get minimum y value (heighest) in radius
            
            float maxHeight = endY;
            bool unreachable = false;
            
            for( int xr=x-radiusSize;xr<x+radiusSize; xr++) {
                for( int yr=y-radiusSize;yr<y+radiusSize; yr++) {
                    float sampledHeight;
                    if( xr < 0 || xr >= width || yr < 0 || yr >= height ) {
                        sampledHeight = 999.f;
                    } else {
                        sampledHeight = heightMap[ xr + yr*width ];
                    }
                    if( sampledHeight > 998.f ) {
                        unreachable = true;
                    }
                    
                    if( endY-startY < 0.f ) {
                        maxHeight = MAX( maxHeight, sampledHeight );
                    } else {
                        maxHeight = MIN( maxHeight, sampledHeight );
                    }
                }
            }
            
            if( !unreachable ) {
                navBytes[ x + y*width ] = maxHeight;
            } else {
                navBytes[ x + y*width ] = 999.f;
            }
        }
    }
    
    be_NSDbg(@"Navigation Map is build, save to cached file %@", cachedDataFileName);
    
    [self.navigationMap writeToFile:filePath atomically:YES];
}

- (float) getHeight:(GLKVector3)position {
    int x = (position.x - self.minMapCoord.x ) / self.mapResolution;
    int y = (position.z - self.minMapCoord.y ) / self.mapResolution;
    
    if( x >= 0 && x < self.mapWidth && y >= 0 && y < self.mapHeight ) {
        float * data = (float *)[self.navigationMap mutableBytes];
        return data[ x + y * self.mapWidth ];
    }
    
    return 999.f;
}

- (float) getInterpolatedHeight:(GLKVector3)position {
    float x = (position.x - self.minMapCoord.x ) / self.mapResolution;
    float y = (position.z - self.minMapCoord.y ) / self.mapResolution;
    
    int xi = (int)floor(x);
    int yi = (int)floor(y);
    
    float xf = x-xi;
    float yf = y-yi;
    
    float h1, h2, h3, h4;
    h1 = h2 = h3 = h4 = 0.f;
    
    float * data = (float *)[self.navigationMap mutableBytes];
    bool success = true;
    
    if( xi >= 0 && xi < self.mapWidth && yi >= 0 && yi < self.mapHeight ) {
        h1 = data[ xi + yi * self.mapWidth ];
    } else {
        success = false;
    }
    
    xi ++;
    
    if( xi >= 0 && xi < self.mapWidth && yi >= 0 && yi < self.mapHeight ) {
        h2 = data[ xi + yi * self.mapWidth ];
    } else {
        success = false;
    }
    
    xi--;
    yi++;
    
    if( xi >= 0 && xi < self.mapWidth && yi >= 0 && yi < self.mapHeight ) {
        h3 = data[ xi + yi * self.mapWidth ];
    } else {
        success = false;
    }
    
    xi ++;
    
    if( xi >= 0 && xi < self.mapWidth && yi >= 0 && yi < self.mapHeight ) {
        h4 = data[ xi + yi * self.mapWidth ];
    } else {
        success = false;
    }
    
    if( h1 > 998.f || h2 > 998.f  || h3 > 998.f  || h4 > 998.f ) success = false;
    
    return success?lerpf( lerpf( h1, h2, xf ), lerpf( h3, h4, xf), yf ):999.f;
}

- (GLKVector3) getRandomPoint:(GLKVector3)position maxDistance:(float)distance minY:(float)minY maxTry:(int)maxTry {
    // random point ...
    
    for(int i=0; i<maxTry; i++) {
        float x = random11() * distance;
        float y = random11() * distance;
        
        float height = [self getInterpolatedHeight:GLKVector3Make(position.x + x, position.y, position.z + y)];
        if( height < 999.f && height > minY ) {
            return GLKVector3Make(position.x+x, height, position.z+y);
        }
    }
    return GLKVector3Make(999.f, 999.f, 999.f);
}


@end
