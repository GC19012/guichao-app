// ignore_for_file: avoid_print, prefer_final_fields, unnecessary_this
import 'dart:math';
import 'dart:convert';

/// A comprehensive random data generator with large built-in datasets.
class GchRandomGen {
  GchRandomGen._();

  static final Random _random = Random.secure();

  // ─── Static Data Constants ───────────────────────────────────────────────

  static const List<String> firstNames = [
    'James', 'Mary', 'John', 'Patricia', 'Robert', 'Jennifer', 'Michael',
    'Linda', 'William', 'Barbara', 'David', 'Elizabeth', 'Richard', 'Susan',
    'Joseph', 'Jessica', 'Thomas', 'Sarah', 'Charles', 'Karen', 'Christopher',
    'Lisa', 'Daniel', 'Nancy', 'Matthew', 'Betty', 'Anthony', 'Margaret',
    'Mark', 'Sandra', 'Donald', 'Ashley', 'Steven', 'Dorothy', 'Paul',
    'Kimberly', 'Andrew', 'Emily', 'Joshua', 'Donna', 'Kenneth', 'Michelle',
    'Kevin', 'Carol', 'Brian', 'Amanda', 'George', 'Melissa', 'Timothy',
    'Deborah', 'Ronald', 'Stephanie', 'Edward', 'Rebecca', 'Jason', 'Sharon',
    'Jeffrey', 'Laura', 'Ryan', 'Cynthia', 'Jacob', 'Kathleen', 'Gary',
    'Amy', 'Nicholas', 'Angela', 'Eric', 'Shirley',
  ];

  static const List<String> lastNames = [
    'Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller',
    'Davis', 'Rodriguez', 'Martinez', 'Hernandez', 'Lopez', 'Gonzalez',
    'Wilson', 'Anderson', 'Thomas', 'Taylor', 'Moore', 'Jackson', 'Martin',
    'Lee', 'Perez', 'Thompson', 'White', 'Harris', 'Sanchez', 'Clark',
    'Ramirez', 'Lewis', 'Robinson', 'Walker', 'Young', 'Allen', 'King',
    'Wright', 'Scott', 'Torres', 'Nguyen', 'Hill', 'Flores', 'Green',
    'Adams', 'Nelson', 'Baker', 'Hall', 'Rivera', 'Campbell', 'Mitchell',
    'Carter', 'Roberts', 'Phillips', 'Evans', 'Turner', 'Torres', 'Parker',
    'Collins', 'Edwards', 'Stewart', 'Flores', 'Morris', 'Nguyen', 'Murphy',
    'Cook', 'Rogers', 'Morgan', 'Peterson', 'Cooper', 'Reed', 'Bailey',
  ];

  static const List<String> chineseFirstNames = [
    '伟', '芳', '娜', '秀英', '敏', '静', '丽', '强', '磊', '洋',
    '艳', '勇', '军', '杰', '娟', '涛', '明', '超', '秀兰', '霞',
    '平', '刚', '桂英', '华', '玲', '志强', '建国', '建华', '雪梅', '春梅',
    '文', '婷', '飞', '鹏', '晶', '斌', '荣', '燕', '芹', '玉兰',
    '俊', '君', '振', '龙', '健', '刚', '峰', '欢', '梅', '雪',
  ];

  static const List<String> chineseLastNames = [
    '王', '李', '张', '刘', '陈', '杨', '黄', '赵', '吴', '周',
    '徐', '孙', '马', '朱', '胡', '郭', '何', '高', '林', '郑',
    '谢', '罗', '梁', '宋', '唐', '许', '韩', '冯', '邓', '曹',
    '彭', '曾', '肖', '田', '董', '潘', '袁', '于', '蒋', '蔡',
    '余', '杜', '叶', '程', '苏', '魏', '吕', '丁', '任', '沈',
    '姚', '卢', '姜', '崔', '钟', '谭', '陆', '汪', '范', '金',
  ];

  static const List<String> cities = [
    'New York', 'Los Angeles', 'Chicago', 'Houston', 'Phoenix', 'Philadelphia',
    'San Antonio', 'San Diego', 'Dallas', 'San Jose', 'Austin', 'Jacksonville',
    'London', 'Paris', 'Tokyo', 'Beijing', 'Shanghai', 'Mumbai', 'Delhi',
    'São Paulo', 'Mexico City', 'Cairo', 'Lagos', 'Dhaka', 'Osaka', 'Karachi',
    'Chongqing', 'Istanbul', 'Buenos Aires', 'Kolkata', 'Kinshasa', 'Lagos',
    'Manila', 'Tianjin', 'Guangzhou', 'Shenzhen', 'Wuhan', 'Chengdu',
    'Sydney', 'Melbourne', 'Toronto', 'Montreal', 'Vancouver', 'Madrid',
    'Barcelona', 'Rome', 'Berlin', 'Vienna', 'Amsterdam', 'Brussels',
    'Seoul', 'Singapore', 'Bangkok', 'Jakarta', 'Kuala Lumpur', 'Hanoi',
    'Nairobi', 'Johannesburg', 'Cape Town', 'Casablanca', 'Accra',
    'Moscow', 'Saint Petersburg', 'Warsaw', 'Prague', 'Budapest',
  ];

  static const List<String> countries = [
    'United States', 'China', 'Japan', 'Germany', 'United Kingdom',
    'France', 'India', 'Italy', 'Canada', 'South Korea', 'Russia',
    'Brazil', 'Australia', 'Spain', 'Mexico', 'Indonesia', 'Netherlands',
    'Saudi Arabia', 'Turkey', 'Switzerland', 'Argentina', 'Sweden',
    'Poland', 'Belgium', 'Norway', 'Austria', 'United Arab Emirates',
    'Nigeria', 'South Africa', 'Egypt', 'Israel', 'Singapore',
    'Malaysia', 'Thailand', 'Philippines', 'Vietnam', 'Pakistan',
    'Bangladesh', 'Iran', 'Iraq', 'Kenya',
  ];

  static const List<String> adjectives = [
    'amazing', 'bold', 'calm', 'daring', 'elegant', 'fierce', 'gentle',
    'happy', 'innovative', 'jovial', 'keen', 'lively', 'majestic',
    'noble', 'optimistic', 'passionate', 'quick', 'radiant', 'serene',
    'thoughtful', 'unique', 'vibrant', 'wise', 'xenial', 'youthful',
    'zealous', 'bright', 'crisp', 'dynamic', 'energetic', 'fluent',
    'graceful', 'humble', 'intelligent', 'joyful', 'kind', 'loyal',
    'mindful', 'nimble', 'open', 'peaceful', 'quiet', 'resourceful',
    'sincere', 'trustworthy', 'upbeat', 'versatile', 'warm', 'exact',
    'agile', 'brilliant', 'charming', 'diligent', 'earnest', 'faithful',
    'genuine', 'honest', 'imaginative', 'just', 'knowledgeable', 'loving',
    'motivated', 'natural', 'orderly', 'polite', 'refined', 'spirited',
    'tenacious', 'understanding', 'valiant', 'witty', 'exemplary', 'youthful',
    'zealous', 'acrobatic', 'balanced', 'creative', 'decisive', 'effective',
    'flexible', 'grounded', 'hardworking', 'industrious', 'judicious',
  ];

  static const List<String> nouns = [
    'mountain', 'river', 'forest', 'ocean', 'desert', 'valley', 'island',
    'cloud', 'star', 'moon', 'sun', 'galaxy', 'planet', 'comet',
    'apple', 'book', 'candle', 'diamond', 'engine', 'flower', 'garden',
    'harbor', 'island', 'jewel', 'kingdom', 'lantern', 'mirror',
    'needle', 'orchard', 'palace', 'quill', 'rainbow', 'summit',
    'tower', 'umbrella', 'vessel', 'window', 'xerograph', 'yacht',
    'zenith', 'bridge', 'castle', 'drum', 'eagle', 'falcon', 'gate',
    'horizon', 'iron', 'jungle', 'kite', 'lighthouse', 'marble',
    'night', 'oak', 'parrot', 'quest', 'ridge', 'shield', 'throne',
    'unicorn', 'volcano', 'wave', 'echo', 'year', 'zone', 'anchor',
    'beacon', 'compass', 'drift', 'element', 'flame', 'glacier',
    'hawk', 'ice', 'jade', 'knot', 'leaf', 'mist', 'nebula',
    'oasis', 'prism', 'quartz', 'reef', 'spark', 'tide', 'unity',
  ];

  static const List<String> verbs = [
    'achieve', 'build', 'create', 'design', 'explore', 'forge', 'grow',
    'help', 'inspire', 'join', 'keep', 'lead', 'make', 'navigate',
    'optimize', 'pursue', 'quest', 'reach', 'solve', 'transform',
    'unlock', 'venture', 'work', 'expand', 'yield', 'zoom', 'accelerate',
    'balance', 'craft', 'discover', 'empower', 'focus', 'generate',
    'harness', 'innovate', 'journey', 'kindle', 'launch', 'motivate',
  ];

  static const List<String> occupations = [
    'Software Engineer', 'Doctor', 'Teacher', 'Lawyer', 'Architect',
    'Designer', 'Nurse', 'Pilot', 'Chef', 'Accountant', 'Manager',
    'Scientist', 'Writer', 'Artist', 'Photographer', 'Journalist',
    'Economist', 'Pharmacist', 'Dentist', 'Veterinarian', 'Psychologist',
    'Marketing Director', 'Product Manager', 'Data Analyst', 'DevOps Engineer',
    'Financial Advisor', 'Civil Engineer', 'Mechanical Engineer',
    'Electrical Engineer', 'Project Manager',
  ];

  static const List<String> companySuffixes = [
    'Inc.', 'LLC', 'Ltd.', 'Corp.', 'Group', 'Holdings', 'Technologies',
    'Solutions', 'Services', 'Partners', 'Consulting', 'Systems',
    'Innovations', 'Ventures', 'Labs', 'Studio', 'Agency', 'Networks',
    'Digital', 'Global',
  ];

  static const List<String> streetTypes = [
    'Street', 'Avenue', 'Boulevard', 'Drive', 'Road', 'Lane', 'Way',
    'Place', 'Court', 'Circle', 'Trail', 'Parkway', 'Commons', 'Loop',
    'Terrace', 'Plaza', 'Square', 'Crescent', 'Grove', 'Ridge',
  ];

  static const List<String> colorNames = [
    'Red', 'Blue', 'Green', 'Yellow', 'Purple', 'Orange', 'Pink',
    'Cyan', 'Magenta', 'Lime', 'Indigo', 'Violet', 'Gold', 'Silver',
    'Bronze', 'Crimson', 'Scarlet', 'Navy', 'Teal', 'Maroon',
    'Coral', 'Salmon', 'Turquoise', 'Lavender', 'Mint', 'Peach',
    'Ivory', 'Beige', 'Charcoal', 'Slate', 'Amber', 'Emerald',
    'Ruby', 'Sapphire', 'Pearl', 'Jade', 'Cobalt', 'Fuchsia',
    'Lilac', 'Cream',
  ];

  static const List<String> fruits = [
    'Apple', 'Banana', 'Cherry', 'Date', 'Elderberry', 'Fig', 'Grape',
    'Honeydew', 'Kiwi', 'Lemon', 'Mango', 'Nectarine', 'Orange',
    'Papaya', 'Quince', 'Raspberry', 'Strawberry', 'Tangerine',
    'Watermelon', 'Blueberry', 'Cranberry', 'Peach', 'Pear', 'Plum',
    'Pineapple', 'Avocado', 'Coconut', 'Pomegranate', 'Lychee', 'Guava',
  ];

  static const List<String> animals = [
    'Lion', 'Tiger', 'Elephant', 'Giraffe', 'Zebra', 'Gorilla', 'Chimpanzee',
    'Penguin', 'Eagle', 'Dolphin', 'Shark', 'Whale', 'Octopus', 'Crab',
    'Horse', 'Deer', 'Wolf', 'Bear', 'Fox', 'Rabbit', 'Squirrel', 'Hedgehog',
    'Panda', 'Koala', 'Kangaroo', 'Platypus', 'Wombat', 'Cheetah', 'Leopard',
    'Jaguar', 'Panther', 'Rhinoceros', 'Hippopotamus', 'Crocodile', 'Alligator',
    'Parrot', 'Flamingo', 'Peacock', 'Owl', 'Hawk',
  ];

  // ─── Generator Methods ───────────────────────────────────────────────────

  /// Generates a random English full name.
  static String name({Random? rng}) {
    final r = rng ?? _random;
    return '${pickOne(firstNames, rng: r)} ${pickOne(lastNames, rng: r)}';
  }

  /// Generates a random Chinese full name.
  static String chineseName({Random? rng}) {
    final r = rng ?? _random;
    return '${pickOne(chineseLastNames, rng: r)}${pickOne(chineseFirstNames, rng: r)}';
  }

  /// Generates a random email address.
  static String email({Random? rng}) {
    final r = rng ?? _random;
    final first = pickOne(firstNames, rng: r).toLowerCase();
    final last = pickOne(lastNames, rng: r).toLowerCase();
    final domains = ['gmail.com', 'yahoo.com', 'hotmail.com', 'outlook.com', 'example.com', 'mail.com'];
    final num = randomInt(1, 999, rng: r);
    return '${first}.${last}${num}@${pickOne(domains, rng: r)}';
  }

  /// Generates a random US-format phone number.
  static String phone({Random? rng}) {
    final r = rng ?? _random;
    final area = randomInt(200, 999, rng: r);
    final mid = randomInt(200, 999, rng: r);
    final end = randomInt(1000, 9999, rng: r);
    return '($area) $mid-$end';
  }

  /// Generates a random address.
  static String address({Random? rng}) {
    final r = rng ?? _random;
    final num = randomInt(1, 9999, rng: r);
    final street = pickOne(adjectives, rng: r);
    final type = pickOne(streetTypes, rng: r);
    final city = pickOne(cities, rng: r);
    final zip = digits(5, rng: r);
    return '$num $street $type, $city $zip';
  }

  /// Generates a random company name.
  static String company({Random? rng}) {
    final r = rng ?? _random;
    final adj = pickOne(adjectives, rng: r);
    final noun = pickOne(nouns, rng: r);
    final suffix = pickOne(companySuffixes, rng: r);
    return '${adj.substring(0, 1).toUpperCase()}${adj.substring(1)} '
        '${noun.substring(0, 1).toUpperCase()}${noun.substring(1)} $suffix';
  }

  /// Generates a random job title.
  static String jobTitle({Random? rng}) {
    return pickOne(occupations, rng: rng);
  }

  /// Generates a random sentence.
  static String sentence({int wordCount = 8, Random? rng}) {
    final r = rng ?? _random;
    final words = <String>[];
    for (int i = 0; i < wordCount; i++) {
      if (i == 0) {
        final adj = pickOne(adjectives, rng: r);
        words.add('${adj[0].toUpperCase()}${adj.substring(1)}');
      } else if (i % 3 == 0) {
        words.add(pickOne(verbs, rng: r));
      } else if (i % 2 == 0) {
        words.add(pickOne(adjectives, rng: r));
      } else {
        words.add(pickOne(nouns, rng: r));
      }
    }
    return '${words.join(" ")}.';
  }

  /// Generates a random paragraph of [sentenceCount] sentences.
  static String paragraph({int sentenceCount = 4, Random? rng}) {
    final r = rng ?? _random;
    return List.generate(sentenceCount, (_) => sentence(rng: r)).join(' ');
  }

  /// Generates a random integer between [min] and [max] (inclusive).
  static int randomInt(int min, int max, {Random? rng}) {
    final r = rng ?? _random;
    return min + r.nextInt(max - min + 1);
  }

  /// Generates a random double between [min] and [max].
  static double randomDouble(double min, double max, {Random? rng}) {
    final r = rng ?? _random;
    return min + r.nextDouble() * (max - min);
  }

  /// Generates a random boolean, with [probability] chance of being true.
  static bool randomBool({double probability = 0.5, Random? rng}) {
    final r = rng ?? _random;
    return r.nextDouble() < probability;
  }

  /// Generates a random IPv4 address string.
  static String ipAddress({Random? rng}) {
    final r = rng ?? _random;
    return '${r.nextInt(256)}.${r.nextInt(256)}.${r.nextInt(256)}.${r.nextInt(256)}';
  }

  /// Generates a random MAC address.
  static String macAddress({Random? rng}) {
    final r = rng ?? _random;
    return List.generate(6, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join(':').toUpperCase();
  }

  /// Generates a random UUID v4.
  static String uuid({Random? rng}) {
    final r = rng ?? Random.secure();
    final bytes = List<int>.generate(16, (_) => r.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    String h(int b) => b.toRadixString(16).padLeft(2, '0');
    final b = bytes.map(h).toList();
    return '${b[0]}${b[1]}${b[2]}${b[3]}-${b[4]}${b[5]}-'
        '${b[6]}${b[7]}-${b[8]}${b[9]}-'
        '${b[10]}${b[11]}${b[12]}${b[13]}${b[14]}${b[15]}';
  }

  /// Generates a random hex color string.
  static String hexColor({Random? rng}) {
    final r = rng ?? _random;
    return '#${r.nextInt(0x1000000).toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  /// Picks one element at random from [list].
  static T pickOne<T>(List<T> list, {Random? rng}) {
    final r = rng ?? _random;
    return list[r.nextInt(list.length)];
  }

  /// Picks [count] unique elements at random from [list].
  static List<T> pickMany<T>(List<T> list, int count, {Random? rng}) {
    final r = rng ?? _random;
    final copy = List<T>.from(list);
    copy.shuffle(r);
    return copy.take(count.clamp(0, copy.length)).toList();
  }

  /// Returns a shuffled copy of [list].
  static List<T> shuffle<T>(List<T> list, {Random? rng}) {
    final r = rng ?? _random;
    final copy = List<T>.from(list);
    copy.shuffle(r);
    return copy;
  }

  /// Generates a random string of [length] characters from [charset].
  static String string(int length, {String charset = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789', Random? rng}) {
    final r = rng ?? _random;
    return List.generate(length, (_) => charset[r.nextInt(charset.length)]).join();
  }

  /// Generates a string of [length] random digits.
  static String digits(int length, {Random? rng}) {
    final r = rng ?? _random;
    return List.generate(length, (_) => r.nextInt(10).toString()).join();
  }

  /// Generates a fake credit card number (Luhn-valid, Visa pattern).
  static String creditCard({Random? rng}) {
    final r = rng ?? _random;
    // Visa starts with 4
    final parts = ['4'];
    for (int i = 0; i < 14; i++) {
      parts.add(r.nextInt(10).toString());
    }
    // Calculate Luhn check digit
    final nums = parts.map(int.parse).toList();
    int sum = 0;
    bool alt = true;
    for (int i = nums.length - 1; i >= 0; i--) {
      int d = nums[i];
      if (alt) {
        d *= 2;
        if (d > 9) d -= 9;
      }
      sum += d;
      alt = !alt;
    }
    final check = (10 - (sum % 10)) % 10;
    parts.add(check.toString());
    final number = parts.join();
    return '${number.substring(0, 4)} ${number.substring(4, 8)} ${number.substring(8, 12)} ${number.substring(12)}';
  }

  /// Generates a fake IBAN (GB format, 22 chars).
  static String iban({Random? rng}) {
    final r = rng ?? _random;
    final bankCode = string(4, charset: 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', rng: r);
    final sortCode = digits(6, rng: r);
    final accountNumber = digits(8, rng: r);
    // Check digits (simplified, not real Mod97)
    final checkDigits = randomInt(10, 99, rng: r).toString();
    return 'GB$checkDigits$bankCode$sortCode$accountNumber';
  }

  /// Generates a fake ISBN-13 (978 prefix, Luhn-compatible check).
  static String isbn13({Random? rng}) {
    final r = rng ?? _random;
    final prefix = '978';
    final group = digits(1, rng: r);
    final publisher = digits(4, rng: r);
    final title = digits(4, rng: r);
    final base = '$prefix$group$publisher$title';
    // Compute ISBN-13 check digit
    int sum = 0;
    for (int i = 0; i < 12; i++) {
      sum += int.parse(base[i]) * (i % 2 == 0 ? 1 : 3);
    }
    final check = (10 - (sum % 10)) % 10;
    return '$prefix-$group-$publisher-$title-$check';
  }

  /// Generates a random color name from the built-in list.
  static String colorName({Random? rng}) {
    return pickOne(colorNames, rng: rng);
  }

  /// Generates a random fruit name.
  static String fruit({Random? rng}) {
    return pickOne(fruits, rng: rng);
  }

  /// Generates a random animal name.
  static String animal({Random? rng}) {
    return pickOne(animals, rng: rng);
  }

  /// Generates a random country name.
  static String country({Random? rng}) {
    return pickOne(countries, rng: rng);
  }

  /// Generates a random city name.
  static String city({Random? rng}) {
    return pickOne(cities, rng: rng);
  }

  /// Generates a map of random user profile data.
  static Map<String, dynamic> userProfile({Random? rng}) {
    final r = rng ?? _random;
    return {
      'name': name(rng: r),
      'email': email(rng: r),
      'phone': phone(rng: r),
      'address': address(rng: r),
      'occupation': jobTitle(rng: r),
      'company': company(rng: r),
      'country': country(rng: r),
      'age': randomInt(18, 75, rng: r),
      'uuid': uuid(rng: r),
    };
  }

  /// Generates a list of [count] random user profiles.
  static List<Map<String, dynamic>> userProfiles(int count, {Random? rng}) {
    final r = rng ?? _random;
    return List.generate(count, (_) => userProfile(rng: r));
  }

  /// Generates a random lorem ipsum-style text with [paragraphCount] paragraphs.
  static String loremIpsum({int paragraphCount = 3, Random? rng}) {
    final r = rng ?? _random;
    return List.generate(paragraphCount, (_) => paragraph(sentenceCount: randomInt(3, 6, rng: r), rng: r))
        .join('\n\n');
  }

  /// Generates a random hex string of [byteCount] bytes.
  static String hexBytes(int byteCount, {Random? rng}) {
    final r = rng ?? _random;
    return List.generate(byteCount, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  }

  /// Generates a weighted random pick from a list with given weights.
  static T weightedPick<T>(List<T> items, List<double> weights, {Random? rng}) {
    assert(items.length == weights.length, 'Items and weights must have the same length');
    final r = rng ?? _random;
    final total = weights.fold<double>(0, (a, b) => a + b);
    double rand = r.nextDouble() * total;
    for (int i = 0; i < items.length; i++) {
      rand -= weights[i];
      if (rand <= 0) return items[i];
    }
    return items.last;
  }

  /// Generates a random date between [start] and [end].
  static DateTime dateTime(DateTime start, DateTime end, {Random? rng}) {
    final r = rng ?? _random;
    final diff = end.difference(start).inSeconds;
    final offset = r.nextInt(diff.abs() + 1);
    return start.add(Duration(seconds: offset));
  }

  /// Generates a random past date within [maxDaysAgo] days.
  static DateTime pastDate({int maxDaysAgo = 365, Random? rng}) {
    final r = rng ?? _random;
    final daysAgo = r.nextInt(maxDaysAgo) + 1;
    return DateTime.now().subtract(Duration(days: daysAgo));
  }

  /// Generates a random future date within [maxDaysAhead] days.
  static DateTime futureDate({int maxDaysAhead = 365, Random? rng}) {
    final r = rng ?? _random;
    final daysAhead = r.nextInt(maxDaysAhead) + 1;
    return DateTime.now().add(Duration(days: daysAhead));
  }

  /// Generates a list of [count] random integers in [[min], [max]].
  static List<int> intList(int count, int min, int max, {Random? rng}) {
    final r = rng ?? _random;
    return List.generate(count, (_) => randomInt(min, max, rng: r));
  }

  /// Generates a list of [count] random doubles in [[min], [max]].
  static List<double> doubleList(int count, double min, double max, {Random? rng}) {
    final r = rng ?? _random;
    return List.generate(count, (_) => randomDouble(min, max, rng: r));
  }

  /// Generates a random valid US zip code.
  static String usZipCode({Random? rng}) {
    return digits(5, rng: rng);
  }

  /// Generates a random price string (e.g., "19.99").
  static String price({double min = 0.99, double max = 999.99, Random? rng}) {
    final value = randomDouble(min, max, rng: rng);
    return value.toStringAsFixed(2);
  }

  /// Generates a random latitude value (-90 to 90).
  static double latitude({Random? rng}) {
    return randomDouble(-90.0, 90.0, rng: rng);
  }

  /// Generates a random longitude value (-180 to 180).
  static double longitude({Random? rng}) {
    return randomDouble(-180.0, 180.0, rng: rng);
  }

  /// Generates a random geo-coordinate pair.
  static Map<String, double> coordinates({Random? rng}) {
    return {
      'latitude': latitude(rng: rng),
      'longitude': longitude(rng: rng),
    };
  }

  /// Generates a random URL string.
  static String url({Random? rng}) {
    final r = rng ?? _random;
    final protocols = ['https', 'http'];
    final tlds = ['com', 'net', 'org', 'io', 'app', 'dev'];
    final proto = pickOne(protocols, rng: r);
    final domain = pickOne(adjectives, rng: r).toLowerCase();
    final tld = pickOne(tlds, rng: r);
    final path = pickOne(nouns, rng: r).toLowerCase();
    return '$proto://$domain.$tld/$path';
  }

  /// Generates a random US Social Security Number (SSN) pattern (for testing only).
  static String ssn({Random? rng}) {
    final r = rng ?? _random;
    final area = randomInt(100, 799, rng: r);
    final group = randomInt(10, 99, rng: r);
    final serial = randomInt(1000, 9999, rng: r);
    return '$area-$group-$serial';
  }

  /// Generates a random product name.
  static String productName({Random? rng}) {
    final r = rng ?? _random;
    final adj = pickOne(adjectives, rng: r);
    final noun = pickOne(nouns, rng: r);
    return '${adj[0].toUpperCase()}${adj.substring(1)} ${noun[0].toUpperCase()}${noun.substring(1)}';
  }

  /// Generates a fake order ID.
  static String orderId({Random? rng}) {
    final r = rng ?? _random;
    final prefix = pickOne(['ORD', 'INV', 'REQ', 'TKT'], rng: r);
    return '$prefix-${digits(8, rng: r)}';
  }

  /// Generates a random file extension.
  static String fileExtension({Random? rng}) {
    return pickOne([
      'pdf', 'docx', 'xlsx', 'pptx', 'txt', 'csv', 'json',
      'xml', 'jpg', 'png', 'gif', 'svg', 'mp4', 'mp3',
      'zip', 'tar', 'gz', 'yaml', 'dart', 'py', 'js',
    ], rng: rng);
  }

  /// Generates a random filename with extension.
  static String fileName({Random? rng}) {
    final r = rng ?? _random;
    final base = '${pickOne(adjectives, rng: r)}_${pickOne(nouns, rng: r)}'.toLowerCase();
    final ext = fileExtension(rng: r);
    return '$base.$ext';
  }

  /// Generates random key-value metadata as a Map<String, String>.
  static Map<String, String> metadata({int count = 4, Random? rng}) {
    final r = rng ?? _random;
    final keys = ['version', 'author', 'source', 'category', 'region', 'lang', 'env', 'build'];
    final result = <String, String>{};
    final selectedKeys = pickMany(keys, count.clamp(1, keys.length), rng: r);
    for (final key in selectedKeys) {
      result[key] = pickOne([...adjectives, ...nouns, ...colorNames], rng: r);
    }
    return result;
  }

  /// Generates a random rating between [min] and [max] (e.g., 1-5 stars).
  static double rating({double min = 1.0, double max = 5.0, Random? rng}) {
    final raw = randomDouble(min, max, rng: rng);
    return (raw * 2).round() / 2; // Round to nearest 0.5
  }

  /// Generates a list of random tags (unique).
  static List<String> tags({int count = 3, Random? rng}) {
    return pickMany([...adjectives, ...nouns, ...colorNames, ...animals], count, rng: rng)
        .map((s) => s.toLowerCase())
        .toList();
  }

  /// Generates a simple random avatar URL (using a placeholder service pattern).
  static String avatarUrl({int size = 100, Random? rng}) {
    final r = rng ?? _random;
    final seed = digits(8, rng: r);
    return 'https://avatars.placeholder.com/$size/$seed.jpg';
  }

  /// Generates a random color in ARGB format as an integer.
  static int colorArgb({Random? rng}) {
    final r = rng ?? _random;
    return 0xFF000000 | r.nextInt(0x1000000);
  }

  /// Generates a mock API response body map.
  static Map<String, dynamic> apiResponse({Random? rng}) {
    final r = rng ?? _random;
    return {
      'id': uuid(rng: r),
      'status': pickOne(['success', 'pending', 'error'], rng: r),
      'timestamp': DateTime.now().toIso8601String(),
      'data': userProfile(rng: r),
      'meta': metadata(rng: r),
    };
  }

  /// Generates a random boolean array of [length] elements.
  static List<bool> boolList(int length, {double probability = 0.5, Random? rng}) {
    final r = rng ?? _random;
    return List.generate(length, (_) => r.nextDouble() < probability);
  }

  /// Generates a random matrix of doubles.
  static List<List<double>> matrix(int rows, int cols, {double min = 0, double max = 1, Random? rng}) {
    final r = rng ?? _random;
    return List.generate(rows, (_) => List.generate(cols, (_) => randomDouble(min, max, rng: r)));
  }

  /// Generates a random slug (URL-safe string).
  static String slug({int wordCount = 3, Random? rng}) {
    final r = rng ?? _random;
    final parts = <String>[];
    for (int i = 0; i < wordCount; i++) {
      parts.add(pickOne([...adjectives, ...nouns], rng: r).toLowerCase().replaceAll(' ', '-'));
    }
    return parts.join('-');
  }

  /// Generates a random 6-digit OTP code.
  static String otp({Random? rng}) => digits(6, rng: rng);

  /// Generates a random hex string of [length] characters.
  static String hexString(int length, {Random? rng}) {
    final r = rng ?? _random;
    const chars = '0123456789abcdef';
    return List.generate(length, (_) => chars[r.nextInt(16)]).join();
  }

  /// Generates a list of unique random indices from [0, max).
  static List<int> uniqueIndices(int count, int max, {Random? rng}) {
    final r = rng ?? _random;
    if (count >= max) return List.generate(max, (i) => i);
    final all = List.generate(max, (i) => i);
    all.shuffle(r);
    return all.take(count).toList();
  }

  /// Generates a random sentence in title case.
  static String titleSentence({int wordCount = 5, Random? rng}) {
    final r = rng ?? _random;
    final words = <String>[];
    for (int i = 0; i < wordCount; i++) {
      final w = pickOne([...adjectives, ...nouns], rng: r);
      words.add('${w[0].toUpperCase()}${w.substring(1)}');
    }
    return words.join(' ');
  }

  /// Generates a random key-value pair.
  static MapEntry<String, String> keyValue({Random? rng}) {
    final r = rng ?? _random;
    final key = pickOne(adjectives, rng: r).toLowerCase();
    final value = pickOne(nouns, rng: r).toLowerCase();
    return MapEntry(key, value);
  }

  /// Generates a list of [count] random key-value pairs as a map.
  static Map<String, String> keyValueMap(int count, {Random? rng}) {
    final r = rng ?? _random;
    final result = <String, String>{};
    for (int i = 0; i < count; i++) {
      final kv = keyValue(rng: r);
      result[kv.key] = kv.value;
    }
    return result;
  }

  /// Generates a random semver string (e.g., "2.14.3").
  static String semver({Random? rng}) {
    final r = rng ?? _random;
    final major = r.nextInt(10);
    final minor = r.nextInt(100);
    final patch = r.nextInt(1000);
    return '$major.$minor.$patch';
  }

  /// Generates a random RGB tuple as a list [r, g, b].
  static List<int> rgb({Random? rng}) {
    final r = rng ?? _random;
    return [r.nextInt(256), r.nextInt(256), r.nextInt(256)];
  }

  /// Generates a random RGBA string (e.g., "rgba(120, 45, 200, 0.8)").
  static String rgbaString({Random? rng}) {
    final r = rng ?? _random;
    final red = r.nextInt(256);
    final green = r.nextInt(256);
    final blue = r.nextInt(256);
    final alpha = randomDouble(0.1, 1.0, rng: r).toStringAsFixed(2);
    return 'rgba($red, $green, $blue, $alpha)';
  }

  /// Generates a random duration between [minSeconds] and [maxSeconds].
  static Duration duration({int minSeconds = 1, int maxSeconds = 3600, Random? rng}) {
    final secs = randomInt(minSeconds, maxSeconds, rng: rng);
    return Duration(seconds: secs);
  }

  /// Generates a random sentence in a given language style.
  static String headlineSentence({Random? rng}) {
    final r = rng ?? _random;
    final verb = pickOne(verbs, rng: r);
    final adj = pickOne(adjectives, rng: r);
    final noun = pickOne(nouns, rng: r);
    return '${verb[0].toUpperCase()}${verb.substring(1)} the ${adj} ${noun}'.replaceAll('-', ' ');
  }

  /// Generates a random product SKU (e.g., "GCH-AZX-4521").
  static String sku({Random? rng}) {
    final r = rng ?? _random;
    final part1 = string(3, charset: 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', rng: r);
    final part2 = string(3, charset: 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', rng: r);
    final part3 = digits(4, rng: r);
    return '$part1-$part2-$part3';
  }

  /// Generates a random version tag (semver with optional pre-release).
  static String versionTag({bool preRelease = false, Random? rng}) {
    final r = rng ?? _random;
    final major = r.nextInt(5);
    final minor = r.nextInt(20);
    final patch = r.nextInt(100);
    final base = 'v$major.$minor.$patch';
    if (!preRelease) return base;
    final labels = ['alpha', 'beta', 'rc', 'preview'];
    final label = pickOne(labels, rng: r);
    final n = r.nextInt(5) + 1;
    return '$base-$label.$n';
  }

  /// Generates a list of [count] random product objects.
  static List<Map<String, dynamic>> products(int count, {Random? rng}) {
    final r = rng ?? _random;
    return List.generate(count, (_) => {
      'id': uuid(rng: r),
      'name': productName(rng: r),
      'sku': sku(rng: r),
      'price': price(rng: r),
      'stock': randomInt(0, 500, rng: r),
      'category': pickOne([...nouns], rng: r),
      'rating': rating(rng: r),
      'tags': tags(count: 3, rng: r),
    });
  }

  /// Generates a mock transaction record.
  static Map<String, dynamic> transaction({Random? rng}) {
    final r = rng ?? _random;
    return {
      'txId': 'TX-${digits(12, rng: r)}',
      'amount': price(min: 1.00, max: 9999.99, rng: r),
      'currency': pickOne(['USD', 'EUR', 'GBP', 'JPY', 'CNY', 'AUD', 'CAD'], rng: r),
      'status': pickOne(['completed', 'pending', 'declined', 'refunded'], rng: r),
      'timestamp': DateTime.now().subtract(duration(minSeconds: 1, maxSeconds: 86400 * 30, rng: r)).toIso8601String(),
      'description': sentence(wordCount: 5, rng: r),
    };
  }

  /// Generates a random 2D point with optional bounds.
  static Map<String, double> point({
    double xMin = -100, double xMax = 100,
    double yMin = -100, double yMax = 100,
    Random? rng,
  }) {
    return {
      'x': randomDouble(xMin, xMax, rng: rng),
      'y': randomDouble(yMin, yMax, rng: rng),
    };
  }

  /// Generates a list of random 2D points.
  static List<Map<String, double>> points(int count, {Random? rng}) {
    return List.generate(count, (_) => point(rng: rng));
  }

  /// Picks a random subset of keys from a map.
  static Map<K, V> sampleMap<K, V>(Map<K, V> source, int count, {Random? rng}) {
    final keys = pickMany(source.keys.toList(), count, rng: rng);
    return Map.fromEntries(keys.map((k) => MapEntry(k, source[k] as V)));
  }

  /// Generates a random gradient stop list (offset: 0.0-1.0, color hex).
  static List<Map<String, dynamic>> gradientStops({int stops = 3, Random? rng}) {
    final r = rng ?? _random;
    final offsets = <double>[];
    offsets.add(0.0);
    for (int i = 1; i < stops - 1; i++) {
      offsets.add(randomDouble(0.01, 0.99, rng: r));
    }
    offsets.add(1.0);
    offsets.sort();
    return offsets.map((o) => {
      'offset': o,
      'color': hexColor(rng: r),
    }).toList();
  }

  /// Generates a random event log entry.
  static Map<String, dynamic> logEntry({Random? rng}) {
    final r = rng ?? _random;
    const levels = ['DEBUG', 'INFO', 'WARN', 'ERROR', 'FATAL'];
    final weights = [0.2, 0.5, 0.2, 0.08, 0.02];
    int idx = 0;
    double rand = r.nextDouble();
    for (int i = 0; i < weights.length; i++) {
      rand -= weights[i];
      if (rand <= 0) { idx = i; break; }
    }
    return {
      'level': levels[idx],
      'message': sentence(wordCount: randomInt(5, 12, rng: r), rng: r),
      'timestamp': DateTime.now().toIso8601String(),
      'source': '${pickOne(adjectives, rng: r)}.${pickOne(nouns, rng: r)}',
      'requestId': uuid(rng: r),
    };
  }

  /// Generates a random color palette of [count] colors.
  static List<String> colorPalette({int count = 5, Random? rng}) {
    final r = rng ?? _random;
    return List.generate(count, (_) => hexColor(rng: r));
  }

  /// Generates a mock notification payload.
  static Map<String, dynamic> notification({Random? rng}) {
    final r = rng ?? _random;
    return {
      'id': uuid(rng: r),
      'title': titleSentence(wordCount: 4, rng: r),
      'body': sentence(wordCount: 10, rng: r),
      'type': pickOne(['info', 'alert', 'message', 'reminder', 'update'], rng: r),
      'read': randomBool(probability: 0.3, rng: r),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Generates a random bank account number (16 digits).
  static String bankAccountNumber({Random? rng}) => digits(16, rng: rng);

  /// Generates a random routing number (9 digits, US format).
  static String routingNumber({Random? rng}) => digits(9, rng: rng);

  /// Generates a random Swift/BIC code (e.g., CHASUS33).
  static String swiftCode({Random? rng}) {
    final r = rng ?? _random;
    final bank = string(4, charset: 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', rng: r);
    final country = pickOne(['US', 'GB', 'DE', 'JP', 'CN', 'AU', 'CA', 'FR'], rng: r);
    final location = string(2, charset: 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789', rng: r);
    return '$bank$country$location';
  }

  /// Generates a random domain name (e.g., "bright-falcon.io").
  static String domain({Random? rng}) {
    final r = rng ?? _random;
    final adj = pickOne(adjectives, rng: r).toLowerCase();
    final noun = pickOne(nouns, rng: r).toLowerCase();
    final tld = pickOne(['com', 'io', 'net', 'org', 'app', 'co'], rng: r);
    return '$adj-$noun.$tld';
  }

  /// Generates a list of [count] random tags without duplicates.
  static List<String> uniqueTags(int count, {Random? rng}) {
    return pickMany([...adjectives, ...nouns, ...colorNames], count, rng: rng)
        .map((s) => s.toLowerCase().replaceAll(' ', '-'))
        .toList();
  }

  /// Generates a random geofence object with center and radius.
  static Map<String, dynamic> geofence({Random? rng}) {
    return {
      ...coordinates(rng: rng),
      'radius': randomDouble(100, 5000, rng: rng),
      'name': titleSentence(wordCount: 2, rng: rng),
    };
  }
}
