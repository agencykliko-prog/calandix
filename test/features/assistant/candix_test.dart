import 'package:eventa/features/assistant/data/candix_answers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Candix répond à partir de sa base, accents ignorés', () {
    expect(
      candixAnswer('Combien coûte la formule Signature ?'),
      contains('4900'),
    );
    expect(
      candixAnswer('comment REMPLIR mon budget'),
      contains('budget cible'),
    );
    expect(candixAnswer('Je cherche un traiteur'), contains('Explorer'));
  });

  test('hors de sa base, Candix oriente vers un conseiller', () {
    expect(
      candixAnswer('Quelle est la capitale du Japon ?'),
      contains('conseiller'),
    );
  });
}
