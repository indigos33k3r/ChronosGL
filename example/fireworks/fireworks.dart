import 'package:chronosgl/chronosgl.dart';
import 'dart:math' as Math;
import 'dart:html' as HTML;

import 'package:vector_math/vector_math.dart' as VM;

List<ShaderObject> createFireWorksShader() {
  return [
    new ShaderObject("FireWorksV")
      ..AddAttributeVar(aVertexPosition)
      ..AddAttributeVar(aNormal)
      ..AddUniformVar(uPerspectiveViewMatrix)
      ..AddUniformVar(uModelMatrix)
      ..AddUniformVar(uTime, uTime)
      ..SetBodyWithMain([
        """
      float t = mod(${uTime}, 5.0);
      vec3 vp = ${aVertexPosition};
      if( t < 3.0) {
       vp.y = t;
      } else {
       vp.y = 3.0;
       vp += normalize(${aNormal})*(t-3.0);
      }
      gl_Position = ${uPerspectiveViewMatrix} * ${uModelMatrix} * vec4(vp, 1.0);
      gl_PointSize = 100.0/gl_Position.z;
"""
      ]),
    new ShaderObject("FireWorksF")
      ..AddUniformVar(uTime)
      ..AddUniformVar(uColor)
      ..AddUniformVar(uTextureSampler)
      ..SetBodyWithMain([
        """
      gl_FragColor = texture2D(${uTextureSampler}, gl_PointCoord);
      float t = mod(${uTime}, 5.0);
      if( t < 3.0) {
         //gl_FragColor.x = 1.0;
      } else {
         //gl_FragColor.rgb = ${uColor};
         gl_FragColor.a -= (t-3.0);
      }
"""
      ])
  ];
}

Math.Random rand = new Math.Random();

Mesh getRocket(Texture tw) {
  int numPoints = 200;

  List<VM.Vector3> vertices = [];
  List<VM.Vector3> normals = [];
  for (var i = 0; i < numPoints; i++) {
    vertices.add(new VM.Vector3(0.0, 0.0, 0.0));
    normals.add(new VM.Vector3(rand.nextDouble() - 0.5, rand.nextDouble() - 0.5,
        rand.nextDouble() - 0.5));
  }

  MeshData md = new MeshData("firefwork-particles")
    ..EnableAttribute(aNormal)
    ..AddFaces1(numPoints)
    ..AddVertices(vertices)
    ..AddAttributesVector3(aNormal, normals);

  Material mat = new Material("mat")
    ..SetUniform(uTextureSampler, tw)
    ..SetUniform(uColor, new VM.Vector3(1.0, 0.0, 0.0))
    ..blend = true
    ..depthWrite = false
    ..blend_dFactor = 0x0301; // WebGLRenderingContext.ONE_MINUS_SRC_COLOR;
  return new Mesh(md.name, md, mat);
}

void main() {
  HTML.CanvasElement canvas = HTML.document.querySelector('#webgl-canvas');
  ChronosGL chronosGL = new ChronosGL(canvas);
  OrbitCamera orbit = new OrbitCamera(15.0);
  Perspective perspective = new Perspective(orbit);
  RenderingPhase phase = new RenderingPhase("main", chronosGL.gl, perspective);

  ShaderProgram programSprites =
      phase.createProgram(createPointSpritesShader());
  programSprites.add(Utils.MakeParticles(2000));

  ShaderProgram pssp = phase.createProgram(createFireWorksShader());
  pssp.add(getRocket(Utils.createParticleTexture("fireworks")));

  double _lastTimeMs = 0.0;
  void animate(double timeMs) {
    double elapsed = timeMs - _lastTimeMs;
    _lastTimeMs = timeMs;
    orbit.azimuth += 0.001;
    orbit.animate(elapsed);
    pssp.SetTime(timeMs / 1000.0);
    perspective.Adjust(canvas);
    phase.draw([]);
    HTML.window.animationFrame.then(animate);
  }

  Texture.loadAndInstallAllTextures(chronosGL.gl).then((dummy) {
    animate(0.0);
  });
}
