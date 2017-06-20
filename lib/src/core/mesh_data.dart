part of core;

Float32List FlattenVector3List(List<VM.Vector3> v, [Float32List data = null]) {
  if (data == null) data = new Float32List(v.length * 3);
  for (int i = 0; i < v.length; ++i) {
    data[i * 3 + 0] = v[i].x;
    data[i * 3 + 1] = v[i].y;
    data[i * 3 + 2] = v[i].z;
  }
  return data;
}

Float32List FlattenVector2List(List<VM.Vector2> v, [Float32List data = null]) {
  if (data == null) data = new Float32List(v.length * 2);
  for (int i = 0; i < v.length; ++i) {
    data[i * 2 + 0] = v[i].x;
    data[i * 2 + 1] = v[i].y;
  }
  return data;
}

Float32List FlattenVector4List(List<VM.Vector4> v, [Float32List data = null]) {
  if (data == null) data = new Float32List(v.length * 4);
  for (int i = 0; i < v.length; ++i) {
    data[i * 4 + 0] = v[i].x;
    data[i * 4 + 1] = v[i].y;
    data[i * 4 + 2] = v[i].z;
    data[i * 4 + 3] = v[i].w;
  }
  return data;
}

Uint32List FlattenUvec4List(List<List<int>> v, [Uint32List data = null]) {
  if (data == null) data = new Uint32List(v.length * 4);
  for (int i = 0; i < v.length; ++i) {
    data[i * 4 + 0] = v[i][0];
    data[i * 4 + 1] = v[i][1];
    data[i * 4 + 2] = v[i][2];
    data[i * 4 + 3] = v[i][3];
  }
  return data;
}

Float32List FlattenMatrix4List(List<VM.Matrix4> v, [Float32List data = null]) {
  if (data == null) data = new Float32List(v.length * 16);
  for (int i = 0; i < v.length; ++i) {
    VM.Matrix4 m = v[i];
    for (int j = 0; j < 16; ++j) data[i * 16 + j] = m[j];
  }
  return data;
}

/// ## Class MeshData
/// presents a VAO - attributes and vertex buffers associated with
/// an mesh, e.g. a sphere, cube, etc.
/// MeshData objects can be populated directly but often they
/// will derived from **GeometryBuilder** objects.
class MeshData extends NamedEntity {
  final ChronosGL _cgl;
  final dynamic _vao;
  final _drawMode;
  final Map<String, dynamic /* gl Buffer */ > _buffers = {};
  final Map<String, int> _locationMap;
  dynamic /* gl Buffer */ _indexBuffer;
  int _indexBufferType = -1;

  Float32List _vertices;
  List<int> _faces;
  Map<String, Float32List> _attributes = {};

  MeshData(String name, this._cgl, this._drawMode, this._locationMap)
      : _vao = _cgl.createVertexArray(),
        super("meshdata:" + name);

  void clearData() {
    for (String canonical in _buffers.keys) {
      _cgl.deleteBuffer(_buffers[canonical]);
    }
    if (_indexBuffer != null) {
      _cgl.deleteBuffer(_indexBuffer);
    }
  }

  void ChangeAttribute(String canonical, List data, int width) {
    if (debug) print("ChangeBuffer ${canonical} ${data.length}");
    assert(data.length ~/ width == _vertices.length ~/ 3);
    _attributes[canonical] = data;
    _cgl.ChangeArrayBuffer(_buffers[canonical], data);
  }

  void ChangeVertices(Float32List data) {
    final String canonical = aVertexPosition;
    _vertices = data;
    ChangeAttribute(canonical, data, 3);
  }

  bool SupportsAttribute(String canonical) {
    return _locationMap.containsKey(canonical);
  }

  int get drawMode => _drawMode;

  int get elementArrayBufferType => _indexBufferType;

  int GetNumItems() {
    if (_faces != null) {
      return _faces.length;
    }
    return _vertices.length ~/ 3;
  }

  int GetNumInstances() {
    return 0;
  }

  Float32List GetAttribute(String canonical) {
    return _attributes[canonical];
  }

  dynamic GetBuffer(String canonical) {
    return _buffers[canonical];
  }

  void AddAttribute(String canonical, List data, int width) {
    _buffers[canonical] = _cgl.createBuffer();
    ChangeAttribute(canonical, data, width);
    _cgl.bindVertexArray(_vao);
    ShaderVarDesc desc = RetrieveShaderVarDesc(canonical);
    if (desc == null) throw "Unknown canonical ${canonical}";
    assert(_locationMap.containsKey(canonical),
        "unexpected attribute ${canonical}");
    int index = _locationMap[canonical];
    _cgl.enableVertexAttribArray(index, 0);
    _cgl.vertexAttribPointer(
        _buffers[canonical], index, desc.GetSize(), GL_FLOAT, false, 0, 0);
  }

  void AddVertices(Float32List data) {
    final String canonical = aVertexPosition;
    _buffers[canonical] = _cgl.createBuffer();
    ChangeVertices(data);
    _cgl.bindVertexArray(_vao);
    ShaderVarDesc desc = RetrieveShaderVarDesc(canonical);
    if (desc == null) throw "Unknown canonical ${canonical}";
    assert(_locationMap.containsKey(canonical));
    int index = _locationMap[canonical];
    _cgl.enableVertexAttribArray(index, 0);
    _cgl.vertexAttribPointer(
        _buffers[canonical], index, desc.GetSize(), GL_FLOAT, false, 0, 0);
  }

  void ChangeFaces(List<int> faces) {
    assert(_vertices != null);
    if (_vertices.length < 3 * 256) {
      _faces = new Uint8List.fromList(faces);
      _indexBufferType = GL_UNSIGNED_BYTE;
    } else if (_vertices.length < 3 * 65536) {
      _faces = new Uint16List.fromList(faces);
      _indexBufferType = GL_UNSIGNED_SHORT;
    } else {
      _faces = new Uint32List.fromList(faces);
      _indexBufferType = GL_UNSIGNED_INT;
    }

    _cgl.bindVertexArray(_vao);
    _cgl.ChangeElementArrayBuffer(_indexBuffer, _faces as TypedData);
  }

  void AddFaces(List<int> faces) {
    _indexBuffer = _cgl.createBuffer();
    ChangeFaces(faces);
  }

  void SetUp() {
    _cgl.bindVertexArray(_vao);
  }

  void TearDown() {
    _cgl.bindVertexArray(null);
  }

  Iterable<String> GetAttributes() {
    return _attributes.keys;
  }

  @override
  String toString() {
    int nf = _faces == null ? 0 : _faces.length;
    List<String> lst = ["Faces:${nf}"];
    for (String c in _attributes.keys) {
      lst.add("${c}:${_attributes[c].length}");
    }

    return "MESH[${name}] " + lst.join("  ");
  }
}

void _GeometryBuilderAttributesToMeshData(GeometryBuilder gb, MeshData md) {
  for (String canonical in gb.attributes.keys) {
    if (!md.SupportsAttribute(canonical)) {
      print("Dropping unnecessary attribute: ${canonical}");
      continue;
    }
    dynamic lst = gb.attributes[canonical];
    ShaderVarDesc desc = RetrieveShaderVarDesc(canonical);

    //print("${md.name} ${canonical} ${lst}");
    switch (desc.type) {
      case VarTypeVec2:
        md.AddAttribute(canonical, FlattenVector2List(lst), 2);
        break;
      case VarTypeVec3:
        md.AddAttribute(canonical, FlattenVector3List(lst), 3);
        break;
      case VarTypeVec4:
        md.AddAttribute(canonical, FlattenVector4List(lst), 4);
        break;
      case VarTypeFloat:
        md.AddAttribute(canonical, new Float32List.fromList(lst), 1);
        break;
      case VarTypeUvec4:
        md.AddAttribute(canonical, FlattenUvec4List(lst), 4);
        break;
      default:
        assert(false,
            "unknown type for ${canonical} [${lst[0].runtimeType}] [${lst.runtimeType}] ${lst}");
    }
  }
}

MeshData GeometryBuilderToMeshData(
    String name, RenderProgram prog, GeometryBuilder gb) {
  MeshData md =
      prog.MakeMeshData(name, gb.pointsOnly ? GL_POINTS : GL_TRIANGLES);
  md.AddVertices(FlattenVector3List(gb.vertices));
  if (!gb.pointsOnly) md.AddFaces(gb.GenerateFaceIndices());
  _GeometryBuilderAttributesToMeshData(gb, md);
  return md;
}

MeshData _ExtractWireframeNormals(
    MeshData out, List<double> vertices, List<double> normals, scale) {
  assert(vertices.length == normals.length);
  Float32List v = new Float32List(2 * vertices.length);
  for (int i = 0; i < vertices.length; i += 3) {
    v[2 * i + 0] = vertices[i + 0];
    v[2 * i + 1] = vertices[i + 1];
    v[2 * i + 2] = vertices[i + 2];
    v[2 * i + 3] = vertices[i + 0] + scale * normals[i + 0];
    v[2 * i + 4] = vertices[i + 1] + scale * normals[i + 1];
    v[2 * i + 5] = vertices[i + 2] + scale * normals[i + 2];
  }
  out.AddVertices(v);

  final int n = 2 * vertices.length ~/ 3;
  List<int> lines = new List<int>(n);
  for (int i = 0; i < n; i++) {
    lines[i] = i;
  }

  out.AddFaces(lines);
  return out;
}

MeshData GeometryBuilderToWireframeNormals(
    RenderProgram prog, GeometryBuilder gb,
    [scale = 1.0]) {
  MeshData out = prog.MakeMeshData("norm", GL_LINES);
  return _ExtractWireframeNormals(out, FlattenVector3List(gb.vertices),
      FlattenVector3List(gb.attributes[aNormal] as List<VM.Vector3>), scale);
}

//Extract Wireframe MeshData
MeshData GeometryBuilderToMeshDataWireframe(
    String name, RenderProgram prog, GeometryBuilder gb) {
  MeshData md = prog.MakeMeshData(name, GL_LINES);
  md.AddVertices(FlattenVector3List(gb.vertices));
  md.AddFaces(gb.GenerateLineIndices());
  _GeometryBuilderAttributesToMeshData(gb, md);
  return md;
}

MeshData LineEndPointsToMeshData(
    String name, RenderProgram prog, List<VM.Vector3> points) {
  MeshData md = prog.MakeMeshData(name, GL_LINES);
  md.AddVertices(FlattenVector3List(points));
  List<int> faces = new List<int>(points.length);
  for (int i = 0; i < points.length; ++i) faces[i] = i;
  md.AddFaces(faces);
  return md;
}

MeshData ExtractWireframeNormals(RenderProgram prog, MeshData md,
    [scale = 1.0]) {
  assert(md._drawMode == GL_TRIANGLES);
  MeshData out = prog.MakeMeshData(md.name, GL_LINES);
  final Float32List vertices = md.GetAttribute(aVertexPosition);
  final Float32List normals = md.GetAttribute(aNormal);
  return _ExtractWireframeNormals(out, vertices, normals, scale);
}

MeshData ExtractWireframe(RenderProgram prog, MeshData md) {
  assert(md._drawMode == GL_TRIANGLES);
  MeshData out = prog.MakeMeshData(md.name, GL_LINES);
  out.AddVertices(md._vertices);
  final List<int> faces = md._faces;
  List<int> lines = new List<int>(faces.length * 2);
  for (int i = 0; i < faces.length; i += 3) {
    lines[i * 2 + 0] = faces[i + 0];
    lines[i * 2 + 1] = faces[i + 1];
    lines[i * 2 + 2] = faces[i + 1];
    lines[i * 2 + 3] = faces[i + 2];
    lines[i * 2 + 4] = faces[i + 2];
    lines[i * 2 + 5] = faces[i + 0];
  }

  out.AddFaces(lines);
  return out;
}
