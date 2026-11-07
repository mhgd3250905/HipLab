/// Display labels for the public catalogue's stable semantic IDs. These never
/// modify source definitions, filters or training prescriptions.
abstract final class HipPublicDisplay {
  static const muscles = <String, String>{
    'deltoids': 'Deltoids',
    'rotator-cuff': 'Rotator cuff',
    'triceps': 'Triceps',
    'biceps': 'Biceps',
    'forearms': 'Forearms',
    'serratus': 'Serratus anterior',
    'scapular': 'Scapular muscles',
    'chest': 'Chest',
    'lats': 'Latissimus dorsi',
    'abs': 'Abdominals',
    'obliques': 'Obliques',
    'erectors': 'Spinal erectors',
    'hip-flexors': 'Hip flexors',
    'glute-max': 'Glutes',
    'hip-abductors': 'Hip abductors',
    'adductors': 'Adductors',
    'quadriceps': 'Quadriceps',
    'hamstrings': 'Hamstrings',
    'calves': 'Calves',
    'tibialis': 'Tibialis anterior',
    'neck': 'Neck',
  };
  static const equipment = <String, String>{
    'mat': 'Mat',
    'chair': 'Chair',
    'band': 'Resistance band',
    'dumbbell': 'Dumbbell',
    'wall': 'Wall',
    'cable': 'Cable machine',
    'block': 'Yoga block',
    'pullup-bar': 'Pull-up bar',
    'parallettes': 'Parallettes',
    'dip-bars': 'Dip bars',
    'slider': 'Slider',
    'rings': 'Rings',
    'landmine': 'Landmine',
    'swiss-ball': 'Exercise ball',
    'roman-chair': 'Roman chair',
    'kettlebell': 'Kettlebell',
    'reverse-hyper': 'Reverse hyper',
    'ghd': 'GHD',
    'hip-abductor-machine': 'Hip-abduction machine',
    'leg-extension-machine': 'Leg-extension machine',
    'foam-roller': 'Foam roller',
    'towel': 'Towel',
    'doorframe': 'Doorframe',
    'bench': 'Bench',
    'barbell': 'Barbell',
  };
  static const categories = <String, String>{
    'strength': 'Strength',
    'core': 'Core',
    'cardio': 'Cardio',
    'mobility': 'Mobility',
    'stretch': 'Stretch',
  };

  static List<String> _list(Object? value) =>
      value is List ? value.whereType<String>().toList() : const [];
  static String muscleText(Map<String, Object?> definition) => _list(
    definition['muscleGroups'],
  ).map((id) => muscles[id] ?? id).join(', ');
  static String metadata(Map<String, Object?> definition) {
    final tools = _list(definition['equipment']);
    return [
      categories[definition['category']] ?? 'Exercise',
      switch (definition['level']) {
        1 => 'Beginner',
        2 => 'Basic',
        _ => 'Advanced',
      },
      tools.isEmpty
          ? 'Bodyweight'
          : tools.map((id) => equipment[id] ?? id).join(' / '),
      if (definition['unilateral'] == true) 'Each side',
    ].join(' · ');
  }
}
