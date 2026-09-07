// lib/utils/department_utils.dart


class DepartmentUtils {
  DepartmentUtils._();

  static const List<String> all = [
    'Computer Engineering',
    'Information Technology',
    'Electronics & Telecommunication',
    'Mechanical Engineering',
    'Civil Engineering',
    'Artificial Intelligence & Data Science',
  ];

  static const Map<String, String> _newsQueries = {
    'Computer Engineering':
        'software OR programming OR "artificial intelligence" OR "computer science"',
    'Information Technology':
        '"information technology" OR "cloud computing" OR cybersecurity OR software',
    'Electronics & Telecommunication':
        'electronics OR telecommunications OR semiconductor OR "5G"',
    'Mechanical Engineering':
        '"mechanical engineering" OR robotics OR manufacturing OR automation',
    'Civil Engineering':
        '"civil engineering" OR "construction technology" OR infrastructure OR "smart cities"',
    'Artificial Intelligence & Data Science':
        '"artificial intelligence" OR "machine learning" OR "data science" OR "generative AI"',
  };

  static String newsQueryFor(String department) {
    return _newsQueries[department] ?? 'technology';
  }
}