part of shape;

/// Parametric representation of a TorusKnot
/// u varies from 0 - 2 PI
/// q == 0 and p == 1 results in a torus
void TorusKnotGetPos(double u, int q, int p, double radius, double heightScale,
    VM.Vector3 vec) {
  final double cq = Math.cos(q * u);
  final double sq = Math.sin(q * u);
  final double cp = Math.cos(p * u);
  final double sp = Math.sin(p * u);

  vec.x = radius * (2.0 + cq) * 0.5 * cp;
  vec.y = radius * (2.0 + cq) * 0.5 * sp;
  vec.z = heightScale * radius * 0.5 * sq;
}

const double _TorusEpsilon = 0.01;

/// q == 0 and p == 1 results in a torus
GeometryBuilder TorusKnotGeometry({double radius = 20.0,
  double tubeRadius = 4.0,
  int segmentsR = 128,
  int segmentsT = 16,
  int p = 2,
  int q = 3,
  double heightScale = 1.0,
  // wrap false => start and end node are separate vertices
  bool wrap = false,
  bool computeUVs = true,
  bool computeNormals = true}) {
  void curveFunc(double u, VM.Vector3 out) {
    TorusKnotGetPos(u, q, p, radius, heightScale, out);
  }

  final List<VM.Vector3> pointsAndTangents = ParametricCurvePointsAndTangents(
      curveFunc, 0.0, 2.0 * Math.pi, segmentsR, halfOpen: true);
  if (!wrap) {
    pointsAndTangents.add(pointsAndTangents[0]);
    pointsAndTangents.add(pointsAndTangents[1]);
  }
  final int h = segmentsR + (wrap ? 0 : 1);
  assert(pointsAndTangents.length == 2 * h);

  final List<List<VM.Vector3>> bands =
  TubeHullBands(pointsAndTangents, segmentsT, tubeRadius);
  if (!wrap) {
    for (List<VM.Vector3> b in bands) {
      b.add(b[0]);
      b.add(b[1]);
    }
  }
  assert(bands.length == h);
  final int w = segmentsT + (wrap ? 0 : 1);

  assert(bands[0].length == 2 * w);

  final GeometryBuilder gb = GeometryBuilder();

  for (List<VM.Vector3> lst in bands) {
    for (int i = 0; i < lst.length; i += 2) {
      gb.AddVertex(lst[i]);
    }
  }
  assert(gb.vertices.length == w * h);

  gb.GenerateRegularGridFaces(w, h, wrap);

  if (computeUVs) {
    gb.GenerateRegularGridUV(w, h);
    assert(gb.attributes[aTexUV].length == gb.vertices.length);
  }

  if (computeNormals) {
    gb.EnableAttribute(aNormal);
    for (List<VM.Vector3> lst in bands) {
      for (int i = 0; i < lst.length; i += 2) {
        gb.AddAttributeVector3(aNormal, lst[i + 1]);
      }
    }
    assert(gb.attributes[aNormal].length == gb.vertices.length);
  }
  return gb;
}

/// Like ShapeTorusKnotGeometry but with duplicate Vertices to make it
/// possible to add aCenter attributes with GenerateWireframeCenters()
GeometryBuilder TorusKnotGeometryWireframeFriendly({double radius = 20.0,
  double tubeRadius = 4.0,
  int segmentsR = 128,
  int segmentsT = 16,
  int p = 2,
  int q = 3,
  double heightScale = 1.0,
  bool computeUVs = true,
  bool computeNormals = true}) {
  void curveFunc(double u, VM.Vector3 out) {
    TorusKnotGetPos(u, q, p, radius, heightScale, out);
  }

  final List<VM.Vector3> pointsAndTangents = ParametricCurvePointsAndTangents(
      curveFunc, 0.0, 2.0 * Math.pi, segmentsR, halfOpen: true);
  pointsAndTangents.add(pointsAndTangents[0]);
  pointsAndTangents.add(pointsAndTangents[1]);
  final int h = segmentsR + 1;
  assert(pointsAndTangents.length == 2 * h);

  final List<List<VM.Vector3>> bands =
  TubeHullBands(pointsAndTangents, segmentsT, tubeRadius);
  for (List<VM.Vector3> b in bands) {
    b.add(b[0]);
    b.add(b[1]);
  }
  assert(bands.length == h);

  final GeometryBuilder gb = GeometryBuilder();

  for (int i = 0; i < segmentsR; ++i) {
    for (int j = 0; j < segmentsT; ++j) {
      final int ip = i + 1;
      final int jp = j + 1;
      gb.AddFaces4(1);
      gb.AddVertices([
        bands[i][jp * 2],
        bands[ip][jp * 2],
        bands[ip][j * 2],
        bands[i][j * 2]
      ]);
    }
  }

  if (computeUVs) {
    gb..EnableAttribute(aTexUV);
    for (int i = 0; i < segmentsR; ++i) {
      for (int j = 0; j < segmentsT; ++j) {
        final int ip = i + 1;
        final int jp = j + 1;
        gb.AddAttributesVector2(aTexUV, [
          VM.Vector2(i / segmentsR, jp / segmentsT),
          VM.Vector2(ip / segmentsR, jp / segmentsT),
          VM.Vector2(ip / segmentsR, j / segmentsT),
          VM.Vector2(i / segmentsR, j / segmentsT)
        ]);
      }
    }
  }

  if (computeNormals) gb.GenerateNormalsAssumingTriangleMode();
  return gb;
}

/// Camera flying through a TorusKnot like through a tunnel
class TorusKnotCamera extends Camera {
  TorusKnotCamera(
      {this.radius = 20.0, this.p = 2, this.q = 3, this.heightScale = 1.0})
      : super("camera:torusknot");

  final double radius;
  final int p;
  final int q;
  final double heightScale;

  final VM.Vector3 p1 = VM.Vector3.zero();
  final VM.Vector3 p2 = VM.Vector3.zero();

  void animate(double timeMs) {
    double u = timeMs / 3000;
    TorusKnotGetPos(u, q, p, radius, heightScale, p1);
    TorusKnotGetPos(u + _TorusEpsilon, q, p, radius, heightScale, p2);

    setPosFromVec(p1);
    lookAt(p2, p1);
  }
}
