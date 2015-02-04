fs = require 'fs'
path = require 'path'
assert = require 'assert'

meshlib = require '../source/index'


models = [
	'unitCube'
	'gearwheel'
	'bunny'
]

checkEquality = (dataFromAscii, dataFromBinary, arrayName) ->
	assert.deepEqual(
		dataFromAscii[arrayName]
		.map (position) -> Math.round position

		dataFromBinary[arrayName]
		.map (position) -> Math.round position
	)

for model in models
	do (model) ->
		asciiStlBuffer = fs.readFileSync path.join __dirname,
			'models', model + '.ascii.stl'

		console.time('ascii-' + model)

		meshlib.parse asciiStlBuffer, null, (error, dataFromAscii) ->
			if error
				throw error
			else if not dataFromAscii
				throw new Error 'Data is empty!'
			else
				console.timeEnd('ascii-' + model)

				binaryStlBuffer = fs.readFileSync path.join __dirname,
					'models', model + '.bin.stl'

				console.time('binary-' + model)
				meshlib.parse binaryStlBuffer, null, (error, dataFromBinary) ->
					if error
						throw error
					else if not dataFromBinary
						throw new Error 'Data is empty!'
					else
						console.timeEnd 'binary-' + model

						for arrayName in [
							'positions'
							'indices'
							'vertexNormals'
							'faceNormals']
							checkEquality dataFromAscii,
								dataFromBinary, arrayName
