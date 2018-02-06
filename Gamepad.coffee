_ = Framer._

Function::define = (prop, desc) ->
	Object.defineProperty this.prototype, prop, desc

class GamepadSystem extends Framer.EventEmitter
	constructor: ->
		@connectedGamepad = undefined
		@loopRequest = undefined
		@pollingGP = undefined
		@buttonsPressed = []
		@buttonsPressedPrev = []
		# Poll loop X times a second for new states
		@loopInterval = 500

		# Threshold for approved axis values - Values above X will be registered as an input
		@axisSensitivity = .2

		# Amount of button events occuring in a sequence
		@eventsInSequence = 0

		# Should events be throttled?
		@throttled = true
		
		if navigator.getGamepads()[0]
			@connectedGamepad = navigator.getGamepads()[0]
			@loopRequest = window.requestAnimationFrame @eventLoop.bind(@)
		
		window.addEventListener 'gamepadconnected', (e) =>
			@connectedGamepad = navigator.getGamepads()[0]
			@loopRequest = window.requestAnimationFrame @eventLoop.bind(@)
		
		window.addEventListener 'gamepaddisconnected', (e) =>
			@connectedGamepad = null
			window.cancelAnimationFrame @loopRequest

	@define 'throttle',
		set: (bool) ->
			@throttled = bool

			if bool == true
				@axisSensitivity = .2
			else
				@axisSensitivity = .2
	
	eventLoop: () =>

		setTimeout () =>
			
			@pollingGP = navigator.getGamepads()[0]
			for button, index in @pollingGP.buttons
				button.type = 'button'
				button.keyCode = index

			#save the button press(es) in the last eventloop
			@buttonsPressedPrev = @buttonsPressed

			@buttonsPressed = _.filter @pollingGP.buttons, {pressed: true}
			for axis, index in @pollingGP.axes
				if (index <= 3)
					activeAxis = {}

					if axis > @axisSensitivity || axis < -@axisSensitivity
						activeAxis.type = 'axis'
						activeAxis.value = axis
					
						switch index
							when 0
								if axis > 0
									activeAxis.keyCode = 39
									@buttonsPressed.push activeAxis
								else
									activeAxis.keyCode = 37
									@buttonsPressed.push activeAxis
							when 1
								if axis > 0
									activeAxis.keyCode = 40
									@buttonsPressed.push activeAxis
								else
									activeAxis.keyCode = 38
									@buttonsPressed.push activeAxis
							when 2
								if axis > 0
									activeAxis.keyCode = 44
									@buttonsPressed.push activeAxis
								else
									activeAxis.keyCode = 42
									@buttonsPressed.push activeAxis
							when 3
								if axis > 0
									activeAxis.keyCode = 43
									@buttonsPressed.push activeAxis
								else
									activeAxis.keyCode = 41
									@buttonsPressed.push activeAxis


			if @buttonsPressed.length

				for buttonPressed, index in @buttonsPressed
					
					#compare the button press(es) in the current and last eventloop
					if(buttonPressed in @buttonsPressedPrev == false)
						
						#if a button press did not exist in the last eventloop i.e. its a new button press...
						@emit 'gamepadkeydown', buttonPressed	
					else
						#if a button press did exist in the last eventloop i.e. its a continued button press...
						@emit 'gamepadkeyheld', buttonPressed

					#in anycase continue to...
					@emit 'gamepadevent', buttonPressed
					

				if @throttled
					switch @eventsInSequence
						when 0
							@loopInterval = 3
						when 1
							@loopInterval = 8
				else
					@loopInterval = 1000

				@eventsInSequence++
			else 
				
				#if there are no button presses in the current eventloop, still check the last eventloop for button presses
				if(@buttonsPressedPrev.length)
					
					# if there are any button presses, loop through them and emit event for each
					for buttonPressed, index in @buttonsPressedPrev
						@emit 'gamepadkeyup', buttonPressed	

				if @throttled
					@eventsInSequence = 0
					@loopInterval = 500
				else
					@eventsInSequence = 0
					@loopInterval = 1000
			
			@loopRequest = window.requestAnimationFrame @eventLoop.bind(@)
		
		, 1000 / @loopInterval

exports.Gamepad = new GamepadSystem()