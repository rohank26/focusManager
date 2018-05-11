# Focus Manager for Framer.
[Read the full documentation here](https://medium.com/@rohan.k/prototyping-for-tv-screens-with-framer-a22f57c098a2)

## Including the module in your project
Copy the .coffee files in the `modules` folder of your framer project. Include the focusManager module in your framer project:
```
{focusManager} = require ‘focusManager’
```

## Initializing the focus manager
The focus manager maintains and tracks focus around the screen. The `focusmanager` object accepts certain properties. Read the  [full documentation](https://medium.com/@rohan.k/prototyping-for-tv-screens-with-framer-a22f57c098a2)to know more about each of these properties in detail.
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
A layer is required to be made selectable in order for it to accept focus.
```
selectableLayer.isSelectable = true
```

## Selecting a default layer
To specify the default focus layer or to manually focus a layer.
```
selectableLayer.selectedItem = selectableLayer
```

## Specifying layer targets
The module will automatically try and find the nearest layer to move the focus to whe na button is pressed. You can override this by specifying targets manually
```
selectableLayer.up = anotherLayer
selectableLayer.down = anotherLayer
selectableLayer.left = anotherLayer
selectableLayer.right = anotherLayer
```

## Overriding default options
You can override the properties of the focusManager object for individual selectable layers
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
An event is generated for the currently selected layer when a button is pressed. The event generated for each of the buttons shown in the event map below

 ![Event Map For buttons](https://cdn-images-1.medium.com/max/2000/1*kqzcdTw5ywNYhwqHitRCUA.png "Event Map For buttons")

### Event Types:

#### Simple Events
These events are generated on the layer everytime a button is pressed
```
selectableLayer.on "up", ->
     print "up button pressed"
selectableLayer.on "cross", ->
     print "cross button pressed"
``` 

#### ButtonPress Events
This is a common event generated on the selectable layer for all button presses. The button name is passed as an argument to the event handler
```
selectableLayer.on "buttonPress", (button) ->
     print button, " was pressed on ", this.name
```

#### Blur & Focus Events
Blur & focus events are generated on a layer wheneber the layer loses or gains focus
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
### Event Propagation
Every time an event is generated on a selectable layer,  it is also propagated to each of its parent layers. 
This continues all the way until the window.document level. The selected layer is passed as an argument to the event handler
```
flowComponent.on "circle", (selectedLayer) ->
     print "circle event generated on ", selectedLayer.name
``` 
