// Generated by CoffeeScript 1.9.0
(function() {
  var Vector;

  Vector = (function() {
    function Vector(_at_x, _at_y, _at_z) {
      this.x = _at_x;
      this.y = _at_y;
      this.z = _at_z;
      return 0;
    }

    Vector.prototype.minus = function(vec) {
      return new Vector(this.x - vec.x, this.y - vec.y, this.z - vec.z);
    };

    Vector.prototype.add = function(vec) {
      return new Vector(this.x + vec.x, this.y + vec.y, this.z + vec.z);
    };

    Vector.prototype.crossProduct = function(vec) {
      return new Vector(this.y * vec.z - this.z * vec.y, this.z * vec.x - this.x * vec.z, this.x * vec.y - this.y * vec.x);
    };

    Vector.prototype.length = function() {
      return Math.sqrt(this.x * this.x + this.y * this.y + this.z * this.z);
    };

    Vector.prototype.euclideanDistanceTo = function(vec) {
      return (this.minus(vec)).length();
    };

    Vector.prototype.multiplyScalar = function(scalar) {
      return new Vector(this.x * scalar, this.y * scalar, this.z * scalar);
    };

    Vector.prototype.normalized = function() {
      return this.multiplyScalar(1.0 / this.length());
    };

    return Vector;

  })();

  module.exports = Vector;

}).call(this);