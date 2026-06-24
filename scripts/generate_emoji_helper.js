const fs = require('fs');
const path = require('path');

const medicalSubjects = [
  { name: 'anatomy', emoji: '💀' },
  { name: 'osteology', emoji: '🦴' },
  { name: 'cardiology', emoji: '🫀' },
  { name: 'cardiovascular', emoji: '🫀' },
  { name: 'pulmonology', emoji: '🫁' },
  { name: 'respiratory', emoji: '🫁' },
  { name: 'neurology', emoji: '🧠' },
  { name: 'neuro', emoji: '🧠' },
  { name: 'gastroenterology', emoji: '🍕' },
  { name: 'nephrology', emoji: '🩺' },
  { name: 'renal', emoji: '🩺' },
  { name: 'hematology', emoji: '🩸' },
  { name: 'endocrinology', emoji: '🧬' },
  { name: 'pathology', emoji: '🔬' },
  { name: 'pharmacology', emoji: '💊' },
  { name: 'microbiology', emoji: '🦠' },
  { name: 'immunology', emoji: '🛡️' },
  { name: 'toxicology', emoji: '☣️' },
  { name: 'forensic medicine', emoji: '🔎' },
  { name: 'pediatrics', emoji: '👶' },
  { name: 'obgyn', emoji: '🤰' },
  { name: 'obstetrics', emoji: '🤰' },
  { name: 'gynecology', emoji: '🤰' },
  { name: 'dermatology', emoji: '🧴' },
  { name: 'radiology', emoji: '🩻' },
  { name: 'ophthalmology', emoji: '👁️' },
  { name: 'ent', emoji: '👂' },
  { name: 'psychiatry', emoji: '🧠' },
  { name: 'surgery', emoji: '🔪' },
  { name: 'orthopedics', emoji: '🦴' },
  { name: 'medicine', emoji: '🩺' }
];

const studyActions = [
  'study', 'revision', 'prep', 'mcqs', 'qbank', 'review', 'read', 'lecture', 'notes',
  'exam', 'class', 'practice', 'flashcards', 'anki', 'test', 'first aid', 'fa', 'video',
  'session', 'learning'
];

const contextMarkers = [
  'in the morning', 'tonight', 'today', 'for exam', 'quick review', 'session 1',
  'session 2', 'module 1', 'chapter 1', 'part a', 'part b', 'unit 1', 'unit 2'
];

const codingLanguages = [
  { name: 'flutter', emoji: '💻' },
  { name: 'react', emoji: '⚛️' },
  { name: 'react native', emoji: '⚛️' },
  { name: 'nextjs', emoji: '🌐' },
  { name: 'python', emoji: '🐍' },
  { name: 'javascript', emoji: '💛' },
  { name: 'typescript', emoji: '💙' },
  { name: 'sql', emoji: '🗄️' },
  { name: 'html', emoji: '🌐' },
  { name: 'css', emoji: '🎨' },
  { name: 'c++', emoji: '⚙️' },
  { name: 'java', emoji: '☕' },
  { name: 'rust', emoji: '🦀' },
  { name: 'go', emoji: '🐹' },
  { name: 'swift', emoji: '🍎' },
  { name: 'android', emoji: '🤖' },
  { name: 'ios', emoji: '📱' },
  { name: 'web', emoji: '🌐' },
  { name: 'node', emoji: '🟢' },
  { name: 'database', emoji: '🗄️' }
];

const codingActions = [
  'coding', 'programming', 'development', 'debugging', 'testing', 'refactoring',
  'deploying', 'git commit', 'code review', 'ui design', 'backend dev', 'frontend dev',
  'database migration', 'api integration', 'server setup'
];

const devContexts = [
  'for the app', 'project', 'bugfix', 'feature', 'refactor', 'v2'
];

const fitnessActivities = [
  { name: 'gym', emoji: '🏋️' },
  { name: 'workout', emoji: '🏋️' },
  { name: 'cardio', emoji: '🏃' },
  { name: 'running', emoji: '🏃' },
  { name: 'jogging', emoji: '🏃' },
  { name: 'walk', emoji: '🚶' },
  { name: 'hiking', emoji: '🥾' },
  { name: 'cycling', emoji: '🚴' },
  { name: 'swimming', emoji: '🏊' },
  { name: 'yoga', emoji: '🧘' },
  { name: 'stretching', emoji: '🧘' },
  { name: 'weightlifting', emoji: '🏋️' },
  { name: 'pushups', emoji: '💪' },
  { name: 'pullups', emoji: '💪' },
  { name: 'pilates', emoji: '🧘' }
];

const fitnessModifiers = [
  'session', 'routine', 'practice', 'training', 'exercise'
];

const mealsAndDrinks = [
  { name: 'breakfast', emoji: '🍳' },
  { name: 'lunch', emoji: '🍽️' },
  { name: 'dinner', emoji: '🍛' },
  { name: 'coffee', emoji: '☕' },
  { name: 'tea', emoji: '☕' },
  { name: 'water', emoji: '💧' },
  { name: 'snack', emoji: '🍎' },
  { name: 'pizza', emoji: '🍕' },
  { name: 'burger', emoji: '🍔' },
  { name: 'salad', emoji: '🥗' },
  { name: 'chicken', emoji: '🍗' },
  { name: 'cooking', emoji: '👨‍🍳' },
  { name: 'baking', emoji: '🍰' },
  { name: 'dishes', emoji: '🧼' }
];

const mealModifiers = [
  'time', 'prep', 'break', 'making', 'eating'
];

const chores = [
  { name: 'cleaning', emoji: '🧹' },
  { name: 'dusting', emoji: '🧹' },
  { name: 'vacuuming', emoji: '🧹' },
  { name: 'laundry', emoji: '🧺' },
  { name: 'ironing', emoji: '👔' },
  { name: 'plants', emoji: '🪴' },
  { name: 'garbage', emoji: '🗑️' },
  { name: 'organizing', emoji: '📂' },
  { name: 'tidy up', emoji: '🧹' },
  { name: 'mopping', emoji: '🧹' }
];

const choreModifiers = [
  'room', 'house', 'desk', 'closet', 'kitchen'
];

const leisure = [
  { name: 'movie', emoji: '🎬' },
  { name: 'show', emoji: '🎬' },
  { name: 'netflix', emoji: '🎬' },
  { name: 'music', emoji: '🎵' },
  { name: 'guitar', emoji: '🎸' },
  { name: 'piano', emoji: '🎹' },
  { name: 'gaming', emoji: '🎮' },
  { name: 'novel', emoji: '📖' },
  { name: 'sketch', emoji: '🎨' },
  { name: 'paint', emoji: '🎨' },
  { name: 'instagram', emoji: '📱' },
  { name: 'reddit', emoji: '📱' },
  { name: 'youtube', emoji: '📺' }
];

const leisureModifiers = [
  'watching', 'playing', 'listening', 'reading', 'checking'
];

// Single word keywords mapping (for tokenized fallback)
const keywordToEmoji = {
  // Medical
  'anatomy': '💀',
  'osteology': '🦴',
  'cardio': '🫀',
  'heart': '🫀',
  'lung': '🫁',
  'pulmo': '🫁',
  'brain': '🧠',
  'neuro': '🧠',
  'kidney': '🩺',
  'renal': '🩺',
  'blood': '🩸',
  'hemo': '🩸',
  'pathology': '🔬',
  'pharma': '💊',
  'drug': '💊',
  'micro': '🦠',
  'virus': '🦠',
  'immune': '🛡️',
  'toxico': '☣️',
  'forensic': '🔎',
  'pediatric': '👶',
  'baby': '👶',
  'obgyn': '🤰',
  'gyne': '🤰',
  'derm': '🧴',
  'skin': '🧴',
  'radio': '🩻',
  'eye': '👁️',
  'opthal': '👁️',
  'ear': '👂',
  'ent': '👂',
  'psych': '🧠',
  'mental': '🧠',
  'surgery': '🔪',
  'ortho': '🦴',
  'medicine': '🩺',
  'doctor': '🩺',
  'clinic': '🏥',
  'ward': '🏥',
  'hospital': '🏥',
  'pathology': '🔬',
  
  // Study
  'study': '📚',
  'read': '📚',
  'revision': '📚',
  'mcq': '📝',
  'qbank': '📝',
  'anki': '🧠',
  'exam': '✍️',
  'test': '✍️',
  'quiz': '✍️',
  'notes': '✍️',
  'lecture': '🎬',
  'video': '🎬',
  'class': '🏫',
  'school': '🏫',
  'college': '🏫',
  'library': '📚',
  'prep': '📚',
  'first aid': '📚',

  // Coding
  'code': '💻',
  'coding': '💻',
  'program': '💻',
  'develop': '💻',
  'app': '💻',
  'web': '🌐',
  'bug': '🐛',
  'debug': '🐛',
  'git': '🐙',
  'github': '🐙',
  'server': '🖥️',
  'api': '🔌',
  'db': '🗄️',
  'sql': '🗄️',
  
  // Life / Health
  'gym': '🏋️',
  'workout': '🏋️',
  'exercise': '🏋️',
  'run': '🏃',
  'walk': '🚶',
  'sleep': '🛌',
  'nap': '🛌',
  'bed': '🛌',
  'eat': '🍽️',
  'food': '🍽️',
  'meal': '🍽️',
  'cook': '👨‍🍳',
  'baking': '🍰',
  'coffee': '☕',
  'tea': '☕',
  'drink': '💧',
  'water': '💧',
  'shower': '🛁',
  'bath': '🛁',
  'clean': '🧹',
  'laundry': '🧺',
  
  // Leisure
  'game': '🎮',
  'gaming': '🎮',
  'play': '🎮',
  'movie': '🎬',
  'netflix': '🎬',
  'music': '🎵',
  'song': '🎵',
  'guitar': '🎸',
  'piano': '🎹',
  'book': '📖',
  'novel': '📖',
  'draw': '🎨',
  'sketch': '🎨',
  'paint': '🎨',
  'social': '📱',
  'chat': '💬',
  'call': '📞',
  'phone': '📱'
};

const taskMap = {};

function add(task, emoji) {
  const normalized = task.trim();
  if (normalized.length === 0) return;
  const key = normalized.toLowerCase();
  taskMap[key] = emoji;
}

// 1. Generate Medical Combinations (30 subjects * 20 actions * 13 markers = 7800 tasks)
for (const sub of medicalSubjects) {
  for (const act of studyActions) {
    add(`${sub.name} ${act}`, sub.emoji);
    add(`${act} ${sub.name}`, sub.emoji);
    
    for (const ctx of contextMarkers) {
      add(`${sub.name} ${act} ${ctx}`, sub.emoji);
      add(`${act} ${sub.name} ${ctx}`, sub.emoji);
    }
  }
}

// 2. Generate Coding Combinations (20 languages * 15 actions * 6 contexts = 1800 tasks)
for (const lang of codingLanguages) {
  for (const act of codingActions) {
    add(`${lang.name} ${act}`, lang.emoji);
    add(`${act} ${lang.name}`, lang.emoji);

    for (const ctx of devContexts) {
      add(`${lang.name} ${act} ${ctx}`, lang.emoji);
      add(`${act} ${lang.name} ${ctx}`, lang.emoji);
    }
  }
}

// 3. Generate Fitness Combinations (15 activities * 5 modifiers = 75 tasks)
for (const fit of fitnessActivities) {
  add(fit.name, fit.emoji);
  for (const mod of fitnessModifiers) {
    add(`${fit.name} ${mod}`, fit.emoji);
    add(`${mod} ${fit.name}`, fit.emoji);
  }
}

// 4. Generate Meal Combinations (14 items * 5 modifiers = 70 tasks)
for (const meal of mealsAndDrinks) {
  add(meal.name, meal.emoji);
  for (const mod of mealModifiers) {
    add(`${meal.name} ${mod}`, meal.emoji);
    add(`${mod} ${meal.name}`, meal.emoji);
  }
}

// 5. Generate Chore Combinations (10 chores * 5 modifiers = 50 tasks)
for (const chore of chores) {
  add(chore.name, chore.emoji);
  for (const mod of choreModifiers) {
    add(`${chore.name} ${mod}`, chore.emoji);
    add(`${mod} ${chore.name}`, chore.emoji);
  }
}

// 6. Generate Leisure Combinations (13 activities * 5 modifiers = 65 tasks)
for (const leis of leisure) {
  add(leis.name, leis.emoji);
  for (const mod of leisureModifiers) {
    add(`${leis.name} ${mod}`, leis.emoji);
    add(`${mod} ${leis.name}`, leis.emoji);
  }
}

// 7. Add specific high-yield entries manually
const manualEntries = {
  // Medical study
  'study anatomy': '💀',
  'read first aid': '📚',
  'anatomy dissection': '💀',
  'anatomy lecture': '💀',
  'physiology lecture': '⚡',
  'cardio study': '🫀',
  'cardiology ward': '🏥',
  'neurology study': '🧠',
  'anki flashcards': '🧠',
  'daily anki': '🧠',
  'anki review': '🧠',
  'qbank practice': '📝',
  'solve mcqs': '📝',
  'solve questions': '📝',
  'first aid revision': '📚',
  'first aid study': '📚',
  'fa page reading': '📚',
  'sketchy medical': '🎨',
  'sketchy micro': '🦠',
  'sketchy pharma': '💊',
  'pathoma video': '🔬',
  'pathoma study': '🔬',
  'uworld practice': '📝',
  'uworld block': '📝',
  'amboss study': '📚',
  'neet pg mock': '📝',
  'fmge preparation': '📚',
  'clinical rotation': '🏥',
  'rounds with doctor': '🩺',
  'patient history taking': '🩺',
  
  // Coding
  'developing app': '💻',
  'app development': '💻',
  'software engineering': '💻',
  'web development': '🌐',
  'writing tests': '🧪',
  'fixing bugs': '🐛',
  'bug fixing': '🐛',
  'refactoring code': '⚙️',
  'git push': '🐙',
  'git merge': '🐙',
  'designing UI': '🎨',
  'building interface': '🖥️',
  
  // Life
  'making tea': '☕',
  'drinking tea': '☕',
  'making coffee': '☕',
  'drinking coffee': '☕',
  'drinking water': '💧',
  'eating breakfast': '🍳',
  'eating lunch': '🍽️',
  'eating dinner': '🍛',
  'cooking breakfast': '🍳',
  'cooking lunch': '🥗',
  'cooking dinner': '🍲',
  'cooking biryani': '🍛',
  'laundry wash': '🧺',
  'ironing clothes': '👔',
  'cleaning room': '🧹',
  'tidying room': '🧹',
  'walk in park': '🚶',
  'morning run': '🏃',
  'evening walk': '🚶',
  'gym workout': '🏋️',
  'yoga practice': '🧘',
  
  // Leisure
  'watch netflix': '🎬',
  'watching movie': '🎬',
  'gaming session': '🎮',
  'play video games': '🎮',
  'listen to music': '🎵',
  'reading novel': '📖',
  'drawing sketches': '🎨',
  'social media scrolling': '📱',
  'browsing reddit': '📱'
};

for (const [k, v] of Object.entries(manualEntries)) {
  add(k, v);
}

// Generate the Dart code string
let code = `// AUTO-GENERATED FILE. DO NOT EDIT DIRECTLY.
// Generated by scripts/generate_emoji_helper.js

class EmojiHelper {
  // A dictionary mapping commonly used tasks/phrases (in lowercase) to emojis.
  // Contains \${Object.keys(taskMap).length} entries.
  static const Map<String, String> taskToEmoji = {
`;

// Sort keys alphabetically so generated file is clean
const sortedTaskKeys = Object.keys(taskMap).sort();
for (const key of sortedTaskKeys) {
  const escapedKey = key.replace(/'/g, "\\\\'");
  code += `    '${escapedKey}': '${taskMap[key]}',\n`;
}

code += `  };

  // A dictionary mapping single root words to emojis (fallback).
  static const Map<String, String> keywordToEmoji = {
`;

const sortedKeywordKeys = Object.keys(keywordToEmoji).sort();
for (const key of sortedKeywordKeys) {
  const escapedKey = key.replace(/'/g, "\\\\'");
  code += `    '${escapedKey}': '${keywordToEmoji[key]}',\n`;
}

code += `  };

  /// Returns the emoji corresponding to the given task title.
  /// First checks for an exact/phrase match, then falls back to matching individual words.
  static String? getEmojiForTask(String title) {
    final clean = title.trim().toLowerCase();
    if (clean.isEmpty) return null;

    // 1. Direct exact or phrase match
    if (taskToEmoji.containsKey(clean)) {
      return taskToEmoji[clean];
    }

    // 2. Tokenized word-by-word match
    final words = clean.split(RegExp(r'[^a-zA-Z0-9]+'));
    for (final word in words) {
      if (word.length < 3) continue; // Skip very short words like 'in', 'on', 'a'
      if (keywordToEmoji.containsKey(word)) {
        return keywordToEmoji[word];
      }
    }

    // 3. Substring match inside the phrase dictionary
    for (final word in words) {
      if (word.length < 3) continue;
      // Find the first task mapping key that contains this word
      for (final key in taskToEmoji.keys) {
        if (key.contains(word)) {
          return taskToEmoji[key];
        }
      }
    }

    return null;
  }

  /// Suggests a list of commonly used task names that match the query prefix.
  static List<String> suggestCommonTasks(String query, {int limit = 10}) {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) return const [];

    final matches = <String>[];
    
    // We prioritize task names that start with the query,
    // then task names that contain the query.
    final startsWithMatches = <String>[];
    final containsMatches = <String>[];

    for (final key in taskToEmoji.keys) {
      if (key.startsWith(trimmed)) {
        startsWithMatches.add(key);
      } else if (key.contains(trimmed)) {
        containsMatches.add(key);
      }
    }

    // Sort to show shorter task names first for better aesthetic
    startsWithMatches.sort((a, b) => a.length.compareTo(b.length));
    containsMatches.sort((a, b) => a.length.compareTo(b.length));

    matches.addAll(startsWithMatches);
    matches.addAll(containsMatches);

    // Title-case helper for suggestions
    String titleCase(String text) {
      if (text.isEmpty) return text;
      return text.split(' ').map((word) {
        if (word.isEmpty) return '';
        return word[0].toUpperCase() + word.substring(1);
      }).join(' ');
    }

    final uniqueMatches = <String>{};
    final results = <String>[];
    
    for (final match in matches) {
      final capitalized = titleCase(match);
      if (uniqueMatches.add(capitalized)) {
        results.add(capitalized);
      }
      if (results.length >= limit) break;
    }

    return results;
  }

  /// Helper to determine if a string already has a leading emoji/icon.
  static bool hasLeadingEmoji(String title) {
    final clean = title.trim();
    if (clean.isEmpty) return false;
    final firstChar = clean.runes.first;
    if (firstChar > 127 || (firstChar >= 0x2000 && firstChar <= 0x32ff) || (firstChar >= 0x1f000)) {
      final charStr = String.fromCharCode(firstChar);
      final isCommonPunct = RegExp(r'^[\\s()[\\].{}!@#%^&*_\\-+=|\\\\:;"' "'" r'<>,.?/~]$').hasMatch(charStr);
      return !isCommonPunct;
    }
    return false;
  }

  /// Appends or prepends a matched emoji if no leading emoji exists.
  static String cleanAndPrependEmoji(String title, String defaultEmoji) {
    final clean = title.trim();
    if (clean.isEmpty) return clean;
    if (hasLeadingEmoji(clean)) return clean;
    final emoji = getEmojiForTask(clean) ?? defaultEmoji;
    return '$emoji $clean';
  }
}
`;

fs.writeFileSync(path.join(__dirname, '../lib/utils/emoji_helper.dart'), code, 'utf-8');
console.log('Successfully generated lib/utils/emoji_helper.dart with ' + Object.keys(taskMap).length + ' entries!');
