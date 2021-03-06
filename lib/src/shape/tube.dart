part of shape;

/// Given the points and corresponding tangents on a curve.
/// Compute the hull (points and normals) at radius around those points
/// divided into segment sections.
List<List<VM.Vector3>> TubeHullBands(List<VM.Vector3> pointsAndTangents,
    int segments, double radius) {

  final List<List<VM.Vector3>> out = [];
  // Avoid unnecessary allocations:
  final VM.Vector3 p = VM.Vector3.zero();
  final VM.Vector3 v1 = VM.Vector3.zero();
  final VM.Vector3 v2 = VM.Vector3.zero();

  for (int i = 0; i < pointsAndTangents.length; i += 2) {
    VM.Vector3 c = pointsAndTangents[i + 0];
    VM.Vector3 d = pointsAndTangents[i + 1];
    List<VM.Vector3> band = [];
    out.add(band);

    VM.buildPlaneVectors(d, v1, v2);
    v1.normalize();
    v2.normalize();

    for (int j = 0; j < segments; ++j) {
      double v = j / segments * 2 * Math.pi;
      double cx = radius * Math.cos(v);
      double cy = radius * Math.sin(v);

      // point on hull
      p.setFrom(c);
      p.addScaled(v1, cx);
      p.addScaled(v2, cy);

      band.add(VM.Vector3.copy(p));

      p.setZero();
      p.addScaled(v1, cx);
      p.addScaled(v2, cy);
      p.normalize();
      band.add(VM.Vector3.copy(p));
    }
  }
  return out;
}

typedef void ParametricCurveFunc(double u, VM.Vector3 out);

/// Note this creates the curve for the interval [start, end] or,
/// if halfOpen == true,  for the half open interval [start, end[.
/// The latter is useful for situations where we expect f(start) == f(end)
/// but because numerical inaccuracies it will be slightly off.
/// In such situations it is better to manually duplicate the f(start)
List<VM.Vector3> ParametricCurvePointsAndTangents(ParametricCurveFunc func,
    double start, double end, int numPoints,
    {double epsilon = 0.001, bool halfOpen = false}) {
  assert(numPoints >= 2);
  final List<VM.Vector3> out = [];
  final VM.Vector3 p = VM.Vector3.zero();
  final VM.Vector3 d = VM.Vector3.zero();
  double denom = numPoints - (halfOpen ? 0.0 : 1.0);
  for (int i = 0; i < numPoints; ++i) {
    double u = (end - start) / denom * i + start;
    func(u, p);
    func(u + epsilon, d);
    d.sub(p);
    out.add(p.clone());
    out.add(d.clone());
  }
  return out;
}
