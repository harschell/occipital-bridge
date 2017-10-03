/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import "PathFinding.h"
#import <BridgeEngine/BridgeEngine.h>
#import <SceneKit/SceneKit.h>
#import <GLKit/GLKit.h>

#include <queue>
#include <stack>
#include <functional>
#include <unordered_map>
#include <map>
#include <vector>

namespace {

    class matrix {
    public:
        std::vector< std::vector< unsigned char > > data;
        int width;
        int height;
        
        void resize( int w, int h ) {
            data.resize(w);
            for( int x=0; x<w; x++ ) {
                data[x].resize(h);
            }
            width = w;
            height = h;
        }
        
        void copy( matrix &source ) {
            resize( source.width, source.height );
            for( int x=0; x<width; x++) {
                for( int y=0; y<height; y++) {
                    data[x][y] = source.data[x][y];
                }
            }
        }
    };
    
} // anonymous

/**
 * Internal PathFindingOperation category.
 */
@interface PathFindingOperation ()
@property(nonatomic, weak)  PathFinding *pathDaemon;

- (instancetype) initWithFrom:(GLKVector3)from
                           to:(GLKVector3)to
                   getClosest:(BOOL)closest
                       daemon:(PathFinding*)daemon;
@end


@interface PathFinding ()
{
    matrix map;
    matrix topoMap;
    float** scores;
    matrix connectedComponentMap;
    
    int robotRadiusInPixels;
    float pixelSizeInMeters;
    
    // THESE ARE OFFSETS FROM PIXEL 0,0 top left
    float worldCenterX;
    float worldCenterY;
    
    NSOperationQueue *pathQueue;
}

- (NSMutableArray*) runPathPlanningWithOperation:(PathFindingOperation*)pathOp;

@end

@implementation PathFinding

struct DijkstraNode
{
    int x,y;
    float accumulatedScore;
    float distanceTravelled;
    float heuristic;
    DijkstraNode* last;
    bool operator<(const DijkstraNode& rhs) const // <3 C++11
    {
        return heuristic >= rhs.heuristic;  // we want the priority queue to put smaller elements on top
    }
};

-(void) pixCoordToWorldXYWithPx:(int)px Py:(int)py Wxp:(float*)wx Wyp:(float*)wy
{
    
    *wx = ((float)px) * pixelSizeInMeters + worldCenterX;
    *wy = ((float)py) * pixelSizeInMeters + worldCenterY;
}

-(void) worldCoordToPixCoordWithWx:(float)wx Wy:(float)wy Pxp:(int*)px Pyp:(int*)py
{
    *px = (int)round((wx - worldCenterX)/pixelSizeInMeters);
    *py = (int)round((wy - worldCenterY)/pixelSizeInMeters);
}

- (UIImage *)loadImage:(NSString*)name  {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                         NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString* path = [NSString stringWithFormat:@"%@/%@", documentsDirectory, name];
    NSLog(@"loading %@", path);
    
    return [[UIImage alloc] initWithContentsOfFile:path];
}

struct setNode
{
    setNode* parent;
    unsigned char label;
};

- (setNode*) find:(setNode*)x
{
    if(x->parent != x)
    {
        x->parent = [self find:x->parent];
        x->label = x->parent->label;
    }
    return x->parent;
}

- (setNode*) unionOf:(setNode*)x andSet:(setNode*) y
{
    setNode* xRoot = [self find:x];
    setNode* yRoot = [self find:y];
    
    if(xRoot->label < yRoot->label)
    {
        yRoot->parent = xRoot;
        return xRoot;
    } else{
        xRoot->parent = yRoot;
        return yRoot;
    }
}

/**
 * Check pathing from starting point to goal point.
 */
- (bool) canPathFromStartPointX:(int)sx startPointY:(int)sy goalPointX:(int)gx goalPointY:(int) gy
{
    // Bail if requested point is out of bounds
    if(sx < 0 || sx >= connectedComponentMap.width || sy < 0 || sy >= connectedComponentMap.height)
    {
        NSLog(@"Bad source point (%d, %d)", sx, sy);
        return false;
    }
    
    if(gx < 0 || gx >= connectedComponentMap.width || gy < 0 || gy >= connectedComponentMap.height)
    {
        NSLog(@"Bad goal point (%d, %d)", gx, gy);
        return false;
    }
    
    return connectedComponentMap.data[sx][sy] == connectedComponentMap.data[gx][gy] && connectedComponentMap.data[sx][sy] != 0;
}

- (instancetype) init
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                         NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *scenePath = [documentsDirectory stringByAppendingPathComponent:@"BridgeEngineScene"];
    NSString *occupancyImagePath = [scenePath stringByAppendingPathComponent:@"OccupancyMap.png"];

    UIImage * mapImage = [[UIImage alloc] initWithContentsOfFile:occupancyImagePath];
    if( mapImage == nil ) {
        NSLog(@"Failed to load the OccupancyMap.png from %@", occupancyImagePath);
        return nil;
    }
    return [self initWithImage:mapImage];
}

- (instancetype) initWithImage:(UIImage*) mapImage
{
    self = [super init];
    if (self) {
        robotRadiusInPixels = 2; // 7.0;
        pixelSizeInMeters = 0.04; // 0.04;
        worldCenterX = -2.89995;
        worldCenterY= -2.90582;
        
        //Load occupancy map
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                             NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *scenePath = [documentsDirectory stringByAppendingPathComponent:@"BridgeEngineScene"];
        NSString *occupancyMetadata = [scenePath stringByAppendingPathComponent:@"OccupancyMap.metadata"];

        // Parse the metadata file for three values, OriginX, OriginZ, PixelSize.
        // Example:
        // { "OriginX" :-3.5293,
        //   "OriginZ": -1.42487,
        //   "MetersPerPixel" : 0.04 }
        NSString *metadata = [[NSString alloc] initWithContentsOfFile:occupancyMetadata encoding:NSUTF8StringEncoding error:nil];
        if( metadata != nil && [metadata length] > 0 ) {
            NSError *error;
            NSData *data = [metadata dataUsingEncoding:NSUTF8StringEncoding];
            NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData:data
                                             options:kNilOptions
                                             error:&error];
            NSAssert(error == nil, @"Error decoding occupancy map : %@", error.localizedDescription);
            
            worldCenterX = [jsonDictionary[@"OriginX"] doubleValue];
            worldCenterY = [jsonDictionary[@"OriginZ"] doubleValue];
            pixelSizeInMeters = [jsonDictionary[@"MetersPerPixel"] doubleValue];
        } else {
            NSLog(@"Failed to load the OccupancyMap.metadata from %@", occupancyMetadata);
            return nil;
        }
        
        //do initialization
        map.resize(mapImage.size.width, mapImage.size.height);
        
        CGImageRef image = [mapImage CGImage];
        NSUInteger width = CGImageGetWidth(image);
        NSUInteger height = CGImageGetHeight(image);
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        unsigned char *rawData = (unsigned char *)malloc(height * width * 4);
        NSUInteger bytesPerPixel = 4;
        NSUInteger bytesPerRow = bytesPerPixel * width;
        NSUInteger bitsPerComponent = 8;
        CGContextRef context = CGBitmapContextCreate(rawData, width, height, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
        CGColorSpaceRelease(colorSpace);
        
        CGContextDrawImage(context, CGRectMake(0, 0, width, height), image);
        CGContextRelease(context);
        
        for(int y = 0; y < mapImage.size.height; y++)
        {
            for(int x = 0; x < mapImage.size.width; x++)
            {
                map.data[x][y] = rawData[(bytesPerRow * y) + x * bytesPerPixel];  //map images should be B&W; use red channel.
            }
        }
        
        free(rawData);


        matrix mapCopy;
        mapCopy.resize(map.width, map.height);
        mapCopy.copy(map);

        // Dialate the occupied regions by the radius
        for (int y = 0; y < map.height; ++y)
        for (int x = 0; x < map.width; ++x)
        {
            for (int dy = -robotRadiusInPixels; dy <= robotRadiusInPixels; dy++)
            for (int dx = -robotRadiusInPixels; dx <= robotRadiusInPixels; dx++)
            {
                const int py = y + dy;
                const int px = x + dx;

                if(dy*dy + dx*dx > robotRadiusInPixels*robotRadiusInPixels)
                    continue;

                if(py < 0 || py >= map.height || px < 0 || px >= map.width) continue;


                if (mapCopy.data[px][py] == 255)
                    map.data[x][y] = 255;
            }
        }
        
        // ------------ Create 1/r^2 topological map ------------
        
        topoMap.resize(map.width, map.height);
        topoMap.copy(map);
        
        int accumulateSize = robotRadiusInPixels*2;
        
        for(int y = 0; y < topoMap.height; y++)
        {
            for(int x = 0; x < topoMap.width; x++)
            {
                float accumulator = 0;
                for(int dy = -1*accumulateSize; dy <= accumulateSize; dy++)
                {
                    for(int dx = -1*accumulateSize; dx <= accumulateSize; dx++)
                    {
                        int py = y + dy;
                        int px = x + dx;
                        
                        if(dx == 0 && dy == 0) continue;
                        
                        if(py < 0 || py >= map.height || px < 0 || px >= map.width)
                        {
                            accumulator += 255.0f / (dx*dx + dy*dy);
                            continue;
                        }
                        
                        if(map.data[px][py] >= 254)
                        {
                            accumulator += ((float)map.data[px][py]) / (dx*dx + dy*dy);
                        }
                    }
                }
                
                accumulator = accumulator / (accumulateSize/1.414);
                accumulator += map.data[x][y];
                if(accumulator > 254) accumulator = 255;
                topoMap.data[x][y] = (unsigned char) accumulator;
            }
        }
        
        // Create a scores map.
        scores = new float*[topoMap.height];
        for(int y = 0; y < topoMap.height; y++)
        {
            scores[y] = new float[topoMap.width];
            for(int x = 0; x < topoMap.width; x++)
            {
                //oc_dbg("%i %i", y, x);
                scores[y][x] = -1;
            }
        }
        
        // Creat a queue for background processing.
        pathQueue = [[NSOperationQueue alloc] init];
        pathQueue.qualityOfService = NSQualityOfServiceBackground;
        pathQueue.maxConcurrentOperationCount = 1;
        pathQueue.name = @"PathFinding Queue";
    }
    
    // ------------ Connected component labelling -----------
    
    connectedComponentMap.resize(topoMap.width, topoMap.height);
    
    // Two-pass connected component algorithm.
    // Areas are considered "connected" if they are not separated by an impassible obstacle.
    
    struct point
    {
        int x,y;
        unsigned char label;
    };
    
    setNode*** disjointSet = new setNode**[connectedComponentMap.height];
    for(int i = 0; i < connectedComponentMap.height; i++)
    {
        disjointSet[i] = new setNode*[connectedComponentMap.width];
        for(int j = 0; j < connectedComponentMap.width; j++)
        {
            disjointSet[i][j] = nullptr;
        }
    }
    
    std::vector<setNode*> linked;  // Indexed by label, this should hold the root node of each linked set.
    linked.push_back(nullptr); // Because the first valid label is 1, we need to offset this a little.
    unsigned char nextLabel = 1;
    
    //Pass 1: Generate labels
    for(int y = 0; y < map.height; y++)
    {
        for(int x = 0; x < map.width; x++)
        {
//            NSLog(@"Labeling at: (%d, %d)\n", x, y);
            if (map.data[x][y] == 255)
                continue;

            //find neighbors that are not obstacles
            std::vector<point> neighbors;
            for(int dy=-1; dy <= 0; dy++)
            {
                for(int dx=-1; dx <=1; dx++)
                {
                    if(dy >= 0 && dx >= 0) continue; // only concern yourself with points that could have been previously labelled
                                                     // This looks NW, N, NE, W of the current point
                    
                    int px = x+dx;
                    int py = y+dy;
                    
                    if(px < 0 || px >= map.width || py < 0 || py >= map.height) continue;
                    
                    if(map.data[px][py] <= 254)
                    {
                        point p;
                        p.x = px;
                        p.y = py;
                        p.label = disjointSet[py][px]->label;
                        
                        neighbors.push_back(p);
                    }
                }
            }
            
            if(neighbors.size() == 0)
            {
                // If this point has no neighbors it's deserving of a new label.
                // This label might eventually be found to be equivalent to an older label, but we'll get to that.

                disjointSet[y][x] = new setNode;
                disjointSet[y][x]->label = nextLabel;
                disjointSet[y][x]->parent = disjointSet[y][x];
                
                linked.push_back(disjointSet[y][x]);
                nextLabel++;
            } else{
                // If there are a few neighbors, we should include them all in the smallest label's set.
                int smallestLabel = INT_MAX;
                for(int i = 0; i < neighbors.size(); i++)
                {
                    if(neighbors[i].label < smallestLabel)
                        smallestLabel = neighbors[i].label;
                }
                
//                    NSLog(@"\t Has %lu neighbors - smallest label: %d\n", neighbors.size(), smallestLabel);
                
                // Add the current point to the smallest label set.
                disjointSet[y][x] = linked[smallestLabel];
                
                for(int i=0; i < neighbors.size(); i++)
                {
                    linked[smallestLabel] = [self unionOf:linked[smallestLabel] andSet:disjointSet[neighbors[i].y][neighbors[i].x]];
                }
            }
        }
    }
    
    // Pass 2 - find and fix equivalent labels
    for(int y = 0; y < topoMap.height; y++)
    {
        for(int x = 0; x < topoMap.width; x++)
        {
            if(disjointSet[y][x] == nullptr)
                connectedComponentMap.data[x][y] = 0;
            else
                connectedComponentMap.data[x][y] = [self find:disjointSet[y][x]]->label;
        }
    }
    
    // Clean up
    for(int i = 0; i < connectedComponentMap.height; i++)
    {
        delete[] disjointSet[i];
    }
    delete[] disjointSet;
    
    return self;
}

- (BOOL) occupied:(GLKVector3)target {
    int posx, posy;
    [self worldCoordToPixCoordWithWx:target.x Wy:target.z Pxp:&posx Pyp:&posy];
    
    if( posx < 0 || posx >= map.width
        || posy < 0 || posy >= map.height )
    {
        // Outer world is always occupied.
         return YES;
    } else {
        return map.data[posx][posy] >= 254;
    }
}

- (PathFindingOperation*) findPath:(GLKVector3)from to:(GLKVector3)to completion:(void (^)(void))completionBlock {
    PathFindingOperation *op = [[PathFindingOperation alloc] initWithFrom:from to:to getClosest:NO daemon:self];
    op.completionBlock = completionBlock;
    [pathQueue addOperation:op];
    return op;
}

- (PathFindingOperation*) findNearestPath:(GLKVector3)from to:(GLKVector3)to completion:(void (^)(void))completionBlock {
    PathFindingOperation *op = [[PathFindingOperation alloc] initWithFrom:from to:to getClosest:YES daemon:self];
    op.completionBlock = completionBlock;
    [pathQueue addOperation:op];
    return op;
}

/**
 * Get the physical size of each occupied grid pixel.
 */
- (float) pixelSizeInMeters {
    return pixelSizeInMeters;
}

/**
 * Create a string value of the point in x,y grid space for logging purposes:
 * ex: (23, 34)
 */
- (NSString*) stringForPoint:(GLKVector3)pt {
    int px, py;
    [self worldCoordToPixCoordWithWx:pt.x Wy:pt.z Pxp:&px Pyp:&py];
    return [NSString stringWithFormat:@"(%d,%d)", px, py];
}


/**
 * Generate an array of occupied points in world coordinate.
 */
- (NSMutableArray<NSValue*> *) occupiedPoints {
    NSMutableArray<NSValue*> *points = [NSMutableArray arrayWithCapacity:1024];
   
    for(int y = 0; y < map.height; y++)
    {
        for(int x = 0; x < map.width; x++)
        {
            if( map.data[x][y] >= 254 ) {
                float wx, wy;
                [self pixCoordToWorldXYWithPx:x Py:y Wxp:&wx Wyp:&wy];
                GLKVector3 p = GLKVector3Make( wx, 0.f,  wy);
                [points addObject:[NSValue valueWithBytes:&p objCType:@encode(GLKVector3)]];
            }
        }
    }

    return points;
}

/**
 * Generate an array of connected component points.
 * @returns array of NSValue of GLKVector3
 *     Coordinates x&z in world coordinates, and y being the comonent value.
 */
- (NSMutableArray<NSValue*> *) connectedComponentPoints {
    NSMutableArray<NSValue*> *points = [NSMutableArray arrayWithCapacity:connectedComponentMap.width * connectedComponentMap.height];
   
    for(int y = 0; y < connectedComponentMap.height; y++)
    {
        for(int x = 0; x < connectedComponentMap.width; x++)
        {
            float componentValue = connectedComponentMap.data[x][y];
            
            if (componentValue == 0) {
                continue;
            }
            float wx, wy;
            [self pixCoordToWorldXYWithPx:x Py:y Wxp:&wx Wyp:&wy];
            GLKVector3 p = GLKVector3Make( wx, componentValue, wy);
            [points addObject:[NSValue valueWithBytes:&p objCType:@encode(GLKVector3)]];
        }
    }

    return points;
}

/**
 * Search through the connected components, finding the largest slab of it.
 * @return the component id.
 */
- (unsigned char) largestConnectedComponent {
    // Build histogram of component counts.
    int componentCounts[256];
    bzero(componentCounts, sizeof(componentCounts));
    for(int y = 0; y < connectedComponentMap.height; y++)
    {
        for(int x = 0; x < connectedComponentMap.width; x++)
        {
            unsigned char componentValue = connectedComponentMap.data[x][y];
            componentCounts[componentValue]++;
        }
    }

    // Find largest component in histogram. Ignoring component zero, unless there really are no components.
    int bestComponent = 0;
    int bestCount=0;
    for( int i=1; i<255; i++ ) {
        if( componentCounts[i] > bestCount ) {
            bestComponent = i;
            bestCount = componentCounts[i];
        }
    }

    return bestComponent;
}


/**
 * Searchs the connectedComponentMap for nearest reachable goal point in component.
 * @param goalPoint goal we're trying to get to
 * @param component that is being searched
 * @param result If successfull result is stored here
 * @return Success if a valid nearest point is found.
 */ 
- (BOOL) closestAccessiblePointTo:(GLKVector3)goalPoint inComponent:(unsigned char)targetComponent result:(GLKVector3*)result {
    int goalPointX, goalPointY;
    [self worldCoordToPixCoordWithWx:goalPoint.x Wy:goalPoint.z Pxp:&goalPointX Pyp:&goalPointY];
    
    float minDistSq = FLT_MAX;
    
    int bestPointX=0, bestPointY=0;
    for(int y = 0; y < map.height; y++)
    {
        for(int x = 0; x < map.width; x++)
        {
            unsigned char component = connectedComponentMap.data[x][y];
            if( component == targetComponent )
            {
                float distSq = (goalPointX - x)*(goalPointX - x) + (goalPointY - y)*(goalPointY - y);
                if(distSq < minDistSq)
                {
                    minDistSq = distSq;
                    bestPointX = x;
                    bestPointY = y;
                }
            }
        }
    }
    
    if( minDistSq == FLT_MAX ) {
        be_NSDbg(@"No option with component. id: %d", (int)targetComponent);
        return NO;
    }
    
    float bestWorldPointX, bestWorldPointY;
    
    [self pixCoordToWorldXYWithPx:bestPointX Py:bestPointY Wxp:&bestWorldPointX Wyp:&bestWorldPointY];
    *result = GLKVector3Make(bestWorldPointX, 0, bestWorldPointY);
    return YES;
}


/**
 * Searchs the connectedComponentMap for nearest reachable goal point to a source point.
 * @param goalPoint goal we're trying to get to
 * @param sourcePoint where we're starting from
 * @param result If successfull result is stored here
 * @return Success if a valid nearest point is found.
 */ 
- (BOOL) closestAccessiblePointTo:(GLKVector3)goalPoint fromPoint:(GLKVector3)sourcePoint result:(GLKVector3*)result
{
//     FIXME: Note this code should probably be completely refactored to use the above:
//    - (BOOL) closestAccessiblePointTo:(GLKVector3)goalPoint inComponent:(unsigned char)targetComponent result:(GLKVector3*)result
//    Just need to get the targetComponent from the sourcePoint.
    
    int goalPointX, goalPointY;
    [self worldCoordToPixCoordWithWx:goalPoint.x Wy:goalPoint.z Pxp:&goalPointX Pyp:&goalPointY];
    
    int sourcePointX, sourcePointY;
    [self worldCoordToPixCoordWithWx:sourcePoint.x Wy:sourcePoint.z Pxp:&sourcePointX Pyp:&sourcePointY];

    be_NSDbg( @"Getting closest point to map goal: (%d,%d)  from: (%d,%d)", goalPointX, goalPointY, sourcePointX, sourcePointY);
    if( connectedComponentMap.data[sourcePointX][sourcePointY] == 0 ) {
        NSLog(@"Bad Source Point?");
    }
    
    float minDistSq = FLT_MAX;
    
    int bestPointX=0, bestPointY=0;
    for(int y = 0; y < map.height; y++)
    {
        for(int x = 0; x < map.width; x++)
        {
            if([self canPathFromStartPointX:sourcePointX startPointY:sourcePointY goalPointX:x goalPointY:y])
            {
                float distSq = (goalPointX - x)*(goalPointX - x) + (goalPointY - y)*(goalPointY - y);
                if(distSq < minDistSq)
                {
                    minDistSq = distSq;
                    bestPointX = x;
                    bestPointY = y;
                }
            }
        }
    }
    
    if( minDistSq == FLT_MAX ) {
        be_NSDbg(@"No pathing option from sourcePoint. id: %d", (int)connectedComponentMap.data[sourcePointX][sourcePointY]);
        return NO;
    } else {
        be_NSDbg(@"best: (%d,%d)", bestPointX,bestPointY);
    }
    
    float bestWorldPointX, bestWorldPointY;
    [self pixCoordToWorldXYWithPx:bestPointX Py:bestPointY Wxp:&bestWorldPointX Wyp:&bestWorldPointY];
    
    // Double check:
    int checkX, checkY;
    [self worldCoordToPixCoordWithWx:bestWorldPointX Wy:bestWorldPointY Pxp:&checkX Pyp:&checkY];
    if( checkX != bestPointX || checkY != bestPointY ) {
        be_NSDbg(@"!!!! Remap point coordinate failure");
        be_NSDbg(@"goal world: (%f, %f)", goalPoint.x, goalPoint.z );
        be_NSDbg(@"best world: (%f, %f) pix:(%d,%d)",bestWorldPointX, bestWorldPointY, checkX, checkY );
    }
    *result = GLKVector3Make(bestWorldPointX, 0, bestWorldPointY);
    return YES;
}


- (NSMutableArray*) runPathPlanningWithOperation:(PathFindingOperation*)pathOp
{
    static uint32_t path_id = 0;
    int startPosX;
    int startPosY;
    int goalPosX;
    int goalPosY;
    
    [self worldCoordToPixCoordWithWx:pathOp.from.x Wy:pathOp.from.z Pxp:&startPosX Pyp:&startPosY];
    [self worldCoordToPixCoordWithWx:pathOp.to.x Wy:pathOp.to.z Pxp:&goalPosX Pyp:&goalPosY];

    be_NSDbg(@"Start of run path planning!");
    
    if(startPosX < 0 || startPosX >= topoMap.width ||
       startPosY < 0 || startPosY >= topoMap.height)
    {
        NSLog(@"Something strange happened to startPosX: %d or startPosY: %d\n",
              startPosX,
              startPosY);
        
        return nil;
    }
    
    be_NSDbg(@"Trying to path plan from (%d, %d) to (%d, %d)\n", startPosX, startPosY, goalPosX, goalPosY);
    
    // ------------ Djikstra search for path ------------
    // Algorithm should seek to minimize the sum of traversed values on the topoMap.
    // This will keep the robot away from edges, and will probably cause it to follow smooth paths.
    

    NSMutableArray *waypoints = [[NSMutableArray alloc] initWithCapacity:16];

    if(![self canPathFromStartPointX:startPosX startPointY:startPosY goalPointX:goalPosX goalPointY:goalPosY])
    {
        NSLog(@"Requested start and end points are not in the same connected component");

        if( pathOp.closest ) {
            GLKVector3 pt;
            
            if( [self closestAccessiblePointTo:pathOp.to fromPoint:pathOp.from result:&pt] ) {
                [self worldCoordToPixCoordWithWx:pt.x Wy:pt.z Pxp:&goalPosX Pyp:&goalPosY];
                NSLog(@"Pathing to (%d, %d) instead\n", goalPosX, goalPosY);
            } else {
                return waypoints;
            }
        } else {
            return waypoints;
        }
    }

    
#if defined(DEBUG)
    NSDate* startTime = [NSDate date];
#endif
    
    be_NSDbg(@"starting A*");

    using GraphLocation = std::pair<int16_t, int16_t>;
    const int w = topoMap.width;
    const int h = topoMap.height;

    // Normal, 2D -> linear array access
    auto hashFcn = [w](const GraphLocation& g) -> size_t
    {
        return g.second * w + g.first;
    };

    // Normal unordered maps, but they accept a special hashing function for std::pair
    // Holds "costs so far"
    std::unordered_map<GraphLocation, float, decltype(hashFcn)> costEstimates(w*h, hashFcn);
    // Holds parent node used to reach you. Used reconstruct the path
    std::unordered_map<GraphLocation, GraphLocation, decltype(hashFcn)> parents(w*h, hashFcn);
    // Key is cost estimate (cost so far + heursitic)
    std::multimap<float, GraphLocation> priorityQueue;

    const GraphLocation startLoc = std::make_pair(startPosX, startPosY);
    const GraphLocation goalLoc = std::make_pair(goalPosX, goalPosY);

    // Set up first node
    parents[startLoc] = startLoc; // unique invariant for starting node: you are your parent
    priorityQueue.insert(std::make_pair(0.f, startLoc));
    costEstimates[startLoc] = 0.f;

    // Returns true if a location is on the graph
    auto inRange = [w, h](const GraphLocation& loc) -> bool
    {
        return ((loc.first >= 0) &&
                (loc.second >= 0) &&
                (loc.first < w) &&
                (loc.second < h));
    };

    // Get all in-range, non-obstacle, neighbors from a location (excluding self)
    auto getNeighbors = [inRange, self](const GraphLocation& currentLocation) -> std::vector<GraphLocation>
    {
        std::vector<GraphLocation> neighborCandidates;
        neighborCandidates.resize(8);

        const std::initializer_list<GraphLocation> neighborIndices { {-1, -1}, {-1, 0}, {-1, 1},
                                                                     {0, -1} ,          {0, 1} ,
                                                                     {1, -1} , {1, 0} , {1, 1} };
        for (const auto& ni : neighborIndices)
        {
            int16_t x, y;
            std::tie(x, y) = ni;
            GraphLocation neighborCandidate(currentLocation.first + x, currentLocation.second + y);
            if (inRange(neighborCandidate)
                && (map.data[neighborCandidate.first][neighborCandidate.second] < 254))
                neighborCandidates.push_back(neighborCandidate);
        }
        return neighborCandidates;
    };

    // Cost to take one step on the graph
    auto stepCostFcn = [](const GraphLocation& current, const GraphLocation& next) -> float
    {
        if (current.first == next.first || current.second == next.second)
            // directly left, right, up, or down
            return 1.f;
        else
            // diagonal
            return 1.414213f;
    };

    auto diagonalDist = [](const GraphLocation& a, const GraphLocation& b) -> float
    {
        const int dx = abs(a.first - b.first);
        const int dy = abs(a.second - b.second);
        return (dx + dy) + (1.41412f - 2.f) * std::min(dx, dy);
    };

    bool solutionFound = false;
    while (!priorityQueue.empty())
    {
        // Get node on the frontier with lowest estimated cost
        const GraphLocation current = priorityQueue.begin()->second;
        priorityQueue.erase(priorityQueue.begin());

        // A* is "best-first" so if we get here we're done
        if (current == goalLoc)
        {
            solutionFound = true;
            break;
        }

        for (auto neighbor : getNeighbors(current))
        {
            const float neighborCost = costEstimates[current] + stepCostFcn(current, neighbor);
            const bool isNew = costEstimates.find(neighbor) == costEstimates.end();

            // if the neighbor is not yet visited or if we found a new, better way to get there
            if (isNew || neighborCost < costEstimates[neighbor])
            {
                costEstimates[neighbor] = neighborCost;
                const float heuristicCost = neighborCost + diagonalDist(goalLoc, neighbor);
                priorityQueue.insert(std::make_pair(heuristicCost, neighbor));
                parents[neighbor] = current;
            }
        }
    }

    std::stack<GraphLocation> simplifiedPath;
    
    be_NSDbg(@"Completed in %fs", [[NSDate date] timeIntervalSinceDate:startTime]);
    
    // ------------- Draw the path if it exists. -------------
    if (!solutionFound)
    {
        NSLog(@"Could not find a path!");
        
    } else{
        
        path_id++;
        NSLog(@"Found a path with score %f, and path_id: %u", costEstimates[goalLoc], path_id);

        float lastX = goalPosX;
        float lastY = goalPosY;
        
        float lastDx = NAN;
        float lastDy = NAN;
        
        float pointsSinceLastWp = 0;  //TODO float max
        
        simplifiedPath.push(goalLoc);
        GraphLocation currentLocation = goalLoc;

        while(parents[currentLocation] != currentLocation)
        {
            //                mapImage(cn->x, cn->y)[0] = 255;
            //                mapImage(cn->x, cn->y)[1] = 0;
            //                mapImage(cn->x, cn->y)[2] = 0;
            
            float dx = lastX - currentLocation.first;
            float dy = lastY - currentLocation.second;
            
            if(pointsSinceLastWp > robotRadiusInPixels/2 && (lastDx != dx || lastDy != dy))
            {
                pointsSinceLastWp = 0;
                lastDx = dx;
                lastDy = dy;
                simplifiedPath.push(currentLocation);
            }
            
            pointsSinceLastWp++;
            
            lastX = currentLocation.first;
            lastY = currentLocation.second;

            currentLocation = parents[currentLocation];
        }
        
        uint32_t sequence_number = 0;
        while(simplifiedPath.size() > 0)
        {
            GraphLocation node = simplifiedPath.top();
            simplifiedPath.pop();
            
            //                mapImage(cn->x, cn->y)[0] = 255;
            //                mapImage(cn->x, cn->y)[1] = 255;
            //                mapImage(cn->x, cn->y)[2] = 0;
            
            float wx, wy;
            [self pixCoordToWorldXYWithPx:node.first Py:node.second Wxp:&wx Wyp:&wy];

            
            be_NSDbg(@"Waypoint: %i, %i \t %f, %f", node.first, node.second, wx, wy);
            
            // if( cn->x != startPosX || cn->y != startPosY ) {
            GLKVector3 target = GLKVector3Make( wx, 0.f,  wy);
            [waypoints addObject:[NSValue valueWithBytes:&target objCType:@encode(GLKVector3)]];
            // }
            sequence_number++;
        }
    }
    
    return waypoints;
}

@end

@implementation PathFindingOperation

- (instancetype) initWithFrom:(GLKVector3)from to:(GLKVector3)to getClosest:(BOOL)closest daemon:(PathFinding*)daemon
{
    self = [super init];
    if (self) {
        self.from = from;
        self.to = to;
        self.closest = closest;
        self.pathDaemon = daemon;
        
    }
    return self;
}

- (void) main {
    if( self.cancelled ) {
        NSLog(@"PathFindingOperation was cancled");
        return;
    }
    
    be_NSDbg(@"PathFindingOperation started");
    self.waypoints = [_pathDaemon runPathPlanningWithOperation:self];
    be_NSDbg(@"PathFindingOperation finished with %lu waypoints", (unsigned long)[_waypoints count] );
}

// TODO: Handle cancelling an operation.

@end

