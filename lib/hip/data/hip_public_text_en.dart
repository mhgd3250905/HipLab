// Display-only English translations of the 209 HipLab-authorized public
// action definitions in the frozen r2-v1 canonical catalogue. Each cue and
// caution preserves the source order; training, safety decisions, IDs and
// stored user text remain in the authoritative source models.

class HipPublicEnglishText {
  const HipPublicEnglishText({
    required this.purpose,
    required this.cues,
    required this.cautions,
    required this.contraindications,
  });
  final String purpose;
  final List<String> cues, cautions, contraindications;
}

const hipPublicTextSourceSha256 =
    'ff9eb70740887752ba81bba0742fccb43d0522c2d810141a5d496228f1fb82c2';

const hipPublicTextEn = <String, HipPublicEnglishText>{
  "abs-A": HipPublicEnglishText(
    purpose: "Train your abs for a steadier body.",
    cues: [
      "Press your lower back into the floor and lift your upper back and legs.",
      "Reach your arms straight alongside your ears, with your legs straight and together.",
      "Hold still and breathe evenly. Do not hold your breath.",
    ],
    cautions: ["If your lower back lifts or hurts, raise your legs higher."],
    contraindications: ["Lower back"],
  ),
  "abs-B": HipPublicEnglishText(
    purpose: "Build abdominal and leg-lifting strength to support your body.",
    cues: [
      "Keep your arms straight and bring your knees towards your chest.",
      "Press your shoulders down without shrugging.",
      "Once stable, try straightening one leg forwards at a time.",
    ],
    cautions: [
      "Stop if your wrists hurt or feel numb.",
      "Warm up your wrists first.",
    ],
    contraindications: ["Wrist"],
  ),
  "abs-C": HipPublicEnglishText(
    purpose:
        "Train your abs to lift your legs while supported on parallel bars.",
    cues: [
      "Keep your arms straight and curl your pelvis to lift your knees.",
      "Lift your knees a little higher than your hips and pause.",
      "Lower slowly without swinging your legs.",
    ],
    cautions: [
      "If the front of your shoulder pinches, lift less high or choose an easier version.",
    ],
    contraindications: ["Shoulder"],
  ),
  "adductors-A": HipPublicEnglishText(
    purpose:
        "Train your inner thighs, glutes and legs to squat steadily to one side.",
    cues: [
      "Squat towards one side while straightening the other leg with its toes pointing up.",
      "Keep the squatting heel down and track that knee towards your toes.",
      "Lean slightly forwards and reach both arms forwards for balance.",
      "One repetition includes both sides.",
    ],
    cautions: [
      "Squat less deeply if your knee feels uncomfortable. Stop if pain continues.",
    ],
    contraindications: ["Knee"],
  ),
  "adductors-B": HipPublicEnglishText(
    purpose: "Train your inner thighs and side core for steadier hips.",
    cues: [
      "Press the upper knee into the bench and lift your hips into a supported hold.",
      "Support yourself on your forearm, with your elbow directly below your shoulder.",
      "Keep your shoulder, hip and knee in a straight line. Hold without sagging and breathe evenly.",
    ],
    cautions: ["Stop immediately if you feel sharp pain in the inner groin."],
    contraindications: ["Inner thigh"],
  ),
  "adductors-C": HipPublicEnglishText(
    purpose: "Train your inner thighs for better hip control.",
    cues: [
      "Keep the leg straight and sweep it inwards across the front of the supporting leg.",
      "Stand side-on to the machine with the ankle strap on the leg nearest it.",
      "Keep your pelvis level and return slowly to the outside.",
    ],
    cautions: ["Reduce the range if it hurts. Stop if pain continues."],
    contraindications: [],
  ),
  "chest-A": HipPublicEnglishText(
    purpose:
        "Train your chest and shoulders while keeping your core steady as you rotate.",
    cues: [
      "Perform a push-up, then rotate your whole body to face the side.",
      "Turn your chest and hips together rather than twisting only your lower back.",
      "Reach the upper hand towards the ceiling, pause, then rotate back.",
      "One repetition includes both sides.",
    ],
    cautions: [
      "Stop if your wrists hurt or feel numb.",
      "Warm up your wrists first.",
    ],
    contraindications: ["Wrist"],
  ),
  "chest-B": HipPublicEnglishText(
    purpose:
        "Train your chest and arms through a deeper range than a standard push-up.",
    cues: [
      "Lower your chest between your hands, with your elbows angled back.",
      "Push up until your arms are straight, then press the floor farther away.",
      "Keep your body in a straight line without letting your lower back sag.",
    ],
    cautions: [
      "Lower less deeply if the front of your shoulder pinches.",
      "Stop if your wrists hurt or feel numb.",
    ],
    contraindications: ["Shoulder", "Wrist"],
  ),
  "chest-C": HipPublicEnglishText(
    purpose: "Train your chest and resist rotation through your core.",
    cues: [
      "Stand steadily in a split stance and press one hand forwards until the arm is straight.",
      "Keep your shoulders and hips facing forwards as you press.",
      "Return slowly without letting the cable pull your hand back.",
      "When changing hands, also switch which foot is in front.",
    ],
    cautions: [
      "Reduce the pressing range if the front of your shoulder pinches.",
    ],
    contraindications: ["Shoulder"],
  ),
  "deltoids-A": HipPublicEnglishText(
    purpose:
        "Train your shoulders and side core for steadier one-handed support.",
    cues: [
      "Place your hand directly below your shoulder and push the floor away.",
      "Lower your hips slowly, then lift back into a straight body line.",
      "Rest the other hand on your hip and keep your supporting shoulder and feet in place.",
    ],
    cautions: [
      "Stop if your wrists hurt or feel numb.",
      "Warm up your wrists first.",
    ],
    contraindications: ["Wrist"],
  ),
  "deltoids-B": HipPublicEnglishText(
    purpose: "Build shoulder stability while changing your body position.",
    cues: [
      "Keep the hand holding the dumbbell pointed towards the ceiling throughout.",
      "Rise onto your elbow, then your hand, then lift your hips into a high bridge.",
      "Stabilise at each step before continuing, and reverse the same path to return.",
    ],
    cautions: [
      "Practise with a very light weight first.",
      "Stop if the front of your shoulder pinches.",
    ],
    contraindications: ["Shoulder"],
  ),
  "deltoids-C": HipPublicEnglishText(
    purpose: "Build shoulder pressing strength with an angled upward press.",
    cues: [
      "Press diagonally forwards and upwards until your arm is straight.",
      "Tighten your glutes and abdomen without leaning your upper body back.",
      "Lower slowly to the front of your shoulder.",
    ],
    cautions: [
      "Reduce the pressing range if the front of your shoulder pinches.",
    ],
    contraindications: ["Shoulder"],
  ),
  "erectors-A": HipPublicEnglishText(
    purpose: "Train your back, glutes and hamstrings.",
    cues: [
      "Push through your hands and lift your hips until your body forms a straight line.",
      "Place your hands below your shoulders, fingers pointing towards your feet.",
      "Keep your arms straight and heels grounded, and squeeze your glutes at the top.",
    ],
    cautions: [
      "Stop if your wrists hurt or feel numb.",
      "Warm up your wrists first.",
    ],
    contraindications: ["Wrist"],
  ),
  "erectors-B": HipPublicEnglishText(
    purpose: "Build endurance in your lower back and glutes.",
    cues: [
      "Rest your hips on the ball and lift only until your body forms a straight line.",
      "Brace your feet against the base of a wall with your legs straight.",
      "Pause for one second at the top, then lower slowly.",
    ],
    cautions: [
      "Lift less high if your lower back feels uncomfortable. Stop if pain continues.",
    ],
    contraindications: ["Lower back"],
  ),
  "erectors-C": HipPublicEnglishText(
    purpose:
        "Train your lower back, glutes and hamstrings to raise your body with control.",
    cues: [
      "Hinge down at your hips while keeping your back flat.",
      "Position the pad below your hip bones and cross your hands over your chest.",
      "Stop lifting when your body forms a straight line; do not arch farther back.",
    ],
    cautions: [
      "Use a shallower bend if your lower back feels uncomfortable. Stop if pain continues.",
    ],
    contraindications: ["Lower back"],
  ),
  "forearms-A": HipPublicEnglishText(
    purpose: "Mobilise your wrists before floor-support exercises.",
    cues: [
      "Rock gently forwards and backwards, increasing pressure gradually.",
      "Use fingers forwards, outwards, backwards, then the backs of your hands down. Rock four times in each position before changing.",
      "Rocking forwards and back counts as one repetition. Keep your arms straight and knees steady.",
    ],
    cautions: ["Stop if you feel sharp wrist pain or numbness."],
    contraindications: ["Wrist"],
  ),
  "forearms-B": HipPublicEnglishText(
    purpose: "Train your forearms to strengthen your grip and wrists.",
    cues: [
      "Rest your forearm flat on your thigh and move only at the wrist.",
      "Curl your wrist upwards, then lower it slowly through the available range.",
      "Take about one second to lift and two seconds to lower.",
    ],
    cautions: [
      "Use a lighter dumbbell and a smaller range if your wrist feels uncomfortable.",
    ],
    contraindications: ["Wrist"],
  ),
  "forearms-C": HipPublicEnglishText(
    purpose: "Train your grip and forearms for steadier wrists.",
    cues: [
      "Hold the kettlebell bottom-up, with your forearm vertical and wrist straight.",
      "Grip the handle firmly and keep your elbow in front of and below your shoulder.",
      "Walk slowly while standing tall.",
    ],
    cautions: [
      "Use a light kettlebell. If it tips, let it go rather than trying to catch it.",
    ],
    contraindications: [],
  ),
  "g-cable-hip-abduction": HipPublicEnglishText(
    purpose: "Train the outer glutes for steadier hips.",
    cues: [
      "Lift your leg to the side while keeping your pelvis and upper body still.",
      "Steady yourself with one hand on a chair and keep the supporting foot grounded.",
      "Return slowly without letting the cable pull the leg back.",
    ],
    cautions: ["Reduce the range if it hurts. Stop if pain continues."],
    contraindications: [],
  ),
  "g-cable-hip-extension": HipPublicEnglishText(
    purpose: "Train your glutes to push your leg backwards more strongly.",
    cues: [
      "Use your glutes to push the leg backwards while keeping your upper body still.",
      "Steady yourself with one hand on a chair and keep the supporting foot grounded.",
      "Do not arch your lower back. Return slowly.",
    ],
    cautions: [
      "Reduce the range if your lower back feels uncomfortable. Stop if pain continues.",
    ],
    contraindications: ["Lower back"],
  ),
  "glute-max-A": HipPublicEnglishText(
    purpose: "Train your glutes to lift your hips on one leg.",
    cues: [
      "Lift one straight leg and use your glutes to push your hips up.",
      "Keep the supporting foot grounded and your pelvis level.",
      "Lower slowly without pushing up through your lower back.",
    ],
    cautions: [
      "Lift less high if your lower back feels uncomfortable. Stop if pain continues.",
      "Rest your head and shoulders on the mat rather than supporting yourself on your neck.",
    ],
    contraindications: ["Lower back", "Shoulder", "Neck"],
  ),
  "glute-max-B": HipPublicEnglishText(
    purpose: "Train your glutes to lift your leg backwards.",
    cues: [
      "Start on hands and knees on the mat, then lift one straight leg backwards and upwards.",
      "Keep your lower back from sagging and lift the leg only to roughly body height.",
      "Pause for one second at the top, then lower slowly.",
    ],
    cautions: [
      "Lift less high if your lower back feels uncomfortable. Stop if pain continues.",
    ],
    contraindications: ["Lower back"],
  ),
  "glute-max-C": HipPublicEnglishText(
    purpose: "Train your glutes and hamstrings to lift your legs backwards.",
    cues: [
      "Use your glutes to lift both legs until they are level with your torso.",
      "Lie your upper body on the pad, hold the handles firmly and keep both legs straight.",
      "Pause briefly at the top, then lower slowly.",
    ],
    cautions: [
      "Lift less high if your lower back feels uncomfortable. Stop if pain continues.",
    ],
    contraindications: ["Lower back"],
  ),
  "h-9090-liftoff": HipPublicEnglishText(
    purpose:
        "Train hip internal-rotation strength and control for better mobility.",
    cues: [
      "Sit tall, keep the rear knee on the floor, and lift the lower leg and foot.",
      "Place the front shin across your body and rest your hands on your knees.",
      "Pause at the top, then lower slowly.",
    ],
    cautions: [
      "Lift less high if your hip or knee feels uncomfortable. Stop if pain continues.",
    ],
    contraindications: ["Knee", "Hip"],
  ),
  "h-adductor-rock": HipPublicEnglishText(
    purpose: "Stretch your inner thighs to improve hip mobility.",
    cues: [
      "Keep your back flat and sit your hips back towards your heel.",
      "Extend one leg to the side with the whole foot grounded and toes facing forwards.",
      "Pause when you feel a stretch in the inner thigh, then move forwards again.",
    ],
    cautions: ["Stop if you feel sharp pain in the inner groin."],
    contraindications: ["Inner thigh"],
  ),
  "h-banana": HipPublicEnglishText(
    purpose: "Stretch the sides of your waist and back.",
    cues: [
      "Move your hands and feet to the same side to form a banana-shaped curve.",
      "Keep both shoulders and your hips on the mat.",
      "Hold still and breathe slowly.",
      "Relax a little more with each exhale without bouncing.",
    ],
    cautions: ["Use less side bend if the stretch becomes painful."],
    contraindications: [],
  ),
  "h-band-chest-fly": HipPublicEnglishText(
    purpose:
        "Train your chest to bring your arms together in front of your body.",
    cues: [
      "Keep a slight, fixed bend in your elbows and bring your arms together in front.",
      "Anchor the band behind and to the side at chest height.",
      "Pause with your hands together, then open slowly without moving your hands behind your body.",
    ],
    cautions: [
      "Do not start unless the anchor is secure.",
      "Reduce the range or stop if the front of your shoulder hurts.",
    ],
    contraindications: ["Shoulder"],
  ),
  "h-band-face-pull": HipPublicEnglishText(
    purpose:
        "Train your upper back and rear shoulders to improve rounded-shoulder posture.",
    cues: [
      "Pull the band towards your face, lifting your elbows out to the sides.",
      "Draw your shoulder blades together without shrugging.",
      "Return slowly until your arms are straight.",
    ],
    cautions: [
      "Do not start unless the anchor is secure.",
      "Use a lighter band if your shoulder hurts.",
    ],
    contraindications: ["Shoulder"],
  ),
  "h-band-hip-extension": HipPublicEnglishText(
    purpose: "Train your glutes to push your leg backwards more strongly.",
    cues: [
      "Use your glutes to push the leg backwards while keeping your body still.",
      "Anchor the band low in front of you. Use the chair only for balance.",
      "Do not arch your lower back. Return slowly.",
    ],
    cautions: [
      "For your first attempt, start with one easy set of six repetitions.",
      "Do not attach the band to the chair.",
    ],
    contraindications: [],
  ),
  "h-band-hip-ir": HipPublicEnglishText(
    purpose: "Train hip internal-rotation strength and control.",
    cues: [
      "Keep the knee still and move the foot out to the side.",
      "Sit tall with your thigh resting on the chair seat and your hands on your thighs.",
      "Pause at the outside, then return slowly.",
    ],
    cautions: [
      "Do not start unless the anchor is secure.",
      "Use a smaller range if your hip or knee feels uncomfortable.",
    ],
    contraindications: ["Knee", "Hip"],
  ),
  "h-band-leg-out": HipPublicEnglishText(
    purpose: "Stretch your inner thighs and hamstrings.",
    cues: [
      "Keep your knee straight and let the leg lower slowly to the side.",
      "Hold the band with your hands so it supports the weight of the leg.",
      "Hold still and breathe slowly.",
      "Relax a little more with each exhale without bouncing.",
    ],
    cautions: ["Stop if you feel sharp pain in the groin."],
    contraindications: ["Inner thigh"],
  ),
  "h-band-pallof": HipPublicEnglishText(
    purpose: "Train the sides of your core to resist rotation.",
    cues: [
      "Press both hands straight forwards without allowing your body to rotate.",
      "Stand tall with your side towards the anchor and knees slightly bent.",
      "Hold the extended position for two seconds, then bring your hands back to your chest.",
    ],
    cautions: [
      "Do not start unless the anchor is secure.",
      "Use a lighter band if your lower back feels uncomfortable.",
    ],
    contraindications: ["Lower back"],
  ),
  "h-band-pull-apart": HipPublicEnglishText(
    purpose:
        "Train your upper back and rear shoulders to improve rounded-shoulder posture.",
    cues: [
      "Keep your arms straight and pull the band apart into a T shape.",
      "Draw your shoulder blades back and down.",
      "Keep your ribs from flaring and return slowly.",
    ],
    cautions: [
      "Use a lighter band if your shoulder hurts.",
      "Do not use a band with tears or cracks.",
    ],
    contraindications: ["Shoulder"],
  ),
  "h-band-row": HipPublicEnglishText(
    purpose: "Train your back for stronger pulling movements.",
    cues: [
      "Pull your elbows back close to your body.",
      "Sit tall with your legs straight and the band looped around both feet.",
      "Squeeze your shoulder blades together at the end, then straighten your arms slowly.",
    ],
    cautions: ["Bend your knees slightly if your lower back feels tight."],
    contraindications: ["Knee", "Lower back"],
  ),
  "h-band-shoulder-ir": HipPublicEnglishText(
    purpose: "Train the small, deep shoulder muscles for better stability.",
    cues: [
      "Keep your elbow against your side, bent to a right angle, and rotate your forearm towards your abdomen.",
      "Stand tall with your side towards the anchor and knees slightly bent.",
      "Pause, then rotate back slowly.",
    ],
    cautions: [
      "Do not start unless the anchor is secure.",
      "Reduce the range or stop if your shoulder hurts.",
    ],
    contraindications: ["Shoulder"],
  ),
  "h-band-standing-abduction": HipPublicEnglishText(
    purpose: "Train the outer glutes for steadier hips.",
    cues: [
      "Lift your leg to the side while keeping your upper body still.",
      "Anchor the band securely at a low point. Use the chair only for balance.",
      "Return slowly and stay within a pain-free range.",
    ],
    cautions: [
      "Do not attach the band to the chair.",
      "Stop if your hip hurts.",
    ],
    contraindications: ["Hip"],
  ),
  "h-band-standing-adduction": HipPublicEnglishText(
    purpose: "Train your inner thighs for better hip control.",
    cues: [
      "Keep your leg straight and bring it in towards the supporting leg.",
      "Anchor the band securely at a low point. Use the chair only for balance.",
      "Return slowly while keeping your pelvis level.",
    ],
    cautions: [
      "Do not attach the band to the chair.",
      "Stop if your groin hurts.",
    ],
    contraindications: ["Inner thigh"],
  ),
  "h-band-stepout": HipPublicEnglishText(
    purpose: "Train your core to resist rotation while moving.",
    cues: [
      "Keep your arms extended in front of your chest and your body facing forwards.",
      "Step out one foot at a time, then step back in one foot at a time.",
      "Keep your knees slightly bent and continue breathing.",
    ],
    cautions: [
      "Do not start unless the anchor is secure.",
      "Do not perform this move on a slippery floor or with obstacles nearby.",
    ],
    contraindications: [],
  ),
  "h-band-straight-leg-raise": HipPublicEnglishText(
    purpose: "Train the front of your hip and thigh.",
    cues: [
      "Keep a slight, fixed bend in your knee and lift your leg forwards.",
      "Do not lean your upper body back. Use the chair only for balance.",
      "Return slowly without locking your knee.",
    ],
    cautions: [
      "For your first attempt, start with one easy set of six repetitions.",
      "Anchor the band securely at a low point behind you.",
    ],
    contraindications: [],
  ),
  "h-band-triceps-pressdown": HipPublicEnglishText(
    purpose: "Train the triceps at the back of your upper arms.",
    cues: [
      "Keep your upper arms against your body and press your hands down until your elbows are straight.",
      "Do not lean forwards or move your shoulders.",
      "Pause with your arms straight, then return slowly.",
    ],
    cautions: [
      "Do not start unless the anchor is secure.",
      "Use a lighter band if your elbow hurts.",
    ],
    contraindications: [],
  ),
  "h-bent-knee-calf-raise": HipPublicEnglishText(
    purpose: "Train your calves for stronger ankles.",
    cues: [
      "Keep your knees bent as you raise your heels.",
      "Rest your hands on your hips and keep your body upright.",
      "Lower your heels slowly without changing the bend in your knees.",
    ],
    cautions: [
      "Reduce the range if your ankles or the area above your heels hurts.",
    ],
    contraindications: [],
  ),
  "h-bilateral-upper-back-hug": HipPublicEnglishText(
    purpose:
        "Stretch your upper back and the area between your shoulder blades.",
    cues: [
      "Wrap both arms forwards around yourself and round your upper back.",
      "Spread your shoulder blades apart and lower your head to relax your neck.",
      "Keep breathing and deepen the hug slightly with each exhale.",
    ],
    cautions: ["Stretch only to a comfortable level. Release if it hurts."],
    contraindications: [],
  ),
  "h-bridge-march": HipPublicEnglishText(
    purpose: "Train your glutes and hamstrings for a steadier pelvis.",
    cues: [
      "Keep your hips lifted and alternate lifting your feet.",
      "Squeeze your glutes and keep your pelvis level.",
      "Place one foot gently back on the floor before changing sides.",
      "One repetition includes both sides.",
    ],
    cautions: [
      "Lift your feet less high if your lower back feels uncomfortable.",
    ],
    contraindications: ["Lower back"],
  ),
  "h-bulgarian": HipPublicEnglishText(
    purpose: "Train the front leg and glutes to build single-leg strength.",
    cues: [
      "Lower your body straight down, with your front knee tracking towards your toes.",
      "Rest the top of your rear foot on the chair seat and keep the front heel grounded.",
      "Lower until the front thigh is roughly parallel to the floor, then push through the front heel to rise.",
    ],
    cautions: [
      "Squat less deeply if your knee feels uncomfortable.",
      "Use a stable chair without wheels.",
    ],
    contraindications: ["Knee"],
  ),
  "h-butterfly-active": HipPublicEnglishText(
    purpose: "Mobilise your hips and train inner-thigh control.",
    cues: [
      "Bring the soles of your feet together and slowly open your knees to the sides.",
      "Pause at a comfortable range.",
      "Use your inner thighs to bring your knees back together without sliding your feet.",
    ],
    cautions: ["Open less far if you feel sharp groin pain."],
    contraindications: ["Inner thigh"],
  ),
  "h-calf-raise": HipPublicEnglishText(
    purpose: "Train your calves for stronger ankles.",
    cues: [
      "Raise your heels straight up without rolling your ankles outwards.",
      "Rest your fingertips lightly on a wall for balance only.",
      "Keep your knees straight and lift your whole body in a straight line.",
    ],
    cautions: [
      "Lift less high if your ankle or Achilles tendon feels uncomfortable. Stop if pain continues.",
    ],
    contraindications: [],
  ),
  "h-catcow-quad": HipPublicEnglishText(
    purpose: "Improve spinal mobility and relax your lower back.",
    cues: [
      "Round your back and lower your head, then lift your chest and gently arch your back.",
      "Keep your hands directly under your shoulders and knees directly under your hips, without moving them.",
      "Let your head move naturally with your body; do not throw it back.",
      "Rounding your back and then lifting your chest counts as one repetition.",
    ],
    cautions: [
      "If your wrists feel uncomfortable, support yourself on your fists or choose a seated version.",
      "Use a smaller range and move slowly if your lower back or neck feels tight.",
    ],
    contraindications: ["Wrist", "Lower back", "Neck"],
  ),
  "h-chair-dip": HipPublicEnglishText(
    purpose: "Train the backs of your arms and your chest.",
    cues: [
      "Bend your elbows straight back without shrugging your shoulders.",
      "Place your hands on the front edge of the chair seat, with your knees bent and feet grounded.",
      "Lower until your upper arms are roughly parallel to the floor, then press back to straight arms.",
    ],
    cautions: [
      "Use a shallower dip or an easier version if the front of your shoulder pinches.",
      "Use a sturdy chair without wheels.",
    ],
    contraindications: ["Shoulder"],
  ),
  "h-chair-kickback": HipPublicEnglishText(
    purpose: "Train your glutes to lift your leg backwards more strongly.",
    cues: [
      "Squeeze your glutes to lift your leg backwards without arching your lower back.",
      "Hold the chair back with both hands and lean slightly forwards.",
      "Keep your pelvis level and return the foot beside the supporting foot.",
    ],
    cautions: [
      "Lift less high if your lower back feels uncomfortable. Stop if pain continues.",
      "Use a sturdy chair without wheels.",
    ],
    contraindications: ["Lower back"],
  ),
  "h-chair-lat": HipPublicEnglishText(
    purpose: "Stretch your back from the armpits down the sides of your body.",
    cues: [
      "Push your hips back and lower your chest between your arms.",
      "Hold the chair back with your arms straight and knees slightly bent.",
      "Hold still and breathe slowly.",
      "Relax a little more with each exhale without bouncing.",
    ],
    cautions: [
      "Stretch only to a comfortable level. Ease off if it hurts.",
      "Use a sturdy chair without wheels.",
    ],
    contraindications: [],
  ),
  "h-chair-progressive-front-split-native": HipPublicEnglishText(
    purpose: "Gradually stretch your hamstrings and the front of your hips.",
    cues: [
      "Rest one hand lightly on the chair and slowly slide your legs apart forwards and backwards.",
      "Slide only as far as you can control, keeping your hips facing forwards.",
      "Hold still and breathe slowly.",
      "Relax a little more with each exhale without bouncing.",
    ],
    cautions: [
      "Stretch only to a comfortable level. Ease off if it hurts.",
      "Use a sturdy chair without wheels.",
    ],
    contraindications: [],
  ),
  "h-chair-single-leg-hip-thrust": HipPublicEnglishText(
    purpose:
        "Train your glutes and hamstrings for stronger single-leg support.",
    cues: [
      "Push through one grounded foot and lift your hips until your body is level.",
      "Rest your upper back on the edge of the chair seat and lift the other leg.",
      "Keep your pelvis from dropping to one side and squeeze your glutes at the top.",
    ],
    cautions: [
      "Lift less high if your lower back feels uncomfortable. Stop if pain continues.",
      "Use a sturdy chair without wheels.",
    ],
    contraindications: ["Lower back"],
  ),
  "h-chair-sit-to-stand": HipPublicEnglishText(
    purpose: "Train your thighs and glutes to make standing up easier.",
    cues: [
      "Lean your upper body forwards, press through both feet and stand up.",
      "Reach your arms forwards to help your balance.",
      "Sit back down slowly rather than dropping onto the chair.",
    ],
    cautions: [
      "Use a sturdy chair without wheels, preferably against a wall.",
      "Choose a higher chair if your knees feel uncomfortable. Stop if pain continues.",
    ],
    contraindications: ["Knee"],
  ),
  "h-chair-step-up": HipPublicEnglishText(
    purpose: "Train the fronts of your thighs and your glutes.",
    cues: [
      "Place your whole foot on the chair seat and use that leg to step up.",
      "Alternate which leg leads, keeping your hands on your hips.",
      "Step down slowly, leading with the other foot.",
      "One repetition includes both sides.",
    ],
    cautions: [
      "Use a sturdy, non-slip chair or stool without wheels, preferably against a wall.",
      "Use a lower step if your knee collapses inwards or hurts.",
    ],
    contraindications: ["Knee"],
  ),
  "h-chair-tspine": HipPublicEnglishText(
    purpose: "Improve upper-back mobility and open your shoulders.",
    cues: [
      "Keep your hips directly above your knees and lower your chest between your arms.",
      "Place your hands flat on the chair seat with your arms straight.",
      "Do not let your lower back sag. Hold and breathe, then lift back to a flat back.",
    ],
    cautions: [
      "Stretch only to a comfortable level. Ease off if it hurts.",
      "Use a sturdy chair without wheels.",
    ],
    contraindications: [],
  ),
  "h-close-stance-forward-fold-native": HipPublicEnglishText(
    purpose: "Stretch your hamstrings and back.",
    cues: [
      "Stand with your feet together and knees slightly bent, then fold forwards from your hips.",
      "Let your arms hang naturally without forcing them towards the floor.",
      "Hold still and breathe slowly.",
      "Relax a little more with each exhale without bouncing.",
    ],
    cautions: [
      "Keep the stretch comfortable and ease back if it hurts.",
      "Rise slowly when finishing. If you feel dizzy, stop and steady yourself.",
    ],
    contraindications: [],
  ),
  "h-cobra": HipPublicEnglishText(
    purpose: "Improve spinal mobility and stretch the front of your abdomen.",
    cues: [
      "Press gently through your hands and slowly lift your chest.",
      "Keep your hips and thighs on the mat and relax your shoulders down.",
      "Hold and breathe, then lower slowly.",
    ],
    cautions: [
      "Lift less high if your lower back feels uncomfortable. Stop if pain continues.",
    ],
    contraindications: ["Lower back"],
  ),
  "h-couch-stretch": HipPublicEnglishText(
    purpose: "Stretch the front of the hip and thigh of your rear leg.",
    cues: [
      "Keep your torso upright, squeeze your glutes and move your hips forwards.",
      "Rest the top of your rear foot on a low stool, ground the front foot and place your hands on your hips.",
      "Hold still and breathe slowly.",
      "Relax a little more with each exhale without bouncing.",
    ],
    cautions: [
      "Stretch only to a comfortable level. Ease off if it hurts.",
      "Place a soft pad under your rear knee and reduce the range if the knee feels uncomfortable.",
    ],
    contraindications: ["Knee"],
  ),
  "h-crunch": HipPublicEnglishText(
    purpose: "Train your abdominal muscles.",
    cues: [
      "Curl your upper body up until your shoulder blades leave the mat.",
      "Keep your lower back on the mat and reach your hands along your thighs towards your knees.",
      "Pause, then lower slowly, one part of your back at a time.",
    ],
    cautions: [
      "Curl less high if your neck feels uncomfortable. Stop if pain continues.",
    ],
    contraindications: ["Neck"],
  ),
  "h-db-calf-raise": HipPublicEnglishText(
    purpose: "Train your calves with dumbbells for stronger ankles.",
    cues: [
      "Raise your heels straight up as high as you can.",
      "Hold dumbbells at your sides and stand tall.",
      "Keep your ankles from rolling outwards and lower slowly.",
    ],
    cautions: ["Start with a light weight and stop if it hurts."],
    contraindications: [],
  ),
  "h-db-curl": HipPublicEnglishText(
    purpose: "Train the fronts of your arms.",
    cues: [
      "Keep your upper arms against your body and move only your forearms.",
      "Alternate arms, gradually turning the palm upwards as you curl.",
      "Lower slowly without swaying your body.",
      "One repetition includes both sides.",
    ],
    cautions: [
      "Use a weight you can control. Stop if your elbow or wrist hurts.",
    ],
    contraindications: ["Wrist"],
  ),
  "h-db-floor-fly": HipPublicEnglishText(
    purpose: "Train your chest to bring your arms together more strongly.",
    cues: [
      "Keep a slight, fixed bend in your elbows as you open your arms to the sides and bring them together.",
      "Lie on your back with your knees bent, feet grounded and dumbbells above your chest.",
      "Stop when your upper arms lightly touch the floor. Do not bounce.",
    ],
    cautions: [
      "Start with a light weight and stop if it hurts.",
      "Open less far if the front of your shoulder pinches.",
    ],
    contraindications: ["Shoulder"],
  ),
  "h-db-floor-press": HipPublicEnglishText(
    purpose: "Train your chest and the backs of your arms.",
    cues: [
      "Lower slowly until your upper arms touch the floor, then press back above your shoulders.",
      "Keep your wrists directly above your elbows, with your upper arms at about 45 degrees to your torso.",
      "Pause gently on the floor without bouncing.",
    ],
    cautions: ["Start with a light weight and stop if it hurts."],
    contraindications: [],
  ),
  "h-db-front-raise": HipPublicEnglishText(
    purpose: "Train the fronts of your shoulders.",
    cues: [
      "Keep a slight, fixed bend in your elbows and lift both arms forwards to shoulder height.",
      "Do not lean back or use your legs for momentum.",
      "Lower slowly while controlling the weight.",
    ],
    cautions: [
      "Use a light weight and begin with one easy set of six repetitions.",
      "Lift less high if the front of your shoulder pinches.",
    ],
    contraindications: ["Shoulder"],
  ),
  "h-db-hammer-curl": HipPublicEnglishText(
    purpose: "Train the fronts of your upper arms and your forearms.",
    cues: [
      "Keep your palms facing each other and upper arms still, bending only your elbows.",
      "Stand tall without rocking forwards or backwards.",
    ],
    cautions: [
      "Use a light weight and begin with one easy set of six repetitions.",
    ],
    contraindications: [],
  ),
  "h-db-kickback": HipPublicEnglishText(
    purpose: "Train the backs of your arms.",
    cues: [
      "Keep your upper arms still against your body and straighten your forearms backwards.",
      "Lean forwards with a flat back and slightly bent knees.",
      "Pause with your arms straight, then bend your elbows back slowly.",
    ],
    cautions: [
      "Use a light weight and begin with one easy set of six repetitions.",
      "Raise your torso if your lower back feels uncomfortable. Stop if pain continues.",
    ],
    contraindications: ["Lower back"],
  ),
  "h-db-lateral": HipPublicEnglishText(
    purpose: "Train the sides of your shoulders.",
    cues: [
      "Keep a slight, fixed bend in your elbows and lift your arms sideways to shoulder height.",
      "Relax your shoulders down without shrugging.",
      "Lower slowly without swaying your body.",
    ],
    cautions: [
      "Start with a light weight and stop if it hurts.",
      "Lift less high if the front of your shoulder pinches.",
    ],
    contraindications: ["Shoulder"],
  ),
  "h-db-overhead-triceps-extension": HipPublicEnglishText(
    purpose:
        "Train the backs of your arms to straighten your elbows more strongly.",
    cues: [
      "Keep your upper arms still beside your ears and lift the dumbbell by straightening your elbows.",
      "Raise the dumbbell from behind your head until your arms are straight.",
      "Lower slowly behind your head and pause briefly at the bottom before lifting again.",
    ],
    cautions: [
      "Start with a light weight and stop if pain occurs.",
      "Reduce the range or choose an easier version if the front of your shoulder pinches.",
    ],
    contraindications: ["Shoulder"],
  ),
  "h-db-press": HipPublicEnglishText(
    purpose: "Train your shoulders and triceps for stronger overhead presses.",
    cues: [
      "Press up from ear height until your arms are almost straight.",
      "Keep your elbows directly below your wrists and slightly in front of your body.",
      "Keep your ribs down without leaning backwards.",
    ],
    cautions: [
      "Start with a light weight and stop if pain occurs.",
      "Reduce the range or choose an easier version if the front of your shoulder pinches.",
    ],
    contraindications: ["Shoulder"],
  ),
  "h-db-rdl": HipPublicEnglishText(
    purpose:
        "Train your hamstrings and glutes, practising a hip hinge without rounding your back.",
    cues: [
      "Push your hips back with a flat back and lower the dumbbells close to your legs.",
      "Keep your knees slightly bent without squatting down.",
      "Stop below knee level when you feel a hamstring stretch, then stand tall.",
    ],
    cautions: [
      "Start with a light weight and stop if pain occurs.",
      "Reduce the range if your lower back feels uncomfortable. Stop if pain continues.",
    ],
    contraindications: ["Lower back"],
  ),
  "h-db-reverse-fly": HipPublicEnglishText(
    purpose:
        "Train your rear shoulders and upper back to help improve rounded-shoulder posture.",
    cues: [
      "Lean forwards with a flat back and open both arms out to the sides until they are level with your back.",
      "Keep a slight, fixed bend in your elbows and squeeze your shoulder blades together.",
      "Lower slowly without shrugging or swinging.",
    ],
    cautions: [
      "Start with a light weight and stop if pain occurs.",
      "Reduce the range if your lower back feels uncomfortable. Stop if pain continues.",
    ],
    contraindications: ["Lower back"],
  ),
  "h-db-row": HipPublicEnglishText(
    purpose: "Train your back for stronger pulling movements.",
    cues: [
      "Pull your elbow up and back close to your body, bringing the dumbbell beside your ribs.",
      "Support one hand on the chair seat and keep your back flat without twisting.",
      "Draw your shoulder blade back, pause, then lower slowly.",
    ],
    cautions: [
      "Start with a light weight and stop if pain occurs.",
      "If the chair slides, replace it with a stable chair without wheels.",
    ],
    contraindications: [],
  ),
  "h-db-split-squat": HipPublicEnglishText(
    purpose: "Train your thighs and glutes to build single-leg strength.",
    cues: [
      "Keep your feet fixed in a split stance and lower your body straight down.",
      "Keep the whole front foot grounded and the front knee tracking towards your toes.",
      "Push through the front foot to stand, keeping your torso upright.",
    ],
    cautions: [
      "Start with a light weight and stop if pain occurs.",
      "Squat less deeply if your knee feels uncomfortable. Stop if pain continues.",
    ],
    contraindications: ["Knee"],
  ),
  "h-db-supported-calf-raise": HipPublicEnglishText(
    purpose:
        "Train your calves with added weight and wall support for balance.",
    cues: [
      "Support one hand on a wall, hold a dumbbell in the other and raise your heels.",
      "Stand tall without rolling your ankles outwards.",
      "Pause at the top, then lower slowly.",
    ],
    cautions: ["Start with a light weight and stop if pain occurs."],
    contraindications: [],
  ),
  "h-dd-shoulder": HipPublicEnglishText(
    purpose: "Open your shoulders and stretch your armpits and chest.",
    cues: [
      "Keep your arms straight and move your chest towards your thighs.",
      "Lift your hips high, lengthen your back and let your heels lower towards the floor.",
      "Hold still and breathe slowly.",
      "Relax a little more with each exhale without bouncing.",
    ],
    cautions: [
      "Ease off if pain occurs and stretch only to a comfortable level.",
      "Stop if you feel sharp wrist pain or numbness. Warm up your wrists first.",
    ],
    contraindications: ["Wrist"],
  ),
  "h-donkey-kick": HipPublicEnglishText(
    purpose: "Train your glutes to lift your leg backwards more strongly.",
    cues: [
      "Keep your knee bent to a right angle and press the sole of your foot towards the ceiling.",
      "Keep your hands and supporting knee steady without moving your body.",
      "Keep your lower back from sagging and return slowly.",
    ],
    cautions: [
      "Reduce the range if your lower back feels uncomfortable. Stop if pain continues.",
      "Stop if you feel sharp wrist pain or numbness. Warm up your wrists first.",
    ],
    contraindications: ["Lower back", "Wrist"],
  ),
  "h-doorframe-forearms-pec-native-r3": HipPublicEnglishText(
    purpose: "Stretch your chest and the fronts of your shoulders.",
    cues: [
      "Rest both forearms against the doorframe and slowly move your body forwards through the doorway.",
      "Stand steadily in a split stance without moving your feet.",
      "Hold still and breathe slowly.",
      "Relax a little more with each exhale without bouncing.",
    ],
    cautions: [
      "Ease off if pain occurs and stretch only to a comfortable level.",
      "Reduce the range or choose an easier version if the front of your shoulder pinches.",
    ],
    contraindications: ["Shoulder"],
  ),
  "h-fixed-bar-vertical-pull": HipPublicEnglishText(
    purpose: "Train your back and arms as a foundation for a full pull-up.",
    cues: [
      "Grip the bar with both hands and bend your elbows to pull your body up.",
      "Pull only to a comfortable height without shrugging towards your ears.",
      "Lower slowly until your arms are straight.",
    ],
    cautions: [
      "Reduce the range or choose an easier version if the front of your shoulder pinches.",
      "Do not perform this move unless the bar is securely installed.",
    ],
    contraindications: ["Shoulder"],
  ),
  "h-forearm-plank": HipPublicEnglishText(
    purpose: "Train your abs and side core for a steadier trunk.",
    cues: [
      "Place your elbows directly below your shoulders and form a straight line from head to heels.",
      "Tighten your glutes and abdomen without lifting or dropping your hips.",
      "Breathe evenly without holding your breath.",
    ],
    cautions: [
      "Shorten the hold or use a kneeling version if your lower back hurts.",
    ],
    contraindications: ["Lower back"],
  ),
  "h-forward-lunge": HipPublicEnglishText(
    purpose: "Train your thighs and glutes for better single-leg control.",
    cues: [
      "Step forwards and lower your body straight down.",
      "Track the front knee towards your toes and keep the front heel grounded.",
      "Push through the front foot to return to standing, then change legs.",
      "One repetition includes both sides.",
    ],
    cautions: [
      "Squat less deeply if your knee feels uncomfortable. Stop if pain continues.",
    ],
    contraindications: ["Knee"],
  ),
  "h-goblet-squat": HipPublicEnglishText(
    purpose:
        "Train your thighs and glutes with added weight for a steadier squat.",
    cues: [
      "Hold the kettlebell at your chest and sit your hips back and down.",
      "Track your knees towards your toes and keep your heels grounded.",
      "Keep your chest lifted and the kettlebell close to your body.",
    ],
    cautions: [
      "Squat less deeply if your knee feels uncomfortable. Stop if pain continues.",
      "Start with a light weight and stop if pain occurs.",
    ],
    contraindications: ["Knee"],
  ),
  "h-good-morning": HipPublicEnglishText(
    purpose:
        "Train your hamstrings and lower back, practising a hip hinge without rounding your back.",
    cues: [
      "Push your hips back and tilt your torso forwards as one straight unit.",
      "Cross your hands over your chest and keep your knees slightly bent.",
      "Stop when your torso is close to horizontal and you feel a hamstring stretch.",
    ],
    cautions: [
      "Reduce the range if your lower back feels uncomfortable. Stop if pain continues.",
    ],
    contraindications: ["Lower back"],
  ),
  "h-hip-gate": HipPublicEnglishText(
    purpose: "Mobilise your hips for easier outward opening and rotation.",
    cues: [
      "Lift your knee to hip height, circle it outwards and lower it.",
      "Hold the chair back with one hand and keep your pelvis and torso facing forwards.",
      "One circle counts as one repetition. Reverse direction for the next circle.",
    ],
    cautions: [
      "Reduce the range if your hip feels uncomfortable. Stop if pain continues.",
      "If the chair slides, replace it with a stable chair without wheels.",
    ],
    contraindications: ["Hip"],
  ),
  "h-incline-pushup": HipPublicEnglishText(
    purpose: "Train your chest and arms with a beginner-friendly push-up.",
    cues: [
      "Keep your body in a straight line and lower your chest towards the bench edge.",
      "Angle your elbows backwards rather than flaring them out to the sides.",
      "Push back up until your arms are straight.",
    ],
    cautions: [
      "Stop if you feel sharp wrist pain or numbness. Warm up your wrists first.",
      "Do not use a bench that slides. Choose a stable one.",
    ],
    contraindications: ["Wrist"],
  ),
  "h-knee-hug": HipPublicEnglishText(
    purpose: "Relax your lower back and glutes.",
    cues: [
      "Hold your knees with both hands and draw them gently towards your chest.",
      "Relax your head and shoulders onto the floor.",
      "Hold still and breathe slowly.",
      "Relax a little more with each exhale without bouncing.",
    ],
    cautions: [
      "Ease off if pain occurs and stretch only to a comfortable level.",
    ],
    contraindications: [],
  ),
  "h-knee-wall-dorsiflexion-native": HipPublicEnglishText(
    purpose: "Improve forward ankle movement for easier squatting and walking.",
    cues: [
      "Keep the front heel grounded and move your knee forwards to touch the wall.",
      "Track your knee towards your second and third toes.",
      "Let your arms rest naturally at your sides and move your body forwards with your knee.",
    ],
    cautions: [
      "Reduce the range if the front of your ankle pinches. Stop if pain continues.",
    ],
    contraindications: [],
  ),
  "h-kneeling-instep-stretch": HipPublicEnglishText(
    purpose: "Stretch the tops of your feet and the fronts of your lower legs.",
    cues: [
      "Kneel with the tops of your feet on the floor and slowly sit back.",
      "Hold still and breathe slowly.",
      "Relax a little more with each exhale without bouncing.",
    ],
    cautions: [
      "Ease off if pain occurs and stretch only to a comfortable level.",
      "Use a soft pad or sit back less far if your knees or the tops of your feet feel uncomfortable.",
    ],
    contraindications: ["Knee"],
  ),
  "h-kneeling-pushup": HipPublicEnglishText(
    purpose: "Train your chest and arms with a beginner-friendly push-up.",
    cues: [
      "Keep your knees grounded and lower with a straight line from your head to your knees.",
      "Angle your elbows backwards rather than flaring them out to the sides.",
      "Push back up until your arms are straight.",
    ],
    cautions: [
      "Stop if you feel sharp wrist pain or numbness. Warm up your wrists first.",
    ],
    contraindications: ["Wrist"],
  ),
  "h-lateral-step-lunge": HipPublicEnglishText(
    purpose:
        "Train your thighs, glutes and inner thighs for steadier sideways movement.",
    cues: [
      "Step to the side and sit your hips back over that leg.",
      "Keep the other leg straight and both sets of toes facing forwards.",
      "Push through the stepping foot to return to standing, then change sides.",
      "One repetition includes both sides.",
    ],
    cautions: [
      "Squat less deeply if your knee feels uncomfortable. Stop if pain continues.",
    ],
    contraindications: ["Knee"],
  ),
  "h-overhead-triceps-stretch": HipPublicEnglishText(
    purpose: "Stretch the backs of your upper arms and your shoulders.",
    cues: [
      "Raise one arm overhead and bend its elbow, gently pressing that elbow with the other hand.",
      "Stand tall without pushing your head forwards.",
      "Hold still and breathe slowly.",
      "Relax a little more with each exhale without bouncing.",
    ],
    cautions: [
      "Ease off if pain occurs and stretch only to a comfortable level.",
    ],
    contraindications: [],
  ),
  "h-plank-side-step": HipPublicEnglishText(
    purpose:
        "Train your core to keep your body steady as your feet change position.",
    cues: [
      "Start in a high plank, tap one foot out to the side, then bring it back.",
      "Keep your hips facing the floor without swaying from side to side.",
      "Keep your hands still and alternate tapping your feet.",
      "One repetition includes both sides.",
    ],
    cautions: [
      "Stop if you feel sharp wrist pain or numbness. Warm up your wrists first.",
      "Reduce the range or choose an easier version if the front of your shoulder pinches.",
    ],
    contraindications: ["Wrist", "Shoulder"],
  ),
  "h-quad-cars": HipPublicEnglishText(
    purpose:
        "Improve hip mobility with slow circles through your available range.",
    cues: [
      "Lift your knee and draw the largest circle you can control.",
      "Keep your hips and back still so only the leg rotates.",
      "One circle counts as one repetition. Reverse direction for the next circle.",
    ],
    cautions: [
      "Reduce the range if your hip feels uncomfortable. Stop if pain continues.",
      "Stop if you feel sharp wrist pain or numbness. Warm up your wrists first.",
    ],
    contraindications: ["Hip", "Wrist"],
  ),
  "h-quadruped-open": HipPublicEnglishText(
    purpose: "Improve upper-back rotation and open your chest.",
    cues: [
      "Support one hand on the floor and open the other arm towards the ceiling.",
      "Follow your hand with your eyes and rotate your chest open.",
      "Keep your hips still.",
    ],
    cautions: [
      "Ease off if pain occurs and stretch only to a comfortable level.",
      "Stop if you feel sharp wrist pain or numbness. Warm up your wrists first.",
    ],
    contraindications: ["Wrist"],
  ),
  "h-quadruped-rockback": HipPublicEnglishText(
    purpose:
        "Mobilise your hips while practising sitting back with a flat back.",
    cues: [
      "Keep your back flat and sit your hips towards your heels.",
      "Keep your hands in place and your arms straight.",
      "Stop just before your back begins to round, then return forwards.",
    ],
    cautions: [
      "Reduce the range if your hip feels uncomfortable. Stop if pain continues.",
      "Stop if you feel sharp wrist pain or numbness. Warm up your wrists first.",
    ],
    contraindications: ["Hip", "Wrist"],
  ),
  "h-reverse-clam": HipPublicEnglishText(
    purpose: "Train your glutes for better control of hip internal rotation.",
    cues: [
      "Keep your knees together and lift the upper foot away from the lower foot.",
      "Do not roll your hips backwards.",
      "Pause at the top, then lower slowly.",
    ],
    cautions: [
      "Reduce the range if your hip feels uncomfortable. Stop if pain continues.",
    ],
    contraindications: ["Hip"],
  ),
  "h-reverse-crunch": HipPublicEnglishText(
    purpose: "Train your lower abdominal muscles.",
    cues: [
      "Use your lower abs to curl your hips off the mat and bring your knees towards your chest.",
      "Press your hands into the floor and keep your upper back on the mat.",
      "Return slowly without letting your feet drop.",
    ],
    cautions: [
      "Reduce the range if your lower back feels uncomfortable. Stop if pain continues.",
    ],
    contraindications: ["Lower back"],
  ),
  "h-russian-twist": HipPublicEnglishText(
    purpose: "Train your side abs for better rotational control.",
    cues: [
      "Lean your torso back with a straight back and slowly turn your chest to one side.",
      "Keep your knees and hips facing forwards and your heels grounded.",
      "Return to the centre, then turn to the other side.",
      "One repetition includes both sides.",
    ],
    cautions: [
      "Reduce the range if your lower back feels uncomfortable. Stop if pain continues.",
    ],
    contraindications: ["Lower back"],
  ),
  "h-seated-reachback": HipPublicEnglishText(
    purpose: "Stretch your chest and the fronts of your shoulders.",
    cues: [
      "Keep both hands fixed behind you and slide your hips forwards slowly.",
      "Point your fingers backwards, straighten your arms and lift your chest.",
      "Hold still and breathe slowly.",
      "Relax a little more with each exhale without bouncing.",
    ],
    cautions: [
      "Ease off if pain occurs and stretch only to a comfortable level.",
      "Stop if you feel sharp wrist pain or numbness. Warm up your wrists first.",
    ],
    contraindications: ["Wrist"],
  ),
  "h-short-side-plank": HipPublicEnglishText(
    purpose:
        "Train your side abs and outer glutes with a beginner-friendly side plank.",
    cues: [
      "Support yourself on your forearm and knees, lifting your hips into a straight line.",
      "Place your elbow directly below your shoulder and push firmly into the floor.",
      "Breathe normally without letting your hips drop.",
    ],
    cautions: [
      "Reduce the range or choose an easier version if the front of your shoulder pinches.",
    ],
    contraindications: ["Shoulder"],
  ),
  "h-side-er": HipPublicEnglishText(
    purpose: "Train the small, deep shoulder muscles for better stability.",
    cues: [
      "Keep your elbow against your body and rotate your forearm upwards and outwards.",
      "You may place a towel under your elbow. Do not roll your body backwards.",
      "Pause at the top, then lower slowly.",
    ],
    cautions: [
      "Reduce the range or choose an easier version if the front of your shoulder pinches.",
      "If adding resistance, a bottle of water is enough.",
    ],
    contraindications: ["Shoulder"],
  ),
  "h-side-leg-raise": HipPublicEnglishText(
    purpose: "Train the outer glutes for steadier single-leg standing.",
    cues: [
      "Lift your straight leg to the side with your toes facing forwards.",
      "Place your hands on your waist and do not lean your upper body to the opposite side.",
      "Pause at the top, then lower slowly.",
    ],
    cautions: [
      "Reduce the range if your hip feels uncomfortable. Stop if pain continues.",
    ],
    contraindications: ["Hip"],
  ),
  "h-slider-body-saw": HipPublicEnglishText(
    purpose:
        "Train your core to keep your lower back steady as your body lengthens.",
    cues: [
      "Keep both hands fixed and slide both feet backwards together, then bring them back.",
      "Keep your elbows and knees mostly straight and move your body as one unit.",
      "Slide only as far as you can control without letting your lower back sag.",
    ],
    cautions: [
      "First be able to hold a pain-free high plank. Begin with one set of four repetitions.",
      "Stop if your wrists, shoulders or lower back hurt.",
    ],
    contraindications: ["Lower back", "Shoulder", "Wrist"],
  ),
  "h-squat": HipPublicEnglishText(
    purpose:
        "Train your thighs and glutes to make squatting and standing easier.",
    cues: [
      "Sit your hips back, with your knees tracking towards your toes.",
      "Keep your heels grounded and your chest lifted.",
      "Squat until your thighs are roughly parallel to the floor, then push through the floor to stand.",
    ],
    cautions: [
      "Squat less deeply if your knee feels uncomfortable. Stop if pain continues.",
    ],
    contraindications: ["Knee"],
  ),
  "h-standing-forearm-rotation": HipPublicEnglishText(
    purpose:
        "Mobilise your forearms for easier, more controlled palm rotation.",
    cues: [
      "Keep your upper arms still and turn your palms upwards, then downwards.",
      "Keep your elbows bent at your sides and your wrists straight.",
      "Turning to one end of the range counts as one repetition. Pause at each end and rotate slowly.",
    ],
    cautions: ["Reduce the range if pain occurs. Stop if pain continues."],
    contraindications: [],
  ),
  "h-standing-wrist-deviation": HipPublicEnglishText(
    purpose:
        "Mobilise your wrists and practise controlled side-to-side movement.",
    cues: [
      "Face your palms down and move your wrists towards the thumbs, then towards the little fingers.",
      "Keep your bent elbows still and do not rotate your forearms.",
      "Moving to one side counts as one repetition. Move slowly and gently without forcing the range.",
    ],
    cautions: ["Reduce the range if pain occurs. Stop if pain continues."],
    contraindications: [],
  ),
  "h-standing-wrist-extensor-stretch": HipPublicEnglishText(
    purpose:
        "Stretch the back-of-hand side of your forearms to relax your wrists.",
    cues: [
      "Reach one arm forwards with the palm facing down and slowly bend the wrist downwards.",
      "Keep your elbow straight without locking it, and do not push with the other hand.",
      "Relax your shoulder, pause at each stretch, then slowly release your wrist.",
    ],
    cautions: [
      "Ease off if pain occurs and stretch only to a comfortable level.",
    ],
    contraindications: [],
  ),
  "h-step-jack": HipPublicEnglishText(
    purpose:
        "Raise your heart rate and coordinate your whole body with a low-impact, no-jump jack.",
    cues: [
      "Step one foot to the side while raising both arms overhead.",
      "Land on the toes first, then place the whole foot down.",
      "Bring the foot back in and lower your arms, then lead with the other foot.",
      "One repetition includes both sides.",
    ],
    cautions: ["Stop and rest if you feel dizzy or have pain."],
    contraindications: [],
  ),
  "h-straight-arm-hang-native": HipPublicEnglishText(
    purpose: "Train your grip and gently lengthen the sides of your back.",
    cues: [
      "Hold the bar with both hands and let your body hang naturally with straight arms.",
      "Keep your body still without swinging.",
      "Place your feet securely before releasing the bar, rather than waiting until your grip fails.",
    ],
    cautions: [
      "Shorten the hold or keep your feet grounded to share your weight if your shoulder hurts.",
      "Do not hang if the bar is insecure or there is no safe place to put your feet.",
    ],
    contraindications: ["Shoulder"],
  ),
  "h-suitcase-hold": HipPublicEnglishText(
    purpose:
        "Train your side core to stay upright while carrying weight in one hand.",
    cues: [
      "Stand tall holding a dumbbell in one hand, without leaning to either side.",
      "Keep both shoulders level and breathe normally.",
      "When the hold ends, lower the weight slowly and repeat with the other hand.",
    ],
    cautions: [
      "Stop if your lower back or shoulder hurts and choose a lighter dumbbell.",
    ],
    contraindications: ["Lower back", "Shoulder"],
  ),
  "h-suitcase-march": HipPublicEnglishText(
    purpose:
        "Train your side core and glutes for steadier movement while carrying weight in one hand.",
    cues: [
      "Hold a dumbbell in one hand and alternate lifting your knees while keeping your pelvis level.",
      "Keep your torso upright without leaning to one side.",
      "You do not need to lift your knee high. Shift your weight onto the supporting foot before lifting.",
      "One repetition includes both knee lifts. Switch the carrying hand for the next set.",
    ],
    cautions: [
      "Stop if your lower back or shoulder hurts and choose a lighter dumbbell.",
    ],
    contraindications: ["Lower back", "Shoulder"],
  ),
  "h-sumo-pry": HipPublicEnglishText(
    purpose: "Open your hips and stretch your inner thighs.",
    cues: [
      "Bring your palms together and use your elbows to gently press your knees outwards.",
      "Stand wide with your toes turned out and heels grounded.",
      "Lift your chest, pause in the squat, then stand up.",
    ],
    cautions: [
      "Squat less deeply if your knee feels uncomfortable. Stop if pain continues.",
    ],
    contraindications: ["Knee"],
  ),
  "h-superman": HipPublicEnglishText(
    purpose: "Train your back and glutes to strengthen the back of your body.",
    cues: [
      "Lift your arms, chest and both legs off the mat together.",
      "Keep your abdomen on the mat and your eyes looking at the mat.",
      "Pause at the top, then lower slowly.",
    ],
    cautions: [
      "Reduce the range if your lower back feels uncomfortable. Stop if pain continues.",
    ],
    contraindications: ["Lower back"],
  ),
  "h-supine-bilateral-leg-raise": HipPublicEnglishText(
    purpose: "Train your abs and the fronts of your hips.",
    cues: [
      "Lift both straight legs together while keeping your lower back on the mat.",
      "Keep your head, upper back and hips on the mat.",
      "Lower slowly without arching your lower back.",
    ],
    cautions: [
      "Reduce the range if your lower back feels uncomfortable. Stop if pain continues.",
    ],
    contraindications: ["Lower back"],
  ),
  "h-supine-heel-slide": HipPublicEnglishText(
    purpose: "Mobilise your hips and knees while training abdominal stability.",
    cues: [
      "Keep your heel on the floor and slowly slide it away, then slide it back.",
      "Keep your lower back on the mat and your pelvis still.",
      "Keep the other foot securely grounded.",
    ],
    cautions: ["Reduce the range if pain occurs. Stop if pain continues."],
    contraindications: [],
  ),
  "h-supine-twist": HipPublicEnglishText(
    purpose: "Relax your lower back and stretch the sides of your body.",
    cues: [
      "Let both knees lower slowly to one side while keeping both shoulders on the mat.",
      "Rest your arms on the mat in a T shape.",
      "Hold still and breathe slowly.",
      "Relax a little more with each exhale without bouncing.",
    ],
    cautions: [
      "Ease off if pain occurs and stretch only to a comfortable level.",
    ],
    contraindications: [],
  ),
  "h-supported-single-leg-calf": HipPublicEnglishText(
    purpose: "Build single-leg calf strength.",
    cues: [
      "Stand on one foot and raise your heel onto the ball of the foot.",
      "Use a wall for balance and keep your pelvis level.",
      "Pause at the top, then lower slowly.",
    ],
    cautions: [
      "Reduce the range if your ankle or heel feels uncomfortable. Stop if pain continues.",
    ],
    contraindications: [],
  ),
  "h-tabletop": HipPublicEnglishText(
    purpose: "Train your glutes and shoulders while opening your chest.",
    cues: [
      "Push through your hands and heels to lift your hips level with your shoulders and knees.",
      "Point your fingers towards your feet and keep your arms straight.",
      "Open your chest and draw your shoulder blades together.",
    ],
    cautions: [
      "Stop if you feel sharp wrist pain or numbness. Warm up your wrists first.",
      "Reduce the range or choose an easier version if the front of your shoulder pinches.",
    ],
    contraindications: ["Wrist", "Shoulder"],
  ),
  "h-tib-raise": HipPublicEnglishText(
    purpose:
        "Train the fronts of your lower legs to lift your toes more strongly when walking and running.",
    cues: [
      "Keep your heels grounded and lift your toes towards your shins.",
      "Rest your back and hips against the wall with your legs straight.",
      "Pause, then lower slowly without slapping the floor.",
    ],
    cautions: ["Reduce the range if pain occurs. Stop if pain continues."],
    contraindications: [],
  ),
  "h-unsupported-star-reach-native": HipPublicEnglishText(
    purpose: "Train single-leg balance and glute control.",
    cues: [
      "Stand steadily on one leg and lightly tap the other foot forwards, sideways and backwards.",
      "Do not shift your weight onto the tapping foot, and keep your pelvis level.",
      "Keep the supporting knee slightly bent and tracking towards your toes.",
    ],
    cautions: ["Hold a wall or chair back if you feel unsteady."],
    contraindications: [],
  ),
  "h-wall-angel": HipPublicEnglishText(
    purpose:
        "Improve overhead shoulder control and open your upper back and shoulders.",
    cues: [
      "Keep your forearms against the wall and slide your arms from a W into a Y.",
      "Keep the back of your head, your back and hips against the wall, with your ribs down.",
      "Slide up until your elbows are almost straight, then return slowly to the W.",
    ],
    cautions: [
      "Slide less high if your shoulder hurts. Stop if pain continues.",
    ],
    contraindications: ["Shoulder"],
  ),
  "h-wall-calf": HipPublicEnglishText(
    purpose: "Stretch the backs of your calves to improve ankle mobility.",
    cues: [
      "Keep the rear leg straight and its heel down as you move your hips towards the wall.",
      "Point the rear toes directly towards the wall and maintain a straight line from your heel to your head.",
      "Hold still and breathe slowly.",
      "Relax a little more with each exhale without bouncing.",
    ],
    cautions: ["Lean forwards less far if it hurts. Stop if pain continues."],
    contraindications: [],
  ),
  "h-wall-calf-bent-knee": HipPublicEnglishText(
    purpose:
        "Stretch the deeper, lower calf muscles to improve ankle mobility.",
    cues: [
      "Keep the rear heel grounded and bend both knees slightly as you lower forwards and down.",
      "Use a short split stance and support both hands on the wall.",
      "Hold still and breathe slowly.",
      "Relax a little more with each exhale without bouncing.",
    ],
    cautions: [
      "On a slippery floor, wear non-slip shoes and steady yourself firmly on the wall.",
      "Reduce the range if it hurts. Stop if pain continues.",
    ],
    contraindications: [],
  ),
  "h-wall-straddle": HipPublicEnglishText(
    purpose: "Use gravity to gradually open your inner thighs.",
    cues: [
      "Rest your legs against the wall and slowly slide them apart into a V.",
      "Lie on your back with your hips close to the wall and your heels supported on it.",
      "Hold still and breathe slowly, relaxing a little more with each exhale.",
      "Do not bounce. A stretch is enough; do not push into pain.",
    ],
    cautions: [
      "Open less far if your inner thighs or hips hurt. Stop if pain continues.",
    ],
    contraindications: ["Hip", "Inner thigh"],
  ),
  "h-wall-wrist-flexor-stretch": HipPublicEnglishText(
    purpose: "Gently stretch your wrists and inner forearms.",
    cues: [
      "Place your palm against the wall with fingers pointing up and slowly lean your body backwards.",
      "Stand steadily and keep your elbow straight without locking it.",
      "Hold still and breathe slowly, relaxing a little more with each exhale.",
      "Do not bounce. Aim for a mild stretch rather than pressing hard into the wall.",
    ],
    cautions: ["Stop if your wrist hurts or your fingers feel numb."],
    contraindications: ["Wrist"],
  ),
  "hamstrings-A": HipPublicEnglishText(
    purpose:
        "Train your hamstrings and glutes for steadier single-leg standing.",
    cues: [
      "Keep the supporting knee slightly bent, hinge your torso forwards and lift the other leg backwards.",
      "Keep the rear leg in line with your torso and your pelvis level.",
      "Let your arms hang naturally and keep your back flat.",
    ],
    cautions: [
      "Lean forwards less far if your lower back feels tight or hurts. Stop if pain continues.",
    ],
    contraindications: ["Lower back"],
  ),
  "hamstrings-B": HipPublicEnglishText(
    purpose:
        "Train your hamstrings by extending and curling your heels while holding a bridge.",
    cues: [
      "Keep your hips lifted and slowly slide your heels away, then pull them back.",
      "Lie on your back with your hips raised and heels resting on sliders.",
      "Bring your heels back below your knees and squeeze your glutes.",
    ],
    cautions: ["The hamstrings may cramp. If they do, stop and rest."],
    contraindications: [],
  ),
  "hamstrings-C": HipPublicEnglishText(
    purpose:
        "Build hamstring strength through a controlled forward lean and return to help reduce strains.",
    cues: [
      "Keep a straight line from your knees to your head and lower forwards as slowly as possible.",
      "Keep your heels securely hooked and your hands in front of your chest for protection.",
      "Use your hamstrings to pull your body back upright.",
    ],
    cautions: [
      "Beginners should lean forwards only a little. Seek professional advice first if you have previously strained a hamstring.",
    ],
    contraindications: [],
  ),
  "hip-abductors-A": HipPublicEnglishText(
    purpose:
        "Train the outer glutes to lift your leg sideways while holding a side plank.",
    cues: [
      "Support yourself on your forearm in a straight body line and lift the upper leg.",
      "Keep the upper leg straight and its toes facing forwards rather than turning outwards.",
      "Place your elbow directly below your shoulder and lift and lower slowly.",
    ],
    cautions: [
      "Use a bent-knee side plank or fewer repetitions if your shoulder hurts. Stop if pain continues.",
    ],
    contraindications: ["Knee", "Shoulder"],
  ),
  "hip-abductors-B": HipPublicEnglishText(
    purpose:
        "Train your outer glutes by opening your raised legs against a resistance band.",
    cues: [
      "Keep both legs straight and press them apart against the band into a wide V.",
      "Lie on your back with your legs vertical and your lower back on the floor.",
      "Pause for two seconds at your widest range, then bring your legs together.",
    ],
    cautions: ["Open less far if your hip hurts. Stop if pain continues."],
    contraindications: ["Hip"],
  ),
  "hip-abductors-C": HipPublicEnglishText(
    purpose:
        "Use a machine to progressively load outward hip movement and train outer-glute strength and endurance.",
    cues: [
      "Rest securely against the backrest and press the pads apart with the outsides of your knees.",
      "Pause for one second at the widest point, then return slowly.",
      "Hold the handles and keep your body from rocking forwards or backwards.",
    ],
    cautions: [
      "Use less weight or a smaller range if your hip hurts. Stop if pain continues.",
    ],
    contraindications: ["Hip"],
  ),
  "hip-flexors-A": HipPublicEnglishText(
    purpose:
        "Train the fronts of your hips by lifting your legs while leaning forwards.",
    cues: [
      "Lean forwards and lift both straight legs a few centimetres off the floor.",
      "Sit on the floor with your legs straight and together and your hands beside your knees.",
      "Hold the lifted position, then lower slowly.",
    ],
    cautions: [
      "Stop and rest if the front of your thigh cramps or your hip hurts.",
    ],
    contraindications: ["Hip"],
  ),
  "hip-flexors-B": HipPublicEnglishText(
    purpose: "Add band resistance to train stronger knee lifts.",
    cues: [
      "Stand tall with wall support and lift your knee above hip height.",
      "Pause for two seconds at the top without leaning backwards or bending at your waist.",
      "Place your foot back in its starting position.",
    ],
    cautions: [
      "Lift your knee less high if the front of your hip hurts. Stop if pain continues.",
    ],
    contraindications: ["Knee", "Hip"],
  ),
  "hip-flexors-C": HipPublicEnglishText(
    purpose: "Train the fronts of your hips with a straight-leg forward lift.",
    cues: [
      "Keep your knee straight and lift your leg as high as you can control.",
      "Attach the low cable to your ankle and stand tall.",
      "Pause briefly at the top, then lower slowly.",
    ],
    cautions: [
      "Lift less high if your lower back feels tight or hurts. Stop if pain continues.",
    ],
    contraindications: ["Lower back"],
  ),
  "lats-A": HipPublicEnglishText(
    purpose:
        "Train the sides of your back by pushing through straight arms and depressing your shoulders.",
    cues: [
      "Keep your arms straight and press your shoulders down to lift your hips.",
      "Sit on the floor with your legs straight and your hands beside your hips.",
      "Pause for two seconds at the top, keeping your shoulders away from your ears.",
    ],
    cautions: [
      "Warm up your wrists first. Stop if you feel sharp wrist pain or numbness.",
    ],
    contraindications: ["Wrist"],
  ),
  "lats-B": HipPublicEnglishText(
    purpose: "Train the sides of your back with a straight-arm band pulldown.",
    cues: [
      "Keep your arms straight and pull down from in front of you to beside your thighs.",
      "Lower your shoulders as you pull, without shrugging.",
      "Pause for one second at the bottom, then return slowly to the front.",
    ],
    cautions: [
      "Use a smaller range or a lighter band if your shoulder hurts. Stop if pain continues.",
    ],
    contraindications: ["Shoulder"],
  ),
  "lats-C": HipPublicEnglishText(
    purpose:
        "Train back and shoulder stability on parallel bars by lifting through shoulder depression alone.",
    cues: [
      "Keep your arms straight and press your shoulders down to raise your body.",
      "As you relax, let your shoulders rise slowly towards your ears without bending your elbows.",
      "Pause for one second at the top with your legs straight and together.",
    ],
    cautions: [
      "Shorten the hold or choose an easier version if the front of your shoulder pinches.",
    ],
    contraindications: ["Shoulder"],
  ),
  "n-chair-wiper": HipPublicEnglishText(
    purpose:
        "Relax your hips while seated, suitable for a break from prolonged sitting.",
    cues: [
      "Keep your feet grounded and let one knee lower slowly inwards.",
      "Sit on the front third of the chair with your feet wider than hip-width apart.",
      "Pause and return to the middle, then change sides.",
      "One repetition includes both sides.",
    ],
    cautions: [
      "Use a smaller range if your knee or hip hurts. Stop if pain continues.",
    ],
    contraindications: ["Knee", "Hip"],
  ),
  "n-half-split": HipPublicEnglishText(
    purpose:
        "Stretch the hamstrings of the front leg as a foundation for a front split.",
    cues: [
      "Sit your hips back, straighten the front leg and lengthen your back.",
      "Keep the rear knee grounded and the front heel down, with your toes drawn up.",
      "Hold still and breathe slowly, relaxing a little more with each exhale.",
      "Do not bounce. A stretch is enough; do not push into pain.",
    ],
    cautions: [
      "Place a soft pad under the kneeling knee.",
      "Sit back less far if your hamstring hurts. Stop if pain continues.",
    ],
    contraindications: ["Knee"],
  ),
  "n-leg-circles": HipPublicEnglishText(
    purpose: "Train hip control in multiple directions.",
    cues: [
      "Keep your pelvis and the other leg still while slowly circling the straight leg.",
      "Lie on your back with your arms at your sides and palms on the floor.",
      "One circle followed by the crossing movement counts as one repetition. Stop the range before your pelvis begins to turn.",
    ],
    cautions: [
      "Make the circle smaller if your hip hurts or clicks uncomfortably. Stop if pain continues.",
    ],
    contraindications: ["Hip"],
  ),
  "n-pelvis-circle": HipPublicEnglishText(
    purpose:
        "Mobilize the hips and lower back for a quick release after prolonged sitting.",
    cues: [
      "Keep both feet planted and slowly trace large circles with your pelvis.",
      "Stand with your feet slightly wider than hip-width, knees soft and hands on your hips.",
      "One circle counts as 1 rep. Change direction after each circle and keep your shoulders as level as possible.",
    ],
    cautions: [
      "If your lower back hurts, make smaller circles; stop if pain persists.",
    ],
    contraindications: ["Lower back"],
  ),
  "n-prone-hip-ext": HipPublicEnglishText(
    purpose:
        "Strengthen the glutes to lift the thigh backward, useful after prolonged sitting and for the rear leg in splits.",
    cues: [
      "Squeeze your glute to lift the thigh off the floor without arching your lower back.",
      "Lie on your stomach with one knee bent to 90 degrees and the sole facing the ceiling.",
      "Lift only a few centimeters, hold for 2 seconds, then lower.",
    ],
    cautions: [
      "If your lower back hurts, lift less high; stop if pain persists.",
    ],
    contraindications: ["Lower back"],
  ),
  "n-prone-ir": HipPublicEnglishText(
    purpose: "Gently mobilize the hips for smoother inward thigh rotation.",
    cues: [
      "Keep your knees and pelvis on the floor as your lower legs open out to the sides.",
      "Lie on your stomach with both knees bent to 90 degrees and the lower legs upright.",
      "Pause, then slowly return the lower legs to vertical.",
    ],
    cautions: [
      "If your knees or hips hurt, open less far; stop if pain persists.",
    ],
    contraindications: ["Knee", "Hip"],
  ),
  "n-seated-ir-drop": HipPublicEnglishText(
    purpose:
        "Relax the outer and rear hip while seated to allow more inward thigh rotation.",
    cues: [
      "Keep your feet planted as one knee slowly drops inward toward the floor.",
      "Sit on the floor with straight arms supporting you from behind and your feet wide apart.",
      "Pause, return, then switch sides.",
      "Doing each side once counts as 1 rep.",
    ],
    cautions: [
      "If your knee or hip hurts, drop less far; stop if pain persists.",
    ],
    contraindications: ["Knee", "Hip"],
  ),
  "n-seated-knee-lift": HipPublicEnglishText(
    purpose: "Build leg-lifting strength while sitting in a chair.",
    cues: [
      "Lift your thigh a few centimeters off the seat without leaning back.",
      "Sit upright with your knees at 90 degrees and both feet on the floor.",
      "Hold briefly, lower, then switch sides.",
      "Doing each side once counts as 1 rep.",
    ],
    cautions: [
      "If the front of your hip hurts, lift less high; stop if pain persists.",
    ],
    contraindications: ["Hip"],
  ),
  "n-seated-squeeze": HipPublicEnglishText(
    purpose: "Strengthen the inner thighs while seated.",
    cues: [
      "Place a yoga block between your knees and squeeze it firmly.",
      "Sit upright with your feet hip-width apart and hands on your thighs.",
      "Hold each squeeze for about 5 seconds, release, then repeat without holding your breath.",
    ],
    cautions: [
      "If your inner thighs or knees hurt, squeeze more gently; stop if pain persists.",
    ],
    contraindications: ["Knee", "Inner thigh"],
  ),
  "n-slider-lateral": HipPublicEnglishText(
    purpose:
        "Build inner-thigh control at the end of a sideways slide to support middle splits.",
    cues: [
      "Slide the straight leg out to the side, then use the inner thigh to draw it back.",
      "Place one foot on a slider. Bend the other knee and sit your hips back.",
      "Stop at a distance you can control; do not force yourself farther.",
    ],
    cautions: [
      "If your inner thigh or knee hurts, shorten the slide; stop if pain persists.",
    ],
    contraindications: ["Knee", "Inner thigh"],
  ),
  "n-squat-shift": HipPublicEnglishText(
    purpose:
        "Build inner-thigh and glute control in a deep squat as a foundation for the Cossack squat.",
    cues: [
      "Keep your chest lifted and slowly shift your weight onto one foot.",
      "Stand with your feet about twice hip-width apart, toes turned out and heels planted.",
      "Bring your palms together at your chest and track the bent knee in line with the toes.",
      "Doing each side once counts as 1 rep.",
    ],
    cautions: [
      "If your knees or hips hurt, squat less deeply; stop if pain persists.",
    ],
    contraindications: ["Knee", "Hip"],
  ),
  "n-straddle-fold": HipPublicEnglishText(
    purpose: "Stretch the inner thighs and hamstrings.",
    cues: [
      "Lengthen your back and slowly lean your upper body forward.",
      "Sit on a mat with straight legs apart, toes and knees pointing up.",
      "Hold still and breathe slowly, relaxing a little more with each exhale.",
      "Do not bounce. A stretch sensation is enough; do not stretch into pain.",
    ],
    cautions: [
      "If the stretched area hurts, reduce the range; stop if pain persists.",
    ],
    contraindications: [],
  ),
  "n-thomas-test": HipPublicEnglishText(
    purpose:
        "Check for tightness at the front of the hip while gently stretching that area.",
    cues: [
      "Hug one knee with both hands while the other leg rests relaxed on the floor.",
      "Check whether the thigh of the straight leg lifts off the floor; lifting suggests tightness at the front of the hip.",
      "Hold still and breathe slowly, relaxing a little more with each exhale.",
      "Do not bounce. A stretch sensation is enough; do not stretch into pain.",
    ],
    cautions: [
      "If your knee or hip hurts, loosen the hug; stop if pain persists.",
    ],
    contraindications: ["Knee", "Hip"],
  ),
  "n-wide-fold": HipPublicEnglishText(
    purpose:
        "Stretch the inner thighs and hamstrings with a move you can do in the office.",
    cues: [
      "Lengthen your back, support your hands on the chair seat and lean forward.",
      "Stand with your feet very wide, toes pointing forward and knees straight but not locked.",
      "Hold still and breathe slowly, relaxing a little more with each exhale.",
      "Do not bounce. A stretch sensation is enough; do not stretch into pain.",
    ],
    cautions: [
      "Rise slowly and pause if you feel dizzy.",
      "If the stretched area hurts, reduce the range; stop if pain persists.",
    ],
    contraindications: [],
  ),
  "n-windshield": HipPublicEnglishText(
    purpose: "Gently mobilize hip rotation and relax the hips.",
    cues: [
      "Keep your feet planted as both knees slowly tip together to one side.",
      "Lie on your back with bent knees, feet slightly wider than hip-width and arms by your sides, palms down.",
      "Pause, pass through the center, then tip to the other side.",
      "Doing each side once counts as 1 rep.",
    ],
    cautions: [
      "If your lower back or hips hurt, reduce the range; stop if pain persists.",
    ],
    contraindications: ["Lower back", "Hip"],
  ),
  "o-chair-knee-extension": HipPublicEnglishText(
    purpose: "Build quadriceps control without added weight.",
    cues: [
      "Keep your thigh on the chair seat as you slowly lift and straighten the lower leg.",
      "Sit on a stable chair without wheels, with your other foot planted.",
      "Stop just short of fully straight; do not lock the knee.",
    ],
    cautions: ["If your knee hurts, reduce the range; stop if pain persists."],
    contraindications: ["Knee"],
  ),
  "o-seated-calf-raise": HipPublicEnglishText(
    purpose: "Build calf and ankle control without added weight.",
    cues: [
      "Keep the balls of your feet on the floor and slowly raise your heels.",
      "Sit on a stable chair with bent knees and keep your hips firmly seated.",
      "Pause at the top, then lower slowly.",
    ],
    cautions: [
      "If your ankles or calves hurt, reduce the range; stop if pain persists.",
    ],
    contraindications: [],
  ),
  "o-seated-catcow": HipPublicEnglishText(
    purpose:
        "Move the whole spine while seated to ease stiffness from prolonged sitting.",
    cues: [
      "First round your back and lower your head, then lift your chest and head.",
      "Sit on the front half of a chair with feet planted and hands on your knees.",
      "Rounding your back and then lifting your chest counts as 1 rep. Move slowly with your breath.",
    ],
    cautions: ["If your back hurts, reduce the range; stop if pain persists."],
    contraindications: ["Lower back"],
  ),
  "o-seated-fig4": HipPublicEnglishText(
    purpose: "Stretch the glutes to ease hip tightness from prolonged sitting.",
    cues: [
      "Rest one ankle on the opposite knee and lean forward with a straight back.",
      "Keep the supporting foot flat and let the raised knee open naturally to the side.",
      "Hold still and breathe slowly, relaxing a little more with each exhale.",
      "Do not bounce. A stretch sensation is enough; do not stretch into pain.",
    ],
    cautions: [
      "If your knee hurts, lean less far forward; stop if pain persists.",
    ],
    contraindications: ["Knee"],
  ),
  "o-seated-ham": HipPublicEnglishText(
    purpose: "Stretch the hamstrings while sitting in a chair.",
    cues: [
      "Straighten one leg in front of you and lean forward with a straight back.",
      "Sit on the front half of the chair, with the straight leg heel on the floor and toes pulled up.",
      "Hold still and breathe slowly, relaxing a little more with each exhale.",
      "Do not bounce. A stretch sensation is enough; do not stretch into pain.",
    ],
    cautions: [
      "If the back of your thigh hurts or feels numb, reduce the range; stop if discomfort persists.",
    ],
    contraindications: [],
  ),
  "o-seated-hip-er": HipPublicEnglishText(
    purpose: "Build control of outward hip rotation without added weight.",
    cues: [
      "Keep your thigh and knee still as your foot slowly swings inward.",
      "Sit in a chair with this foot slightly off the floor and the other foot firmly planted.",
      "Use small, slow swings without turning your torso or pelvis.",
    ],
    cautions: [
      "If your knee or hip hurts, reduce the range; stop if pain persists.",
    ],
    contraindications: ["Knee", "Hip"],
  ),
  "o-seated-sidebend": HipPublicEnglishText(
    purpose:
        "Stretch the side of the body to ease back tightness from prolonged sitting.",
    cues: [
      "Raise one arm overhead and slowly bend your body to the other side.",
      "Keep your hips firmly seated and both feet planted, with the other arm hanging relaxed.",
      "Hold still and breathe slowly, relaxing a little more with each exhale.",
      "Do not bounce. A stretch sensation is enough; do not stretch into pain.",
    ],
    cautions: [
      "If your back or shoulder hurts, reduce the range; stop if pain persists.",
    ],
    contraindications: ["Lower back", "Shoulder"],
  ),
  "o-seated-twist": HipPublicEnglishText(
    purpose:
        "Rotate the upper and lower back to ease stiffness from prolonged sitting.",
    cues: [
      "Sit upright, turn your body to one side and hold the chair back.",
      "Place the other hand on the outside of the knee on the side you are turning toward.",
      "Hold still and breathe slowly, relaxing a little more with each exhale.",
      "Do not bounce. A stretch sensation is enough; do not stretch into pain.",
    ],
    cautions: ["If your back hurts, turn less far; stop if pain persists."],
    contraindications: ["Lower back"],
  ),
  "o-stand-crossreach": HipPublicEnglishText(
    purpose: "Stretch the outer hip and the side of the waist.",
    cues: [
      "Push your hip outward and bend your body toward the chair.",
      "Cross the leg farther from the chair behind the other leg, and reach your free arm overhead.",
      "Hold still and breathe slowly, relaxing a little more with each exhale.",
      "Do not bounce. A stretch sensation is enough; do not stretch into pain.",
    ],
    cautions: [
      "If your hip or lower back hurts, reduce the range; stop if pain persists.",
    ],
    contraindications: ["Lower back", "Hip"],
  ),
  "o-stand-ham": HipPublicEnglishText(
    purpose: "Stretch the hamstrings while standing.",
    cues: [
      "Place the front heel on the floor with toes pulled up and lean slightly forward.",
      "Hold the chair securely with one hand and keep the supporting knee slightly bent.",
      "Hold still and breathe slowly, relaxing a little more with each exhale.",
      "Do not bounce. A stretch sensation is enough; do not stretch into pain.",
    ],
    cautions: [
      "If the back of your thigh hurts or feels numb, reduce the range; stop if discomfort persists.",
    ],
    contraindications: [],
  ),
  "o-stand-lunge": HipPublicEnglishText(
    purpose:
        "Stretch the front of the hip to ease tightness from prolonged sitting.",
    cues: [
      "Squeeze your glute and slowly move your hips forward.",
      "Stand in a split stance with the rear heel raised and one hand on the chair back.",
      "Hold still and breathe slowly, relaxing a little more with each exhale.",
      "Do not bounce. A stretch sensation is enough; do not stretch into pain.",
    ],
    cautions: [
      "If your lower back hurts, reduce the range; stop if pain persists.",
    ],
    contraindications: ["Lower back"],
  ),
  "o-stand-quad": HipPublicEnglishText(
    purpose: "Stretch the front of the thigh.",
    cues: [
      "Hold your ankle and draw the heel toward your glute.",
      "Stand upright on one leg while holding the chair, keeping your knees beside each other.",
      "Hold still and breathe slowly, relaxing a little more with each exhale.",
      "Do not bounce. A stretch sensation is enough; do not stretch into pain.",
    ],
    cautions: ["If your knee hurts, bend it less; stop if pain persists."],
    contraindications: ["Knee"],
  ),
  "o-stand-sidebend": HipPublicEnglishText(
    purpose: "Stretch the side of the waist and back.",
    cues: [
      "Reach one arm overhead and bend to the other side without moving your hips.",
      "Stand with feet hip-width apart and the other hand on the outside of your thigh.",
      "Hold still and breathe slowly, relaxing a little more with each exhale.",
      "Do not bounce. A stretch sensation is enough; do not stretch into pain.",
    ],
    cautions: [
      "If your back or shoulder hurts, reduce the range; stop if pain persists.",
    ],
    contraindications: ["Lower back", "Shoulder"],
  ),
  "o-supported-ankle-inversion": HipPublicEnglishText(
    purpose: "Build control of turning the sole inward without added weight.",
    cues: [
      "Keep the lower leg still as you slowly turn the sole inward.",
      "Lightly hold the chair with one hand and keep this foot off the floor.",
      "Turn through a small range, then slowly return to neutral.",
    ],
    cautions: [
      "Hold a stable chair without wheels. Stop if you feel pain or cannot stay steady.",
    ],
    contraindications: [],
  ),
  "o-supported-ankle-pump": HipPublicEnglishText(
    purpose: "Mobilize the ankle and relax the calf.",
    cues: [
      "Keep the hip and knee still; point the toes, then pull them up.",
      "Lightly hold the chair with one hand and keep this foot off the floor.",
      "Pointing and then pulling up counts as 1 rep. Move slowly without holding your breath.",
    ],
    cautions: [
      "Hold a stable chair without wheels. Stop if you feel pain or cannot stay steady.",
    ],
    contraindications: [],
  ),
  "o-supported-hip-airplane": HipPublicEnglishText(
    purpose: "Build control of hip rotation while standing on one leg.",
    cues: [
      "Slowly rotate your pelvis and upper body open together.",
      "Stand steadily on one leg with the knee soft, lightly holding the chair with one hand.",
      "Rotate open and back through a small range; do not twist through the lower back alone.",
    ],
    cautions: [
      "Hold a stable chair without wheels. Stop if you feel pain or cannot stay steady.",
    ],
    contraindications: [],
  ),
  "o-supported-hip-hitch": HipPublicEnglishText(
    purpose:
        "Build control to keep the pelvis level while standing on one leg.",
    cues: [
      "Keep the supporting leg steady and slowly lift the opposite side of your pelvis.",
      "Lightly hold the chair and keep the lifted knee bent throughout.",
      "Lift through a small range and return to level without bending your torso sideways.",
    ],
    cautions: [
      "Start with 1 set of 4 reps per side, using a small range.",
      "Stop if your lower back, hip or knee hurts, or if you cannot stay steady.",
    ],
    contraindications: ["Knee", "Lower back", "Hip"],
  ),
  "o-supported-hip-ir": HipPublicEnglishText(
    purpose: "Build control of inward hip rotation without added weight.",
    cues: [
      "Keep your thigh and knee still as the lower leg slowly swings outward.",
      "Stand upright with your pelvis facing forward and one hand lightly on the chair.",
      "Move within a comfortable range; do not force the knee or ankle to twist.",
    ],
    cautions: ["Start with 1 set of 4–6 reps per side. Stop if it hurts."],
    contraindications: [],
  ),
  "o-supported-knee-curl": HipPublicEnglishText(
    purpose: "Build hamstring control of knee bending without added weight.",
    cues: [
      "Keep your thigh still as you slowly raise the heel toward your glute.",
      "Stand upright with one hand lightly holding a stable chair.",
      "Pause at the top, then lower slowly.",
    ],
    cautions: [
      "Hold a stable chair without wheels. Stop if you feel pain or cannot stay steady.",
    ],
    contraindications: [],
  ),
  "o-supported-march": HipPublicEnglishText(
    purpose: "Use chair support to build balance and leg-lifting strength.",
    cues: [
      "Stand upright and slowly raise your knees in turn.",
      "Hold the chair back securely with one hand and let the other hand relax naturally.",
      "Lift each knee to a comfortable height, then lower slowly.",
      "Doing each side once counts as 1 rep.",
    ],
    cautions: [
      "Use a stable chair without wheels. Stop if you cannot stay steady.",
    ],
    contraindications: [],
  ),
  "o-supported-mini-squat": HipPublicEnglishText(
    purpose:
        "Use chair support to strengthen the thighs and glutes; suitable for beginners.",
    cues: [
      "Sit your hips slightly back and lower into a shallow squat.",
      "Hold the chair back securely with both hands, keeping both feet firmly planted.",
      "Keep your knees in line with your toes, then press through the floor to stand.",
    ],
    cautions: [
      "Use a stable chair without wheels. Stop if you cannot stay steady.",
      "If your knees hurt, reduce the range; stop if pain persists.",
    ],
    contraindications: ["Knee"],
  ),
  "o-supported-single-leg-rdl": HipPublicEnglishText(
    purpose:
        "Hinge forward on one leg with chair support to train the glutes and hamstrings.",
    cues: [
      "Keep the supporting knee soft and your back flat as you hinge forward.",
      "Hold the chair back securely with one hand, letting the lifted leg rise behind you as your body tilts.",
      "Hinge through a small range, then slowly stand upright.",
    ],
    cautions: [
      "Use a stable chair without wheels. Stop if you cannot stay steady.",
      "If your lower back or hamstring hurts, reduce the range; stop if pain persists.",
    ],
    contraindications: ["Lower back"],
  ),
  "o-supported-star-reach": HipPublicEnglishText(
    purpose: "Build stability and control in a shallow single-leg squat.",
    cues: [
      "Slightly bend the supporting leg and tap the other foot forward, sideways and backward in turn.",
      "Keep your pelvis level and facing forward, with one hand lightly on the chair.",
      "Tap lightly without putting your weight onto the tapping foot.",
      "Each tap counts as 1 rep.",
    ],
    cautions: [
      "Use a stable chair without wheels. Stop if you cannot stay steady.",
    ],
    contraindications: [],
  ),
  "o-wall-hip-hinge-stretch": HipPublicEnglishText(
    purpose: "Stretch the sides of the back and underarms.",
    cues: [
      "Place both hands on the wall, shift your hips back and let your chest lower.",
      "Place your hands at chest height, keep your feet planted and soften your knees.",
      "Hold still and breathe slowly, relaxing a little more with each exhale.",
      "Do not bounce. A stretch sensation is enough; do not stretch into pain.",
    ],
    cautions: [
      "If your shoulders hurt, reduce the range; stop if pain persists.",
    ],
    contraindications: ["Shoulder"],
  ),
  "obliques-A": HipPublicEnglishText(
    purpose: "Build rotational control while supporting your body on one hand.",
    cues: [
      "Support yourself with one hand as one leg threads underneath your body.",
      "Start on all fours with your knees slightly off the floor.",
      "As you turn, push firmly through the supporting hand and keep your hips off the floor.",
      "Doing each side once counts as 1 rep.",
    ],
    cautions: [
      "If your wrists feel uncomfortable, gently move them to warm up first.",
      "Stop immediately if you feel sharp wrist pain or numbness.",
    ],
    contraindications: ["Wrist"],
  ),
  "obliques-B": HipPublicEnglishText(
    purpose:
        "Train the sides of the core to resist being pulled into rotation.",
    cues: [
      "Press both hands straight forward without letting the pull rotate your body.",
      "Stand upright side-on to the anchor, holding the handle with both hands at your chest.",
      "Hold for 2 seconds with your arms straight, then return your hands to your chest.",
    ],
    cautions: [
      "Do not start if the anchor is not secure.",
      "Use a lighter band if your back feels uncomfortable.",
    ],
    contraindications: ["Lower back"],
  ),
  "obliques-C": HipPublicEnglishText(
    purpose: "Build strength for rotating the shoulders and hips together.",
    cues: [
      "Pull diagonally down from a high position to the outside of the opposite hip.",
      "Keep your arms mostly straight and rotate your shoulders and hips together.",
      "Let your rear foot turn with the movement, then slowly return to the high position.",
    ],
    cautions: [
      "Reduce the rotation if your lower back feels tight or painful.",
    ],
    contraindications: ["Lower back"],
  ),
  "quadriceps-A": HipPublicEnglishText(
    purpose: "Strengthen the quadriceps in a lengthened position.",
    cues: [
      "Keep a straight line from knees to shoulders and lean back only as far as you can control.",
      "Kneel upright, squeeze your glutes and cross your hands at your chest.",
      "Do not bend at the hips; return your whole body upright as one unit.",
    ],
    cautions: [
      "If the front of your knees feels uncomfortable, lean back less and add padding under your knees.",
    ],
    contraindications: ["Knee"],
  ),
  "quadriceps-B": HipPublicEnglishText(
    purpose: "Target the final part of straightening the knee.",
    cues: [
      "Firmly straighten your knee and tighten the front of the thigh.",
      "Place a band behind your knee and begin with the knee slightly bent.",
      "Hold for 2 seconds once straight, keeping the heel on the floor.",
    ],
    cautions: [
      "If your knee hurts, use a lighter band; stop if pain persists.",
    ],
    contraindications: ["Knee"],
  ),
  "quadriceps-C": HipPublicEnglishText(
    purpose: "Strengthen the quadriceps with the knee fully straightened.",
    cues: [
      "Extend the legs fully, hold for 2 seconds, then lower slowly.",
      "Align your knees with the machine pivot.",
      "Keep your back against the pad and hold the handles with both hands.",
    ],
    cautions: [
      "Start with a light weight.",
      "Reduce the range if the front of your knees hurts.",
    ],
    contraindications: ["Knee"],
  ),
  "rotator-cuff-A": HipPublicEnglishText(
    purpose:
        "Build shoulder stability while supporting your weight on one hand.",
    cues: [
      "Push firmly through the supporting hand and keep your hips still as you tap your shoulder.",
      "Start in a high plank with your feet slightly apart.",
      "Lift one hand to tap the opposite shoulder, then place it back down.",
      "Doing each side once counts as 1 rep.",
    ],
    cautions: [
      "If your wrists feel uncomfortable, gently move them to warm up first.",
      "Stop immediately if you feel sharp wrist pain or numbness.",
    ],
    contraindications: ["Wrist"],
  ),
  "rotator-cuff-B": HipPublicEnglishText(
    purpose:
        "Strengthen the small, deep shoulder muscles for greater shoulder stability.",
    cues: [
      "Keep your elbows against your body and open only the forearms outward.",
      "Bend your elbows to right angles and place a small pad between each elbow and your body.",
      "Return slowly without shrugging your shoulders.",
    ],
    cautions: [
      "If your shoulder hurts, use a lighter band or rotate through a smaller range.",
    ],
    contraindications: ["Shoulder"],
  ),
  "rotator-cuff-C": HipPublicEnglishText(
    purpose: "Build shoulder control with the arm raised.",
    cues: [
      "Keep your upper arm level and still while rotating only the forearm upward to vertical.",
      "Hold the upper arm at shoulder height with the elbow bent to a right angle.",
      "Keep your shoulder down and body still. Pause at the top, then slowly rotate back.",
    ],
    cautions: [
      "Use a very light weight.",
      "Stop immediately if the front of your shoulder hurts.",
    ],
    contraindications: ["Shoulder"],
  ),
  "s-9090": HipPublicEnglishText(
    purpose: "Stretch the glute and outer hip of the front leg.",
    cues: [
      "Keep your back straight and slowly lean over the shin of the front leg.",
      "Bend the front leg and the leg beside you to right angles, with your chest facing the front leg.",
      "Hold still and breathe slowly, relaxing a little more with each exhale.",
      "Do not bounce. A stretch sensation is enough; do not stretch into pain.",
    ],
    cautions: [
      "If your knee hurts, lean less far or raise your hips on a support; stop if pain persists.",
    ],
    contraindications: ["Knee"],
  ),
  "s-butterfly": HipPublicEnglishText(
    purpose: "Stretch the inner thighs.",
    cues: [
      "Bring the soles of your feet together and slowly lean forward with a straight back.",
      "Draw your heels close to your body and let your knees open naturally to the sides.",
      "Hold still and breathe slowly, relaxing a little more with each exhale.",
      "Do not bounce. A stretch sensation is enough; do not stretch into pain.",
    ],
    cautions: [
      "If your inner thighs hurt, reduce the range; stop if pain persists.",
    ],
    contraindications: ["Inner thigh"],
  ),
  "s-figure4": HipPublicEnglishText(
    purpose: "Stretch the deep glutes to ease hip tightness.",
    cues: [
      "Rest one ankle on the opposite thigh and let the knee open outward.",
      "Lie on your back and move the planted foot a little closer to your glutes, keeping your head and shoulders relaxed.",
      "Hold still and breathe slowly, relaxing a little more with each exhale.",
      "Do not bounce. A stretch sensation is enough; do not stretch into pain.",
    ],
    cautions: ["If your knee hurts, reduce the range; stop if pain persists."],
    contraindications: ["Knee"],
  ),
  "s-frog": HipPublicEnglishText(
    purpose: "Stretch the inner thighs.",
    cues: [
      "Open your knees to the sides and slowly sit your hips back.",
      "Support yourself on your forearms, turn your toes outward and keep your back flat.",
      "Hold still and breathe slowly, relaxing a little more with each exhale.",
      "Do not bounce. A stretch sensation is enough; do not stretch into pain.",
    ],
    cautions: [
      "Place soft padding under your knees. Do not open them farther if they feel uncomfortable.",
      "If your inner thighs hurt, sit back less far. Do not let anyone push you down.",
    ],
    contraindications: ["Knee", "Inner thigh"],
  ),
  "s-kneel-hipflex": HipPublicEnglishText(
    purpose:
        "Stretch the front of the hip to ease tightness from prolonged sitting.",
    cues: [
      "Squeeze your glute and slowly shift your body forward.",
      "Kneel on the rear knee with the front foot planted and the torso upright.",
      "Hold still and breathe slowly, relaxing a little more with each exhale.",
      "Do not bounce. A stretch sensation is enough; do not stretch into pain.",
    ],
    cautions: [
      "Place soft padding under the kneeling knee.",
      "If the front of your hip hurts, reduce the range; stop if pain persists.",
    ],
    contraindications: ["Knee", "Hip"],
  ),
  "s-lizard": HipPublicEnglishText(
    purpose:
        "Stretch the front of the rear hip and the inner thigh of the front leg.",
    cues: [
      "Slowly let your hips move forward and down.",
      "Place the front foot well forward, kneel on the rear knee and support both hands on blocks.",
      "Hold still and breathe slowly, relaxing a little more with each exhale.",
      "Do not bounce. A stretch sensation is enough; do not stretch into pain.",
    ],
    cautions: [
      "Place soft padding under the kneeling knee.",
      "If your hip or inner thigh hurts, reduce the range; stop if pain persists.",
    ],
    contraindications: ["Knee", "Hip", "Inner thigh"],
  ),
  "s-pigeon": HipPublicEnglishText(
    purpose:
        "Stretch the glute of the front leg and the front of the rear hip.",
    cues: [
      "Place the front shin across your body and straighten the rear leg behind you.",
      "Support your hands on blocks, keep the pelvis as square as possible and do not force yourself downward.",
      "Hold still and breathe slowly, relaxing a little more with each exhale.",
      "Do not bounce. A stretch sensation is enough; do not stretch into pain.",
    ],
    cautions: [
      "If your knee hurts, raise your hips on a support or switch to a lying figure-four stretch.",
    ],
    contraindications: ["Knee"],
  ),
  "s-seated-fold": HipPublicEnglishText(
    purpose: "Stretch the hamstrings.",
    cues: [
      "Keep your back straight and slowly fold forward.",
      "Straighten both legs together with your toes pointing up.",
      "Hold still and breathe slowly, relaxing a little more with each exhale.",
      "Do not bounce. A stretch sensation is enough; do not stretch into pain.",
    ],
    cautions: [
      "If the back of your thighs hurts or feels numb, reduce the range; stop if discomfort persists.",
    ],
    contraindications: [],
  ),
  "scapular-A": HipPublicEnglishText(
    purpose:
        "Strengthen the upper back and muscles around the shoulder blades to improve shoulder positioning.",
    cues: [
      "Draw your shoulder blades down and back before lifting your hands.",
      "Lie face down with your forehead resting lightly on the mat and form Y, T and W shapes in turn.",
      "Point your thumbs upward; lift your hands off the mat, then lower them.",
      "Each letter shape counts as 1 rep.",
    ],
    cautions: [
      "If your shoulders hurt, reduce the range; stop if pain persists.",
    ],
    contraindications: ["Shoulder"],
  ),
  "scapular-B": HipPublicEnglishText(
    purpose:
        "Build strength and stability in drawing the shoulder blades down.",
    cues: [
      "Keep your arms straight and lift your body only by drawing your shoulder blades down.",
      "Hold the bar with an overhand grip slightly wider than shoulder-width, with your legs together.",
      "Hold at the top for 1 second, then slowly return to the hanging position.",
    ],
    cautions: [
      "Check that the bar is securely installed first.",
      "Reduce the reps if the front of your shoulders feels pinched and painful.",
    ],
    contraindications: ["Shoulder"],
  ),
  "serratus-A": HipPublicEnglishText(
    purpose:
        "Build the ability to push the floor away and keep the shoulder blades close to the rib cage.",
    cues: [
      "Keep your arms straight, let your chest sink slightly, then push the floor away.",
      "Start in a high plank with your body in a straight line.",
      "Let your upper back round slightly at the top of the push.",
    ],
    cautions: [
      "If your wrists feel uncomfortable, gently move them to warm up first.",
      "Stop immediately if you feel sharp wrist pain or numbness.",
    ],
    contraindications: ["Wrist"],
  ),
  "serratus-B": HipPublicEnglishText(
    purpose:
        "Train the shoulder blades to rotate upward and stay close to the rib cage as your arms lift overhead.",
    cues: [
      "Press your forearms into the foam roller and roll it up the wall.",
      "Stand upright facing the wall with parallel forearms and palms facing each other.",
      "At the highest position, reach your shoulders slightly forward, pause, then slide back down.",
    ],
    cautions: [
      "If your shoulders hurt, slide less high; stop if pain persists.",
    ],
    contraindications: ["Shoulder"],
  ),
  "serratus-C": HipPublicEnglishText(
    purpose:
        "Train chest and arm strength and shoulder-blade stability on moving rings.",
    cues: [
      "After pushing up, press down a little farther so your upper back rounds slightly.",
      "Hang the rings low, a little over 10 centimeters above the floor, and keep them close to your sides.",
      "Keep your body in a straight line and lower slowly.",
    ],
    cautions: [
      "If the front of your shoulders feels pinched and painful, lower less deeply or use an easier version.",
      "Stop immediately if you feel sharp wrist pain or numbness.",
    ],
    contraindications: ["Shoulder", "Wrist"],
  ),
  "t-seated-straddle-lift-1leg": HipPublicEnglishText(
    purpose:
        "Lift a straight leg from a seated straddle to strengthen the front of the thigh.",
    cues: [
      "Keep the leg straight and lift one leg off the floor.",
      "Sit tall in a straddle, with your fingertips on the floor on either side of the leg you will lift.",
      "Lower the leg and let it settle before lifting your hands, moving them to the other side and supporting yourself again.",
      "Doing each side once counts as 1 rep.",
    ],
    cautions: [
      "Stop and rest if the front of your thigh cramps or your hip hurts.",
    ],
    contraindications: ["Hip"],
  ),
  "triceps-A": HipPublicEnglishText(
    purpose:
        "Train the backs of the arms by fully straightening the elbows at the top of the push-up.",
    cues: [
      "Bend your elbows backward close to your body, then straighten and pause after pushing up.",
      "Place your hands shoulder-width apart or slightly narrower.",
      "Keep your body in a straight line and push the floor away.",
    ],
    cautions: [
      "If your wrists feel uncomfortable, gently move them to warm up first.",
      "Stop immediately if you feel sharp wrist pain or numbness.",
    ],
    contraindications: ["Wrist"],
  ),
  "triceps-B": HipPublicEnglishText(
    purpose: "Train straight-arm support of your body weight.",
    cues: [
      "Straighten your arms and press your shoulders down, away from your ears.",
      "Start with your toes lightly touching the floor. Press the shoulders down, then draw in your knees to support your body off the floor.",
      "Hold still and breathe evenly without holding your breath.",
    ],
    cautions: [
      "If your wrists feel uncomfortable, gently move them to warm up first.",
      "Stop immediately if you feel sharp wrist pain or numbness.",
    ],
    contraindications: ["Wrist"],
  ),
  "triceps-C": HipPublicEnglishText(
    purpose:
        "Train the backs of the arms and the chest by pushing your body up from a lowered position.",
    cues: [
      "Lower until your upper arms are approximately parallel to the floor, then push up.",
      "At the top, straighten your elbows, press your shoulders down and pause.",
      "Keep your knees bent and do not swing your legs.",
    ],
    cautions: [
      "If your shoulders feel uncomfortable, begin with a support hold at the top, then gradually increase the depth.",
    ],
    contraindications: ["Shoulder"],
  ),
  "w-bird-dog": HipPublicEnglishText(
    purpose:
        "Build core stability while coordinating one arm with the opposite leg.",
    cues: [
      "Reach one arm and the opposite leg away without letting your body sway.",
      "Start on all fours with your hands under your shoulders and knees under your hips.",
      "Lift the leg to hip height and the arm to shoulder height, hold, then draw them back in.",
    ],
    cautions: [
      "If your lower back hurts, shorten the reach; stop if pain persists.",
    ],
    contraindications: ["Lower back"],
  ),
  "w-chair-hip-thrust": HipPublicEnglishText(
    purpose: "Strengthen the glutes with your upper back supported on a chair.",
    cues: [
      "Press through your heels to lift your hips and squeeze your glutes at the top.",
      "Rest your upper back against the edge of a stable chair, with feet hip-width apart and hands on your hips.",
      "At the top, line up your thighs with your torso and keep your lower legs vertical.",
    ],
    cautions: [
      "Check that the chair is stable and cannot slide.",
      "If your lower back hurts, reduce the range; stop if pain persists.",
    ],
    contraindications: ["Lower back"],
  ),
  "w-clamshell": HipPublicEnglishText(
    purpose: "Strengthen the outer glutes for greater hip stability.",
    cues: [
      "Keep your feet together and slowly open the upper knee upward.",
      "Lie on your side with the lower forearm on the floor, keeping your bent hips and knees stacked.",
      "Do not roll your pelvis backward. Pause, then slowly close the knee.",
    ],
    cautions: ["If your hip hurts, open less far; stop if pain persists."],
    contraindications: ["Hip"],
  ),
  "w-dead-bug": HipPublicEnglishText(
    purpose:
        "Build core stability while keeping the lower back on the floor as the limbs move.",
    cues: [
      "Keep your lower back against the floor while slowly reaching one arm and the opposite leg away.",
      "Lie on your back with your hands pointing at the ceiling and hips and knees each bent to right angles.",
      "Slowly return to the starting position, then switch to the other arm and leg.",
      "Doing each side once counts as 1 rep.",
    ],
    cautions: [
      "Shorten the reach if your lower back arches up.",
      "Keep the leg higher if the front of your hip feels uncomfortable.",
    ],
    contraindications: ["Lower back", "Hip"],
  ),
  "w-feet-on-chair-bridge": HipPublicEnglishText(
    purpose: "Strengthen the glutes and hamstrings.",
    cues: [
      "Press your heels into the chair seat and lift until shoulders, hips and knees form a straight line.",
      "Lie on your back with your arms beside your body, pressing into the floor.",
      "Hold at the top, then lower slowly.",
    ],
    cautions: [
      "Check that the chair is stable and cannot slide.",
      "Stop and rest if your hamstrings cramp.",
    ],
    contraindications: [],
  ),
  "w-fire-hydrant": HipPublicEnglishText(
    purpose: "Strengthen the outer glutes for greater hip stability.",
    cues: [
      "Keep the knee bent and lift the leg to the side.",
      "Start on all fours with your hands under your shoulders and knees under your hips.",
      "Keep your body still, pause, then lower slowly.",
    ],
    cautions: ["If your hip hurts, lift less high; stop if pain persists."],
    contraindications: ["Hip"],
  ),
  "w-prone-swimmer": HipPublicEnglishText(
    purpose: "Strengthen the upper back for smoother shoulder movement.",
    cues: [
      "Lift your chest slightly and sweep your straight arms from overhead to beside your hips.",
      "Lie on your stomach with straight legs and your arms hovering off the floor.",
      "Turn your palms upward beside your hips, then sweep your arms back overhead.",
    ],
    cautions: [
      "If your lower back or shoulders hurt, reduce the range; stop if pain persists.",
    ],
    contraindications: ["Lower back", "Shoulder"],
  ),
  "w-wall-sit": HipPublicEnglishText(
    purpose: "Build thigh and glute endurance with a stationary squat hold.",
    cues: [
      "Keep your back against the wall, thighs parallel to the floor and knees above your ankles.",
      "Place your feet hip-width apart and reach your arms straight forward.",
      "Breathe evenly without holding your breath.",
    ],
    cautions: [
      "If your knees hurt, hold a higher squat; stop if pain persists.",
    ],
    contraindications: ["Knee"],
  ),
};
