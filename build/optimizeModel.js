// Generated by CoffeeScript 1.9.0
(function() {
  var Octree, OptimizedModel, Vec3;

  OptimizedModel = require('./OptimizedModel');

  Octree = require('./Octree');

  Vec3 = require('./Vector');

  module.exports = function(importedStl, options) {
    var avgNormals, biggestPointIndex, cleanseStl, faceNormals, index, indices, newPointIndex, octreeRoot, optimized, point, pointDistanceEpsilon, poly, vertexIndex, vertexPositions, vertexnormals, _i, _j, _len, _ref;
    if (options == null) {
      options = {};
    }
    cleanseStl = options.cleanseStl || true;
    pointDistanceEpsilon = options.pointDistanceEpsilon || 0.0001;
    if (cleanseStl) {
      importedStl.cleanse();
    }
    vertexnormals = [];
    faceNormals = [];
    index = [];
    octreeRoot = new Octree(pointDistanceEpsilon);
    biggestPointIndex = -1;
    _ref = importedStl.polygons;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      poly = _ref[_i];
      indices = [-1, -1, -1];
      for (vertexIndex = _j = 0; _j <= 2; vertexIndex = ++_j) {
        point = poly.points[vertexIndex];
        newPointIndex = octreeRoot.add(point, new Vec3(poly.normal.x, poly.normal.y, poly.normal.z), biggestPointIndex);
        indices[vertexIndex] = newPointIndex;
        if (newPointIndex > biggestPointIndex) {
          biggestPointIndex = newPointIndex;
        }
      }
      index.push(indices[0]);
      index.push(indices[1]);
      index.push(indices[2]);
      faceNormals.push(poly.normal.x);
      faceNormals.push(poly.normal.y);
      faceNormals.push(poly.normal.z);
    }
    vertexPositions = new Array((biggestPointIndex + 1) * 3);
    octreeRoot.forEach(function(node) {
      var i, v;
      v = node.vec;
      i = node.index * 3;
      vertexPositions[i] = v.x;
      vertexPositions[i + 1] = v.y;
      return vertexPositions[i + 2] = v.z;
    });
    avgNormals = new Array((biggestPointIndex + 1) * 3);
    octreeRoot.forEach(function(node) {
      var avg, i, normal, normalList, _k, _len1;
      normalList = node.normalList;
      i = node.index * 3;
      avg = new Vec3(0, 0, 0);
      for (_k = 0, _len1 = normalList.length; _k < _len1; _k++) {
        normal = normalList[_k];
        normal = normal.normalized();
        avg = avg.add(normal);
      }
      avg = avg.normalized();
      avgNormals[i] = avg.x;
      avgNormals[i + 1] = avg.y;
      return avgNormals[i + 2] = avg.z;
    });
    optimized = new OptimizedModel();
    optimized.positions = vertexPositions;
    optimized.indices = index;
    optimized.vertexNormals = avgNormals;
    optimized.faceNormals = faceNormals;
    return optimized;
  };

}).call(this);
