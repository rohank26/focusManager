# MODIFY THE LAYER CLASS #

#create a container array for all selectable objects 
allSelectables = []
defaultSelectionBorder = true
defaultSelectionBorderWidth = 5
defaultSelectionBorderColor = "#fff"
# function to add a border around the selected layer
addBorder = (layer) ->
	if (layer.childrenWithName("border").length is 0)

		border = new Layer
			name:"border"
			parent: layer
			size: layer
			borderRadius: layer.borderRadius
			backgroundColor: null
			opacity: 1

		if (layer.selectionBorderColor is undefined)
			border.borderColor = defaultSelectionBorderColor
		else
			border.borderColor = layer.selectionBorderColor

		if (layer.selectionBorderWidth is undefined)
			border.borderWidth = defaultSelectionBorderWidth
		else
			border.borderWidth = layer.selectionBorderWidth

		# border.animate
		# 		opacity: 1
		# 		borderWidth: layer.selectionBorderWidth
		# 		options:
		# 			time:0.15

# remove the border when a layer is deselected
removeBorder = (layer) ->
	allBorders = layer.childrenWithName("border")
	for border in allBorders
		# border.animate
		# 	opacity: 0
		# 	options:
		# 		time:0.15
		# border.on Events.AnimationEnd, ->
		# 	this.destroy()
		border.destroy()
	
#isSelectable: specifies whether a layer is focusable or not, if yes, adds it to the allSelectables[] array
try Layer.define "isSelectable",
	get: -> @_properties["isSelectable"]
	set: (value) ->
		@_properties["isSelectable"] = value
		if(value is true)
			allSelectables.push(@)
			@.states.defaultOnState = defaultOnState
			@.states.defaultOffState = defaultOffState
			@.stateSwitch("defaultOffState")
			
		if(value is false)
			delete @.states.defaultOnState
			delete @.states.defaultOffState
			#TODO: remove layer from all selectables

try Layer.define "selected",
	get: -> @_properties["selected"]
	set: (value) ->
		
		@_properties["selected"] = value
		
		if(value is true and @_properties["isSelectable"] is true)
			
			if((defaultSelectionBorder is true and @_properties["selectionBorder"] is undefined) or (@_properties["selectionBorder"] is true))
					if (@.childrenWithName("border").length is 0)
						addBorder(@)

			if(@.states.on is undefined)
				@.animate("defaultOnState")
			else
				@.animate("on")

		if(value is false and @_properties["isSelectable"] is true)
			if(@.childrenWithName("border").length)
				removeBorder(@)
			if(@.states.off is undefined)
				@.animate("defaultOffState")
			else
				@.animate("off")

#properties to manually define what is to the up, down, left and right of each selectable layer
try Layer.define "up",
	get: -> @_properties["up"]
	set: (value) ->
		@_properties["up"] = value

try Layer.define "down",
	get: -> @_properties["down"]
	set: (value) ->
		@_properties["down"] = value

try Layer.define "left",
	get: -> @_properties["left"]
	set: (value) ->
		@_properties["left"] = value

try Layer.define "right",
	get: -> @_properties["right"]
	set: (value) ->
		@_properties["right"] = value

#selectionBorder: specifies whether a selected layer should have a border around it
try Layer.define "selectionBorder",
	get: -> @_properties["selectionBorder"]
	set: (value) ->
		@_properties["selectionBorder"] = value

try Layer.define "selectionBorderWidth",
	get: -> @_properties["selectionBorderWidth"]
	set: (value) ->
		@_properties["selectionBorderWidth"] = value

try Layer.define "selectionBorderColor",
	get: -> @_properties["selectionBorderColor"]
	set: (value) ->
		@_properties["selectionBorderColor"] = value

#propagateEvents: specifies whether th events emitted by a selectable layer are propagated
try Layer.define "propagateEvents",
	get: -> @_properties["propagateEvents"]
	set: (value) ->
		@_properties["propagateEvents"] = value


layers = Framer.CurrentContext._layers 

for existingLayer in layers
	existingLayer.up = undefined
	existingLayer.down = undefined
	existingLayer.left = undefined
	existingLayer.right = undefined
	existingLayer.selectionBorder = undefined
	existingLayer.selectionBorderWidth = undefined
	existingLayer.selectionBorderColor = undefined
	existingLayer.propagateEvents = true
	existingLayer.isSelectable = false
	existingLayer.selected = false



#assign the defaults to all properties when a layer is created
Framer.CurrentContext.on "layer:create", (newLayer) ->
	newLayer.up = undefined
	newLayer.down = undefined
	newLayer.left = undefined
	newLayer.right = undefined
	newLayer.selectionBorder = undefined
	newLayer.selectionBorderWidth = undefined
	newLayer.selectionBorderColor = undefined
	newLayer.propagateEvents = true
	newLayer.isSelectable = false
	newLayer.selected = false


### FOCUS MANAGER CLASS ###
{Gamepad} = require 'Gamepad'

#define the default appearance of selected items
defaultOnState = {
}
	
#define the default appearance of the deselected items
defaultOffState = {
}

#default options for the selectionController
selectionControllerDefaultOptions =
	leftStickDpad: false
	selectedItem : null
	controller: "PS4"
	lastSelectedItem: null
	width:0
	height:0
	defaultOnState: defaultOnState
	defaultOffState: defaultOffState
	defaultSelectionBorder: true
	defaultSelectionBorderWidth: 5
	defaultSelectionBorderColor: "fff"
	

#get a layer's absolute coordinates on the screen
getCoords = (currentSelection, param) ->
	switch (param)
		when "x"
			return currentSelection.screenFrame.x
			
		when "y"
			return currentSelection.screenFrame.y
			
		when "midX"
			return currentSelection.screenFrame.x + currentSelection.screenFrame.width / 2
			
		when "minX"
			return currentSelection.screenFrame.x
			
		when "maxX"
			return currentSelection.screenFrame.x + currentSelection.screenFrame.width
			
		when "midY"
			return currentSelection.screenFrame.y + currentSelection.screenFrame.height / 2
			
		when "minY"
			return currentSelection.screenFrame.y
			
		when "maxY"
			return currentSelection.screenFrame.y + currentSelection.screenFrame.height

# this is used to check if the current and target layers are infact on the same page 
# when using the nearest neighbor fn. with a flow component
# input arrays are a list of all parent layers of the current and target layer
# return true if current and target layers have a common parent other than a flow component
hasCommonAncestor = (element1,element2) ->
	arr1 = element1.ancestors()
	arr2 = element2.ancestors()
	for i in [0..arr1.length-1]
		for j in [0..arr2.length-1]
			if(arr1[i] is arr2[j] and arr1[i].constructor.name isnt "FlowComponent")
				return true
	return false		

# this is used to make sure that the target layer returned by the nearest neighbor fn. is infact visible
# so that we do not move the selection to an invisible layer
# return true if any ancestor of the input layer is not visible
isVisible = (layer) ->
	if(layer.opacity is 0 or layer.visible is false)
		return false
		
	parentLayers = layer.ancestors()
	for i in [0..parentLayers.length-1]
		if(parentLayers[i].visible is false or parentLayers[i].opacity is 0 )
				return false
	return true		

# return all layer that are on top, bottom, right or left of the current layer to calculate the nearest neighbor
filterSelectablesByDirection = (currentSelection, direction) ->
	filteredArray = []
	for selectable in allSelectables
		if(hasCommonAncestor(selectable, currentSelection) and isVisible(selectable))
			switch(direction)
				when "up"
					if(getCoords(selectable,"maxY")-5 < getCoords(currentSelection,"minY")+5)
						filteredArray.push(selectable)
						
				when "down"
					if(getCoords(selectable,"minY")+5 > getCoords(currentSelection,"maxY")-5)
						filteredArray.push(selectable)
						
				when "left"
					if(getCoords(selectable,"maxX")-5 < getCoords(currentSelection,"minX")+5)
						filteredArray.push(selectable)
						
				when "right"
					if(getCoords(selectable,"minX")+5 > getCoords(currentSelection,"maxX")-5)
						filteredArray.push(selectable)
						
	return filteredArray


# return the layer nearest to the current layer in a specified direction
findNearest = (currentSelection, direction) ->

	switch(direction)
	#get the x,y coordinates of the current selection to calculate distance
		when "up"
			x2 = getCoords(currentSelection,"midX")
			y2 = getCoords(currentSelection,"minY")+5
			
		when "down"
			x2 = getCoords(currentSelection,"midX")
			y2 = getCoords(currentSelection,"maxY")-5
			
		when "left"
			x2 = getCoords(currentSelection,"minX")+5
			y2 = getCoords(currentSelection,"midY")
			
		when "right"
			x2 = getCoords(currentSelection,"maxX")-5
			y2 = getCoords(currentSelection,"midY")
			
	nearestSelectable  = null
	
	filteredSelectables = filterSelectablesByDirection(currentSelection, direction)
	
	#Start with a arbitary large number to compare all other distances to
	distanceToNearest = 5000

	for selectable in filteredSelectables
	
		switch(direction)
		#get the x,y coordinates of the target selection to calculate distance
			when "up"
				x1 = getCoords(selectable,"midX")
				y1 = getCoords(selectable,"maxY")-5
				
			when "down"
				x1 = getCoords(selectable,"midX")
				y1 = getCoords(selectable,"minY")+5
				
			when "left"
				x1 = getCoords(selectable,"maxX")-5
				y1 = getCoords(selectable,"midY")
				
			when "right"
				x1 = getCoords(selectable,"minX")+5
				y1 = getCoords(selectable,"midY")
		

		#calculate distance
		dx = x1 - x2
		dy = y1 - y2
		selectableDistance = Math.sqrt (dx*dx + dy*dy)
		
		if (selectableDistance < distanceToNearest)
			distanceToNearest = selectableDistance
			nearestSelectable = selectable
			
	return nearestSelectable 

# TODO: MOAR EVENTS!!!
# Gamepad.on 'gamepadkeyup', (event) ->
# 	print "key up",event
# 	
# Gamepad.on 'gamepadkeydown', (event) ->
# 	print "key down",event
# 
# Gamepad.on 'gamepadkeyheld', (event) ->
# 	print "key held",event


# move the selection to the nearest neighbor in a specified direction
moveSelection = (direction, that) =>
	switch(direction)
		when "up"
			target = that.currentSelection.up
		when "down"
			target = that.currentSelection.down
		when "left"
			target = that.currentSelection.left
		when "right"
			target = that.currentSelection.right

	if(target is undefined)
		target = findNearest(that.currentSelection, direction)
		
	if(target is null)
		return

	
	that.lastSelection = that.currentSelection
	that.currentSelection.selected = false
	
	that.currentSelection = target
	that.currentSelection.selected = true	

	bubbleBlurEvent(that.currentSelection, that.lastSelection) 	
	that.lastSelection.emit "blur"

	bubbleFocusEvent(that.currentSelection, that.lastSelection) 	
	that.currentSelection.emit "focus"

	that.emit "change:selection"


# bubbles the focus events from current layer all the way to the top
# note: make sure that current selection and last selection are updated BEFORE this function is called!!!
bubbleFocusEvent = (currentSelection, lastSelection) =>
	
	if(currentSelection is null)
		return

	if(currentSelection.propagateEvents is false)
		return
	
	
	# focus event is always called  from the current selection
	parentElements = currentSelection.ancestors()
	originatingLayer = currentSelection
	
	for element in parentElements
		#emit the event normally if the parent element is NOT a flow component:
		if(element.constructor.name isnt "FlowComponent")
			element.emit "focus", originatingLayer
		else
		#if it IS a flow component:
			# The user intent behind listening to the blur / focus events on a flow component is to see if the selection has moved in / out of the flow component
			# therefore, the blur / focus events are supressed for a flow component if both the current and last selection are inside the same flow component
			
			#step 1: get the current element's descendants
			children = element.descendants
			
			#step 2: search for the current and last selection in the descendant tree
			currentSelectionIsChild = false
			lastSelectionIsChild = false
			for i in [0..children.length-1]
				if(children[i] is currentSelection)
					currentSelectionIsChild = true

				if(children[i] is lastSelection)
					lastSelectionIsChild = true
			
			#step 3: emit focus event only if the selection has moved in to the flow component
			if(lastSelectionIsChild is false and currentSelectionIsChild is true) 	
					element.emit "focus", originatingLayer
					
	#emit events on window.document
	event = new CustomEvent("focus", {detail: originatingLayer })	
	window.document.dispatchEvent(event)



# bubbles the blur events from current layer all the way to the top
# note: make sure that current selection and last selection are updated BEFORE this function is called!!!
bubbleBlurEvent = (currentSelection, lastSelection) =>

	if(lastSelection is null)
		return

	if(lastSelection.propagateEvents is false)
		return

	#emit events on parent layers
	
	# blur event is always called on the last selection
	parentElements = lastSelection.ancestors()
	originatingLayer = lastSelection

	for element in parentElements
		#emit the event normally if the parent element is NOT a flow component:
		if(element.constructor.name isnt "FlowComponent")
			element.emit "blur", originatingLayer
		else
		#if it IS a flow component:

			# The user intent behind listening to the blur / focus events on a flow component is to see if the selection has moved in / out of the flow component
			# therefore, the blur / focus events are supressed for a flow component if both the current and last selection are inside the same flow component
			
			#step 1: get the current element's descendants
			children = element.descendants
			
			#step 2: search for the current and last selection in the flow component's descendants
			currentSelectionIsAChild = false
			lastSelectionIsAChild = false
			for i in [0..children.length-1]
				if(children[i] is currentSelection)
					currentSelectionIsAChild = true

				if(children[i] is lastSelection)
					lastSelectionIsAChild = true

			#step 3: emit blur event only if the selection has moved out of the flow component, i.e. last selection is a child and the current selection isnt
			if(lastSelectionIsAChild is true and currentSelectionIsAChild is false) 	
					element.emit "blur", originatingLayer

	#emit events on window.document
	event = new CustomEvent("blur", {detail: originatingLayer })	
	window.document.dispatchEvent(event)
		

# bubbles all other events from current layer all the way to the top
bubbleEvent = (bubbledEvent, originatingLayer) =>
	
	if(originatingLayer.propagateEvents is false)
		return

	#emit button press event on current layer
	originatingLayer.emit "buttonPress", bubbledEvent

	#emit event on parent layers
	parentElements = originatingLayer.ancestors()
	for element in parentElements
		element.emit bubbledEvent, originatingLayer
		element.emit "buttonPress", bubbledEvent, originatingLayer
			
	#emit events on window.document
	event1 = new CustomEvent(bubbledEvent, {detail: originatingLayer })	
	window.document.dispatchEvent(event1)
	
	event2 = new CustomEvent("buttonPress", {
		detail: {
			key: bubbledEvent
			layer: originatingLayer
			}
		});
	window.document.dispatchEvent(event2)
	

	
#focus manager class to track the selection around the screen
class focusManager extends Layer
	@.currentSelection = null
	@.lastSelection = null
	@.keycodes = {}
	constructor: ( options={} ) ->
		@.options = _.defaults options, selectionControllerDefaultOptions
		@.currentSelection = @.options.selectedItem
		super @options

		if(@.options.controller is "PS4")
			keycodes={

				square 		:		0
				cross		:		1
				circle 		:		2
				triangle 	:		3
				
				l1 			:		4
				r1 			:		5

				r2 			:		6
				l2 			:		7				
				
				l3press 	:		10
				r3press 	:		11

				home 		:		12
				touchpad 	:		13

				up 			:		14
				down 		:		15
				left 		:		16
				right 		:		17


				l3Left 		:		37
				l3Up 		:		38
				l3Right 	:		39
				l3Down 		:		40
				
				r3Up 		:		41
				r3Left 		:		42				
				r3Down 		:		43
				r3Right 	:		44

			}


		if(@.options.controller is "XB1")
			keycodes={

				a			:		0
				b 			:		1
				x 			:		2
				y 			:		3
				
				lb			:		4	
				rb			:		5	
				
				ljPress 	:		6
				rjPress 	:		7

				start 		:		8
				select 		:		9
				home 		:		10


				rt			:		15	# unconfirmed
				lt 			:		16	# unconfirmed		

				up 			:		11
				down 		:		12
				left 		:		13
				right 		:		14

				ljLeft 		:		37
				ljUp 		:		38
				ljRight 	:		39
				ljDown 		:		40
				
				rjUp 		:		41
				rjLeft 		:		42				
				rjDown 		:		43
				rjRight 	:		44


			}

		#create event listener for gamepad key presses and emit corresponding events
		Gamepad.on 'gamepadevent', Utils.throttle 0.25, (event) =>

			if(@.currentSelection is null)
				return

			keycode = event.keyCode
			
			#save current selection to a temp variable as it might change while the events are still being emitted
			a = @.currentSelection

			if(keycode is keycodes.up)
				bubbleEvent("up", a)				
				a.emit "up"
				moveSelection("up", @)
						
			if(keycode is keycodes.down)
				bubbleEvent("down", a)								
				a.emit "down"
				moveSelection("down", @)
														
			#left arrow
			if(keycode is keycodes.left)
				bubbleEvent("left", a)				
				a.emit "left"
				moveSelection("left", @)
							
			#right arrow
			if(keycode is keycodes.right)
				bubbleEvent("right", a)
				a.emit "right"
				moveSelection("right", @)

			#cross / A button
			if(keycode is keycodes.cross or keycode is keycodes.a)
				bubbleEvent("a", a)					
				bubbleEvent("cross", a)

				a.emit "a"
				a.emit "cross"
				
			#circle / B button
			if(keycode is keycodes.circle or keycode is keycodes.b)
				bubbleEvent("b", a)
				bubbleEvent("circle", a)
				
				a.emit "b"
				a.emit "circle"
				
			#square / X button
			if(keycode is keycodes.square or keycode is keycodes.x)
				bubbleEvent("x", a)
				bubbleEvent("square", a)
				
				a.emit "x"
				a.emit "square"

			#triangle / Y button
			if(keycode is keycodes.triangle or keycode is keycodes.y)
				bubbleEvent("y", a)
				bubbleEvent("triangle", a)
				
				a.emit "y"
				a.emit "triangle"
				
			#L1 / left bumper button
			if(keycode is keycodes.l1 or keycode is keycodes.lb)
				bubbleEvent("lb", a)
				bubbleEvent("l1", a)

				a.emit "lb"
				a.emit "l1"

			#R1 / right bumper button
			if(keycode is keycodes.r1 or keycode is keycodes.rb)
				bubbleEvent("rb", a)
				bubbleEvent("r1", a)

				a.emit "rb"
				a.emit "r1"

			#R2 / right trigger button
			if(keycode is keycodes.r2 or keycode is keycodes.rt)
				bubbleEvent("rt", a)
				bubbleEvent("r2", a)

				a.emit "rt"
				a.emit "r2"

				
			#L2 / left trigger button
			if(keycode is keycodes.l2 or keycode is keycodes.lt)
				bubbleEvent("lt", a)
				bubbleEvent("l2", a)
				
				a.emit "lt"
				a.emit "l2"
				


			#left joystick direction
			if(keycode is keycodes.l3Left or keycode is keycodes.ljLeft)
				if(@.options.leftStickDpad) 
					bubbleEvent("left", a)
					a.emit "left"
					moveSelection("left", @)
				
				bubbleEvent("ljLeft", a)
				bubbleEvent("l3Left", a)

				a.emit "ljLeft"
				a.emit "l3Left"
				
				

			if(keycode is keycodes.l3Up or keycode is keycodes.ljUp)
				if(@.options.leftStickDpad) 
					bubbleEvent("up", a)
					a.emit "up"
					moveSelection("up", @)

				bubbleEvent("l3Up", a)
				bubbleEvent("ljUp", a)

				a.emit "ljUp"
				a.emit "l3Up"


			if(keycode is keycodes.l3Right or keycode is keycodes.ljRight)
				if(@.options.leftStickDpad) 
					bubbleEvent("right", a)
					a.emit "right"
					moveSelection("right", @)			

				bubbleEvent("ljRight", a)
				bubbleEvent("l3Right", a)

				a.emit "ljRight"
				a.emit "l3Right"

			if(keycode is keycodes.l3Down or keycode is keycodes.ljDown)
				if(@.options.leftStickDpad) 
					bubbleEvent("down", a)
					a.emit "down"							
					moveSelection("down", @)

				a.emit "ljDown"					
				a.emit "l3Down"

				bubbleEvent("ljDown", a)
				bubbleEvent("l3Down", a)

			#L3 / left joystick button
			if(keycode is keycodes.l3Press or keycode is keycodes.ljPress)
				bubbleEvent("ljPress", a)
				bubbleEvent("l3Press", a)
				
				a.emit "ljPress"						
				a.emit "l3Press"

			#right joystick
			if(keycode is keycodes.r3Left or keycode is keycodes.rjLeft)
				bubbleEvent("r3Left", a)
				bubbleEvent("rjLeft", a)

				a.emit "rjLeft"
				a.emit "r3Left"
			
				

			if(keycode is keycodes.r3Up or keycode is keycodes.rjUp)
				bubbleEvent("rjUp", a)
				bubbleEvent("r3Up", a)

				a.emit "rjUp"
				a.emit "r3Up"

			if(keycode is keycodes.r3Right or keycode is keycodes.rjRight)
				bubbleEvent("rjRight", a)
				bubbleEvent("r3Right", a)

				a.emit "rjRight"
				a.emit "r3Right"

			if(keycode is keycodes.r3Down or keycode is keycodes.rjDown)
				bubbleEvent("rjDown", a)
				bubbleEvent("r3Down", a)
				
				a.emit "rjDown"
				a.emit "r3Down"
			
			#R3 / right joystick button
			if(keycode is keycodes.r3Press or keycode is keycodes.rjPress)
				bubbleEvent("rjPress", a)
				bubbleEvent("r3Press", a)

				a.emit "rjPress"
				a.emit "r3Press"

			#home button
			if(keycode is keycodes.home)
				bubbleEvent("home", a)
				a.emit "home"

			#touchpad button (PS only)
			if(keycode is keycodes.touchpad)
				bubbleEvent("touchpad", a)
				a.emit "touchpad"
				

			#select button (XB1 only)
			if(keycode is keycodes.select)
				bubbleEvent("select", a)
				a.emit "select"
				

			#start button (XB1 only)
			if(keycode is keycodes.start)
				bubbleEvent("start", a)
				a.emit "start"
				

		#create event listener for keyboard key presses
		document.addEventListener 'keydown', Utils.throttle 0.2, (event) =>
			
			if(@.currentSelection is null)
				return

			keycode = event.which

			a = @.currentSelection

			
			if(keycode is 38)
				bubbleEvent("up", a)
				a.emit "up"				
				moveSelection("up", @)
						
			if(keycode is 40)
				bubbleEvent("down", a)
				a.emit "down"				
				moveSelection("down", @)

			#left arrow
			if(keycode is 37)
				bubbleEvent("left", a)
				a.emit "left"
				moveSelection("left", @)
							
			#right arrow
			if(keycode is 39)
				bubbleEvent("right", a)
				a.emit "right"
				moveSelection("right", @)


			if(keycode is 13)
				#save current selection to a temp variable as it might change while the events are being emitted
				a = a

				bubbleEvent("cross", a)
				bubbleEvent("a", a)
				bubbleEvent("enter", a)

				a.emit "cross"
				a.emit "a"
				a.emit "enter"



			if(keycode is 8)
				bubbleEvent("circle", a)
				bubbleEvent("b", a)
				bubbleEvent("back", a)

				a.emit "circle"
				a.emit "b"
				a.emit "back"


			if(keycode is 27 or keycode is 80)
				bubbleEvent("home", a)
				a.emit "home"
							
	@define 'selectedItem',
		get: ->
			return @.currentSelection

		set: (value)->

			@.lastSelection = @.currentSelection

			if(@.currentSelection isnt null and @.currentSelection isnt undefined)
				@.currentSelection.selected = false
			
			@.currentSelection = value

			if(@.currentSelection isnt null and @.currentSelection isnt undefined)
				@.currentSelection.selected = true

				bubbleBlurEvent(@.currentSelection, @.lastSelection)
				if(@.lastSelection isnt null)
					@.lastSelection.emit "blur"

				bubbleFocusEvent(@.currentSelection, @.lastSelection) 
				if(@.currentSelection isnt null)
					@.currentSelection.emit "focus"
			
			@.emit "change:selection", @.currentSelection


	@define 'lastSelectedItem',
		get: ->
			return @.lastSelection

	@define 'controller',
		get: ->
			return @.options.controller
		set: (value)->
			@.options.controller = value

	@define 'leftStickDpad',
		get: ->
			return @.options.leftStickDpad
		set: (value)->
			@.options.leftStickDpad = value

	@define 'defaultOnState',
		get: ->
			return @.options.defaultOnState
		set: (value)->
			defaultOnState = @.options.defaultOnState = value
			for selectable in allSelectables
				selectable.states.defaultOnState = defaultOnState

	@define 'defaultOffState',
		get: ->
			return @.options.defaultOffState
		set: (value)->
			defaultOffState = @.options.defaultOffState = value
			for selectable in allSelectables
				selectable.states.defaultOffState = defaultOffState


	@define 'defaultSelectionBorder',
		get: ->
			return @.options.defaultSelectionBorder
		set: (value)->
			defaultSelectionBorder = @.options.defaultSelectionBorder = value

	@define 'defaultSelectionBorderWidth',
		get: ->
			return @.options.defaultSelectionBorderWidth
		set: (value)->
			defaultSelectionBorderWidth = @.options.defaultSelectionBorderWidth = value

	@define 'defaultSelectionBorderColor',
		get: ->
			return @.options.defaultSelectionBorderColor
		set: (value)->
			defaultSelectionBorderColor = @.options.defaultSelectionBorderColor = value

exports.focusManager = focusManager
