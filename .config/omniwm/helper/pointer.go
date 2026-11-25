package main

/*
#include <dlfcn.h>
#include <stdbool.h>
#include <CoreGraphics/CoreGraphics.h>

// CoreGraphics is opened only when an action needs the pointer: linking it would load it at
// every start and slow down every action by several milliseconds.
static void *coreGraphics(void) {
	static void *handle;
	if (!handle) handle = dlopen("/System/Library/Frameworks/CoreGraphics.framework/CoreGraphics", RTLD_LAZY);
	return handle;
}

static bool pointerLocation(double *x, double *y) {
	void *cg = coreGraphics();
	if (!cg) return false;
	CGEventRef (*create)(CGEventSourceRef) = dlsym(cg, "CGEventCreate");
	CGPoint (*location)(CGEventRef) = dlsym(cg, "CGEventGetLocation");
	void (*release)(CFTypeRef) = dlsym(cg, "CFRelease");
	if (!create || !location || !release) return false;
	CGEventRef event = create(NULL);
	if (!event) return false;
	CGPoint point = location(event);
	release(event);
	*x = point.x;
	*y = point.y;
	return true;
}

// Returns a CGError, or -1 when CoreGraphics can't be loaded.
static int warpPointer(double x, double y) {
	void *cg = coreGraphics();
	if (!cg) return -1;
	CGError (*warp)(CGPoint) = dlsym(cg, "CGWarpMouseCursorPosition");
	CGError (*associate)(boolean_t) = dlsym(cg, "CGAssociateMouseAndMouseCursorPosition");
	if (!warp || !associate) return -1;
	CGError error = warp(CGPointMake(x, y));
	// Without re-associating the mouse, macOS ignores pointer movement for a moment after the warp.
	associate(true);
	return error;
}
*/
import "C"

import (
	"errors"
	"fmt"
)

// CoreGraphics counts y downwards from the top of the main display; AppKit, like OmniWM's
// frames, upwards from its bottom.

// pointerLocation returns the pointer position in AppKit coordinates.
func pointerLocation(displays []display) (x, y float64, err error) {
	main, err := mainDisplay(displays)
	if err != nil {
		return 0, 0, err
	}
	var cx, cy C.double
	if !C.pointerLocation(&cx, &cy) {
		return 0, 0, errors.New("cannot read the pointer position from CoreGraphics")
	}
	return float64(cx), main.Frame.Height - float64(cy), nil
}

// warpPointer moves the pointer to the center of target.
func warpPointer(target display, displays []display) error {
	main, err := mainDisplay(displays)
	if err != nil {
		return err
	}
	x, y := target.Frame.center()
	if code := C.warpPointer(C.double(x), C.double(main.Frame.Height-y)); code != 0 {
		return fmt.Errorf("cannot move the pointer to %s (CGError %d)", target.Name, code)
	}
	return nil
}
