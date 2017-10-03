/*
    This file is part of the Structure SDK.
    Copyright © 2016 Occipital, Inc. All rights reserved.
    http://structure.io
*/

#pragma once

#import <BridgeEngine/BridgeEngineAPI.h>
#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

BE_API
@interface BEMesh : NSObject

/** Create a copy of the current mesh.
 
 @param mesh The mesh from which to copy.
 */
- (instancetype)initWithMesh:(BEMesh *)mesh;

/// Number of partial meshes.
- (int)numberOfMeshes;

/** Number of faces of a given submesh.
 
 @param meshIndex Index to the partial mesh.
 */
- (int)numberOfMeshFaces:(int)meshIndex;

/** Number of vertices of a given submesh.
 
 @param meshIndex Index to the partial mesh.
 */
- (int)numberOfMeshVertices:(int)meshIndex;

/// Whether per-vertex normals are available.
- (BOOL)hasPerVertexNormals;

/// Whether per-vertex colors are available.
- (BOOL)hasPerVertexColors;

/// Whether per-vertex UV texture coordinates are available.
- (BOOL)hasPerVertexUVTextureCoords;

/** Pointer to a contiguous chunk of `numberOfMeshVertices:meshIndex` `GLKVector3` values representing (x, y, z) vertex coordinates.
 
 @param meshIndex Index to the partial mesh.
 */
- (GLKVector3 *)meshVertices:(int)meshIndex;

/** Pointer to a contiguous chunk of `numberOfMeshVertices:meshIndex` `GLKVector3` values representing (nx, ny, nz) per-vertex normals.
 
 @note Returns `NULL` is there are no per-vertex normals.
 
 @param meshIndex Index to the partial mesh.
 */
- (GLKVector3 *)meshPerVertexNormals:(int)meshIndex;

/** Pointer to a contiguous chunk of `numberOfMeshVertices:meshIndex` `GLKVector3` values representing (r, g, b) vertices colors.
 
 @note Returns `NULL` is there are no per-vertex colors.
 
 @param meshIndex Index to the partial mesh.
 */
- (GLKVector3 *)meshPerVertexColors:(int)meshIndex;

/** Pointer to a contiguous chunk of `numberOfMeshVertices:meshIndex` `GLKVector2` values representing normalized (u, v) texture coordinates.
 
 @note Returns `NULL` is there are no per-vertex texture coordinates.
 
 @param meshIndex Index to the partial mesh.
 */
- (GLKVector2 *)meshPerVertexUVTextureCoords:(int)meshIndex;

/** Pointer to a contiguous chunk of `(3 * numberOfMeshFaces:meshIndex)` 16 bits `unsigned short` values representing vertex indices. Each face is represented by three vertex indices.
 
 @param meshIndex Index to the partial mesh.
 */
- (unsigned short *)meshFaces:(int)meshIndex;

/** Optional texture associated with the mesh.
 
 The pixel buffer is encoded using `kCVPixelFormatType_420YpCbCr8BiPlanarFullRange`.
 */
- (CVPixelBufferRef)meshYCbCrTexture;

@end
