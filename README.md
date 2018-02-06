# Focus Manager for Framer.
[Read the full documentation here](https://medium.com/@rohan.k/prototyping-for-tv-screens-with-framer-a22f57c098a2 "Google's Homepage")

## Including the module in your project
```
{focusManager} = require ‘focusManager’
```

## Initializing the focus manager
```
focusManager = new focusManager
     leftStickDpad: boolean
     controller: "PS4" / "XB1"
     defaultOnState: object
     defaultOffstate: object
     defaultSelectionBorder: boolean
     defaultSelectionBorderWidth: integer
     defaultSelectionBorderColor: color
```
## Making a layer selectable
`selectableLayer.isSelectable = true`

## Specifying layer targets
The module will automatically try and find the nearest layer to move the selection to. If it doesn't work, you can override it by specifying targets manually
```
selectableLayer.up = anotherLayer
selectableLayer.down = anotherLayer
selectableLayer.left = anotherLayer
selectableLayer.right = anotherLayer
```

## Overriding default options
You can override the properties of the focusManager object for individual layers
```
selectableLayer.selectionBorder = false
selectableLayer.selectionBorderWidth = 5
selectableLayer.selectionBorderColor = "rgba(255,255,255,0.5)"
selectableLayer.states.on =
     scale: 1.1
 selectableLayer.states.off =
     scale: 1
 ```
 
## Events
### Event Map for PS4 and Xbox One controllers
 ![Event Map For buttons](https://cdn-images-1.medium.com/max/2000/1*kqzcdTw5ywNYhwqHitRCUA.png "Event Map For buttons")

### Examples:

#### Simple Events
An event is generated on a layer for each of the buttons shown in the event map
```
selectableLayer.on "up", ->
     print "up button pressed"
selectableLayer.on "cross", ->
     print "cross button pressed"
``` 

#### ButtonPress Events
This event is generated on the a layer everytime any button is pressed. The button's event name is passed as an argument to the event handler
```
selectableLayer.on "buttonPress", (button) ->
     print button, " was pressed on ", this.name
```

#### Blur & Focus Events
A blur event is generated on a layer anytime the layer is deselected, and a focus event is generated anytime the layer is selected
```
selectableLayer.on "focus", ->
     print this.name," is selected"
     
selectableLayer.on "blur", ->
     print this.name," is deselected"
```

#### Selection Change Event
This event is generated on the focusManager object everytime the selection changes, the layer name is passed as an argument to the event handler
```
focusManager.on "change:selection", (layer) ->
     print "selection changed to ", layer.name
```
#### Event Propagation
Every time an event is generated on a selectable layer,  it is also propagated to each of its parent layers. 
This continues all the way until the window.document level. The selected layer is passed as an argument to the event handler
```
flowComponent.on "circle", (selectedLayer) ->
     print "circle event generated on ", selectedLayer.name
```
