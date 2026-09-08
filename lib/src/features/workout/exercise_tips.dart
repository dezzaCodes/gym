// A small built-in tip library so the app works out of the box with no
// backend or API key. If you later want AI-generated tips for arbitrary
// exercise names, you'll need your own server holding the API key —
// never embed an Anthropic API key directly in a shipped app; it can be
// extracted from the compiled binary.
class ExerciseTips {
  static const Map<String, List<String>> _library = {
    // Chest
    'bench press': [
      'Keep your feet flat and drive through the floor.',
      'Lower the bar to your mid-chest with control.',
      'Keep your shoulder blades pulled back and down.',
    ],
    'incline bench press': [
      'Set the bench between 30 and 45 degrees to target the upper chest.',
      'Lower the bar to your upper chest, just below the collarbone.',
      'Keep your wrists stacked over your elbows at the bottom.',
    ],
    'decline bench press': [
      'Secure your feet or hips before you unrack the bar.',
      'Lower the bar to your lower chest with control.',
      'Keep the movement short to protect your shoulders.',
    ],
    'dumbbell bench press': [
      'Keep the dumbbells stacked over your elbows throughout the press.',
      'Lower until your upper arms are about parallel to the floor.',
      "Don't let the dumbbells drift together or apart at the top.",
    ],
    'incline dumbbell press': [
      'Use a moderate incline so the work stays on your chest, not your shoulders.',
      'Lower the dumbbells to chest level with your elbows tucked slightly.',
      'Press up and slightly in without banging the dumbbells together.',
    ],
    'decline dumbbell press': [
      'Get help getting the dumbbells into position on a decline bench.',
      'Lower with control to your lower chest.',
      'Keep your core braced since the decline angle challenges stability.',
    ],
    'push-up': [
      'Keep your body in a straight line from head to heels.',
      'Lower until your chest is just above the floor.',
      'Keep your elbows at roughly a 45-degree angle to your torso.',
    ],
    'dumbbell fly': [
      'Keep a slight bend in your elbows throughout the movement.',
      'Lower the dumbbells until you feel a stretch across your chest.',
      "Squeeze your chest to bring the dumbbells together, don't just lift with your shoulders.",
    ],
    'cable fly': [
      'Set the pulleys so the cables load your chest through the full range.',
      'Keep a slight forward lean and a soft bend in your elbows.',
      'Squeeze at the center instead of letting the handles clash together.',
    ],
    'chest dip': [
      'Lean your torso forward to bias your chest over your triceps.',
      'Lower until you feel a stretch in your shoulders, not past it.',
      'Press back up without flaring your elbows out wide.',
    ],
    'machine chest press': [
      'Set the seat so the handles line up with mid-chest height.',
      'Press out fully without locking your elbows aggressively.',
      'Control the return instead of letting the weight stack slam down.',
    ],

    // Back
    'deadlift': [
      'Keep the bar close to your shins throughout the lift.',
      'Brace your core before you break the floor.',
      'Drive through your heels and finish tall.',
    ],
    'romanian deadlift': [
      'Push your hips back rather than bending your knees.',
      'Keep the bar close to your legs.',
      'Stop the descent once you feel a hamstring stretch.',
    ],
    'sumo deadlift': [
      'Take a wide stance with your toes pointed slightly out.',
      'Keep your shins vertical and chest up as you set your grip.',
      'Drive your knees out as you pull to keep tension on your hips.',
    ],
    'trap bar deadlift': [
      'Stand centered inside the bar with a neutral grip.',
      'Keep the bar close to your body throughout the pull.',
      'Drive through your heels and stand up tall at the top.',
    ],
    'rack pull': [
      'Set the pins just below knee height to start.',
      'Keep your back flat and drive through your heels.',
      "Don't round your back to make up for a heavy load.",
    ],
    'good morning': [
      'Keep a soft bend in your knees and a flat back.',
      'Hinge at the hips, pushing them back as you lower your torso.',
      'Use a light weight until your hamstring flexibility and form are solid.',
    ],
    'back extension': [
      'Hinge at the hips rather than rounding your lower back.',
      'Squeeze your glutes at the top instead of hyperextending your spine.',
      'Control the descent instead of dropping into the stretch.',
    ],
    'pull-up': [
      'Start from a dead hang for full range of motion.',
      'Drive your elbows down and back.',
      "Avoid excessive kipping if you're training for strength.",
    ],
    'chin-up': [
      'Use an underhand grip about shoulder-width apart.',
      'Start from a dead hang and pull your chest toward the bar.',
      'Lower under control instead of dropping from the top.',
    ],
    'lat pulldown': [
      'Pull the bar to your upper chest, not behind your neck.',
      'Lead with your elbows and squeeze your shoulder blades down.',
      'Avoid leaning back excessively to use momentum.',
    ],
    'barbell row': [
      'Hinge at the hips and keep your back flat.',
      'Pull the bar to your lower ribcage.',
      'Control the descent instead of letting it drop.',
    ],
    'pendlay row': [
      'Start each rep from a dead stop on the floor.',
      'Keep your torso close to parallel with the floor.',
      'Pull explosively into your lower ribcage, then reset fully.',
    ],
    'dumbbell row': [
      'Support yourself with one hand and knee on a bench.',
      'Keep your back flat and pull the dumbbell to your hip.',
      'Avoid twisting your torso to help the weight up.',
    ],
    't-bar row': [
      'Hinge at the hips with a flat back before pulling.',
      'Pull the handles to your sternum, squeezing your shoulder blades.',
      'Lower with control rather than letting the weight drop.',
    ],
    'seated cable row': [
      'Sit tall and avoid rounding your lower back.',
      'Pull the handle to your torso while keeping your elbows close.',
      "Don't rock your torso to generate momentum.",
    ],
    'chest-supported row': [
      'Keep your chest pressed against the pad throughout the set.',
      'Pull with your elbows rather than just your hands.',
      'Squeeze your shoulder blades together at the top of each rep.',
    ],
    'face pull': [
      'Pull the rope toward your face, leading with your elbows high.',
      'Externally rotate your hands at the end of the pull.',
      'Use a light weight and focus on the squeeze, not the load.',
    ],

    // Shoulders
    'overhead press': [
      'Brace your core and squeeze your glutes to protect your lower back.',
      'Press in a straight line, moving your head back slightly.',
      'Lock out fully at the top without excessive shrugging.',
    ],
    'seated dumbbell press': [
      'Keep your back flat against the bench pad.',
      'Press the dumbbells up without arching your lower back.',
      'Lower until your upper arms are about parallel to the floor.',
    ],
    'arnold press': [
      'Start with your palms facing you and rotate as you press.',
      'Keep your core braced to avoid leaning back.',
      'Finish with your palms facing forward at the top of the press.',
    ],
    'push press': [
      'Dip slightly at the knees before driving the bar overhead.',
      'Use your legs to generate power, not just your shoulders.',
      'Finish with the bar locked out directly overhead.',
    ],
    'landmine press': [
      'Brace your core and press the bar up and slightly forward.',
      'Keep a stable base with your feet shoulder-width apart.',
      'Control the lowering phase back to the starting position.',
    ],
    'lateral raise': [
      'Raise your arms out to the sides, not in front of you.',
      'Stop at about shoulder height to keep tension on your delts.',
      "Use a lighter weight than you think, it's easy to cheat this one.",
    ],
    'front raise': [
      'Raise the weight to about eye level, no higher.',
      'Keep a slight bend in your elbows throughout.',
      'Avoid swinging the weight up with your hips.',
    ],
    'rear delt fly': [
      'Hinge forward at the hips with a flat back.',
      'Lead with your elbows and squeeze your shoulder blades together.',
      'Keep a slight bend in your elbows throughout the movement.',
    ],
    'upright row': [
      'Pull the bar close to your body, leading with your elbows.',
      'Stop at about chest height to protect your shoulders.',
      'Use a grip width that feels comfortable on your wrists.',
    ],
    'shrug': [
      'Lift your shoulders straight up toward your ears.',
      'Avoid rolling your shoulders, just go straight up and down.',
      'Pause briefly at the top for a full contraction.',
    ],

    // Legs
    'squat': [
      'Keep your chest up and core braced.',
      'Push your knees out in line with your toes.',
      'Go to at least parallel depth with control.',
    ],
    'back squat': [
      'Keep your chest up and core braced.',
      'Push your knees out in line with your toes.',
      'Go to at least parallel depth with control.',
    ],
    'front squat': [
      'Keep your elbows up high to support the bar on your shoulders.',
      'Keep your torso as upright as possible throughout the squat.',
      'Sit down between your hips rather than back like a back squat.',
    ],
    'goblet squat': [
      'Hold the weight close to your chest throughout the movement.',
      'Sit down between your hips and keep your chest up.',
      'Push your knees out in line with your toes.',
    ],
    'hack squat': [
      'Keep your back flat against the pad throughout the set.',
      'Push your knees out in line with your toes.',
      'Avoid locking your knees out aggressively at the top.',
    ],
    'sissy squat': [
      'Keep your hips extended and lean back as you bend your knees.',
      'Move slowly and stay in control throughout the range.',
      'Hold onto something stable until your balance and strength improve.',
    ],
    'zercher squat': [
      'Cradle the bar in the crooks of your elbows.',
      'Keep your torso as upright as possible.',
      'Use padding on the bar until you build tolerance.',
    ],
    'bulgarian split squat': [
      'Rest your rear foot on a bench behind you.',
      'Keep most of your weight on your front leg.',
      'Lower until your front thigh is about parallel to the floor.',
    ],
    'walking lunge': [
      'Keep your front knee tracking over your foot.',
      "Take a step long enough that your knee doesn't pass your toes.",
      'Keep your torso upright throughout.',
    ],
    'reverse lunge': [
      'Step back and lower your back knee toward the floor.',
      'Keep your front knee tracking over your foot.',
      'Push through your front heel to return to standing.',
    ],
    'step-up': [
      'Choose a box height that lets you keep good form.',
      'Drive through your front heel rather than pushing off your back foot.',
      'Control the descent back down instead of dropping.',
    ],
    'leg press': [
      'Keep your lower back flat against the pad.',
      "Don't let your knees cave inward as you press.",
      'Avoid locking your knees out aggressively at the top.',
    ],
    'leg extension': [
      'Sit back fully in the seat with your knees aligned to the pivot.',
      'Extend fully without slamming into the top of the range.',
      'Lower with control instead of letting the weight stack drop.',
    ],
    'leg curl': [
      'Keep your hips pressed into the pad throughout the movement.',
      'Curl through a full range of motion.',
      'Control the return instead of letting the weight snap back.',
    ],
    'nordic curl': [
      'Anchor your ankles securely before starting.',
      'Lower yourself as slowly as you can control.',
      'Use your hands to catch yourself and push back up if needed.',
    ],
    'hip thrust': [
      'Set your upper back on the bench with the bar over your hips.',
      'Drive through your heels and squeeze your glutes at the top.',
      "Avoid overextending your lower back at the top of the rep.",
    ],
    'glute bridge': [
      'Drive through your heels and squeeze your glutes at the top.',
      'Keep your ribs down to avoid arching your lower back.',
      'Pause briefly at the top for a full contraction.',
    ],
    'calf raise': [
      'Get a full stretch at the bottom of each rep.',
      'Pause briefly at the top for a full contraction.',
      'Control the tempo rather than bouncing.',
    ],
    'seated calf raise': [
      'Get a full stretch at the bottom of each rep.',
      'Pause briefly at the top for a full contraction.',
      'Control the tempo rather than bouncing through reps.',
    ],

    // Arms
    'bicep curl': [
      'Keep your elbows pinned to your sides.',
      'Avoid swinging the weight with your back.',
      "Control the lowering phase, don't just drop it.",
    ],
    'hammer curl': [
      'Keep your palms facing each other throughout the curl.',
      'Keep your elbows pinned to your sides.',
      "Control the lowering phase, don't just drop it.",
    ],
    'preacher curl': [
      'Rest your upper arms fully on the pad before starting.',
      'Avoid locking your elbows out completely at the bottom.',
      'Control the descent instead of letting the weight drop.',
    ],
    'concentration curl': [
      'Brace your elbow against your inner thigh for stability.',
      'Curl through a full range of motion without swinging.',
      'Squeeze at the top before lowering with control.',
    ],
    'cable curl': [
      'Keep your elbows pinned to your sides throughout.',
      'Avoid leaning back to help the weight up.',
      'Control the return instead of letting the cable snap back.',
    ],
    'ez bar curl': [
      'Use the angled grips to keep your wrists comfortable.',
      'Keep your elbows pinned to your sides.',
      "Control the lowering phase, don't just drop it.",
    ],
    'reverse curl': [
      'Use an overhand grip throughout the curl.',
      'Keep your elbows pinned to your sides.',
      'Control the descent instead of letting the weight drop.',
    ],
    'wrist curl': [
      'Rest your forearms on a bench or your thighs.',
      'Move through a full range of motion at the wrist.',
      'Use a light weight since this is a small, easily strained joint.',
    ],
    'tricep pushdown': [
      'Keep your elbows pinned to your sides.',
      'Extend fully without locking out aggressively.',
      'Control the return instead of letting the weight snap back.',
    ],
    'skull crusher': [
      'Keep your upper arms still and vertical throughout.',
      'Lower the bar toward your forehead or just behind it.',
      'Extend fully without locking out aggressively.',
    ],
    'overhead tricep extension': [
      'Keep your elbows pointed forward and close to your head.',
      'Lower the weight behind your head with control.',
      'Extend fully without flaring your elbows out.',
    ],
    'cable overhead extension': [
      'Keep your elbows close to your head throughout.',
      'Extend fully without locking out aggressively.',
      'Control the return instead of letting the cable snap back.',
    ],
    'close-grip bench press': [
      'Use a grip about shoulder-width apart or slightly narrower.',
      'Keep your elbows tucked closer to your body than a regular bench press.',
      'Lower the bar to your lower chest with control.',
    ],
    'tricep dip': [
      'Keep your torso upright to bias your triceps over your chest.',
      'Lower until your elbows reach about 90 degrees.',
      'Press back up without flaring your elbows out wide.',
    ],
    'diamond push-up': [
      'Form a diamond shape with your thumbs and index fingers.',
      'Keep your elbows close to your body as you lower.',
      'Keep your body in a straight line throughout.',
    ],

    // Core
    'plank': [
      'Keep your body in a straight line from head to heels.',
      'Brace your core and squeeze your glutes.',
      "Don't let your hips sag or pike up.",
    ],
    'side plank': [
      'Stack your shoulders, hips, and ankles in one line.',
      'Keep your supporting elbow directly under your shoulder.',
      "Don't let your hips drop toward the floor.",
    ],
    'crunch': [
      'Curl your shoulders up off the floor, not your neck.',
      'Keep your lower back pressed into the floor.',
      'Exhale as you crunch up to engage your core fully.',
    ],
    'sit-up': [
      'Keep your feet anchored or held down for stability.',
      'Curl up through your spine rather than yanking with your neck.',
      'Control the descent back down instead of dropping.',
    ],
    'hanging leg raise': [
      'Keep a slight bend in your knees to protect your lower back.',
      'Raise your legs by curling your pelvis, not just swinging them.',
      'Avoid excessive swinging to generate momentum.',
    ],
    'hanging knee raise': [
      'Curl your pelvis to bring your knees up rather than swinging.',
      'Keep your core braced throughout the movement.',
      'Lower with control instead of letting your legs drop.',
    ],
    'russian twist': [
      'Keep your chest up and back flat, not rounded.',
      'Rotate from your torso rather than just your arms.',
      'Keep your feet lifted for an added core challenge.',
    ],
    'cable woodchopper': [
      'Rotate through your torso and hips together.',
      'Keep your arms relatively straight and let your core do the work.',
      'Control the return instead of letting the cable snap back.',
    ],
    'ab wheel rollout': [
      'Brace your core hard before you start rolling out.',
      "Don't let your lower back sag as you extend.",
      'Roll out only as far as you can control the return.',
    ],
    'mountain climber': [
      'Keep your hips level, avoid piking up.',
      'Drive your knees toward your chest at a controlled pace.',
      'Keep your core braced throughout the movement.',
    ],
    'dead bug': [
      'Press your lower back into the floor throughout.',
      'Move opposite arm and leg slowly and with control.',
      "Don't let your back arch as you extend your limbs.",
    ],
    'bicycle crunch': [
      'Bring your elbow to the opposite knee with control.',
      'Keep your lower back pressed into the floor.',
      'Avoid pulling on your neck with your hands.',
    ],
    'v-up': [
      'Reach your hands toward your toes as you fold up.',
      'Keep your legs relatively straight throughout the movement.',
      'Control the descent back down instead of dropping.',
    ],
    'pallof press': [
      'Resist the cable pulling you sideways as you press out.',
      'Keep your core braced and hips square throughout.',
      'Press straight out and pull straight back in, no twisting.',
    ],

    // Functional & Olympic
    'kettlebell swing': [
      "Hinge at the hips, don't squat the weight up.",
      'Drive through your hips to snap the kettlebell up.',
      'Keep your back flat and core braced throughout.',
    ],
    'clean and jerk': [
      'Keep the bar close to your body during the pull.',
      'Drop under the bar quickly as you catch it on your shoulders.',
      'Drive the bar overhead in the jerk with a slight leg dip.',
    ],
    'snatch': [
      'Keep the bar close to your body throughout the pull.',
      'Pull yourself under the bar quickly to catch it overhead.',
      'Lock out your arms fully as you receive the bar.',
    ],
    'power clean': [
      'Keep the bar close to your shins and thighs during the pull.',
      'Extend explosively through your hips as the bar passes your knees.',
      'Catch the bar on your shoulders in a quarter-squat position.',
    ],
    "farmer's carry": [
      'Keep your shoulders back and core braced as you walk.',
      'Take controlled steps rather than rushing.',
      "Don't let the weights pull your shoulders forward.",
    ],
    'battle ropes': [
      'Keep your core braced and knees slightly bent.',
      'Generate waves from your shoulders, not just your wrists.',
      'Keep a steady rhythm rather than rushing and breaking form.',
    ],
    'box jump': [
      'Swing your arms to generate upward momentum.',
      'Land softly with your knees bent to absorb impact.',
      'Step down off the box rather than jumping down.',
    ],
    'burpee': [
      'Keep your core braced as you drop into the plank.',
      'Land softly with bent knees on the jump.',
      'Move at a pace you can sustain with good form.',
    ],
    'wall ball': [
      'Sit your hips back into a squat before you throw.',
      'Drive up through your legs to power the throw.',
      'Catch the ball and absorb it back into the squat.',
    ],
    'thruster': [
      'Sit your hips back into a full squat before pressing.',
      'Drive up out of the squat to power the press overhead.',
      'Keep your core braced throughout to protect your lower back.',
    ],
    'turkish get-up': [
      'Keep your eyes on the weight throughout the movement.',
      'Move slowly and deliberately through each position.',
      'Keep your arm locked out overhead the entire time.',
    ],
    'medicine ball slam': [
      'Reach fully overhead before slamming the ball down.',
      'Use your hips and core to drive the slam.',
      'Catch the bounce and reset your stance before the next rep.',
    ],
    'sled push': [
      'Keep your shins angled and drive through the balls of your feet.',
      'Keep your core braced and back flat.',
      'Take short, powerful steps rather than overstriding.',
    ],
    'sled pull': [
      'Keep your core braced as you lean back to pull.',
      'Drive through your heels with each step.',
      'Keep tension on the strap or rope throughout.',
    ],
  };

  static const List<String> _fallback = [
    'Warm up with a lighter set before your working weight.',
    'Move through a full range of motion with control.',
    'Stop the set if your form starts to break down.',
  ];

  static List<String> tips(String exerciseName) {
    final key = exerciseName.toLowerCase().trim();
    return _library[key] ?? _fallback;
  }
}
