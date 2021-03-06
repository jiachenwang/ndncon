//
//  NCGlView.m
//  NdnCon
//
//  Created by Peter Gusev on 9/29/14.
//  Copyright 2013-2015 Regents of the University of California.
//

#import "NCGlView.h"
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>

#define GetError( )\
{\
for ( GLenum Error = glGetError( ); ( GL_NO_ERROR != Error ); Error = glGetError( ) )\
{\
switch ( Error )\
{\
case GL_INVALID_ENUM:      printf( "\n%s\n\n", "GL_INVALID_ENUM"      ); assert( 1 ); break;\
case GL_INVALID_VALUE:     printf( "\n%s\n\n", "GL_INVALID_VALUE"     ); assert( 1 ); break;\
case GL_INVALID_OPERATION: printf( "\n%s\n\n", "GL_INVALID_OPERATION" ); assert( 1 ); break;\
case GL_OUT_OF_MEMORY:     printf( "\n%s\n\n", "GL_OUT_OF_MEMORY"     ); assert( 1 ); break;\
default:                                                                              break;\
}\
}\
}

CGRect CGRectMakeRectFromRectWithRatio(CGRect rect, CGFloat w, CGFloat h)
{
    CGRect result = rect;
    
    if (CGRectGetWidth(rect)/CGRectGetHeight(rect) > w/h)
    { // squeeze horizontally
        CGFloat width = CGRectGetHeight(rect)*w/h;
        CGFloat x = CGRectGetMinX(rect) + (CGRectGetWidth(rect) - width)/2.;
        
        result = CGRectMake(x, CGRectGetMinY(rect), width, CGRectGetHeight(rect));
    }
    else
        if (CGRectGetWidth(rect)/CGRectGetHeight(rect) < w/h)
        { // squeeze vertically
            CGFloat height = CGRectGetWidth(rect)*h/w;
            CGFloat y = CGRectGetMinY(rect) + (CGRectGetHeight(rect) - height)/2.;
            
            result = CGRectMake(CGRectGetMinX(rect), y, CGRectGetWidth(rect), height);
        }
    
    result = CGRectMake(roundf(result.origin.x), roundf(result.origin.y), roundf(result.size.width), roundf(result.size.height));
    
    return result;
}

@interface NCGlView ()
{
    NSRect _renderingRect;
    NSLock *_renderingLock;
    BOOL _openGlReady;
}

@end

@implementation NCGlView

-(id)initWithFrame:(NSRect)frameRect pixelFormat:(NSOpenGLPixelFormat *)format
{
    self = [super initWithFrame:frameRect pixelFormat:format];
    
    if (self)
    {
        _openGlReady = NO;
        _renderingLock = [[NSLock alloc] init];
    }
    
    return self;
}

-(void)dealloc
{
    [_renderingLock lock];
    [self.openGLContext makeCurrentContext];
    
    if (glIsTexture(_texture))
        glDeleteTextures(1, (const GLuint*) &_texture);
    
    free(_renderingBuffer);
    [_renderingLock unlock];
}

-(uint8_t*)bufferForWidth:(int)width andHeight:(int)height
{
    if (!self.openGLContext || !_openGlReady)
        return NULL;
    
    BOOL sizeChanged = (width != _width) || (height != _height);
    
    _width = width;
    _height = height;
    
    int requiredSize = width*height*4;
    
    if (!_renderingBuffer || _bufferSize < requiredSize || sizeChanged)
    {
        _renderingBuffer = (uint8_t*)realloc((void*)_renderingBuffer, requiredSize);
        memset(_renderingBuffer, 0, requiredSize);
        _bufferSize = requiredSize;
        
        [self createTexture];
    }

    return _renderingBuffer;
}

-(void)updateBuffer
{
    if (!self.openGLContext || !_openGlReady)
        return;
    
    [_renderingLock lock];
    [self.openGLContext makeCurrentContext];
    
    glBindTexture(GL_TEXTURE_RECTANGLE_ARB, _texture);
    GetError();
    glTexSubImage2D(GL_TEXTURE_RECTANGLE_ARB,
                    0,
                    0, 0,
                    _width, _height,
                    GL_BGRA, GL_UNSIGNED_INT_8_8_8_8,
                    _renderingBuffer);
    GetError();
    
    self.bufferUpdated = YES;
    
    [_renderingLock unlock];
}

-(void)createTexture
{
    [_renderingLock lock];
    [self.openGLContext makeCurrentContext];
    
    if (glIsTexture(_texture))
    {
        glDeleteTextures(1, (const GLuint*) &_texture);
        GetError();
        _texture = 0;
    }
    
    glGenTextures(1, (GLuint*) &_texture);
    GetError();
    
    glBindTexture(GL_TEXTURE_RECTANGLE_ARB, _texture);
    GetError();
    
    glPixelStorei(GL_UNPACK_ROW_LENGTH, (GLint)_width);
    GetError();
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    GetError();
    glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    GetError();
    glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    GetError();
    glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    GetError();
    glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    GetError();
    
    glTexImage2D(GL_TEXTURE_RECTANGLE_ARB,
                 0,
                 GL_RGBA8,
                 _width,
                 _height,
                 0,
                 GL_BGRA,
                 GL_UNSIGNED_INT_8_8_8_8,
                 _renderingBuffer);
    GetError();
    
    _renderingRect = CGRectMakeRectFromRectWithRatio(self.bounds, _width, _height);
    
    [_renderingLock unlock];
}

-(void)prepareOpenGL
{
    BOOL locked = [_renderingLock tryLock];
    
    // Disable not needed functionality to increase performance
    glDisable(GL_DITHER);
    glDisable(GL_ALPHA_TEST);
    glDisable(GL_STENCIL_TEST);
    glDisable(GL_FOG);
    glDisable(GL_TEXTURE_2D);
    glPixelZoom(1.0, 1.0);
    glDisable(GL_BLEND);
    glDisable(GL_DEPTH_TEST);
    glDepthMask(GL_FALSE);
    glDisable(GL_CULL_FACE);
    
    // Set texture parameters
    glTexParameterf(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_PRIORITY, 1.0);
    glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_STORAGE_HINT_APPLE, GL_STORAGE_SHARED_APPLE);
    
    glEnable(GL_TEXTURE_RECTANGLE_ARB);
    glTexParameteri(GL_TEXTURE_RECTANGLE_ARB,
                    GL_TEXTURE_STORAGE_HINT_APPLE,
                    GL_STORAGE_CACHED_APPLE);
    glPixelStorei(GL_UNPACK_CLIENT_STORAGE_APPLE, GL_TRUE);
    
    glViewport(0, 0,
               CGRectGetWidth(self.bounds),
               CGRectGetHeight(self.bounds));
    
    // Synchronize buffer swaps with vertical refresh rate
    GLint swapInt = 1;
    [self.openGLContext setValues:&swapInt
                     forParameter:NSOpenGLCPSwapInterval];
    
    _openGlReady = YES;
    
    if (locked) [_renderingLock unlock];
}

-(void)drawRect:(NSRect)dirtyRect
{
    [_renderingLock lock];
    
    [self clearCanvas];
    
    if (_renderingBuffer)
    {
        self.bufferUpdated = NO;
        [self renderBuffer];
    }
    
    [_renderingLock unlock];
}

-(void)reshape
{
    [_renderingLock lock];
    
    [self.openGLContext makeCurrentContext];
    glViewport(0, 0,
               CGRectGetWidth(self.bounds),
               CGRectGetHeight(self.bounds));
    GetError();
    
    [self clearCanvas];
    _renderingRect = CGRectMakeRectFromRectWithRatio(self.bounds, _width, _height);
    
    [self update];
    
    [_renderingLock unlock];
}

-(void)clearCanvas
{
    glClearColor( 0.0, 0.0, 0.0, 1.0 );
    glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
}

-(void)renderBuffer
{
    GLfloat _startWidth = _renderingRect.origin.x/self.bounds.size.width,
    _startHeight = _renderingRect.origin.y/self.bounds.size.height,
    _stopWidth = CGRectGetMaxX(_renderingRect)/self.bounds.size.width,
    _stopHeight = CGRectGetMaxY(_renderingRect)/self.bounds.size.height;
    
    GLfloat xStart = (2.0f * _startWidth - 1.0f);
    GLfloat xStop = (2.0f * _stopWidth - 1.0f);
    GLfloat yStart = (1.0f - 2.0f * _stopHeight);
    GLfloat yStop = (1.0f - 2.0f * _startHeight);
    
    glBindTexture(GL_TEXTURE_RECTANGLE_ARB, _texture);
    glLoadIdentity();
    
    glBegin(GL_POLYGON);
    {
        glTexCoord2f(0.0, 0.0); glVertex2f(xStart, yStop);
        glTexCoord2f(_width, 0.0); glVertex2f(xStop, yStop);
        glTexCoord2f(_width, _height); glVertex2f(xStop, yStart);
        glTexCoord2f(0.0, _height); glVertex2f(xStart, yStart);
    }
    glEnd();
    glFinish();
    
    [self.openGLContext flushBuffer];
}

@end