fs = require 'fs'
path = require 'path'
chai = require 'chai'
yaml = require 'js-yaml'

ExplicitModel = require '../source/ExplicitModel'
meshlib = require '../source/index'
calculateProjectedFaceArea = require(
	'../source/helpers/calculateProjectedFaceArea')
calculateProjectionCentroid = require(
	'../source/helpers/calculateProjectionCentroid')
buildFacesFromFaceVertexMesh = require(
	'../source/helpers/buildFacesFromFaceVertexMesh')


chai.use require './chaiHelper'
chai.use require 'chai-as-promised'
expect = chai.expect

loadYaml = (path) ->
	return yaml.safeLoad fs.readFileSync path

generateMap = (collection) ->
	return collection.reduce (previous, current, index) ->
		previous[current.name] = models[index]
		return previous
	, {}


models = [
	'cube'
	'tetrahedron'
	'tetrahedronIrregular'
	'tetrahedrons'
	'missingFace'
].map (model) ->
	return {
	name: model
	filePath: path.join(
		__dirname, 'models/', model + '.yaml'
	)
	}

modelsMap = generateMap models


checkEquality = (dataFromAscii, dataFromBinary, arrayName) ->
	fromAscii = dataFromAscii[arrayName].map (position) -> Math.round position
	fromBinary = dataFromBinary[arrayName].map (position) -> Math.round position

	expect(fromAscii).to.deep.equal(fromBinary)


describe 'Meshlib', ->
	it 'returns a model object', ->
		jsonModel = loadYaml modelsMap['cube'].filePath

		modelPromise = meshlib jsonModel
		.done (model) -> model

		return expect(modelPromise).to.eventually.be.an.explicitModel


	it 'creates a face-vertex mesh', ->
		jsonModel = loadYaml modelsMap['cube'].filePath

		modelPromise = meshlib jsonModel
		.buildFaceVertexMesh()
		.done (model) -> model

		return expect(modelPromise).to.eventually.have.faceVertexMesh


	it 'builds faces from face vertex mesh', ->
		jsonModel = loadYaml modelsMap['tetrahedron'].filePath

		modelPromise = meshlib jsonModel
		.buildFaceVertexMesh()
		.setFaces(null)
		.buildFacesFromFaceVertexMesh()
		.getObject()
		.then (object) ->
			return object.mesh.faces

		return expect(modelPromise)
		.to.eventually.deep.equal(
			loadYaml(modelsMap['tetrahedron'].filePath).faces
		)


	it 'calculates face-normals', ->
		jsonModel = loadYaml modelsMap['cube'].filePath

		jsonModel.faces.forEach (face) ->
			delete face.normal

		modelPromise = meshlib jsonModel
		.calculateNormals()
		.done (model) -> model

		return expect(modelPromise).to.eventually.have.correctNormals


	it 'extracts individual geometries to submodels', ->
		jsonModel = loadYaml modelsMap['tetrahedrons'].filePath

		modelPromise = meshlib jsonModel
		.buildFaceVertexMesh()
		.getSubmodels()

		return expect(modelPromise).to.eventually.be.an('array')
		.and.to.have.length(2)


	it 'returns a JSON representation of the model', ->
		jsonModel = loadYaml modelsMap['cube'].filePath

		modelPromise = meshlib jsonModel
		.getJSON()

		return expect(modelPromise).to.eventually.be.a('string')


	it 'returns a javascript object representing the model', ->
		jsonModel = loadYaml modelsMap['cube'].filePath

		modelPromise = meshlib jsonModel
		.getObject()

		return expect(modelPromise).to.eventually.be.an('object')
		.and.to.have.any.keys('name', 'fileName', 'mesh')


	describe 'Modification Invariant Translation', ->
		it 'calculates the centroid of a face-projection', ->
			expect calculateProjectionCentroid {
				vertices: [
					{x: 0, y: 0, z: 0}
					{x: 2, y: 0, z: 0}
					{x: 0, y: 2, z: 0}
				]
			}
			.to.deep.equal {
				x: 0.6666666666666666
				y: 0.6666666666666666
			}

		it 'returns a modification invariant translation matrix', ->
			jsonModel = loadYaml modelsMap['tetrahedron'].filePath

			modelPromise = meshlib jsonModel
			.getModificationInvariantTranslation()

			return expect(modelPromise).to.eventually.deep.equal {
				x: -0.3333333333333333
				y: -0.3333333333333333
			}


	describe 'Two-Manifold Test', ->
		it 'recognizes that model is two-manifold', ->
			jsonModel = loadYaml modelsMap['tetrahedron'].filePath

			modelPromise = meshlib jsonModel
			.buildFaceVertexMesh()
			.isTwoManifold()

			return expect(modelPromise).to.eventually.be.true


		it 'recognizes that model is not two-manifold', ->
			jsonModel = loadYaml modelsMap['missingFace'].filePath

			modelPromise = meshlib jsonModel
			.buildFaceVertexMesh()
			.isTwoManifold()

			return expect(modelPromise).to.eventually.be.false


	describe 'calculateBoundingBox', ->
		it 'calculates the bounding box of a tetrahedron', ->
			jsonTetrahedron = loadYaml modelsMap['tetrahedron'].filePath

			modelPromise = meshlib jsonTetrahedron
			.buildFaceVertexMesh()
			.getBoundingBox()

			return expect(modelPromise).to.eventually.deep.equal({
				min: {x: 0, y: 0, z: 0},
				max: {x: 1, y: 1, z: 1}
			})


		it 'calculates the bounding box of a cube', ->
			jsonCube = loadYaml modelsMap['cube'].filePath

			modelPromise = meshlib jsonCube
			.buildFaceVertexMesh()
			.getBoundingBox()

			return expect(modelPromise).to.eventually.deep.equal({
				min: {x: -1, y: -1, z: -1},
				max: {x: 1, y: 1, z: 1}
			})

	describe 'Faces', ->
		it 'calculates the in xy-plane projected surface-area of a face', ->
			expect calculateProjectedFaceArea {
				vertices: [
					{x: 0, y: 0, z: 2}
					{x: 1, y: 0, z: 0}
					{x: 0, y: 1, z: 0}
				]
			}
			.to.equal 0.5

			expect calculateProjectedFaceArea {
				vertices: [
					{x: 0, y: 0, z: -2}
					{x: 2, y: 0, z: 0}
					{x: 0, y: 4, z: 0}
				]
			}
			.to.equal 4


		it 'retrieves the face with the largest xy-projection', ->
			jsonTetrahedron = loadYaml(
				modelsMap['tetrahedronIrregular'].filePath
			)

			modelPromise =  meshlib jsonTetrahedron
			.getFaceWithLargestProjection()

			return expect(modelPromise).to.eventually.deep.equal {
				normal: {x: 0, y: 0, z: -1}
				vertices: [
					{x: 0, y: 0, z: 0}
					{x: 0, y: 2, z: 0}
					{x: 3, y: 0, z: 0}
				]
				attribute: 0
			}


		it 'iterates over all faces in the face-vertex-mesh', ->
			jsonTetrahedron = loadYaml modelsMap['tetrahedron'].filePath,
				vertices = []

			return meshlib jsonTetrahedron
			.buildFaceVertexMesh()
			.forEachFace (face, index) ->
				vertices.push [face, index]
			.done () ->
				expect(vertices).to.have.length(4)


	describe 'Base64', ->
		tetrahedronBase64Array = [
			# vertexCoordinates
			'AACAPwAAAAAAAAAAAAAAAAAAgD8AAAAAAAAAAAAAAAAAAIA/AAAAAAAAAAAAAAAA',

			# faceVertexIndices
			'AAAAAAEAAAACAAAAAwAAAAAAAAACAAAAAwAAAAIAAAABAAAAAwAAAAEAAAAAAAAA',

			# vertexNormalCoordinates
			'6toxP/EyAr/xMgK/8TICv+raMT/xMgK/8TICv/EyAr/q2jE/Os0TvzrNE786zRO/',

			# faceNormalCoordinates
			'Os0TPzrNEz86zRM/AAAAAAAAgL8AAAAAAACAvwAAAAAAAAAAAAAAAAAAAAAAAIC/',

			# name
			'tetrahedron'
		]


		it 'exports model to base64 representation', ->
			model = modelsMap['tetrahedron']
			jsonTetrahedron = loadYaml model.filePath

			modelPromise = meshlib jsonTetrahedron
			.setName model.name
			.buildFaceVertexMesh()
			.getBase64()
			.then (base64String) -> base64String.split('|')

			expect(modelPromise)
			.to.eventually.be.deep.equal(tetrahedronBase64Array)


		it 'creates model from base64 representation', ->
			jsonTetrahedron = loadYaml modelsMap['tetrahedron'].filePath

			return meshlib jsonTetrahedron
			.buildFaceVertexMesh()
			.getFaceVertexMesh()
			.then (faceVertexMesh) ->
				actual = meshlib
				.Model
				.fromBase64 tetrahedronBase64Array.join('|')
				.getFaceVertexMesh()

				expect(actual).to.eventually.equalFaceVertexMesh(faceVertexMesh)
