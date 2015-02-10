class Model

	# Abstracts the actual model from the external fluid api

	constructor: (@mesh, @options) ->
		@ready = Promise.resolve null

	toStl: (options) ->
		options ?= {}
		options.encoding ?= 'binary' # ascii
		options.type ?= 'buffer' # string

	optimize: () =>
		@ready = @ready.then (model) ->
			return new Promise (fulfill, reject) ->
				try
					@mesh = optimizeModel @mesh
				catch error
					return reject error

				fulfill model

		return @ready


module.exports = Model
