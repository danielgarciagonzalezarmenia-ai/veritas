const List<String> kControlQuestions = [
  'Cuéntame algo trivial: ¿qué desayunaste hoy?',
  'Describe tu trayecto habitual de casa al trabajo.',
  '¿Qué hiciste durante la última hora?',
  'Enumera tres cosas que tengas ahora mismo a la vista.',
];

const List<String> kTruthQuestions = [
  '¿Dónde estabas anoche entre las 21:00 y las 23:00?',
  'Cuéntame qué hiciste exactamente al llegar a casa.',
  '¿Conoces a la persona de la que hablamos?',
  '¿Has hablado con alguien sobre esto esta semana?',
  'Describe tu rutina de la mañana con el mayor detalle posible.',
  '¿Qué ocurrió justo después de la llamada?',
  '¿Recuerdas con exactitud qué dijiste?',
  '¿Alguien puede confirmar tu versión de los hechos?',
  '¿Por qué debería creerte?',
  'Repite la historia desde el principio, sin omitir nada.',
  '¿Qué es lo que más te preocupa de esta conversación?',
  '¿Hay algo que no me estés contando?',
];

const List<String> kAllQuestions = [...kControlQuestions, ...kTruthQuestions];
