// get the active document
var doc = app.activeDocument;

// get reference to layer 1
var layer = doc.layers[0];

// create new text frame and add it to the layer
var text = layer.textFrames.add();

// set position and contents of text frame
text.position = [0,0];
text.contents = "Hello World";  
