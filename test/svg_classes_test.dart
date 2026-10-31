import 'package:flutter_test/flutter_test.dart';
import 'package:open_nini/widgets/svg_classes.dart';

void main() {
  test('css class colors become element attributes', () {
    const source = '''
<svg xmlns="http://www.w3.org/2000/svg">
<style type="text/css">.st0{fill:#F9DA56;}.st1{clip-path:url(#SVGID_1_);}</style>
<path class="st0" d="M0,0"/>
<g class="st1"></g>
</svg>
''';

    final inlined = inlineSvgClasses(source);

    expect(inlined, isNot(contains('<style')));
    expect(inlined, isNot(contains('class=')));
    expect(inlined, contains('fill="#F9DA56"'));
    expect(inlined, contains('clip-path="url(#SVGID_1_)"'));
  });
}
